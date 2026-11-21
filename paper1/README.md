# Paper 1 working package — "Dams, queues and droughts"

Created 20 November 2026 from
`../Queueing-Drought_Junction_Research_Roadmap_2027-2029.pdf` (the GLM 5.3
document) and `../citations.txt`. Updated 21 November 2026.

## What is here

| File | Purpose |
|---|---|
| **`../START_HERE.md`** | **Read first.** Plain-language summary of what was done, what is being done, and the reading order. |
| `P1_draft_v0.md` | Original draft (superseded; retained for provenance). |
| `P1_draft_v1.md` | First revision after the literature audit; still contained `[VERIFY]` markers. Superseded. |
| **`P1_draft_v2.md`** | **Current manuscript draft.** All references verified; prior art correctly positioned; no outstanding `[VERIFY]` markers. |
| `literature_audit.md` | Crossref/OpenAlex search protocol, queries, verified prior art, novelty verdicts and remaining search-scope limitations. |
| `queueing_howto.md` | Practical "how to use queueing theory" note: dual representations, equations, estimators, CMIP6/IMD data mapping, validation design, guardrails. |
| `src/queue_core.py` | Self-contained non-stationary finite-capacity birth–death CTMC solver (RK4), exact stationary solution, Gillespie DES check, and drought indicators. NumPy only. |
| `src/test_queue_core.py` | Acceptance tests for the solver. |
| `src/data_pipeline.py` | Skeleton mapping IMD/CWC/CMIP6 series to λ(t) and μ(t), with specified (unimplemented) loaders and a labelled synthetic pilot demo. |
| `scopus_wos_search_plan.md` | Copy-paste Scopus and Web of Science Advanced Search strings (S1–S5), forward-citation seeds and screening protocol. |
| `data_access_spec.md` | **Revision 2:** verified inventory of the IMD, CAMELS-India and CMIP6 files actually on disk, revised pilot choice, and data-quality findings. |
| `../NOVELTY_AND_PLAN_REPORT.md` | Plain-language novelty verdict and the complete, ordered plan for P1 and P3, including the expanded literature hunt. |
| `../paper3/R/01_build_rates.R` | Builds daily λ(t), μ(t) from CAMELS-India forcings + observed streamflow for gauge 4026. Base R, no packages. |
| `../paper3/R/02_run_queue.R` | RK4-solves the finite-capacity CTMC from that CSV and writes E[Q], Pr(Q≥6), ρ and unmet demand. |

## Run

Use the existing `drought` Conda environment. The default `python` on this
machine has no NumPy.

```powershell
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper1/src/queue_core.py          # prints the Box 1 numbers
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper1/src/test_queue_core.py     # 5 acceptance tests
& 'C:\Users\deshm\miniconda3\envs\drought\python.exe' paper1/src/data_pipeline.py       # synthetic Punjab pilot; no data needed

# Real-data pilot (in this order; R 4.5.1 path shown)
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/02_run_queue.R
```

## Verified so far

**Solver.** Generator row sums zero; RK4 matches the exact product-form
stationary distribution to machine precision (L1 = 0.00000). Independent DES
time-average E[Q] = 0.91295 vs exact 0.91607 (0.34% error); jump-epoch averaging
gives 1.41, a documented bias. At identical mean rates, the non-stationary run
gives 2.3× peak backlog and 17× peak critical-exceedance probability.

**Literature.** Crossref/OpenAlex audit found substantive prior art and changed
the framing. Langbein (1958) published "Queuing Theory and Water Storage" in
the *Journal of the Hydraulics Division*; hydrological queueing also includes
Gamble et al. (1990a,b), Buchberger & Schade (1997), Batabyal (1996), Harel &
Mouche (2013), Gordienko & Ruiz de Chávez (2012), Palková & Hennyeyová (2012),
Lefebvre (2019), Unami et al. (2015) and Al-Sifao et al. (2026). The review
therefore **reclaims** a hydrological lineage rather than claiming a new
junction. Defensible gap: drought-specific unmet-demand backlog indicators with
non-stationary, covariate-learned rates and pre-specified validation.

## What is NOT done

1. **Further literature screening.** Web of Science S1–S3 are screened (S3 was
   a complete null); S4 (6), S5 (66) and Extra A/C (8/13) still need a
   record-level screen because the results renderer stalled. **Scopus is
   complete** (21 November 2026, institutional IP): S1–S5 and Extra A/C,
   295 records screened, no gap-changing study. OpenAlex citation tracing is
   done; database "Cited by" tracing and full-text screening remain. All
   remaining limitations are of *search scope*, not unresolved references.
2. **Observational data now present, but not yet fully exploited.** IMD
   NetCDF/HDF5 (1951–2025), CAMELS-India forcings/streamflow/attributes and
   CMIP6 **historical** (24 models) are on disk — see `data_access_spec.md`.
   The R pilot in `../paper3/R/` runs on CAMELS-India gauge 4026 today. Python
   `data_pipeline.py` loaders remain unimplemented because this Python
   installation has no NetCDF reader; R has `ncdf4`/`terra`.
3. **Claim convention — locked provisionally.** One claim = 10⁷ m³ = 20 mm over
   a nominal 50,000 ha command; K=20 = 400 mm; cap 3 claims/day. Recorded in
   `../START_HERE.md` §4, `data_access_spec.md` §1, `src/data_pipeline.py` and
   `../paper3/R/01_build_rates.R`. It is an assumption, not a measurement; the
   sensitivity envelope is still outstanding.
4. **Missing inputs for a full study.** No SSP CMIP6 files, no GRACE, no
   crop-area/canal-command records, and no documentation of whether gauge 4026
   flows are regulated. Gauge 4026 also has 68% zero-flow days — check whether
   these are true zeros or fill values.
5. **P1 vs P3 scope.** User decision: P1 (this review) first, then P3 (the
   ML-assisted non-stationary queue methods paper). `queue_core.py` is the
   methods core for both.

## Suggested next working session

1. Re-export the pending WoS searches (S4, S5, Extra A, Extra C) from
   `scopus_wos_search_plan.md` so their record cards can be screened; update
   `literature_audit.md` and, if anything new appears, the v2 gap statement.
   Scopus needs no further work.
2. Look for real canal-command/crop-area records; if none are found, keep the
   locked provisional 50,000 ha / 10⁷ m³ and run the planned sensitivity envelope.
3. Confirm the regulation status and zero-flow meaning for gauge 4026; consider
   switching the pilot to gauge 4064 if the zeros are a fill value.
4. Proceed to P3 using `queue_core.py` as the methods core and the R pilot as
   the real-data entry point.
