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

**Current phase: S9 (write-up package), Path B with a target-dependent positive.**

The **primary** confirmatory endpoint (external district soil-moisture target)
is **null**: adding queue probability to SSI-3 gives a median Brier improvement
of **+0.00204** with a two-level bootstrap interval that includes zero
(10/15, p = 0.151). The prospective endpoint is also null. The **leakage-clean**
training-only SPI-3 target is **positive**: median **+0.00397**, CI
**[+0.00013, +0.00949]**, **12/15**, p = 0.0176, AUC **+0.038** (14/15).

The ranking signal is real but modest: mean AUC rises from **0.771 (SSI-3)** to
**0.815 (SSI-3 + queue)**. The utilisation slope is positive in India (+0.0066)
but not significant (p = 0.188), so the conditional rule is a hypothesis. The
US reservoir pilot is an **exploratory replication** and is null on both Brier
and AUC once the window is applied.

The outcome is therefore **Path B with a target-dependent positive**: a methods
and negative-result paper framed as *what queueing can and cannot do for
low-flow hydrology* — one honest null, one target-dependent positive signal,
one verified reusable engine, and one zero-flow data-quality warning. It is not
a superiority claim.

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
| 1 | **`README.md`** | The v2 rebuild in brief and the folder map |
| 2 | **`START_HERE.md`** (this file) | The whole situation in plain language |
| 3 | **`HELP.md`** | How to run the numbered sequence |
| 4 | `PLAN_SUMMARY.md` | One-page plan, result, limitations and next actions |
| 5 | `manuscript/MANUSCRIPT.md` | The HESS draft |
| 6 | `protocol/PROTOCOL_v2.md`, `protocol/COMMON_PROTOCOL.md` | The pre-specified design and the like-for-like comparison rules |
| 7 | `analysis/P02_methods/RESULTS_v2.md`, `US_PILOT_RESULTS.md` | Every result with its source script |
| 8 | `AGENTS.md` | Operating rules, frozen sentence, verification protocol |
| 9 | `P01/literature_audit.md`, `P01/search_protocol.md`, `analysis/P01_literature/` | The evidence trail for prior art |
| 10 | `docs/project/MERGED_PAPER_PLAN.md`, `SESSION_LOG_v2.md` | Paper plan and gate reports |

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
Rscript steps/run_all_steps.R            # India baseline + USA + common arm + figures
Rscript steps/run_all_steps.R --full     # also the long India sensitivity grid
Rscript steps/step_12_verify.R           # 14/14 battery
```

Nothing under `output/` or `figures/` is hand-written. Every CSV has a JSON
sidecar recording the git hash, parameters, seed and R session.
