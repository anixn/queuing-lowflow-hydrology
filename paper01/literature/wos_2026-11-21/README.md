# P01 literature analysis

| File | Purpose |
|---|---|
| `wos_screening_2026-11-21.md` | Record-level screen of WoS S4, S5, Extra A and Extra C: 93/93 screened, zero retained |
| `citation_trace_2026-11-21.md` | Forward-citation trace of all seeds in WoS/Scopus: 76 citing records screened, two new prior-art records, zero gap-changing |
| `exports/` | Seven WoS search exports (five original plus S1/S4 refreshes) and two preserved citing-article exports |

The frozen gap sentence lives in `../../../AGENTS.md` §2. Scopus screening is recorded in `../literature_audit.md`.

Decision rule: retain a record only if it could change the four-part gap sentence; otherwise record a one-line exclusion reason. Two citing-set exports are absent and two WoS citation-count discrepancies remain unreconciled; these limitations are disclosed in the trace note.
