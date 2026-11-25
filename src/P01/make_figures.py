"""Generate reproducible P01 manuscript figures as PNG and SVG.

Rendering uses matplotlib, available in the base Python environment. The
underlying figure data use only NumPy and the shared queue engine.

Run from the repository root:
    python src/P01/make_figures.py
"""

from __future__ import annotations

from pathlib import Path
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))

from P01.figure_data import box1_series, load_sensitivity_rows  # noqa: E402

OUT = ROOT / "P01/figures"
PROVENANCE = "Synthetic; illustrative, under the stated assumptions."
COLORS = {
    "ink": "#1f2937",
    "blue": "#2563eb",
    "teal": "#0f766e",
    "orange": "#d97706",
    "red": "#b91c1c",
    "grey": "#6b7280",
    "light": "#eff6ff",
}


def _save(fig, stem: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT / f"{stem}.png", dpi=220, bbox_inches="tight",
                facecolor="white")
    fig.savefig(OUT / f"{stem}.svg", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def _box(ax, xy, wh, text, face=COLORS["light"], edge=COLORS["blue"]):
    x, y = xy
    w, h = wh
    patch = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.012,rounding_size=0.02",
                           linewidth=1.6, edgecolor=edge, facecolor=face)
    ax.add_patch(patch)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=11, color=COLORS["ink"], weight="bold")


def _arrow(ax, start, end, color=COLORS["grey"]):
    ax.add_patch(FancyArrowPatch(start, end, arrowstyle="-|>", mutation_scale=16,
                                 linewidth=1.6, color=color))


def mapping_figure() -> None:
    fig, ax = plt.subplots(figsize=(12, 7.2))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    _box(ax, (0.02, 0.70), (0.18, 0.14), "Demand D(t)\narrivals")
    _box(ax, (0.25, 0.70), (0.15, 0.14), "λ(t)\nclaims/day")
    _box(ax, (0.02, 0.40), (0.18, 0.14), "Supply\nflow / releases")
    _box(ax, (0.25, 0.40), (0.15, 0.14), "μ(t)\nclaims/server/day")
    _box(ax, (0.46, 0.55), (0.18, 0.16), "Backlog Q(t)\nfinite capacity Kq",
         face="#fff7ed", edge=COLORS["orange"])
    _box(ax, (0.46, 0.22), (0.18, 0.14), "Storage X(t)\ncapacity Ks",
         face="#f0fdfa", edge=COLORS["teal"])
    _box(ax, (0.72, 0.55), (0.25, 0.16), "Drought indicators\nE[Q], Pr(Q≥q*), exposure,\nrecovery, abandonment")
    _box(ax, (0.72, 0.22), (0.25, 0.14), "Verification and validation\nexact references → held-out events",
         face="#fef2f2", edge=COLORS["red"])
    _arrow(ax, (0.20, 0.77), (0.25, 0.77))
    _arrow(ax, (0.20, 0.47), (0.25, 0.47))
    _arrow(ax, (0.40, 0.77), (0.46, 0.65))
    _arrow(ax, (0.40, 0.47), (0.46, 0.60))
    _arrow(ax, (0.64, 0.63), (0.72, 0.63))
    _arrow(ax, (0.64, 0.29), (0.72, 0.29), color=COLORS["teal"])
    _arrow(ax, (0.55, 0.55), (0.55, 0.36), color=COLORS["teal"])
    ax.text(0.58, 0.45, "shared served-water flux S(t)", fontsize=9,
            color=COLORS["teal"], rotation=90, va="center")
    ax.text(0.02, 0.10,
            "Conservation ledger: demand = served + abandoned + change in backlog.\n"
            "Storage and backlog are coupled states, not simple reflections.",
            fontsize=10, color=COLORS["ink"])
    ax.text(0.02, 0.02, PROVENANCE, fontsize=9, color=COLORS["grey"])
    _save(fig, "figure1_mapping")


def box1_figure() -> None:
    d = box1_series()
    fig, axes = plt.subplots(3, 1, figsize=(10, 8.6), sharex=True)
    axes[0].plot(d["time_n"], d["lambda_n"], color=COLORS["orange"], label="λ(t)")
    axes[0].plot(d["time_n"], d["mu_n"], color=COLORS["blue"], label="μ(t)")
    axes[0].set_ylabel("Rate\n(claims/day; μ per server)")
    axes[0].legend(frameon=False, ncol=2)
    axes[0].set_title("Same mean rates; different transient risk")

    axes[1].plot(d["time_s"], d["E_Q_s"], color=COLORS["grey"],
                 label="Stationary at mean")
    axes[1].plot(d["time_n"], d["E_Q_n"], color=COLORS["red"],
                 label="Seasonal / non-stationary")
    axes[1].set_ylabel("E[Q]\n(claims)")
    axes[1].legend(frameon=False)
    axes[1].annotate(f"peak {d['E_Q_n'].max():.3f}",
                     xy=(d["time_n"][d["E_Q_n"].argmax()], d["E_Q_n"].max()),
                     xytext=(12, -18), textcoords="offset points", color=COLORS["red"])

    axes[2].plot(d["time_s"], d["P_crit_s"], color=COLORS["grey"])
    axes[2].plot(d["time_n"], d["P_crit_n"], color=COLORS["red"])
    axes[2].set_ylabel("Pr(Q ≥ 6)\n(probability)")
    axes[2].set_xlabel("Evaluation day after one-year spin-up (day)")
    axes[2].annotate(f"peak {d['P_crit_n'].max():.4f}",
                     xy=(d["time_n"][d["P_crit_n"].argmax()], d["P_crit_n"].max()),
                     xytext=(12, -18), textcoords="offset points", color=COLORS["red"])
    for ax in axes:
        ax.grid(alpha=0.22)
        ax.spines[["top", "right"]].set_visible(False)
    fig.text(0.01, 0.005, PROVENANCE, fontsize=9, color=COLORS["grey"])
    fig.tight_layout(rect=(0, 0.025, 1, 1))
    _save(fig, "figure2_box1")


def sensitivity_figure() -> None:
    rows = load_sensitivity_rows()
    groups = ["baseline", "one_at_a_time", "combined_amplitude_phase"]
    labels = ["Baseline", "One-at-a-time", "Combined grid"]
    metrics = [("peak_E_Q_ratio", "Peak E[Q] ratio"),
               ("peak_P_crit_ratio", "Peak Pr(Q ≥ 6) ratio")]
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.8))
    for ax, (key, title) in zip(axes, metrics):
        data = [[float(r[key]) for r in rows if r["experiment"] == g]
                for g in groups]
        ax.boxplot(data, tick_labels=labels, showfliers=True,
                   medianprops={"color": COLORS["red"]})
        ax.scatter([1], [float(rows[0][key])], color=COLORS["red"], zorder=5,
                   label="Baseline")
        ax.axhline(1.0, color=COLORS["grey"], linestyle="--", linewidth=1)
        ax.set_title(title)
        ax.set_ylabel("Seasonal / stationary ratio")
        ax.grid(axis="y", alpha=0.22)
        ax.spines[["top", "right"]].set_visible(False)
    fig.text(0.01, 0.005,
             PROVENANCE + " 44 cases; direction preserved in every case.",
             fontsize=9, color=COLORS["grey"])
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    _save(fig, "figure3_sensitivity")


def main() -> None:
    mapping_figure()
    box1_figure()
    sensitivity_figure()
    print(f"Wrote P01 figures to {OUT}")


if __name__ == "__main__":
    main()
