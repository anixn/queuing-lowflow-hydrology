# Paper 1 working package — "Dams, queues and droughts"

Created 20 November 2026 from
`../Queueing-Drought_Junction_Research_Roadmap_2027-2029.pdf` (the GLM 5.3
document) and `../citations.txt`. Updated 25 November 2026.

## What is here

| File | Purpose |
|---|---|
| **`../START_HERE.md`** | **Read first.** Plain-language summary of what was done, what is being done, and the reading order. |
| `P1_draft_v0.md` | Original draft (superseded; retained for provenance). |
| `P1_draft_v1.md` | First revision after the literature audit; still contained `[VERIFY]` markers. Superseded. |
| **`P1_draft_v2.md`** | **Current manuscript draft.** All references verified; prior art correctly positioned; no outstanding `[VERIFY]` markers. |
| `literature_audit.md` | Crossref/OpenAlex search protocol, queries, verified prior art, novelty verdicts and remaining search-scope limitations. |
| `queueing_howto.md` | Practical note: coupled storage/backlog representations, conservation ledger, equations, estimators, CMIP6/IMD mapping, validation design and guardrails. |
| `src/queue_core.py` | Self-contained non-stationary finite-capacity birth–death CTMC solver (RK4), exact stationary solution, Gillespie DES check, drought indicators and demand-conservation ledger. NumPy only. |
| `src/test_queue_core.py` | Acceptance tests for the solver, conservation ledger and sensitivity baseline. |
| `src/box1_sensitivity.py` | Reproducible 44-case synthetic Box 1 sensitivity grid; writes a provenance-labelled CSV. |
| `src/data_pipeline.py` | Skeleton mapping IMD/CWC/CMIP6 series to λ(t) and μ(t), with specified (unimplemented) loaders and a labelled synthetic pilot demo. |
| `scopus_wos_search_plan.md` | Copy-paste Scopus and Web of Science Advanced Search strings (S1–S5), forward-citation seeds and screening protocol. |
| `data_access_spec.md` | **Revision 2:** verified inventory of the IMD, CAMELS-India and CMIP6 files actually on disk, revised pilot choice, and data-quality findings. |
| `../NOVELTY_AND_PLAN_REPORT.md` | Plain-language novelty verdict and the complete, ordered plan for P1 and P3, including the expanded literature hunt. |
| `../paper3/R/01_build_rates.R` | Builds daily λ(t), μ(t) from CAMELS-India forcings + observed streamflow for gauge 4026. Base R, no packages. |
| `../paper3/R/02_run_queue.R` | RK4-solves the finite-capacity CTMC from that CSV and writes E[Q], Pr(Q≥6), nominal load and the legacy U abandoned-demand total. P3 unit-label correction is scheduled after Gate B. |

## Run

Use the existing `drought` Conda environment. The default `python` on this
machine has no NumPy.

```powershell
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper1/src/queue_core.py          # prints the Box 1 numbers
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper1/src/test_queue_core.py     # 9 acceptance tests
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper1/src/box1_sensitivity.py   # 44 synthetic sensitivity cases
& 'C:\Users\ankit.deshmukh\AppData\Local\miniconda3\envs\drought\python.exe' paper1/src/data_pipeline.py       # synthetic Punjab pilot; no data needed

# Real-data pilot (in this order; R 4.5.1 path shown)
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/01_build_rates.R
& 'C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe' paper3/R/02_run_queue.R
```

## Verified so far

**Solver.** Generator row sums zero; RK4 matches the exact product-form
stationary distribution to machine precision (L1 = 0.00000). Independent DES
time-average E[Q] = 0.91295 vs exact 0.91607 (0.34% error); jump-epoch averaging
gives 1.41, a documented bias. At identical mean rates, the non-stationary run
gives 2.3× peak backlog and 17× peak critical-exceedance probability. The
44-case sensitivity grid preserves the direction of the effect in every case
(peak-backlog ratios 1.20–5.33; critical-probability ratios 2.06–92.9).

**Literature.** The completed Crossref/OpenAlex, WoS, Scopus and citation-trace
audit found substantive prior art and changed the framing. Langbein (1958)
published "Queuing Theory and Water Storage" in the *Journal of the Hydraulics
Division*; hydrological queueing also includes Gamble et al. (1990a,b),
Buchberger & Schade (1997), Batabyal (1996), Harel & Mouche (2013), Gordienko &
Ruiz de Chávez (2012), Palková & Hennyeyová (2012), Lefebvre (2019), Unami et
al. (2015) and Al-Sifao et al. (2026). The 25 November supplementary search
added Acosta et al. (2026) for coupled drought state spaces and Zhao et al.
(2018) for non-stationary supply–demand resilience. The review therefore
**reclaims** a hydrological lineage rather than claiming a new junction. The
frozen four-part gap is unchanged.

## What is NOT done

1. **Submission-stage literature refresh.** Phase A is complete: 142 WoS and
   295 Scopus records were screened, database citation tracing is complete,
   and zero gap-changing records were retained. Repeat the targeted searches
   immediately before submission because the field is moving; do not treat the
   scoping audit as a systematic review.
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

1. Finish the P1 conservation/identification framing and build the
   reproducible mapping, Box 1 and data → rates → queue → indicators figures.
2. Run the Box 1 sensitivity grid over amplitudes, phase lag, $K_q$, $q^*$,
   $\theta$, $\alpha$ and $\eta$; retain the 2.3× result only as an illustrative
   case.
3. Prepare the WRR abstract, cover letter and code/data availability statement.
4. Only after Gate B, start P3 with the indicator-unit, server-accounting,
   spin-up and leakage corrections, then time-varying recovery distributions
   and the identification experiments.
