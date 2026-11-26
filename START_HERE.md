# START HERE — what this project is, what changed, and which file to open

Prepared 26 November 2026 (v2 rebuild). Supersedes the 21 November v1 orientation.
Plain language; no statistics training needed.

---

## 1. The project in one paragraph

We read a drought as a **queue**. Water demand from farms arrives like customers
at a service desk (`lambda(t)`); river supply serves them (`mu(t)`); unmet demand
accumulates as a **backlog** `Q`; a full backlog hits a finite **capacity** `K`;
abandoned demand is **reneging**. Standard indices such as SPI measure unusual
weather. They do not directly measure how much water was missed, for how long,
or how long recovery will take. The queue description adds those quantities. We
are **not** claiming that linking queues to water is new — hydrology published
that link in 1958. Our claim is narrow and is frozen verbatim in section 5.

## 2. Why there was a rebuild

The v1 Python analysis returned a null, but the null was **not interpretable**:

1. **Unit mix** — demand and supply were expressed on inconsistent scales.
2. **Wrong regime** — utilisation `rho` was ~0.02–0.08, so a null was guaranteed.
3. **Two gauges only** — four held-out drought months per gauge; no power.
4. **Target leakage and benchmark fairness** were not audited.
5. **Python-only** — the deliverable was meant to be reproducible R.

v2 fixes each of these in `REDESIGN_PLAN_v2_R.md`. Python is archived on the
`legacy-python` branch (tag `v1-audited`); `main` is R and R Markdown only.

## 3. What v2 actually does

| Fix | v2 implementation |
|---|---|
| One unit system | One claim = 20 mm over a per-gauge command area; demand and supply share it (`R/00_utils/units.R`) |
| Catchment-relative thresholds | `q* = ceil(q_days*lam_bar)`, `K`, `theta` scale with the gauge, not absolute counts |
| Utilisation screen | Admit only `0.15 <= rho <= 1.20`; 212 of 279 profiled gauges qualify |
| More catchments | 24 gauges across 11 basins, both split periods, <= 3 per basin |
| Exact verification | 14/14 battery: closed forms, RK4 vs discrete-event simulation, ledger, unit wall, gap rules |
| Predeclared protocol | Endpoints, contrasts, sensitivities, harm bound and power fixed in `protocol/PROTOCOL_v2.md` |
| Leakage audit | Primary external SMA target disclosed; training-only SPI-3 target is the clean sensitivity |
| All sensitivities reported | V0/V1/V2 zeros, `f_irr` sweep, SUP-1/2/3, cap, `q_days`, `K_days`, PET source, target |

## 4. The current phase and the honest result

**Current phase: S9 (write-up package), Path B.**

The predeclared confirmatory endpoint (E1: does adding queue probability to SSI-3
lower the held-out Brier score?) is **null**. The paired per-gauge improvement has
a median near `+0.0008` with a two-level bootstrap interval that includes zero,
and the sign test does not reach significance. The prospective endpoint (E2) is
also null. A power analysis shows the Brier minimal detectable effect is larger
than the observed effect, so the null is **interpretable**, not merely
underpowered.

The **secondary** AUC contrast is positive: the queue improves ranking even
though it does not improve calibrated probability. Per the locked protocol this
is reported as secondary and is **never upgraded post hoc**.

The outcome is therefore a **methods + negative-result paper with a utilisation
diagnosis** — Path B in the plan. It is not a superiority claim.

## 5. The frozen novelty sentence (unchanged, 21 November 2026)

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens
> (142 records) and the completed Scopus S1–S5 / Extra A/C screens
> (295 records), plus the citation traces, we found no study that puts all
> four of these together: (1) drought as an accumulated unmet-demand backlog
> with a finite-capacity state; (2) queue-state indicators reported as
> drought quantities; (3) non-stationary rates estimated from hydroclimatic
> covariates; (4) validation against exact reference solutions and
> pre-specified drought tests."

We always write "we found no study in these sources", never "no such study
exists". The sentence was frozen after the WoS record-level screen completed
both databases (437 records, zero gap-changing findings). It is owned by Phase
A and must not be reworded by the rebuild.

## 6. Which document to read, in what order

| Order | File | What it gives you |
|---|---|---|
| 1 | **`README.md`** | The v2 rebuild in brief and the run commands |
| 2 | **`START_HERE.md`** (this file) | The whole situation in plain language |
| 3 | `PLAN_SUMMARY.md` | One-page plan, result, limitations and next actions |
| 4 | `protocol/PROTOCOL_v2.md` | What was fixed before unblinding |
| 5 | `analysis/P02_methods/RESULTS_v2.md` | Every result with its source script |
| 6 | `AGENTS.md` | Operating rules, frozen sentence, verification protocol |
| 7 | `docs/project/MERGED_PAPER_PLAN.md` | Outcome-contingent paper framing |
| 8 | `P01/literature_audit.md`, `P01/search_protocol.md` | The evidence trail for prior art |
| 9 | `R/` notebooks | The methods, written as documentation that asserts its own schema |

## 7. What is done and what remains

**Done:** v1 archived; R scaffold; 14/14 verification; data inventory; zero
audit; 24-gauge selection; baseline pipeline; power analysis; figures; all
predeclared sensitivity axes; protocol lock; notebooks.

**Remaining before submission:** author sign-off on submission metadata,
archive links, the demand/supply interpretation envelope, the disclosed
literature limitations, and the Path-B reframing. `renv` lockfile is a known
environment gap (documented in the protocol); `renv` is not installed on this
machine.

**Explicitly not done:** any future-climate (CMIP6) result. That stage is gated
(`R/50_future/21_cmip6_extract.Rmd`) and no raw CMIP6 number may be published.

## 8. How to see it run

From the project root, in PowerShell:

```powershell
Rscript R/verify/run_tests.R            # 14/14 must pass
Rscript R/run_pipeline.R                # ~6 minutes; writes output/
Rscript R/analysis/power_analysis.R
Rscript R/analysis/sensitivity_grid.R   # ~1 hour; every predeclared axis
Rscript R/analysis/make_figures.R
Rscript R/run_all.R                     # renders notebooks; stops on any failed assert
```

Nothing under `output/` or `figures/` is hand-written. Every CSV has a JSON
sidecar recording the git hash, parameters, seed and R session.
