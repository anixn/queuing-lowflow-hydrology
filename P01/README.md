# P01 working package — Dams, queues and droughts

P01 is the review/perspective paper for *Water Resources Research*. It establishes the drought–queue mapping, audits prior art, demonstrates the averaging error with synthetic examples, and defines an identifiability-first validation programme.

Read `../START_HERE.md` first. The ordered plan is in `../docs/novelty/NOVELTY_AND_PLAN_REPORT.md`.

## Contents

| File | Purpose |
|---|---|
| `P01_draft_v2.md` | Current manuscript draft |
| `literature_audit.md` | Completed Crossref/OpenAlex/WoS/Scopus audit, citation trace and supplementary search |
| `search_protocol.md` | Exact WoS/Scopus strings, interface notes and screening log |
| `queueing_howto.md` | Technical mapping, conservation ledger, equations and guardrails |
| `data_access_spec.md` | Verified data inventory, extract contracts and provisional claim convention |
| `../src/shared/queue_core.py` | Shared finite-capacity CTMC engine, exact solution, DES and indicators |
| `../src/P01/box1_sensitivity.py` | Reproducible 44-case Box 1 sensitivity grid |
| `../src/P01/claim_scale_envelope.py` | Exact fluid and finite-claim checks for the revisable convention |
| `../src/P01/data_pipeline.py` | Data-to-rates skeleton and synthetic demonstration |
| `../tests/test_queue_core.py` | Shared-engine and P01 acceptance tests |

## Run

```powershell
python src/shared/queue_core.py
python src/P01/box1_sensitivity.py
python src/P01/claim_scale_envelope.py
python tests/test_queue_core.py
```

The sensitivity script writes `analysis/novelty_2026-11-25/data/box1_sensitivity.csv`.

## Verified synthetic results

Illustrative, under the stated assumptions:

- Exact/RK4 `E[Q] = 0.91607` claims; DES `0.91295` claims (0.34% difference).
- Non-stationary peak `E[Q] = 2.12950` claims at the same mean rates.
- Peak `Pr(Q ≥ 6) = 0.07331` versus stationary `0.00434`.
- The 44-case sensitivity grid preserves the direction of the averaging effect: peak-backlog ratios 1.20–5.33 and critical-probability ratios 2.06–92.9.
- Demand-ledger residual is below `1.7e-6` claims across the grid.
- The 30-case claim-scale envelope preserves exact fluid results across area/depth; finite-claim peak backlog ranges from 389.98 to 397.52 mm for 10–40 mm claims.

## Literature position

The queue–storage lineage begins with Langbein (1958). Hydrological queueing also includes soil water, groundwater, runoff, irrigation and water-supply reliability. Acosta et al. (2026) and Zhao et al. (2018) are cited as coupled state-space and non-stationary supply–demand prior art. The 25 November WoS refresh left S1, Extra A and S5 unchanged and added one irrelevant wireless-QoS record to S4. Scopus's current UI did not return targeted results, so no new Scopus screen is claimed. The frozen four-part gap sentence in `../AGENTS.md` §2 is unchanged.

## Remaining P01 work

1. Build reproducible manuscript figures.
2. Complete the novelty-language and internal-consistency pass.
3. Prepare the WRR abstract, cover letter and code/data availability statement.

P02 code is not part of Gate B; see `../P02/README.md`.
