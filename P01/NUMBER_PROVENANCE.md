# P01 numerical provenance

Every scientific number in the manuscript is synthetic or bibliometric. No gauge-4026 pilot indicator is presented as a finding.

| Manuscript number | Unit | Status | Script or record |
|---|---|---|---|
| Exact/RK4 E[Q] = 0.91607 | claims | Synthetic anchor | `src/shared/queue_core.py::run_demos`; `tests/test_queue_core.py` |
| DES E[Q] = 0.91295; 0.34% difference | claims; percent | Synthetic anchor | `src/shared/queue_core.py::run_demos`; `tests/test_queue_core.py` |
| L1(RK4, exact) < 1×10⁻⁵ | probability mass | Synthetic solver check | `src/shared/queue_core.py::run_demos` |
| Seasonal peak E[Q] = 2.12950/2.130 | claims | Synthetic, illustrative | `src/shared/queue_core.py`; `src/P01/figure_data.py`; Floquet benchmark |
| Seasonal peak Pr(Q≥6) = 0.07331/0.0733 | probability | Synthetic, illustrative | Same as above |
| Stationary peak Pr(Q≥6) = 0.00434/0.0043 | probability | Synthetic, illustrative | Same as above |
| Backlog exposure 668.73 vs 795.01 | claim-days | Synthetic, illustrative | `src/shared/queue_core.py::run_demos` |
| Abandoned demand 13.37 vs 15.90; +18.9% | claims; percent | Synthetic, illustrative | `src/shared/queue_core.py::run_demos` |
| Non-stationary ledger residual 2.2×10⁻⁷ | claims | Synthetic solver check | `src/shared/queue_core.py::run_demos` |
| Ramp peak/mean E[Q] = 1.56/1.13; abandoned demand 24.78; ledger residual 3.7×10⁻³ (<5×10⁻³ tolerance) | claims | Synthetic, illustrative | `src/shared/queue_core.py::run_demos` |
| 44-case peak-backlog ratio 1.20–5.33; median 2.32 | ratio | Synthetic, illustrative | `src/P01/box1_sensitivity.py`; `analysis/novelty_2026-11-25/data/box1_sensitivity.csv` |
| 44-case critical-probability ratio 2.06–92.9; median 16.78 | ratio | Synthetic, illustrative | Same as above |
| Maximum grid ledger residual 1.7×10⁻⁶ | claims | Synthetic solver check | Same as above |
| WoS 142; Scopus 295; total 437; WoS refresh S4 7 | records | Bibliometric measurement | `src/P01/validate_literature_counts.py`; `P01/literature_audit.md`; `analysis/P01_literature/`; `analysis/claim_convention_2026-11-25/wos_refresh_2026-11-25.csv` |
| WoS record-level 93; citation trace 76; two new records | records | Bibliometric measurement | `src/P01/validate_literature_counts.py`; `analysis/P01_literature/wos_screening_2026-11-21.md`; `analysis/P01_literature/citation_trace_2026-11-21.md` |

## Regeneration

```powershell
python src/shared/queue_core.py
python src/P01/box1_sensitivity.py
python src/P01/claim_scale_envelope.py
python src/P01/make_figures.py
python src/P01/validate_literature_counts.py
python tests/test_queue_core.py
```

All synthetic values must be described as **illustrative, under the stated assumptions**.
