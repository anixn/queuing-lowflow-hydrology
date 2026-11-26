# Paper 01 — complete writing package

**Title.** Recession-calibrated storage states for seasonal
hydrological-drought and low-flow forecasting in Indian catchments:
a pre-registered large-sample test and the lead-time skill benchmark.

Everything you need to write is in this folder. Structure:

```text
paper01/
  MANUSCRIPT_Paper01.Rmd    the bullet-point manuscript source (APA style,
                            all numbers knitted from tables/)
  MANUSCRIPT_Paper01.pdf    the knitted PDF (key-highlights box, figures, tables)
  figures/                  Fig01-Fig08, each in PDF + 300-dpi PNG
  tables/                   Table 1-5 + appendix tables, CSV + JSON sidecars
  results/                  frozen copies of the study outputs (+ sidecars)
  figure_table_captions.md  suggested captions and sources for every figure/table
  README.md                 this file
```

## The three key highlights (as written in the manuscript)

1. **The lead-time skill benchmark.** Across 231 Indian catchments:
   median BSS vs climatology 0.42-0.50 at a 1-month lead, 0.01-0.08 at
   3 months, at most 0.02 at 6 months; persistence is the strongest baseline
   at every lead. (`figures/Fig03_leadtime_skill.png`, `tables/table03_bss.csv`)
2. **The storage-state test, pre-registered and scored once.** H0 parity at
   the 1-month lead is confirmed exactly as predicted; H1 (3-month) and
   H2 (6-month) fail (medians -0.0015 / -0.0007; signs 43% / 41%). The
   mechanism is measured: median recession constant about 8 days, so the
   fluid state is a smoothed mirror of the indices' own information.
   (`tables/table04_confirmatory.csv`, `figures/Fig04_paired_deltas.png`,
   `figures/Fig05_example_state.png`)
3. **Two trustworthy nulls and the power measurement.** The retired
   deficit-queue design, corrected and re-run (Gate G2), loses to the honest
   memory baselines; the power analysis shows that design was unresolvable
   at any n up to 300. (`figures/Fig08_power.png`, `tables/table06_power.csv`,
   `results/gateG2_summary.csv`)

## Where every number comes from

- All in-text statistics in the manuscript are knitted from
  `tables/table0*.csv` at render time - editing a number by hand is
  impossible without also editing the table.
- `tables/` are written by `R/tables_paper01.R` from `results/` (frozen
  copies of the repository's `output/*.csv`, each with a JSON provenance
  sidecar: git hash, code hash, shape, R session).
- `figures/` are drawn by the sibling script `R/figures_paper01.R` from the
  same results.

## Reproduce everything

From the repository root:

```powershell
Rscript R/verify.R               # 22/22 checks must pass first
Rscript R/study_p1.R             # the study (India + USA transfer arm)
Rscript R/study_gate_g2.R        # Gate G2 record
Rscript R/power_check.R          # power curve
Rscript R/figures_paper01.R      # this folder's figures
Rscript R/tables_paper01.R       # this folder's tables
Rscript -e "rmarkdown::render('paper01/MANUSCRIPT_Paper01.Rmd')"
```

## Notes for writing

- `figure_table_captions.md` has ready-made captions with sources - edit
  wording freely, never edit numbers.
- Cross-references: figures are labelled fig:leadtime etc.; tables
  tab:sample, tab:bss, tab:confirmatory, tab:usa, tab:power, tab:params,
  tab:kclass.
- The manuscript is intentionally in bullet-fragment form; join bullets into
  prose section by section. Every assumption is labelled and Appendix B
  lists them all - keep that register intact when prose replaces bullets.
- Reference entries marked "[standard reference; details to be verified
  before submission]" are deliberately left incomplete rather than invented -
  verify them (AGENTS.md rule 7) before submission.
- The P1 novelty sentence (PIVOT.md section 9) needs its Phase-A-style
  literature screen before any title claiming a gap is finalised.
