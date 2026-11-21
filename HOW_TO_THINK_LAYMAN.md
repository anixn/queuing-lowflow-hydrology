# HOW_TO_THINK_LAYMAN.md — The systematic method, in plain words

Companion to `AGENTS.md`. No statistics training needed. This is the
"thinking recipe" that keeps the project honest and systematic.

---

## 1. The one idea, told like a story

Imagine a big farm system next to a river.

- Every day, the farms **ask for water**. That is the *arrival* — like
  people joining a queue at a counter.
- The river (and its dams) **hands out water**. That is the *service* —
  like the clerk serving people.
- If requests come faster than water can be handed out, the waiting line
  grows. In our story the waiting line is **unmet water demand** — the
  *backlog*.
- When rainy weeks come, the line shrinks. That is *recovery*.
- The line cannot grow forever: there is only so much storage. That ceiling
  is *capacity*.

A drought, in this story, is not "the rain was low". It is: **the queue got
long**. That gives us things we can count:

| Symbol | Plain meaning | Why it matters for drought |
|---|---|---|
| `λ(t)` lambda | how much water is requested per day (it changes by season) | the demand side of the story |
| `μ(t)` mu | how much backlog the river can clear per day (it also changes) | the supply side |
| `ρ` rho | traffic intensity = how close demand is to supply capacity | ρ near 1 = congestion; above 1 = the line grows |
| `E[Q]` | the average length of the waiting line | typical unmet demand |
| `Pr(Q≥k)` | chance the line is longer than a serious level | how often we are in "real drought territory" |
| `U` | total missed water over the dry spell (claim-days) | the size of the shortage |
| recovery time | days for the line to empty after rains return | what managers most want to know |

**Why the old indices are not enough:** SPI/SPEI say "the weather was
unusual". They never say "the queue reached 6 claims and stayed there for 40
days". Two droughts with identical rainfall deficits can harm farms very
differently depending on *when* demand arrived and *how fast* supply could
respond. That difference is exactly what the queue counts.

**Why non-stationarity (changing rates) is the whole point:** if you replace
a seasonal pattern by its yearly average, the average looks mild — but the
peak queue is what hurts. In our verified example the true peak backlog is
**2.13 claims**, the "average year" calculation says **0.92** — it hides
**more than half** the risk (2.3× understatement), and the chance of a severe
state is understated ~17×. That one number is the reason this project exists.

## 2. The five-step thinking loop (use it for every task)

```
1. ASK      Write the question in one sentence. ("Are the zero-flow days real?")
2. GATHER   Name the exact file(s), columns, and rows that can answer it.
3. COMPUTE  Do the smallest calculation that could possibly answer it.
4. CHECK    Verify the answer a second, independent way.
5. DECIDE   Write what this means for the paper, and the next question.
```

Worked example — the zero-flow question:

1. **Ask:** are gauge 4026's 68% zero-flow days real dry days, or a code for
   "no data"?
2. **Gather:** the CAMELS-IND data-description PDF (Zenodo record), the
   observed-streamflow file, and the LSTM-predicted streamflow file for the
   same gauge and days.
3. **Compute:** count how often observed = 0 while LSTM predicts > 0.1, and
   look for stretches of exact zeros longer than a season.
4. **Check:** read the basin context (Krishna at Kurundwad, 15,190 km²,
   upstream dams) and the data-description text. A 15,000 km² river being
   bone dry two days out of three is physically surprising — surprise is a
   signal to investigate, not to average away.
5. **Decide:** if fill value → treat as missing, or switch pilot to 4064;
   if real (regulated/intermittent) → say so in the paper and interpret ρ
   with that caveat. Write the decision down in `data_access_spec.md`.

If you cannot do step 2 (no file can answer it), the honest output is not a
guess — it is "unknown, here is what would answer it".

## 3. Label every number: [measurement] or [assumption]

This is the single most protective habit in the project.

- `[measurement]` — comes from an observed file (rainfall, streamflow).
- `[assumption]` — chosen by us because no record exists (the 50,000 ha
  command, the 10^7 m³ claim, firm share 0.5, the generic crop curve).

Rule: **an [assumption]-driven number is always called "illustrative"**, in
conversation, in the README, and in the paper. This is not weakness — it is
what lets you later swap in real records without rewriting the science.
The audit trail (`literature_audit.md`, `data_access_spec.md`) exists so
that six months from now, you can tell which numbers to trust.

## 4. The three-way check (why we trust the engine)

Any solver or model change is checked three independent ways:

1. **Exact formula** — pencil-and-paper mathematics where it exists.
2. **Numerical solver** — the computer takes small time steps (RK4).
3. **Simulation** — the computer "plays the story" thousands of times with
   random days (discrete-event simulation) and counts.

If three different routes agree (ours do, to 0.34%), the engine is real.
If two agree and one does not, that mismatch is the most interesting thing
in the repo that week — investigate it, do not delete it.

## 5. How to read this repository (order matters)

1. `START_HERE.md` — what was done, what is next (10 minutes).
2. `NOVELTY_AND_PLAN_REPORT.md` §1, §3.6, §4 — the idea, the claim, the plan.
3. `paper1/P1_draft_v2.md` — the actual manuscript.
4. `paper1/literature_audit.md` — why we may claim what we claim.
5. `paper1/data_access_spec.md` — what data exists and what is assumed.
6. `paper1/queueing_howto.md` — the equations, when you are ready.
7. `paper1/README.md` and `paper3/README.md` — what to run, in what order.

## 6. Session recipe (print this)

```
[ ] Read AGENTS.md §8: which phase am I in? What is the ONE next action?
[ ] Run the 18 tests. All green? (If not, fix before anything else.)
[ ] Do the next action with the 5-step loop.
[ ] Label every new number [measurement] or [assumption].
[ ] Update the audit/spec file that the action touches.
[ ] Re-run the 18 tests.
[ ] Write 3 sentences: what changed, what I learned, what is next.
```

## 7. Words you will see, decoded

- **CTMC (continuous-time Markov chain):** the mathematics of "the system is
  in state n = line length n, and it hops between states with certain
  probabilities per day".
- **Birth–death process:** the special case where the line can only change
  by ±1 per step (one arrival = birth, one service = death). Our queue is
  this, with time-varying hop rates.
- **RK4:** a standard accurate way to step a system forward in tiny time
  slices.
- **Floquet:** the mathematics of systems that repeat in a cycle (seasons).
  It gives the exact long-run answer for a repeating pattern.
- **MMPP:** arrivals that switch between "busy" and "quiet" regimes at
  random — a strict test of the estimator.
- **GBDT (gradient-boosted trees):** a workhorse machine-learning model that
  learns `λ(t)` or `μ(t)` from weather columns. Not fancy; trustworthy.
- **Isotonic / monotone:** forces the learned μ to always rise with river
  flow — physics as a constraint on the learner.
- **Bootstrap interval:** "re-do the estimate on 100 resampled datasets and
  see the spread" — our uncertainty bands.
- **Bias correction:** future climate model data is systematically off; we
  adjust its statistics to match observed IMD data before use. Raw model
  output may never enter a published number.
- **Ablation:** remove one ingredient at a time to prove each ingredient
  actually contributes. Our honesty test versus "correlation with SPI".
- **Gate:** a written checkpoint. You may not pass it until its checklist is
  objectively true.
