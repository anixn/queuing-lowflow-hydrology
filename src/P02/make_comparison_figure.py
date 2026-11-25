"""Render the actual-data queue comparison figure as PNG and SVG.

The six panels show, for each gauge: the observed 3-month soil-moisture target,
held-out drought probabilities with observed drought months shaded, Brier skill,
and reliability. The figure reads saved CSV outputs only; no model is refitted.

Run from the repository root:
    python src/P02/make_comparison_figure.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "analysis/P02_methods/data"
OUT = ROOT / "analysis/P02_methods/figures"

__all__ = ["make_figure"]

MODELS = ("climatology", "spi3", "spei3", "ssi3", "queue", "ssi3_plus_queue")
TIME_MODELS = ("climatology", "spi3", "spei3", "ssi3", "queue", "ssi3_plus_queue")
LABELS = {
    "climatology": "Climatology",
    "spi3": "SPI-3*",
    "spei3": "SPEI-3*",
    "ssi3": "SSI-3",
    "queue": "Queue",
    "ssi3_plus_queue": "SSI-3 + queue",
}
COLORS = {
    "climatology": "#6b7280",
    "spi3": "#a16207",
    "spei3": "#b45309",
    "ssi3": "#2563eb",
    "queue": "#0f766e",
    "ssi3_plus_queue": "#b91c1c",
}
STYLES = {
    "climatology": ":",
    "spi3": "--",
    "spei3": "-",
    "ssi3": "-",
    "queue": "-",
    "ssi3_plus_queue": "-",
}


def _shade_drought_months(ax: plt.Axes, dates: pd.Series, y: pd.Series) -> None:
    """Shade contiguous observed drought months without implying forecast lead."""
    mask = np.asarray(y, dtype=int) == 1
    position = 0
    while position < len(mask):
        if not mask[position]:
            position += 1
            continue
        start = position
        while position + 1 < len(mask) and mask[position + 1]:
            position += 1
        end = position
        left = pd.Timestamp(dates.iloc[start]) - pd.Timedelta(days=15)
        right = pd.Timestamp(dates.iloc[end]) + pd.Timedelta(days=15)
        ax.axvspan(left, right, color="#b91c1c", alpha=0.09, linewidth=0)
        position += 1


def _date_axis(ax: plt.Axes, show_labels: bool = True) -> None:
    locator = mdates.AutoDateLocator(minticks=5, maxticks=9)
    ax.xaxis.set_major_locator(locator)
    ax.xaxis.set_major_formatter(mdates.ConciseDateFormatter(locator))
    ax.tick_params(axis="x", labelbottom=show_labels, rotation=0)
    ax.spines[["top", "right"]].set_visible(False)
    ax.grid(alpha=0.18)


def _plot_observed_target(ax: plt.Axes, group: pd.DataFrame, gauge_id: int,
                          panel: str) -> None:
    dates = group["date"]
    _shade_drought_months(ax, dates, group["y_sma"])
    ax.plot(dates, group["sma_pct"], color="#111827", linewidth=1.6,
            label="Observed SMA")
    ax.axhline(-15.0, color="#b91c1c", linestyle="--", linewidth=1.1,
               label="Drought threshold (−15%)")
    ax.axhline(0.0, color="#9ca3af", linewidth=0.8)
    ax.set_ylabel("SMA (%)")
    n_events = int(((group["y_sma"] == 1)
                    & (group["y_sma"].shift(fill_value=0) == 0)).sum())
    ax.set_title(
        f"{panel}  Gauge {gauge_id} — observed target "
        f"({int(group['y_sma'].sum())} drought months, {n_events} events)",
        loc="left", fontsize=11,
    )
    ax.legend(frameon=False, fontsize=8, loc="lower left")
    _date_axis(ax, show_labels=False)


def _plot_probabilities(ax: plt.Axes, group: pd.DataFrame, gauge_id: int,
                        panel: str) -> None:
    dates = group["date"]
    _shade_drought_months(ax, dates, group["y_sma"])
    for model in TIME_MODELS:
        ax.plot(dates, group[model], color=COLORS[model], linestyle=STYLES[model],
                linewidth=1.25, alpha=0.95)
    ax.set_ylim(0.0, 1.0)
    ax.set_ylabel("Predicted drought probability")
    ax.set_xlabel("Held-out month")
    ax.set_title(f"{panel}  Gauge {gauge_id} — model-predicted probabilities, q*=6",
                 loc="left", fontsize=11)
    _date_axis(ax)


def make_figure() -> Path:
    """Create and save the six-panel observed-data comparison figure."""
    metrics = pd.read_csv(DATA / "real_data_comparison_metrics.csv")
    reliability = pd.read_csv(DATA / "real_data_reliability.csv")
    monthly = pd.read_csv(DATA / "real_data_comparison_monthly.csv",
                          parse_dates=["date"])
    predictions = pd.read_csv(DATA / "real_data_comparison_predictions.csv",
                              parse_dates=["date"])
    primary = metrics.loc[
        metrics["target"].eq("sma") & metrics["q_star"].eq(6)
    ]
    if set(primary["gauge_id"].unique()) != {4026, 4064}:
        raise ValueError("figure requires both pilot gauges")

    held_out = predictions.loc[
        predictions["target"].eq("sma")
        & predictions["q_star"].eq(6)
        & predictions["split"].eq("test")
    ]
    wide = held_out.pivot(index=["gauge_id", "date"], columns="model",
                          values="predicted_probability").reset_index()
    observed = monthly.loc[
        monthly["split"].eq("test"),
        ["gauge_id", "date", "sma_pct", "y_sma"],
    ]
    plot_data = wide.merge(observed, on=["gauge_id", "date"], how="inner",
                           validate="one_to_one").sort_values(["gauge_id", "date"])

    fig, axes = plt.subplots(3, 2, figsize=(14.0, 12.2))
    panels = (("a", "b"), ("d", "e"))
    for column, gauge_id in enumerate((4026, 4064)):
        group = plot_data.loc[plot_data["gauge_id"].eq(gauge_id)].copy()
        _plot_observed_target(axes[0, column], group, gauge_id, panels[column][0])
        _plot_probabilities(axes[1, column], group, gauge_id, panels[column][1])
        axes[1, column].sharex(axes[0, column])
        _date_axis(axes[1, column])

    # Bottom row: both-gauge skill summary and reliability.
    gauge_offsets = np.arange(len(MODELS), dtype=float)
    width = 0.36
    for offset, gauge_id, hatch in ((-width / 2, 4026, ""), (width / 2, 4064, "//")):
        gauge = primary.loc[primary["gauge_id"].eq(gauge_id)].set_index("model")
        values = gauge.loc[list(MODELS), "brier_skill"].to_numpy(dtype=float)
        bars = axes[2, 0].bar(gauge_offsets + offset, values, width=width,
                              color=[COLORS[model] for model in MODELS],
                              alpha=0.88 if gauge_id == 4026 else 0.62, hatch=hatch,
                              edgecolor="white", label=f"Gauge {gauge_id}")
        for position, value in enumerate(values):
            if abs(value) < 5e-4:
                continue
            label_offset = 0.008 if gauge_id == 4026 else -0.008
            axes[2, 0].text(gauge_offsets[position] + offset,
                            value + label_offset,
                            f"{value:.3f}", ha="center",
                            va="bottom" if gauge_id == 4026 else "top",
                            fontsize=6.8)
    axes[2, 0].axhline(0.0, color="#111827", linewidth=0.9)
    axes[2, 0].set_xticks(gauge_offsets, [LABELS[model] for model in MODELS],
                          rotation=28, ha="right")
    axes[2, 0].set_ylabel("Brier skill vs climatology")
    axes[2, 0].set_title("c  Both gauges — Brier skill", loc="left", fontsize=11)
    axes[2, 0].legend(frameon=False, fontsize=8, loc="upper right")
    axes[2, 0].grid(axis="y", alpha=0.18)
    axes[2, 0].spines[["top", "right"]].set_visible(False)

    for gauge_id, alpha, marker in ((4026, 0.95, "o"), (4064, 0.60, "s")):
        rel = reliability.loc[
            reliability["gauge_id"].eq(gauge_id)
            & reliability["target"].eq("sma")
            & reliability["q_star"].eq(6)
        ]
        for model in MODELS:
            group = rel.loc[rel["model"].eq(model)].sort_values("bin")
            if group.empty:
                continue
            axes[2, 1].plot(group["mean_predicted_probability"],
                            group["observed_frequency"], marker=marker,
                            markersize=4, linewidth=1.2, color=COLORS[model],
                            linestyle=STYLES[model], alpha=alpha)
    axes[2, 1].plot([0, 1], [0, 1], linestyle="--", color="#9ca3af", linewidth=1,
                    label="Perfect reliability")
    axes[2, 1].set_xlim(0.0, 1.0)
    axes[2, 1].set_ylim(0.0, 1.0)
    axes[2, 1].set_xlabel("Mean predicted probability")
    axes[2, 1].set_ylabel("Observed drought frequency")
    axes[2, 1].set_title("f  Both gauges — held-out reliability",
                         loc="left", fontsize=11)
    axes[2, 1].grid(alpha=0.18)
    axes[2, 1].spines[["top", "right"]].set_visible(False)
    gauge_handles = [
        plt.Line2D([0], [0], color="#6b7280", marker="o", linewidth=0,
                   label="Gauge 4026"),
        plt.Line2D([0], [0], color="#6b7280", marker="s", linewidth=0,
                   label="Gauge 4064"),
        plt.Line2D([0], [0], color="#9ca3af", linestyle="--",
                   label="Perfect reliability"),
    ]
    axes[2, 1].legend(handles=gauge_handles, frameon=False, fontsize=7.5,
                      ncol=3, loc="upper left")

    model_handles = [plt.Line2D([0], [0], color=COLORS[model],
                                linestyle=STYLES[model], marker="o",
                                linewidth=1.4, label=LABELS[model])
                     for model in MODELS]
    fig.legend(handles=model_handles, loc="lower center", ncol=6, frameon=False,
               bbox_to_anchor=(0.5, 0.092), fontsize=9)
    fig.suptitle(
        "Observed district soil-moisture drought and held-out queue comparison, q*=6",
        fontsize=15, y=0.975,
    )
    fig.text(
        0.02, 0.012,
        "Red shading = observed SMA drought. Each gauge has 98 held-out months and 4 drought months; reliability bins are sparse.\n"
        "* SMA/SPI/SPEI use an external 1981–2020 reference overlapping the test years; target/benchmarks are not strictly held-out. Probabilities are uncalibrated.\n"
        "Retrospective same-month flow; no forecast claim. Queue outputs are illustrative, under the stated assumptions.",
        fontsize=7.6, color="#374151", va="bottom",
    )
    fig.subplots_adjust(left=0.07, right=0.98, top=0.93, bottom=0.22,
                        wspace=0.24, hspace=0.40)
    OUT.mkdir(parents=True, exist_ok=True)
    png = OUT / "real_data_comparison.png"
    svg = OUT / "real_data_comparison.svg"
    fig.savefig(png, dpi=220, facecolor="white")
    fig.savefig(svg, facecolor="white")
    plt.close(fig)
    svg.write_text(
        "\n".join(line.rstrip() for line in svg.read_text(encoding="utf-8").splitlines())
        + "\n",
        encoding="utf-8",
    )
    return png


if __name__ == "__main__":
    print(make_figure())
