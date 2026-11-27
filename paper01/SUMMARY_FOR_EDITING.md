# What we tested, what we found, and how to edit the paper

**Plain-language guide for the author.** Written 27 November 2026. It explains the
study in words a non-specialist can repeat back, records every number the
manuscript quotes, and says which file holds what. If you only read one
section, read §1 and §3.

---

## 1. The study in one page

We asked whether a **storage-deficit state** helps forecast **hydrological
drought** in Indian catchments better than the simple things an operator
already uses.

The storage state is built from each catchment's own recession behaviour: how
fast the river falls after rain stops. That fall rate gives a "memory" for the
catchment. We pushed the state forward day by day with a water balance
(rain in, evaporation out, release to the river out) and used it as a
predictor of drought three months later.

We compared it against three honest baselines: **persistence** (last month's
drought index), **lagged indices** (SPI-3, SSI-3, SSI-6, SPI-6), and an
**antecedent precipitation index** (a weighted memory of past rain). All five
families used the same model machinery.

**The answer is no.** The storage state adds nothing useful. Not "we could not
detect it", but "it is smaller than the smallest change an operator would act
on". We can say that because we declared that smallest useful change in
advance (0.005 Brier) and then showed the whole uncertainty interval sits
inside it.

**Why it fails is measured, not guessed.** These catchments drain in about
nine days. A three-month drought index remembers three months by
construction. A state that forgets in nine days cannot compete with it, and no
model can fix that — the information is not there to learn.

**What the paper gives instead:**
1. a bounded null (the effect is provably below usefulness, not merely
   undetected);
2. the India-wide lead-time ceiling (how much skill exists at 1, 2, 3, 6 and
   12 months, on one common sample);
3. the criterion that says where such a state *could* work: the recession
   constant must be at least the lead divided by 1.39 (about 22 days for a
   one-month lead, 66 days for three).

---

## 2. What we tested, precisely

| Element | Choice |
|---|---|
| Study sample | India, CAMELS-IND, 472 gauges read; 257 prepared; 231 with complete months; 218 with enough drought events; 136 with a usable recession record; 111 of those borrow basin-median parameters |
| Transfer check | USA, Caravan, 652 read; 639 complete; 540 storage-scored |
| Confirmatory target | monthly SSI-3 ≤ −1 (hydrological drought) |
| Descriptive target | monthly mean flow below the training-period Q90 (low flow) |
| Leads | 1, 2, 3, 6, 12 months; **1, 3 and 6 were frozen before scoring**, 2 and 12 were added later and are labelled exploratory |
| Families | climatology, persistence, lagged indices, API, storage alone, storage + indices (confirmatory) |
| Baseline to beat | the per-gauge best of persistence, lagged indices, API, chosen on training years only |
| Split | fit on 1981–2010; test on 2011–2020, touched once |
| Confirmatory statistic | paired per-gauge Brier difference on identical months, median across gauges, two-level bootstrap (2000 resamples) |
| Harm bound | 0.005 Brier, declared before scoring as the smallest change worth acting on |
| Extra test | equivalence (two one-sided tests): is the whole interval inside ±0.005? |

Pre-registration: H0 = parity at 1 month (a null was the *expected* outcome),
H1 = a gain at 3 months, H2 = a gain at 6 months.

---

## 3. What we got

### 3.1 The confirmatory answer (India, drought target)

| Lead | Median ΔBrier | 95 % interval | Gauges where storage wins | Verdict |
|---:|---|---|---:|---|
| 1 mo | −0.0003 | [−0.0019, +0.0012] | 47 % (62/131) | H0 parity — **as predicted** |
| 2 mo (exploratory) | +0.0001 | [−0.0016, +0.0015] | 51 % (67/131) | parity |
| 3 mo | −0.0015 | [−0.0032, +0.0001] | 43 % (56/130) | **H1 FAIL** |
| 6 mo | −0.0007 | [−0.0027, +0.0001] | 41 % (54/131) | **H2 FAIL** |
| 12 mo (exploratory) | −0.0011 | [−0.0031, +0.0001] | 40 % (53/131) | worse still |

Positive = storage better. All five medians are at or below zero from three
months on.

### 3.2 The stronger statement: equivalence

At **every lead, in both countries**, the 90 % interval sits inside ±0.005
Brier, with p_TOST < 0.001. So the effect is not "unresolved" — it is bounded
below the threshold of operational usefulness.

USA nuance: at one month the USA shows a small but detectable gain (median
+0.0009, 59 % of 540 gauges, sign test p < 0.001). It is still eight times
smaller than the harm bound. Detectable and meaningful are different things;
this is the cleanest example in the paper.

### 3.3 The lead-time ceiling (median BSS vs climatology, India, one common sample)

| Family | 1 mo | 2 mo | 3 mo | 6 mo | 12 mo |
|---|---:|---:|---:|---:|---:|
| persistence | 0.501 | 0.227 | 0.070 | 0.010 | 0.014 |
| lagged indices | 0.467 | 0.199 | 0.070 | 0.019 | −0.004 |
| storage + indices | 0.478 | 0.196 | 0.037 | 0.005 | −0.024 |
| storage alone | 0.231 | 0.081 | 0.005 | −0.007 | −0.009 |

Read the collapse, not the one-month number: the 0.5 at one month is mostly
autocorrelation of a three-month index. By three months you have 7 % of
climatology's error removed; by twelve months nothing, and the storage family
is below climatology.

### 3.4 The mechanism

| Quantity | Value |
|---|---|
| Median recession constant k | 9.2 days |
| 25th / 75th / 95th percentile | 5.6 / 12.3 / 15.4 days |
| Slowest gauge | 41.3 days |
| Share draining in under 10 days | 65 % |
| Share draining in under 30 days | 99 % |
| Median memory retained at 1 month | 3.6 % |
| at 2 / 3 months | 0.13 % / 0.005 % |

A gauge would need k ≈ 22 days for a quarter of its memory at one month and
≈ 66 days for three months. No gauge in this sample reaches the second.

There is a **weak gradient**: the median gain rises from −0.025 in the
fastest fifth of gauges to +0.002 in the slowest — real, but still below the
harm bound. The rank correlation across gauges is ≈ 0 and the directions
cancel (39 % of gauges above +0.005, 51 % below −0.005).

### 3.5 Catchment attributes

- **Cannot enter the forecast**: within a gauge an attribute is a constant, so
  the model cannot use it. (The storage family already carried k, BFI and
  S_cap as constants; they were inert.)
- **Do explain where skill lives**: reservoir density ρ = +0.27 and area
  ρ = +0.27 (both BH p = 0.05); zero-flow fraction ρ = −0.22, runoff ratio
  ρ = −0.23, storage scale ρ = −0.23 (marginal). A standardised model gives
  R² = 0.20.
- **Explain nothing about the storage gain**: strongest ρ = −0.20
  (irrigation fraction), none survives correction (all BH p > 0.9).
- **Area is not monotone**: skill is lowest in the smallest headwaters and the
  largest basins, peaking near 10⁴ km².
- **Basin spread**: ten basins have ≥ 5 gauges; median 3-month skill ranges
  from 0.159 (Mahanadi) to −0.02 (WF_RN).

---

## 4. What we did **not** test — do not claim these

1. Independent storage (groundwater levels, GRACE). The state here is a
   re-transform of the same rain, temperature and flow as the indices.
2. Slow catchments. There are none in this sample; the criterion says where to
   try (k ≥ lead/1.39), but nobody has run it there.
3. A pooled multi-catchment model with attributes under leave-one-basin-out.
   That is the only version that could claim a forecasting gain from
   attributes; it needs saved feature tables and is not done.
4. Climate projections. Study P3 (queue reliability under SSPs) is separate
   and not part of this paper.
5. Any claim that the storage approach is wrong in general. The claim is
   scoped: it cannot work where the memory is days.

---

## 5. Where each number comes from

| Manuscript content | File |
|---|---|
| Sample counts | `paper01/tables/table01_sample.csv` |
| Storage parameters by basin | `paper01/tables/table02_storage_params.csv` |
| Descriptive skill (not used for claims) | `paper01/tables/table03_bss.csv` |
| Confirmatory table | `paper01/tables/table04_confirmatory.csv` |
| USA transfer check | `paper01/tables/table05_usa_transfer.csv` |
| Post-hoc k-class cut (appendix) | `paper01/tables/table06_kclass.csv` |
| Equivalence | `paper01/tables/table07_equivalence.csv` |
| Paired benchmark | `paper01/tables/table08_bss_paired.csv` |
| Memory budget | `paper01/tables/table09_memory.csv` |
| Attribute correlations / model / basins | `paper01/output/p1_attr_cor.csv`, `p1_attr_lm.csv`, `p1_basin_attr.csv` |
| Figure sources | `paper01/figure_table_captions.md` |

Numbers typed directly into the bullet text (they match the tables): the
confirmatory medians and sign shares (§3.1), the BSS series (§3.3), the memory
values (§3.4), and the attribute correlations (§3.5). If you rerun the study,
re-read those from the tables above before submitting.

---

## 6. The figures, and what each is for

| Figure | Purpose |
|---|---|
| `fig_p1_summary_grid` | the whole argument on one page — use it as the graphical abstract |
| `fig_p1_memory_wall` | why: recession constants against the memory each lead needs |
| `fig_p1_skill_memory` | the weak gradient: skill gain against k, no group reaches usefulness |
| `fig_p1_equivalence` | the bounded null: every interval inside the harm band |
| `fig_p1_leadtime` / `Fig03_leadtime_skill` | the ceiling: skill decay by family |
| `fig_p1_basin_grid` | the decay holds basin by basin |
| `fig_p1_attr_cor` | attributes explain skill, not the gain |
| `fig_p1_attr_scatter` | per-gauge skill versus six attributes |
| `fig_p1_basin_skill` | basin ranking of skill |
| `Fig02_study_map` / `fig_p1_map` | the sample on the map |
| `Fig05_example_state` | what the state looks like for one catchment |

---

## 7. How to edit the manuscript

- Open `paper01/MANUSCRIPT_Paper01.Rmd`. Everything is **short bullets**; join
  them into prose section by section.
- Tables and figures are inserted by R code chunks. Do not type numbers into
  them; they read the CSVs in `paper01/tables/`.
- Captions are chunk options. **Do not put an underscore inside a caption** —
  LaTeX will fail. Say "table 1" rather than a file name.
- Avoid non-ASCII characters (`≤`, `–`, `—`, `é`). Use `$\le$`, `--`, `---`,
  `\'e`.
- Build: `Rscript -e "rmarkdown::render('paper01/MANUSCRIPT_Paper01.Rmd')"`.

After any data change, rebuild in this order:

```powershell
Rscript R/verify.R                    # 23/23 must pass
Rscript R/study_p1.R                  # the study (India + USA)
Rscript R/paired_analysis_p1.R        # equivalence + paired benchmark
Rscript R/attr_analysis_p1.R          # attributes (descriptive)
Rscript R/kclass_exploratory.R        # post-hoc cut
Rscript R/figures_p1_finding.R        # memory, skill, equivalence
Rscript R/figures_p1_grid.R           # the two grid plates
Rscript R/figures_p1.R                # study figures (needs the map boundary)
Rscript R/figures_paper01.R           # publication figures
Rscript R/tables_paper01.R            # tables
```

---

## 8. Plain-language glossary

- **Brier score** — average squared error of a probability forecast. Lower is
  better; 0 is perfect.
- **BSS (Brier skill score)** — improvement over a naive forecast, as a
  fraction. 1 = perfect, 0 = as good as climatology, negative = worse than
  climatology.
- **SSI-3** — the 3-month standardised streamflow index. A value of −1 means
  flow is one standard deviation below the normal for that month.
- **Recession constant k** — how many days it takes for the catchment's
  storage to fall by a factor of e (about 2.7). Small k = fast drainage.
- **ΔBrier (paired)** — the difference between two forecasts' Brier scores,
  computed on exactly the same months and gauges. Positive means the storage
  family is better.
- **Bootstrap interval** — a range that accounts for the fact that we have a
  sample of gauges, not all gauges.
- **Equivalence / TOST** — a test that asks whether a difference is small
  enough to be negligible, rather than whether it is zero.
- **Harm bound** — the largest change we decided in advance would still be
  irrelevant to an operator (0.005 Brier).

---

## 9. Status

- Verification battery: 23/23.
- Manuscript: 18 pages, compiles clean.
- Technical document: `paper01/STUDY.html`.
- Everything regenerable from the commands in §7.
- Nothing in this repository is committed since 26 November 2026; all changes
  are staged and waiting for your review.

**This chapter is closed.** The next study in the plan (P3, climate-projection
queue reliability) is separate and would use the frozen CTMC engine, which is
preserved in `R/functions/queue_engine.R` and covered by checks V1–V7 and V10.
