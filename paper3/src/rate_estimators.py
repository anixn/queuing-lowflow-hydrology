"""NumPy-only rate estimators for the Paper 3 non-stationary queue.

Estimates lambda(t) and mu(t) from noisy hydroclimatic covariates, with the
physical constraints the P1 review commits to:

  * positivity          -> fit in log space, return exp(eta)
  * monotone mu in flow -> isotonic component in flow + tree residual elsewhere
  * seasonal mass       -> rescale lambda so its total matches observed demand
  * uncertainty         -> bootstrap percentile intervals

Includes a ridge baseline and a seasonal-climatology baseline so the ML model
must earn its place rather than being compared with nothing.

No scikit-learn / PyTorch required.

Run:  python paper3/src/rate_estimators.py
"""

from __future__ import annotations

from dataclasses import dataclass
import numpy as np

__all__ = [
    "isotonic_regression",
    "RegTree",
    "GBDT",
    "RateEstimator",
    "seasonal_climatology",
    "calibrate_seasonal_mass",
    "predict_with_interval",
]


# --------------------------------------------------------------------------
# Shape-constrained component
# --------------------------------------------------------------------------
def isotonic_regression(y: np.ndarray, increasing: bool = True) -> np.ndarray:
    """Pool-adjacent-violators isotonic regression (equal weights)."""
    y = np.asarray(y, dtype=float)
    if y.ndim != 1:
        raise ValueError("y must be 1-D")
    values: list[float] = []
    weights: list[float] = []
    counts: list[int] = []
    for yi in y:
        values.append(float(yi))
        weights.append(1.0)
        counts.append(1)
        while len(values) > 1:
            viol = (values[-2] > values[-1]) if increasing else (values[-2] < values[-1])
            if not viol:
                break
            v2, w2, c2 = values.pop(), weights.pop(), counts.pop()
            v1, w1, c1 = values.pop(), weights.pop(), counts.pop()
            values.append((v1 * w1 + v2 * w2) / (w1 + w2))
            weights.append(w1 + w2)
            counts.append(c1 + c2)
    out = np.empty(len(y), dtype=float)
    i = 0
    for v, c in zip(values, counts):
        out[i:i + c] = v
        i += c
    return out


# --------------------------------------------------------------------------
# Minimal regression tree and gradient boosting
# --------------------------------------------------------------------------
class RegTree:
    """Depth-limited squared-error regression tree."""

    def __init__(self, max_depth: int = 2, min_samples_leaf: int = 20,
                 max_splits: int = 32):
        self.max_depth = max_depth
        self.min_samples_leaf = min_samples_leaf
        self.max_splits = max_splits
        self.feature: int | None = None
        self.threshold: float | None = None
        self.value: float = 0.0
        self.left: RegTree | None = None
        self.right: RegTree | None = None

    def fit(self, X: np.ndarray, g: np.ndarray, depth: int = 0) -> "RegTree":
        X = np.asarray(X, dtype=float)
        g = np.asarray(g, dtype=float)
        self.value = float(g.mean())
        if depth >= self.max_depth or len(g) < 2 * self.min_samples_leaf:
            return self

        best_sse = np.inf
        best = None
        n = len(g)
        for j in range(X.shape[1]):
            order = np.argsort(X[:, j], kind="stable")
            xs, gs = X[order, j], g[order]
            for i in range(self.min_samples_leaf, n - self.min_samples_leaf):
                if xs[i] == xs[i - 1]:
                    continue
                left, right = gs[:i], gs[i:]
                sse = float(((left - left.mean()) ** 2).sum()
                            + ((right - right.mean()) ** 2).sum())
                if sse < best_sse:
                    best_sse = sse
                    best = (j, 0.5 * (xs[i - 1] + xs[i]), i, order)

        if best is None or best_sse >= float(((g - g.mean()) ** 2).sum()) - 1e-12:
            return self

        j, thr, i, order = best
        self.feature, self.threshold = j, thr
        self.left = RegTree(self.max_depth, self.min_samples_leaf,
                            self.max_splits).fit(X[order[:i]], g[order[:i]], depth + 1)
        self.right = RegTree(self.max_depth, self.min_samples_leaf,
                             self.max_splits).fit(X[order[i:]], g[order[i:]], depth + 1)
        return self

    def predict(self, X: np.ndarray) -> np.ndarray:
        X = np.asarray(X, dtype=float)
        out = np.full(X.shape[0], self.value, dtype=float)
        if self.left is None:
            return out
        go_left = X[:, self.feature] <= self.threshold
        out[go_left] = self.left.predict(X[go_left])
        out[~go_left] = self.right.predict(X[~go_left])
        return out


class GBDT:
    """Small gradient-boosted regression trees (squared loss)."""

    def __init__(self, n_estimators: int = 60, learning_rate: float = 0.1,
                 max_depth: int = 2, min_samples_leaf: int = 20):
        self.n_estimators = n_estimators
        self.learning_rate = learning_rate
        self.max_depth = max_depth
        self.min_samples_leaf = min_samples_leaf
        self.base: float = 0.0
        self.trees: list[RegTree] = []

    def fit(self, X: np.ndarray, y: np.ndarray) -> "GBDT":
        X, y = np.asarray(X, float), np.asarray(y, float)
        self.base = float(y.mean())
        pred = np.full(len(y), self.base)
        self.trees = []
        for _ in range(self.n_estimators):
            resid = y - pred
            tree = RegTree(self.max_depth, self.min_samples_leaf).fit(X, resid)
            update = self.learning_rate * tree.predict(X)
            pred += update
            self.trees.append(tree)
        return self

    def predict(self, X: np.ndarray) -> np.ndarray:
        X = np.asarray(X, float)
        return self.base + sum(self.learning_rate * t.predict(X) for t in self.trees)


# --------------------------------------------------------------------------
# Rate estimator with physical constraints
# --------------------------------------------------------------------------
@dataclass
class RateEstimator:
    """Estimate a positive rate from covariates, optionally monotone in one field.

    Parameters
    ----------
    monotone_col : int | None
        Column of X whose *partial* effect must be non-decreasing (e.g. upstream
        flow for mu).  Its effect is modelled by an isotonic component and the
        boosted trees use all *other* columns only, so the rate is monotone in
        that column **holding the other covariates fixed**.  Because real
        covariates are correlated, the marginal (observed) rate need not be
        monotone in flow; the physical constraint is ceteris paribus.
    n_estimators, learning_rate, max_depth, min_samples_leaf
        GBDT hyperparameters.
    """

    monotone_col: int | None = None
    n_estimators: int = 60
    learning_rate: float = 0.1
    max_depth: int = 2
    min_samples_leaf: int = 20
    eps: float = 1e-6

    def __post_init__(self):
        self._model: GBDT | None = None
        self._iso_x: np.ndarray | None = None
        self._iso_y: np.ndarray | None = None
        self._other_cols: list[int] = []

    def _split(self, X: np.ndarray):
        if self.monotone_col is None:
            return X, None
        cols = [j for j in range(X.shape[1]) if j != self.monotone_col]
        return X[:, cols], X[:, self.monotone_col]

    def fit(self, X: np.ndarray, y: np.ndarray) -> "RateEstimator":
        X, y = np.asarray(X, float), np.asarray(y, float)
        if np.any(y <= 0):
            raise ValueError("rates must be positive; supply observed rates > 0")
        log_y = np.log(y)
        X_other, x_mono = self._split(X)

        if self.monotone_col is not None:
            order = np.argsort(x_mono, kind="stable")
            iso = isotonic_regression(log_y[order], increasing=True)
            self._iso_x = np.sort(x_mono)
            self._iso_y = iso
            resid = log_y - np.interp(x_mono, self._iso_x, self._iso_y)
            self._model = GBDT(self.n_estimators, self.learning_rate,
                               self.max_depth, self.min_samples_leaf).fit(X_other, resid)
        else:
            self._iso_x = self._iso_y = None
            self._model = GBDT(self.n_estimators, self.learning_rate,
                               self.max_depth, self.min_samples_leaf).fit(X_other, log_y)
        return self

    def predict(self, X: np.ndarray) -> np.ndarray:
        X = np.asarray(X, float)
        X_other, x_mono = self._split(X)
        eta = self._model.predict(X_other)
        if x_mono is not None:
            eta += np.interp(x_mono, self._iso_x, self._iso_y)
        return np.exp(np.clip(eta, -50.0, 50.0))


def seasonal_climatology(day_of_year: np.ndarray, values: np.ndarray,
                         n_years: int) -> np.ndarray:
    """Day-of-year climatological mean; a deliberately simple benchmark."""
    doy = np.asarray(day_of_year, int)
    v = np.asarray(values, float)
    out = np.empty(len(doy), float)
    for d in range(1, 367):
        mask = doy == d
        if not mask.any():
            continue
        pool = np.concatenate([v[(doy == d) & (np.arange(len(doy)) // 365 == k)]
                               for k in range(n_years)])
        pool = pool[np.isfinite(pool) & (pool > 0)]
        out[mask] = pool.mean() if pool.size else np.nanmedian(v)
    return out


def calibrate_seasonal_mass(pred: np.ndarray, target_total: float) -> np.ndarray:
    """Rescale a predicted rate series to match a known seasonal total.

    Uses e.g. district crop-area and cropping-calendar statistics to anchor the
    total demand while leaving the estimated within-season shape untouched.
    """
    pred = np.asarray(pred, float)
    total = float(pred.sum())
    if total <= 0 or target_total <= 0:
        raise ValueError("predicted total and target total must be positive")
    return pred * (target_total / total)


def predict_with_interval(X: np.ndarray, y: np.ndarray, X_new: np.ndarray,
                          estimator: RateEstimator, n_boot: int = 20,
                          seed: int = 0, alpha: float = 0.1):
    """Bootstrap percentile interval for the predicted rate.

    ``estimator`` may be unfitted; it is fitted on the full data for the point
    prediction and refitted on each bootstrap resample for the intervals.
    """
    rng = np.random.default_rng(seed)
    point = estimator.fit(X, y).predict(X_new)
    draws = np.empty((n_boot, len(X_new)), float)
    n = len(y)
    for b in range(n_boot):
        idx = rng.integers(0, n, n)
        m = RateEstimator(monotone_col=estimator.monotone_col,
                          n_estimators=estimator.n_estimators,
                          learning_rate=estimator.learning_rate,
                          max_depth=estimator.max_depth,
                          min_samples_leaf=estimator.min_samples_leaf)
        draws[b] = m.fit(X[idx], y[idx]).predict(X_new)
    lo = np.quantile(draws, alpha / 2.0, axis=0)
    hi = np.quantile(draws, 1.0 - alpha / 2.0, axis=0)
    return point, lo, hi


# --------------------------------------------------------------------------
# Demo
# --------------------------------------------------------------------------
def main() -> None:
    rng = np.random.default_rng(3)
    t = np.arange(365.0)
    doy = t + 1.0
    true_lam = 0.8 + 0.35 * np.sin(2 * np.pi * t / 365.0)
    true_mu = 1.0 - 0.28 * np.sin(2 * np.pi * (t - 75.0) / 365.0)

    temp = 0.9 * np.sin(2 * np.pi * t / 365.0) + rng.normal(0, 0.25, 365)
    rain = -0.9 * np.sin(2 * np.pi * (t - 75.0) / 365.0) + rng.normal(0, 0.25, 365)
    flow = 1.0 + 0.7 * (true_mu - 1.0) + rng.normal(0, 0.12, 365)

    X_lam = np.column_stack([np.sin(2 * np.pi * doy / 365),
                             np.cos(2 * np.pi * doy / 365), temp, rain])
    X_mu = np.column_stack([np.sin(2 * np.pi * doy / 365),
                            np.cos(2 * np.pi * doy / 365), rain, flow])

    obs_lam = true_lam * np.exp(rng.normal(0, 0.10, 365))
    obs_mu = true_mu * np.exp(rng.normal(0, 0.08, 365))

    lam_model = RateEstimator().fit(X_lam, obs_lam)
    mu_model = RateEstimator(monotone_col=3).fit(X_mu, obs_mu)
    lam_hat, mu_hat = lam_model.predict(X_lam), mu_model.predict(X_mu)

    print("RATE ESTIMATOR DEMO (synthetic, illustrative only)")
    print(f"  lambda RMSE : {np.sqrt(np.mean((lam_hat - true_lam) ** 2)):.4f}")
    print(f"  mu RMSE     : {np.sqrt(np.mean((mu_hat - true_mu) ** 2)):.4f}")
    print(f"  lambda mass : {lam_hat.sum():.1f} vs observed {obs_lam.sum():.1f}")

    # Correct test of the constraint: vary flow, hold other covariates fixed.
    flows = np.linspace(flow.min(), flow.max(), 100)
    X_cf = np.tile(X_mu[0], (100, 1))
    X_cf[:, 3] = flows
    mu_cf = mu_model.predict(X_cf)
    print("  mu monotone in flow (ceteris paribus)? ",
          "yes" if np.all(np.diff(mu_cf) >= -1e-9) else "NO")

    point, lo, hi = predict_with_interval(X_lam, obs_lam, X_lam,
                                          RateEstimator(), n_boot=10, seed=1)
    cover = np.mean((true_lam >= lo) & (true_lam <= hi))
    print(f"  90% interval coverage of truth: {cover:.2f}")


if __name__ == "__main__":
    main()
