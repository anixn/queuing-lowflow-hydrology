"""Read-only validator for P01 bibliometric counts.

This does not recreate manual screening. It checks that the counts quoted in the
manuscript match the preserved run log, record table, citation-trace summary and
25 November refresh CSV.
"""

from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

__all__ = ["collect_counts", "validate"]


def _cells(line: str) -> list[str]:
    return [c.strip() for c in line.strip().strip("|").split("|")]


def collect_counts() -> dict[str, int]:
    protocol = (ROOT / "P01/search_protocol.md").read_text(encoding="utf-8")
    wos = 0
    scopus = 0
    for line in protocol.splitlines():
        if not line.startswith("|"):
            continue
        c = _cells(line)
        if len(c) < 7:
            continue
        date, database, string = c[0], c[1], c[2]
        try:
            hits = int(c[3])
        except ValueError:
            continue
        if date in {"20 Nov 2026", "21 Nov 2026"} and database == "WoS Core Collection":
            if string.startswith(("S", "Extra")):
                wos += hits
        if date == "21 Nov 2026" and database.startswith("Scopus"):
            if string.startswith(("S", "Extra")):
                scopus += hits

    screening = (ROOT / "analysis/P01_literature/wos_screening_2026-11-21.md").read_text(
        encoding="utf-8")
    record_section = screening.split("## 5. Record table", 1)[1].split("\n## ", 1)[0]
    record_level = sum(
        1 for line in record_section.splitlines()
        if line.startswith(("| Extra A |", "| S4 |", "| S5 |", "| Extra C |"))
    )

    trace_raw = (ROOT / "analysis/P01_literature/citation_trace_2026-11-21.md").read_text(
        encoding="utf-8")
    trace = " ".join(trace_raw.split())
    table_counts = []
    for line in trace_raw.splitlines():
        if not line.startswith("|"):
            continue
        c = _cells(line)
        if len(c) == 6 and c[4].isdigit() and not c[0].startswith(("Langbein", "Prajamwong")):
            table_counts.append(int(c[4]))
    if "Cited 11 times in Scopus" not in trace:
        raise ValueError("Missing Yang 2016 citation count")
    citing = sum(table_counts) + 11

    refresh_path = ROOT / "analysis/claim_convention_2026-11-25/wos_refresh_2026-11-25.csv"
    with refresh_path.open(newline="", encoding="utf-8") as handle:
        refresh = {r["query_id"]: int(r["current_hits_2026_11_25"])
                   for r in csv.DictReader(handle)}

    return {
        "wos_original": wos,
        "scopus_original": scopus,
        "total_original": wos + scopus,
        "wos_record_level": record_level,
        "citation_trace": citing,
        "refresh_S1": refresh["S1"],
        "refresh_ExtraA": refresh["ExtraA"],
        "refresh_S5": refresh["S5"],
        "refresh_S4": refresh["S4"],
    }


def validate() -> dict[str, int]:
    counts = collect_counts()
    expected = {
        "wos_original": 142,
        "scopus_original": 295,
        "total_original": 437,
        "wos_record_level": 93,
        "citation_trace": 76,
        "refresh_S1": 25,
        "refresh_ExtraA": 8,
        "refresh_S5": 66,
        "refresh_S4": 7,
    }
    if counts != expected:
        raise ValueError(f"Literature count mismatch: {counts} != {expected}")
    return counts


if __name__ == "__main__":
    print(validate())
