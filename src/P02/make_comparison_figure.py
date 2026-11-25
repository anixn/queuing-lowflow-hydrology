"""Render the predeclared real-data comparison figure as PNG and SVG.

The figure uses only saved CSV outputs from real_data_comparison.py. Rendering
requires matplotlib in the base Python environment; no model is refitted here.

Run from the repository root:
    python src/P02/make_comparison_figure.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "analysis/P02_methods/data"
OUT = ROOT / "analysis/P02_methods/figures"

__all__ = ["make_figure"]

MODELS = ("climatology", "spi3", "spei3", "ssi3", "queue", "ssi3_plus_queue")
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
RELIABILITY_MODELS = ("climatology", "spei3", "ssi3", "queue", "ssi3_plus_queue")


def make_figure() -> Path:
    """Create and save the two-gauge Brier-skill/reliability figure."""
    metrics = pd.read_csv(DATA / "real_data_comparison_metrics.csv")
    reliability = pd.read_csv(DATA / "real_data_reliability.csv")
    primary = metrics.loc[
        metrics["target"].eq("sma") & metrics["q_star"].eq(6)
    ]
    if set(primary["gauge_id"].unique()) != {4026, 4064}:
        raise ValueError("figure requires both pilot gauges")

    fig, axes = plt.subplots(2, 2, figsize=(12.0, 8.4))
    for column, gauge_id in enumerate((4026, 4064)):
        gauge = primary.loc[primary["gauge_id"].eq(gauge_id)].set_index("model")
        ax = axes[0, column]
        values = gauge.loc[list(MODELS), "brier_skill"].to_numpy(dtype=float)
        colors = [COLORS[model] for model in MODELS]
        bars = ax.bar(range(len(MODELS)), values, color=colors, width=0.72)
        for bar, model in zip(bars, MODELS):
            if model in {"spi3", "spei3"}:
                bar.set_hatch("//")
                bar.set_edgecolor("white")
        ax.axhline(0.0, color="#111827", linewidth=0.9)
        ax.set_xticks(range(len(MODELS)), [LABELS[model] for model in MODELS],
                      rotation=28, ha="right")
        ax.set_ylabel("Brier skill vs climatology")
        ax.set_title(f"Gauge {gauge_id} — Brier skill")
        ax.grid(axis="y", alpha=0.2)
        ax.spines[["top", "right"]].set_visible(False)
        for position, value in enumerate(values):
            ax.text(position, value + (0.006 if value >= 0 else -0.012),
                    f"{value:.3f}", ha="center",
                    va="bottom" if value >= 0 else "top", fontsize=8)

        ax = axes[1, column]
        rel = reliability.loc[
            reliability["gauge_id"].eq(gauge_id)
            & reliability["target"].eq("sma")
            & reliability["q_star"].eq(6)
        ]
        for model in RELIABILITY_MODELS:
            group = rel.loc[rel["model"].eq(model)].sort_values("bin")
            if group.empty:
                continue
            ax.plot(group["mean_predicted_probability"],
                    group["observed_frequency"], marker="o", markersize=4,
                    linewidth=1.5, color=COLORS[model], label=LABELS[model])
        ax.plot([0, 1], [0, 1], linestyle="--", color="#9ca3af", linewidth=1,
                label="Perfect reliability")
        ax.set_xlim(0.0, 1.0)
        ax.set_ylim(0.0, 1.0)
        ax.set_xlabel("Mean predicted probability")
        ax.set_ylabel("Observed drought frequency")
        ax.set_title(f"Gauge {gauge_id} — held-out reliability")
        ax.grid(alpha=0.2)
        ax.spines[["top", "right"]].set_visible(False)

    handles = [plt.Line2D([0], [0], color=COLORS[model], marker="o",
                          linewidth=1.5, label=LABELS[model])
               for model in RELIABILITY_MODELS]
    handles.append(plt.Line2D([0], [0], color="#9ca3af", linestyle="--",
                              label="Perfect reliability"))
    fig.legend(handles=handles, loc="lower center", ncol=6, frameon=False,
               bbox_to_anchor=(0.5, 0.085), fontsize=9)
    fig.suptitle(
        "Held-out district soil-moisture drought, q*=6: 98 months and 4 event months per gauge",
        fontsize=13, y=0.97,
    )
    fig.text(
        0.02, 0.025,
        "* SPI/SPEI are external 1981–2020-standardized benchmarks, not strict held-out baselines. "
        "Retrospective same-month flow; no forecast claim. Queue outputs are illustrative, under the stated assumptions.",
        fontsize=8, color="#374151",
    )
    fig.subplots_adjust(left=0.07, right=0.98, top=0.88, bottom=0.22,
                        wspace=0.28, hspace=0.62)
    OUT.mkdir(parents=True, exist_ok=True)
    png = OUT / "real_data_comparison.png"
    svg = OUT / "real_data_comparison.svg"
    fig.savefig(png, dpi=220, facecolor="white")
    fig.savefig(svg, facecolor="white")
    plt.close(fig)
    # Matplotlib writes spaces at the end of SVG path-data lines. They are
    # semantically irrelevant but fail git diff --check, so normalize them.
    svg.write_text(
        "\n".join(line.rstrip() for line in svg.read_text(encoding="utf-8").splitlines())
        + "\n",
        encoding="utf-8",
    )
    return png


if __name__ == "__main__":
    print(make_figure())
