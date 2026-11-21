# Approach preparation for Paper 01 and Paper 03

Prepared 21 November 2026. This is a working note, not a manuscript edit. It does
not change the frozen gap sentence in `AGENTS.md` §2.

## 1. Where the project stands

We are in **Phase A: finish the gap hunt** — record-level screens are now
complete (21 November 2026). The last database job, the record-level screen of
four Web of Science sets (S4: 6 records, S5: 66, Extra A: 8, Extra C: 13 — 93
in total), was done on 21 November 2026 by export; zero records retained
(`analysis/P01/wos_screening_2026-11-21.md`; `paper1/literature_audit.md`).
The repository also states that P01
comes first and P03 starts only after P01 is stable (`AGENTS.md:21-28`,
`:192`; `START_HERE.md:125-137`).

**Single next action (Phase B):** tighten the P1 mapping section and fold the
two new citation-trace prior-art records (Yang 2016 CSAE; Jones 2016/2019
runoff-runon) into the P1 prior-art table
(`paper1/P1_draft_v2.md` §2; `paper1/literature_audit.md`). The 93-record WoS
screen, the seed citation trace and the frozen gap sentence are all complete
as of 21 November 2026.

**P03 status:** preparation only. Do not start Phase C work before Gate B. Gate B
requires the gap sentence to be frozen, all prior art to be cited, and every
numerical claim to have a reproducible script (`AGENTS.md:184-190`;
`NOVELTY_AND_PLAN_REPORT.md:234-246`).

## 2. Numbers trusted today, 21 November 2026

All values below are synthetic or pipeline-check outputs unless marked otherwise.
They were regenerated on 21 November 2026 using
`C:\Users\deshm\miniconda3\envs\drought\python.exe`. Units and provenance are
part of the number.

| Quantity | Value | Unit | Status and source |
|---|---:|---|---|
| Exact stationary E[Q] | 0.91607 | claims | Synthetic anchor, `paper1/src/queue_core.py`; `AGENTS.md:87-90`, `paper1/P1_draft_v2.md:268-272` |
| RK4 stationary E[Q] | 0.91607 | claims | Same solver check; `paper1/P1_draft_v2.md:269-272` |
| DES time-average E[Q] | 0.91295 | claims | 0.34% below exact; `AGENTS.md:87-90`, `paper1/P1_draft_v2.md:270-272` |
| L1(RK4, exact) | < 0.00001 | probability mass | Solver check; `paper1/P1_draft_v2.md:270-272` |
| Seasonal peak E[Q] | 2.130 | claims | Same mean rates as stationary run; 2.3× the stationary value; `paper1/P1_draft_v2.md:274-282` |
| Stationary peak E[Q] | 0.916 | claims | Comparison value; `paper1/P1_draft_v2.md:280-282` |
| Peak Pr(Q≥6), seasonal | 0.0733 | probability | 17× the stationary value; `paper1/P1_draft_v2.md:283` |
| Peak Pr(Q≥6), stationary | 0.0043 | probability | Comparison value; `paper1/P1_draft_v2.md:283` |
| Unmet demand U, 3 yr | 16.79 vs 15.05 | claim-days | Seasonal vs stationary; +11.6%; `paper1/P1_draft_v2.md:284` |
| Floquet peak E[Q] | 2.1295 | claims | Independent periodic benchmark; `paper3/README.md:68-72` |
| Floquet eigenvalue residual | 1.57×10⁻¹⁵ | dimensionless | Regenerated from `paper3/src/nonstationary_bench.py`; `paper3/README.md:68-72` |
| MMPP amplification | 1.16× | ratio | One parameter setting only; not a general claim; `paper3/README.md:74-79` |
| Gauge 4026 pilot E[Q] mean | 1.43 | claims | Illustrative, under the stated assumptions; `paper3/README.md:90-111`, `paper1/data_access_spec.md:76-78` |
| Gauge 4026 pilot E[Q] peak | 3.60 | claims | Illustrative, under the stated assumptions; `paper3/README.md:99-105` |

The claim convention behind every real-data pilot number is `[assumption]`:
50,000 ha command, one claim = 10⁷ m³ = 20 mm, K = 20 claims, service cap
3 claims/day, firm share 0.5 (`START_HERE.md:68-92`;
`paper1/data_access_spec.md:19-39`). Pilot numbers stay labelled
"illustrative, under the stated assumptions" until real canal/crop records or a
documented sensitivity envelope exist.

## 3. Paper 01: approach from here

### 3.1 Finish Gate A first

1. Add a screening table to `paper1/literature_audit.md` with columns:
   search set, title, year, DOI or stable identifier, decision, one-line reason.
   Cover S4, S5, Extra A and Extra C. The decision rule already in the search
   plan is: retain for full text only when a record could change the four-part
   gap statement; otherwise drop with a reason
   (`paper1/scopus_wos_search_plan.md:141-148`).
2. Complete the citation-trace additions named in the plan: Yang 2019,
   Harel & Mouche 2014, Mouche & Harel 2016 and Prajamwong 1997
   (`AGENTS.md:176-180`; `NOVELTY_AND_PLAN_REPORT.md:225-230`). Mouche & Harel
   2016 and Prajamwong 1997 are already in the audit and P01 reference list
   (`paper1/literature_audit.md:139-140`; `paper1/P1_draft_v2.md:171-172`,
   `:472-493`).
3. Full-text screen the retained set. Record keep/drop reasons in the same
   audit file (`paper1/literature_audit.md:196-204`).
4. Freeze the gap sentence with date and search scope only after the screens
   are complete. Do not strengthen, weaken, renumber or reword the existing
   frozen sentence without redoing the search (`AGENTS.md:30-45`).
5. Update `paper1/scopus_wos_search_plan.md` run log with the date, interface,
   hit counts, screened counts, retained counts and exclusion reasons.

**Gate A done when:** one dated sentence exists and every retained record has a
keep/drop reason (`AGENTS.md:181-182`).

### 3.2 Then finish P01 (Gate B)

Work in the order already fixed by the plan
(`NOVELTY_AND_PLAN_REPORT.md:234-246`).

| Order | Task | Concrete action |
|---:|---|---|
| 1 | Tighten mapping, P01 §2 | Lead with Langbein/Moran and the water-system mapping, not the EV-charging example that currently opens §2.1 (`paper1/P1_draft_v2.md:107-111`). Pair arrival, service, capacity, abandonment, busy period and recovery with one hydrological meaning and one caveat. |
| 2 | Expand prior art | Keep the 1997 and 2016 entries already in the table (`paper1/P1_draft_v2.md:171-172`). Add explicit paragraphs on mature non-stationary queueing and ML-for-queues from the audit (`paper1/literature_audit.md:144-174`). Do not present either as our contribution. |
| 3 | Strengthen non-stationarity | Use Box 1 only with its script and units: 0.91607 vs 0.91295 claims three-way check; 2.130 vs 0.916 claims peak backlog; 0.0733 vs 0.0043 peak severe-state probability; all synthetic (`paper1/P1_draft_v2.md:266-292`). |
| 4 | Write falsifiable programme | Convert §5 into a table: test, metric, baseline, null-result clause. Baselines: constant rate, climatological rate, SPI/SPEI/SSI and storage anomaly. Pre-specify before examining P03 outputs (`paper1/P1_draft_v2.md:294-317`; `NOVELTY_AND_PLAN_REPORT.md:240-242`). |
| 5 | Add guardrails box | Use the six rules in §6 (`paper1/P1_draft_v2.md:330-347`) plus: no raw CMIP6 number in a published result; every pilot number labelled illustrative; no correlation-only superiority claim (`AGENTS.md:47-66`). |
| 6 | Build figures/tables | Mapping table, prior-art table, Box 1 comparison and data→rates→queue→indicators flow diagram. Every numeric figure must come from `queue_core.py` or another named script (`NOVELTY_AND_PLAN_REPORT.md:242`). |
| 7 | Language pass | Search the draft for "novel", "first", "new", "unique" and "no study". Replace the abstract phrase "The novelty we claim..." at `paper1/P1_draft_v2.md:44` with scope-limited wording tied to the frozen sentence. Keep "we found no study in these sources" wording (`AGENTS.md:30-45`). |
| 8 | WRR package | Abstract, cover letter stating the narrow gap and search scope, code/data availability statement (`NOVELTY_AND_PLAN_REPORT.md:244`). |

**Gate B done when:** gap sentence frozen, all prior art cited, every numerical
claim script-backed (`AGENTS.md:189-190`).

## 4. Paper 03: preparation to hold until Gate B

P03's role is to estimate λ(t) and μ(t) from covariates, validate against exact
references, and test whether queue indicators add drought information beyond
baselines (`NOVELTY_AND_PLAN_REPORT.md:72-84`). ML-for-queues, time-varying and
correlated arrivals are mature fields; they are not contributions
(`paper1/literature_audit.md:144-174`; `AGENTS.md:62-66`).

| Gate B order | Work package | Deliverable and stop rule |
|---:|---|---|
| 1 | μ error near ρ≈1 | Fix the dominant estimator weakness first (`NOVELTY_AND_PLAN_REPORT.md:250`). Current synthetic evaluation has μ RMSE about 0.098/day and the mass-calibrated estimator overshoots oracle peak severe probability under warming; treat both as diagnostics, not findings (`paper3/README.md:81-84`; `paper3/src/evaluate_estimators.py:127-133`). Add a test. |
| 2 | Floquet convergence | Vary dt; report residual and peak-indicator stability. Keep the RK4 dt cap: generator reaches about 8.5/day and dt×|λmax| must stay below about 2.78 (`paper3/README.md:86-88`; `AGENTS.md:137-139`). |
| 3 | MMPP sweep | Vary switching rate and high/low contrast. The 1.16× amplification is one setting and must not become a general claim (`paper3/README.md:74-79`; `NOVELTY_AND_PLAN_REPORT.md:252`). |
| 4 | Multi-gauge R pipeline | Add gauge 4064 Yadgir while keeping linear BLOCK-1 scripts and base R (`paper1/data_access_spec.md:47-55`; `NOVELTY_AND_PLAN_REPORT.md:253`). |
| 5 | Zero-flow semantics | Check `CAMELS_IND_Data_Description.pdf`. Gauge 4026 has 9,710 zero-flow days out of 14,308 non-missing (68%); do not interpret ρ on zero-flow days until resolved (`paper1/data_access_spec.md:59-61`; `AGENTS.md:163-166`). |
| 6 | Claim convention | Search for real canal/crop records. If absent, run a documented sensitivity envelope; keep every pilot number illustrative (`paper1/data_access_spec.md:80-97`; `START_HERE.md:87-92`). Change the convention in all four required places in one step (`AGENTS.md:73-76`). |
| 7 | CMIP6 bias correction | Bias-correct against IMD/CAMELS before any future rate. Raw `cmip_4026_*.csv` and Hargreaves ET0 are pipeline checks only (`AGENTS.md:53-55`; `paper1/data_access_spec.md:91-93`). |
| 8 | Future μ(t) | Build future service rates by delta-change scaling observed streamflow or a rainfall–runoff transfer function; CMIP6 extract gives pr and temperature, not streamflow (`paper3/README.md:144-146`). |
| 9 | Pre-registered validation | Write metrics, baselines and held-out year/basin/event design before looking at results (`NOVELTY_AND_PLAN_REPORT.md:258`). |
| 10 | Uncertainty propagation | Carry bootstrap intervals from `rate_estimators.py` into E[Q], Pr(Q≥6), U and recovery time (`NOVELTY_AND_PLAN_REPORT.md:259`). |
| 11 | Ablation | Test incremental information beyond SPI/SPEI/SSI and a climatological queue. If none, write the null result (`AGENTS.md:59-61`; `NOVELTY_AND_PLAN_REPORT.md:260`). |
| 12 | Write HESS | Only after Gate C: estimator beats climatology on held-out data, or a solid null result is written honestly (`AGENTS.md:198-199`). |

## 5. Current blockers and decisions

- **Database access:** the WoS record cards for the four pending sets did not
  render; exports or a working browser session are needed
  (`paper1/literature_audit.md:57-63`).
- **Environment:** the default `python` is Miniconda 3.13.9 without NumPy. The
  existing `drought` environment (Python 3.12.16, NumPy 2.5.4) runs all 18
  tests. Run commands now record this in `START_HERE.md:141-148`,
  `paper1/README.md:28-34` and `paper3/README.md:41-52`.
- **Data semantics:** zero-flow meaning, regulation status of gauge 4026,
  crop/canal records and CMIP6 bias correction are unresolved
  (`paper1/data_access_spec.md:59-67`, `:80-97`).
- **Venue/order confirmation:** the plan asks for confirmation that WRR (P01)
  then HESS (P03) remains the order of work
  (`NOVELTY_AND_PLAN_REPORT.md:283-288`). No change has been made.
