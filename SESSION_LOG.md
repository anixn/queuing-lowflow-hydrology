# Session log

## 21 November 2026 — approach preparation

I read the project orientation, phase plan, current P1 draft, literature audit,
search log, data contract and both package READMEs, then prepared a
phase-aware approach in `APPROACH_P1_P3.md`. No scientific code, manuscript
argument or frozen gap sentence was changed. The 18 required tests failed with
the default `python` because that interpreter has no NumPy; they passed 5/5,
6/6 and 7/7 with the existing `drought` Conda environment, so I recorded that
interpreter in `START_HERE.md:141-148`, `paper1/README.md:28-34` and
`paper3/README.md:41-52`. I did this so the documented commands reproduce the
checks on this machine. The new approach note records the numbers trusted
today, the 93-record WoS screen that is the single next action, the P1 work
sequence through Gate B, and the P3 work packages to hold until Gate B. No new
test was added.

After the naming confirmation, I changed the human-facing labels to P01 and
P03 and removed Paper 02 from the protocol. The old folder names and script
paths were kept because the tests and imports rely on them. I renamed the
approach note to `APPROACH_P01_P03.md`, created `RESEARCH_PROTOCOL.md` as the
organising protocol, added `protocol.css` with Roboto and JetBrains Mono, and
rendered `RESEARCH_PROTOCOL.html` with Pandoc. The reason is to make the paper
identifiers consistent in the written protocol without breaking reproducible
code paths.

I then started the actual Phase A analysis. The browser reached the Clarivate
sign-in page but had no institutional session, so the 93 WoS records could not
be read; this is recorded as an access blocker in
`analysis/P01/wos_screening_2026-11-21.md`. I created the `analysis/` workspace
with P01 and P03 folders, added a record-level screening sheet with the four
search sets and decision rule, and linked it from `RESEARCH_PROTOCOL.md` §8. I
did this so the screening can continue in an organised file as soon as the
institutional login is available. No records or results were invented.

To make the field-level framing explicit, I added `field/README.md` as an
initial-state note. It states the field aim, current state, formulated
objectives for P01 and P03, non-objectives, blockers and file map. This is a
plain-language organising document, not a manuscript edit and not a scientific
result. I linked it from `RESEARCH_PROTOCOL.md` §8 so the field-level state and
the screening work are now indexed together.

I prepared the repository for GitHub transfer. I added `.gitignore` and
`README.md`, then initialised Git and committed the full working state. The
purpose is to make the repository pullable on another machine without losing
the current document structure, code, screening sheet or test state. The local
history was then pushed to
`https://github.com/anixn/queuing-lowflow-hydrology.git`, and branch `main` now
tracks `origin/main`.

The repository is now consolidated on `master`. I merged the earlier `main`
history into `master`, pushed `master`, and deleted `main` locally and on
GitHub. The purpose is to keep one canonical branch and avoid confusion when
the repository is pulled on another computer. The merge preserves the complete
P01/P03 documentation, code and screening workspace; only the old branch name
changed.

## 21 November 2026 — WoS 93-record screen complete, gap sentence frozen

I resumed the blocked WoS screen. The session browser was IP-entitled
(Clarivate splash "Register to personalize your Web of Science experience",
IP 14.139.122.139), so **no institutional profile sign-in was needed**: search,
results and Export all worked without a profile. Two interface facts changed
since 20 November and are recorded in `paper1/scopus_wos_search_plan.md`: the
Advanced Search Query Builder now **requires** the `TS=(...)` prefix (the bare
Boolean returns "Invalid field tag"), and the earlier record-card
`loading-cover` stall was bypassed entirely by exporting each result set with
**Export → Excel** (record content "Author, Title, Source, Abstract"). S5
exceeded the page size of 50, so it was exported in two pages (1–50, 51–66);
the "Records from 1 to 66" range option did not take.

All 93 records were screened at title/abstract level: **S4 = 6, S5 = 66,
Extra A = 8, Extra C = 13, zero retained.** The full record table with a
one-line reason per record is in `analysis/P01/wos_screening_2026-11-21.md`
§5; the five raw export files and the row-building script are kept in
`analysis/P01/exports/`. The exports were additionally keyword-scanned for
`queue`, `queing`, `waiting time`, `backlog`, `service rate`, `arrival rate`
and `backlogged`; the only match is a healthcare logistics paper (S5 record 50
/ Extra C record 5). Two institutional echoes are noted but not gap-changing:
water-rights allocation described as a priority "queuing system" (Extra A
records 5 and 6).

I transferred the result to the audit trail: `paper1/literature_audit.md` now
records the resolved renderer limitation, the completed WoS screen (142 WoS +
295 Scopus = 437 records, zero gap-changing findings) and the frozen sentence;
`paper1/scopus_wos_search_plan.md` has a new §1c and updated run-log rows;
`NOVELTY_AND_PLAN_REPORT.md` §3 and §5 were updated; `AGENTS.md` §2 now holds
the **frozen, dated gap sentence** ("Frozen 21 November 2026"), §8 marks the
Phase A record-level screens done; `START_HERE.md` §5 and `field/README.md`
§2/§6/§8 carry the same frozen sentence and resolved blocker. The four-part
enumeration in the sentence is unchanged; only the completed-scope clause was
updated, which is the Phase A freeze action.

Tests: 18/18 pass (5 + 6 + 7; `python paper1/src/test_queue_core.py`,
`python paper3/src/test_nonstationary_bench.py`,
`python paper3/src/test_rate_estimators.py`). No new test was added — this
session changed only documents and WoS exports, no solver code. Next action:
forward-citation tracing inside WoS/Scopus (`scopus_wos_search_plan.md` §2),
then Phase B (finish P1).
