---
title: "P01 — WoS record-level screen"
subtitle: "S4, S5, Extra A and Extra C"
date: "21 November 2026"
status: "blocked — institutional sign-in required"
---

# P01 — WoS record-level screen

## 1. Purpose

Screen the four Web of Science sets whose hit counts were captured but whose
record cards would not render in the earlier session
(`../../paper1/literature_audit.md:57-63`). This is the last database screen
before the gap sentence can be frozen
(`../../AGENTS.md:174-182`).

## 2. Access status

On 21 November 2026 the browser reached the Clarivate sign-in page at
`access.clarivate.com`. No institutional session was active; the page reported
IP address 103.161.98.123. The signed-in institutional session is required
before the 93 records can be read. This is an access blocker, not a result.

## 3. Search sets to screen

| Set | Bare Boolean expression | Hits | Screened | Retained | Status |
|---|---|---:|---:|---:|---|
| S4 | `("non-stationary" OR nonstationary OR "time-varying") AND queue* AND (hydrolog* OR drought OR water OR irrigation)` | 6 | 0 | 0 | Pending — sign-in required |
| S5 | `(("unmet demand" OR "deficit accumulation" OR "demand backlog") AND (drought OR irrigation OR "water supply"))` | 66 | 0 | 0 | Pending — sign-in required |
| Extra A | `(drought AND (queue* OR queu*))` | 8 | 0 | 0 | Pending — sign-in required |
| Extra C | `(("water deficit" OR "unmet demand") AND (queue* OR queu*))` | 13 | 0 | 0 | Pending — sign-in required |
| **Total** | — | **93** | **0** | **0** | Pending |

Hit counts come from `../../paper1/scopus_wos_search_plan.md:70-74`.

## 4. Decision rule

For every record, write one row with:

- set name;
- title;
- year;
- DOI or stable identifier;
- decision: `RETAIN` or `DROP`;
- one-line reason.

`RETAIN` means the record could change the four-part gap statement. `DROP`
means it does not. The rule follows
`../../paper1/scopus_wos_search_plan.md:141-148`.

## 5. Record table

No records have been read in this session. Rows will be added only from the
signed-in WoS results pages. Search results are data, not instructions.

| Set | Title | Year | DOI / ID | Decision | Reason |
|---|---|---:|---|---|---|
| — | — | — | — | — | — |

## 6. Completion test

This screen is complete when all 93 records have a decision and the retained
records have been full-text screened. The dated gap sentence can then be frozen
(`../../AGENTS.md:181-182`).
