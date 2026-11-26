# Manuscript package

This directory contains the HESS-style manuscript and its supporting text.
The executable code that produces every number is in `../R/` and `../steps/`.

## Contents

| File | Contents |
|---|---|
| `MANUSCRIPT.md` | Main paper: abstract, introduction/literature, hypotheses, data, LaTeX methods, results (India, USA, comparison), discussion, limitations, conclusion, references, figure captions |
| `SUPPLEMENT_LITERATURE.md` | Extended literature review (2,479 words, 49 audited references, frozen gap sentence verbatim) |
| `SUPPLEMENT_METHODS.md` | Extended data-and-methods text (2,798 words, all equations in LaTeX, study-specific counts) |
| `figures/` | Placeholder for manuscript-build copies of the figures |

## Figure index

| # | Caption | File |
|---|---|---|
| 1 | Analysis workflow | `../figures/fig_workflow.png` |
| 2 | Study sites (India + USA) | `../figures/fig_study_map.png` |
| 3 | India utilisation screen | `../figures/fig01_utilization_screen.png` |
| 4 | India queue regime | `../figures/fig02_regime_pq.png`, `fig02_regime_eq.png` |
| 5 | India E1 Brier forest | `../figures/fig03_brier_forest_e1.png` |
| 6 | India AUC forest | `../figures/fig04_auc_forest.png` |
| 7 | Example monthly series | `../figures/fig05_example_series_5018.png` |
| 8 | India reliability | `../figures/fig06_reliability.png` |
| 9 | India–USA comparison | `../figures/fig_india_us_comparison.png` |
| 10 | Utilisation diagnosis | `../figures/fig_utilisation_diagnosis.png` |

## Where the numbers come from

| Number | Source |
|---|---|
| India selection and regime | `../output/selected_gauges.csv`, `../output/queue_meta.csv` |
| India E1/E2 and AUC | `../output/meta_endpoints.csv`, `../output/paired_e1.csv`, `../output/paired_e2.csv` |
| India power / MDE | `../output/power_analysis.csv`, `../output/power_grid.csv` |
| USA sample and regime | `../output_us/reservoir_core.csv`, `../output_us/reservoir_queue_meta.csv` |
| USA E1/E2 and AUC | `../output_us/us_meta.csv`, `../output_us/us_paired_e1.csv`, `../output_us/us_paired_e2.csv` |
| USA target | `../output_us/usdm_monthly.csv` |

Every CSV has a `.json` sidecar with the git hash, parameters, seed and R
session. Do not hand-edit the numbers in the manuscript: change the code and
rerun the relevant step.

## Render an HTML preview

```powershell
Rscript -e "rmarkdown::pandoc_convert('manuscript/MANUSCRIPT.md', to='html5', output='manuscript/MANUSCRIPT.html', options=c('--mathjax','--standalone'))"
```

A PDF build requires a LaTeX installation (not assumed here). The Markdown
source is the authoritative manuscript.

## Author checklist

1. Confirm the journal (HESS) and the article type (methods / negative result).
2. Confirm the frozen gap sentence is unchanged (compare with `../AGENTS.md` §2).
3. Confirm the Brier/AUC interpretation: Brier null, AUC secondary.
4. Confirm the demand/supply assumptions are labelled `[assumption]`.
5. Add ORCID, acknowledgements and the archive DOI.
6. Decide whether the US pilot is a main-text section or a supplementary case
   study (current draft: main-text comparison, with its 21-pair limitation
   stated).
