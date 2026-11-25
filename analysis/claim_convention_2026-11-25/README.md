# Claim-convention and novelty refresh — 25 November 2026

## Decision

The claim convention is **revisable**. The working point is now:

| Quantity | Working value | Status |
|---|---:|---|
| Command area | 45,000 ha | `[assumption/proxy]` Sangli district canal-irrigated area |
| One claim | 9×10⁶ m³ | `[assumption]` 20 mm over the proxy area |
| Backlog tolerance K | 20 claims | `[assumption]` 400 mm over the proxy area |
| Service cap | 3 claims/day | `[assumption]` 60 mm/day = 2.7×10⁷ m³/day |
| Severe threshold q* | 6 claims | `[assumption]` 120 mm |
| Firm-supply share | 0.5 | `[assumption]` unchanged |

This is not a gauge-4026 command-area measurement. It replaces a round 50,000 ha guess with a documented district proxy while preserving the physical depths used in the synthetic demonstrations.

## Evidence for the area proxy

| Source | Reported value | How used |
|---|---:|---|
| Sangli agriculture contingency plan, official district source | Gross irrigated area 190,000 ha; net irrigated area 174,000 ha; canals 45,000 ha | 45,000 ha working proxy; 174,000 and 190,000 ha envelope cases |
| CGWB Sangli district profile (2010–11 table) | Major irrigation benefited area 84,725 ha; actual irrigated area 82,786 ha | Context only; not substituted because it is a different year/definition |
| Yadgir district profile | Net sown area 516,088 ha; irrigated share 14% | Context for gauge 4064; not used for gauge 4026 |
| Upper Krishna Project official district page | 1,536,000 acres across five districts | Basin/project context only; too broad for a gauge-level demand proxy |

Source URLs and access dates are in `sources.csv`. PDF copies retained from official sites are in `sources/`.

## Declared sensitivity envelope

Before physical interpretation, repeat the pilot across:

- command area: 45,000 / 174,000 / 190,000 ha;
- firm-supply share: 0.3 / 0.5 / 0.7;
- delivery depth: 10 / 20 / 40 mm, with claim volume, K, q* and the service cap rescaled consistently to preserve the chosen physical tolerance and cap.

Every resulting number remains **illustrative, under the stated assumptions** until gauge-specific canal/crop records are available.

### Envelope result

`src/P01/claim_scale_envelope.py` generated 30 cases in
`data/claim_scale_envelope.csv`:

- The exact fluid ledger is invariant to command area and claim depth when the
  physical tolerance and cap are preserved. Peak backlog is 395.80, 397.00 and
  398.20 mm for firm shares 0.7, 0.5 and 0.3, respectively.
- The finite-claim CTMC gives peak backlog 397.52, 395.03 and 389.98 mm for
  10, 20 and 40 mm claims. The largest absolute ledger residual is 0.102 mm.

The convention change therefore does not alter the physical conclusion within
the declared grid. The dominant sensitivity is the firm-supply assumption, not
the arbitrary claim unit.

## WoS IP-access refresh

| Query | 21 Nov 2026 | 25 Nov 2026 | Decision |
|---|---:|---:|---|
| S1 queue + drought/low flow/storage/unmet demand | 25 | 25 | No change |
| Extra A drought + queue | 8 | 8 | No change |
| S5 unmet demand/deficit backlog + drought/irrigation/water supply | 66 | 66 | No change |
| S4 non-stationary/time-varying queue + hydrology/drought/water | 6 | 7 | One new record, dropped as wireless-network QoS, not hydrology |

New S4 record: **Markov Chain-Based Joint Queue-and-Channel-Aware QoS Assurance for Emergency Networks** (2026), DOI `10.1109/ISWCS69382.2026.11713729`. OpenAlex topics are wireless-network optimisation, traffic/congestion control and wireless communications.

Scopus was accessed through the institutional browser session, but its current search UI returned no documents even for the exact known title “Queuing Theory and Water Storage” and displayed an intermittent-service notice. No new Scopus screen is claimed. The last complete Scopus screen remains the 295-record screen of 21 November 2026.

## Novelty consequence

The frozen 21 November 2026 sentence is unchanged. The numerical claim convention is an implementation scale, not one of the four novelty elements. Changing the proxy therefore does not weaken the literature gap.

## Next action

Regenerate `P02/data/generated/rates_4026.csv` with the revised convention. Do not regenerate or quote the legacy indicator summary until the P02 unit/server/spin-up contract is corrected.
