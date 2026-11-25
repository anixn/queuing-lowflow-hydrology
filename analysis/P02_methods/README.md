# P02 methods analysis

**Current status:** design protocol only; P02 implementation begins after P01 reaches Gate B.

- `MODELLING_PLAN.md` — model stack, equations, validation ladder and work packages.
- `DATA_REQUIREMENTS.md` — what is required now, before validation and only for stronger claims.
- `data_inventory_2026-11-25.csv` — verified local/remote data inventory.

Planned outputs, in order:

1. R/Python indicator-contract and evaluation-plumbing corrections with golden tests.
2. Time-varying recovery distributions and parameter-identification experiments.
3. μ-error diagnostic near congestion.
4. Floquet convergence study.
5. MMPP parameter sweep.
6. Multi-gauge R outputs for gauges 4026 and 4064.
7. Zero-flow and regulation semantics note.
8. Claim-convention sensitivity envelope.
9. CAMELS-IND-Proj LSTM provenance and historical validation, forcing recovery without double bias correction, and conditional future μ(t) ensemble.
10. Pre-registered held-out validation and uncertainty propagation.
11. SPI/SPEI/SSI ablation, including an honest null if that is the outcome.

Details are in `../../docs/project/RESEARCH_PROTOCOL.md` and `../../docs/novelty/NOVELTY_AND_PLAN_REPORT.md`.
