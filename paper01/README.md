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
  MANUSCRIPT_fragment.Rmd   the earlier one-page paper fragment (reference only)
  STUDY.Rmd / STUDY.html    the technical document: data, methods, results
  figures/                  Fig01-Fig07 (publication) + fig_p1_* (study), PDF + PNG
  tables/                   Table 1-5 + appendix tables, CSV + JSON sidecars
  output/                   the study's results, CSV + JSON sidecars
  literature/               the frozen evidence record: literature audit, search
                            protocol, P1 novelty screen, WoS exports, submission text
  figure_table_captions.md  suggested captions and sources for every figure/table
  README.md                 this file
```

## The three key highlights (as written in the manuscript)

1. **A bounded null, not a failed test.** The storage family is equivalent to
   the best memory baseline at the declared harm bound of 0.005 Brier at all
   five leads (1, 2, 3, 6, 12 months): every 90% interval sits inside the
   band, `p_TOST < 0.001`. Any gain is smaller than the smallest change an
   operator would act on. (`tables/table07_equivalence.csv`,
   `figures/fig_p1_equivalence.png`)
2. **The lead-time ceiling for India.** On one common sample, skill against
   climatology falls from about 0.50 at one month to 0.23, 0.07, 0.02 and
   0.01 at two, three, six and twelve months; the storage family then falls
   below climatology. (`tables/table08_bss_paired.csv`,
   `figures/Fig03_leadtime_skill.png`)
3. **The mechanism, measured.** Median recession constant is about 9 days and
   no gauge exceeds 41 days, so the state retains a few per cent of its
   memory at one month and essentially none beyond. The stress test finds a
   weak gradient with the recession constant, but even the slowest fifth of
   gauges reaches only +0.002 Brier, below the harm bound.
   (`tables/table09_memory.csv`, `figures/fig_p1_memory_wall.png`,
   `figures/fig_p1_skill_memory.png`)

## Where every number comes from

- All in-text statistics in the manuscript are knitted from
  `tables/table0*.csv` at render time - editing a number by hand is
  impossible without also editing the table.
- `tables/` are written by `R/tables_paper01.R` from `output/` (the study's
  results, each with a JSON provenance sidecar: git hash, code hash, seed,
  shape, R session).
- `figures/` are drawn by the sibling script `R/figures_paper01.R` from the
  same results.

## Reproduce everything

From the repository root:

```powershell
Rscript R/verify.R               # 23/23 checks must pass first
Rscript R/study_p1.R             # the study (India + USA transfer arm)
Rscript R/paired_analysis_p1.R   # equivalence + paired benchmark
Rscript R/kclass_exploratory.R   # labelled post-hoc k-class cut (optional)
Rscript R/novelty_p1_screen.R     # rapid Crossref/OpenAlex P1 screen
Rscript R/figures_p1_finding.R   # the three argument figures
Rscript R/figures_paper01.R      # this folder's figures
Rscript R/tables_paper01.R       # this folder's tables
Rscript -e "rmarkdown::render('paper01/MANUSCRIPT_Paper01.Rmd')"
```

## Notes for writing

- `figure_table_captions.md` has ready-made captions with sources - edit
  wording freely, never edit numbers.
- Cross-references: figures are labelled fig:leadtime etc.; tables
  tab:sample, tab:bss, tab:confirmatory, tab:usa, tab:params,
  tab:kclass.
- The manuscript is intentionally in bullet-fragment form; join bullets into
  prose section by section. Every assumption is labelled and Appendix B
  lists them all - keep that register intact when prose replaces bullets.
- Reference entries marked "[standard reference; details to be verified
  before submission]" are deliberately left incomplete rather than invented -
  verify them (AGENTS.md rule 7) before submission.
- The P1 novelty sentence is **frozen as of 27 November 2026** after a rapid
  Crossref/OpenAlex title/abstract screen: 903 relevance-ranked records
  retrieved, 822 deduplicated records screened, 21 candidates manually
  reviewed, 103 forward-citation records included, zero gap-changing
  findings. The full record and the exact scoped sentence are in
  `paper01/literature/p1_novelty_screen_2026-11-27.md` and `PIVOT.md` section 9. This supports
  finalising the current title; it is not an exhaustive WoS/Scopus screen and
  no stronger claim is permitted.
