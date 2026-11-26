# Drought as a deficit queue — one study, two regions

**One method, applied identically to India (CAMELS-IND) and the USA
(Caravan-US).** Nothing about the method changes between regions. Only the
catchments and their climate differ.

## The study in one table

| Element | Rule (identical in both regions) |
|---|---|
| Unit | gauge catchment |
| Target | **catchment SPEI-3 ≤ −1** (primary); SPI-3 ≤ −1 (sensitivity) |
| Demand | `need = max(Kc·ET0 − 0.7·P, 0)`, `lambda = need / 20`, `Kc = 0.8` |
| Supply | `mu = min(Q·86400·0.5/A_cmd·1000, 10) / 20` |
| Catchment size | `A_cmd = f_irr · A_catchment`, `f_irr = 0.10`; one claim = 20 mm over `A_cmd` |
| Capacity | `K = min(80, max(25, ceil(365·lambda_bar)))` |
| Severe state | `q* = ceil(60·lambda_bar)` |
| Split | train 1981–2010, test 2011–2020 |
| Evaluation | 8 model families, paired Brier/AUC, two-level bootstrap |

**Why SPEI-3?** It uses the catchment's own precipitation and PET time series.
There is no district soil-moisture product, no US Drought Monitor, and no
reservoir. The target is therefore the same object in both regions.

**Catchment size is explicit.** It sets the command area, the claim volume and
the supply conversion. Demand is a depth rate, so area cancels there by design;
supply and capacity use it.

## Files (deliberately few)

```text
R/
  config.R            paths, seeds, all parameters
  functions/          verified engine + units + indices + evaluation
  study.R             the one pipeline: rates -> screen -> queue -> target -> fit
  figures.R           slides-ready figures (map + three result figures)
  verify.R            the 15-check battery
STUDY.Rmd             one technical document: data, methods, results
MANUSCRIPT.Rmd        fragment-style paper, knits to MANUSCRIPT.pdf
README.md             this file
HELP.md               how to run, data locations, outputs
AGENTS.md             project rules and frozen novelty sentence
P01/                  literature audit and search protocol (evidence only)
analysis/P01_literature/  WoS/Scopus exports and screening (evidence only)
analysis/novelty_2026-11-25/  supplementary novelty evidence (historical)
output/               generated CSVs + JSON sidecars
figures/              generated figures
```

## Run

From the repository root:

```powershell
Rscript R/verify.R      # 15/15 checks
Rscript R/study.R       # the one study (both regions, both targets)
Rscript R/figures.R     # figures
```

Knit the paper (TinyTeX installed):

```powershell
Rscript -e "rmarkdown::render('MANUSCRIPT.Rmd')"
```

Or open `STUDY.Rmd` for the technical document and `MANUSCRIPT.Rmd` for the paper.

## Result

`[measurement]` Under the common protocol:

| Target | India (n = 12) | USA (n = 58) |
|---|---|---|
| SPEI-3 (primary) | +0.0019, CI [−0.0006, +0.0051] | +0.0021, CI [+0.0003, +0.0035] |
| SPI-3 (sensitivity) | +0.0010, CI [−0.0014, +0.0032] | +0.0011, CI [+0.0000, +0.0028] |

The USA improvement is small but consistent across both targets; the India
interval includes zero; the USA-minus-India difference includes zero for both
targets. The queue does not beat SSI-3 as a general rule. Numbers are written by
`R/study.R` to `output/region_summary.csv` and `output/region_difference.csv`
and quoted in `MANUSCRIPT.Rmd`.

## Data

- **India:** CAMELS-IND, 472 gauges (Mangukiya et al., 2025, *ESSD*,
  doi:10.5194/essd-17-461-2025).
- **USA:** Caravan-US, 671 gauges (Kratzert et al., 2023, *Scientific Data*,
  doi:10.1038/s41597-023-01975-w).

Both are read from local paths defined in `R/config.R`; no data are copied into
this repository.
