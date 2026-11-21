# WHY_THIS_APPROACH.md — Why the queue view, and why now?

Companion to `AGENTS.md` and `HOW_TO_THINK_LAYMAN.md`. Plain language.
This file answers the question every collaborator, reviewer and future-you
will ask: *we already know P, T, PET and Q for CAMELS-IND catchments — why
do we need a queue on top of that?*

---

## 1. The honest framing (never say "better than hydrological modeling")

The queue view is **not a replacement** for hydrological modelling; it is a
**different question asked on top of the same data**.

| Tool | Question it answers |
|---|---|
| Rainfall-runoff model (SWAT, VIC, GR4J, LSTM…) | "How much water will flow in the river?" — converts rain into streamflow |
| Drought indices (SPI, SPEI, SSI) | "How unusual was the weather?" — a dimensionless anomaly |
| **The queue** | "Given what users demand and what the river can serve, how big is the unmet backlog now, how bad can it get, how long until it clears?" |

Demand and capacity are **not state variables** in rainfall-runoff models or
in indices. One can run the best model available and still have to invent a
threshold afterwards to declare "this is a drought". The queue makes demand,
service and the storage ceiling explicit state variables, so shortage is
**computed, not declared**.

## 2. What more information it gives (the quantities)

| Question a water manager asks | SPI/SSI | Rainfall-runoff model | Queue view |
|---|---|---|---|
| How unusual is the weather? | yes | needs extra step | yes (via covariates) |
| How much streamflow next month? | no | yes | no (μ comes from flow) |
| How much demand is unmet right now? | no | no | **E[Q] backlog** |
| Chance of a severe shortage state? | no | no | **Pr(Q ≥ k)** |
| Total volume that will go unserved? | no | no | **unmet demand U** |
| Days until recovery after rains return? | empirical only | no | **busy-period / first-passage maths** |
| Are we near the hard storage ceiling? | no | no | **blocking at K** |

Three points that make this scientific rather than a metaphor:

1. **Same deficit, different disaster.** Two catchments with identical SPI
   can suffer very differently, because harm depends on *when* demand
   arrives (kharif vs rabi) and *how fast* supply can respond. The queue
   captures that demand–supply interaction; an index cannot by construction.
2. **The averaging error is measured, not claimed.** Verified Box 1
   (`queue_core.py`, reproduced independently by the Floquet benchmark):
   true peak backlog **2.13 claims** vs **0.92** under
   stationary-at-the-average rates — a **2.3× understatement** of peak risk;
   peak severe-state probability 0.073 vs 0.004 (~17×). Standard practice
   (climatological means) commits exactly this error. That number justifies
   the project.
3. **It yields a falsifiable claim, not a story.** Pre-specified test: does
   the queue state add drought information (unmet volume, recovery time,
   severe-state probability) beyond SPI/SSI and a climatological queue, on
   held-out years and held-out basins? A null result is publishable and will
   be reported (AGENTS.md §3, rule 4).

## 3. Use cases (who uses this, and for what)

1. **Reservoir / canal-command operations.** "Monsoon failed this month —
   how many days until unmet demand crosses our buffer, and what intake cap
   keeps Pr(severe) below 5%?" Queue theory is built for capacity design:
   test changes in K (storage) or μ (intake) analytically, in seconds,
   without re-running a calibrated model.
2. **A consequence-based drought atlas from CAMELS-IND.** 242
   streamflow-sufficient catchments (v2.2) with P, T, PET, Q and 211
   attributes → queue indicators per catchment → the first Indian drought
   comparison where severity means *unmet demand*, not rainfall rank. The
   25 anthropogenic attributes (dams, irrigation) then serve as explanatory
   variables for why equal-SPI basins suffer unequally. This kind of
   large-sample study is only possible since CAMELS-IND (Mangukiya et al.,
   2025, ESSD 17:461–491).
3. **Climate change without hand-waving.** Bias-corrected CMIP6 → future
   λ(t), μ(t) (delta-change scaling of observed flow) → future Pr(Q ≥ k):
   "under SSP2-4.5, severe-backlog probability in the rabi window doubles by
   2040" is actionable and scenario-comparable.
4. **Monitoring / early warning.** The backlog is a daily-trackable state;
   recovery time is the first number a manager asks for.
5. **Transparency and speed.** NumPy-only engine, seconds per run, no
   calibration, validated against exact solutions (three-way agreement,
   0.34% DES error). Heavy models need months of setup and carry structural
   assumptions no reviewer can fully audit.

## 4. Why has nobody used it until now? (five honest reasons)

1. **It fell between two disciplines.** Queueing lived in operations
   research (telecom, hospitals). Hydrology kept the storage mathematics —
   Langbein (1958) *was* queueing — but drought science drifted to cheap
   rainfall indices in the data-poor era. Water shortage was handled by
   water-systems engineering (reliability–resiliency–vulnerability) in its
   own vocabulary. Both halves exist in the prior-art audit; the
   combination does not.
2. **The demand data never existed at scale.** λ(t) needs demand records,
   and canal-command-level demand is unrecorded almost everywhere, India
   included. Studies therefore defaulted to supply-side indices. This is
   the structural reason, and the source of our one true data gap
   (DATA_GUIDE.md §2).
3. **Non-stationarity was not urgent before climate change.** Stationary
   queueing has exact solutions; time-varying rates are genuinely hard, and
   only recently became tractable (Floquet methods, covariate-learned
   rates).
4. **The enabling tools are all young.** Large-sample catchment datasets
   (CAMELS-IND arrived 2025), ML that can learn λ(t) = fθ(weather) from
   covariates, cheap CTMC solvers. The junction was *impossible* circa 1990
   and *pointless* circa 2005; it is only *feasible now*. That is the
   "why now" paragraph of P1.
5. **Cultural resistance, stated honestly.** A lumped stochastic state
   model looks "too simple" to process-minded hydrologists and "too applied"
   to queueing theorists; no community's reward system paid for the bridge.
   The guardrails (exact validation, pre-specified tests, honest null
   reporting) exist precisely so the work cannot be dismissed as
   analogy-without-maths.

## 5. Where traditional modelling still wins (say this out loud)

Spatial detail; ungauged basins; land-use-change effects on supply;
snow, groundwater and inter-basin transfers. The queue also still needs
μ(t) *from* somewhere — observed streamflow in the pilot, a model or
delta-change in the future. The two compose: **hydrology supplies the
physics; the queue converts it into shortage-risk states.** P1's positioning
is the bridge, never the replacement.

## 6. The one-sentence version

Indices tell us the weather was strange; models tell us the river will be
low; only a demand–service–capacity state description can tell us *how much
water people will actually miss, how bad it can get, and how long recovery
will take* — and the data, the maths and the machines to do that have only
just become available together.
