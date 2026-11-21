# ROADMAP_POSITION.md — Where I am on the 2027–2029 roadmap right now

Companion to `AGENTS.md`. Plain language. Prepared 21 November 2026.

---

## 1. The one-line answer

**You are ahead of the roadmap.** The plan said 2027 would be spent building
and validating the queueing core and writing the positioning paper (P1).
On 20–21 November 2026 you already have: a tested engine, exact benchmarks,
a screened literature hunt (295 Scopus records), a real-data pilot running on
one CAMELS-IND gauge, and a P1 manuscript at draft v2. You are effectively
**doing early Phase-C work while still finishing Phase-A/B work** — which is
fine, as long as Phase A gets closed before the manuscript is finalised.

## 2. Scoreboard (roadmap item → status)

| Roadmap item | Planned for | Status today |
|---|---|---|
| Queueing core library (time-varying rates, finite capacity, reneging, thresholds) | 2027 Q1–Q2 | **Done** (`queue_core.py`): exact + RK4 + DES agree (E[Q] 0.9161 vs 0.9129, 0.34%) |
| Synthetic benchmarks + validation | 2027 Q1–Q3 | **Mostly done**: Floquet periodic + MMPP/2 benchmarks exist; Floquet convergence study and MMPP parameter sweep still owed |
| Paper P1 (storage-theory review + positioning) | 2027 Q3 submit | **Draft v2 exists.** Literature screen 295 Scopus records clean; 4 WoS searches need record-level screening; then figures + guardrails box |
| Topic 1 / Topic 6 data pipeline (demand-supply series) | 2027 Q2–Q4 | **Pilot works**: CAMELS-IND gauge 4026 → λ(t), μ(t) → queue → indicators (illustrative numbers only) |
| Topic 6 ML estimation of λ(t), μ(t) | 2028 Q1–Q2 | **First version exists** (GBDT + isotonic μ, bootstrap); known μ-error near ρ≈1 must be fixed |
| Low-flow case studies (multi-gauge) | 2028 Q2–Q3 | Single gauge only (4026); add 4064 Yadgir next |
| CMIP6 future rates | 2028 Q3–Q4 | Extraction runs (1 model/SSP); **bias correction not done**; future μ(t) not built |
| Held-out validation / ablation | 2028 Q3–Q4 | Not started (pre-register metrics first) |
| Papers P2 (agricultural), P4 (groundwater), P5 (package) | 2028 Q2 → 2029 | Not started (correctly waiting) |
| Version control | Phase D hygiene | **No git repo yet — do this now, it is one command and protects everything** |

## 3. The next ten actions, in exact order

1. ~~**Initialise git**~~ — done (repo initialised, committed, pushed to
   GitHub; branch `master`).
2. ~~**Screen the four pending WoS searches**~~ — done 21 November 2026:
   93/93 records screened by export, zero retained
   (`analysis/P01/wos_screening_2026-11-21.md`).
3. ~~**Full-text screen the retained prior-art set**~~ — empty by definition:
   nothing was retained.
4. ~~**Freeze the gap sentence** with date + scope (Gate A)~~ — done 21
   November 2026 (`AGENTS.md` §2).
5. **Check the zero-flow semantics** for gauge 4026: open
   `CAMELS_IND_Data_Description.pdf` (in the CAMELS-IND Zenodo record) and
   search for how zero discharge is defined; cross-check the LSTM-predicted
   streamflow file on the same days. Decide: real intermittency/regulated
   zeros vs fill value. If fill value → switch pilot to 4064 and re-run.
6. **Search `camels_ind_anth.csv` (25 anthropogenic attributes)** for dam,
   canal, and irrigated-area variables. Anything useful there can replace
   parts of the provisional 50,000 ha / 10^7 m^3 convention. Whatever
   remains assumed → run the sensitivity envelope.
7. **Finish P1 Phase B:** tighten §2 mapping, add prior-art rows (Mouche &
   Harel 2016; Prajamwong et al. 1997), guardrails box, reproducible figures,
   novelty-language pass, WRR package. Gate B = gap sentence frozen, all
   prior art cited, all numbers regenerable.
8. **Fix the μ-estimation error near ρ≈1** (monotone constraints,
   calibration); then the Floquet convergence study and MMPP sweep.
9. **Multi-gauge pilot:** parameterise `01_build_rates.R` for gauge 4064;
   run the pair; compare queue behaviour across the two basins.
10. **Bias-correct CMIP6 against IMD** (e.g., quantile mapping), then build
    future μ(t) by delta-change scaling of observed streamflow.

## 4. What "ahead" means for the schedule

- The 2027 Q3 "P1 submit" target is realistically reachable in **2027 H1**.
- The slack you have earned should go to **P3 quality** (μ-error, validation
  design), not to starting P2/P4 early. Topic 1 (P2) still needs a real
  demand-side data decision before it can start; do not let an easy pilot
  tempt you into treating an assumption as a finding.
- Keep one conference abstract in 2027 (EGU-style general assembly) from the
  4026 pilot — clearly labelled illustrative — so the community sees the
  method early.
