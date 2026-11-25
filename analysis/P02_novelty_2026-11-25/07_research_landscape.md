# 07 — Research landscape

## Temporal landscape

- **1950s–1998:** queueing and stochastic storage are unified mathematically (Moran, Gani, Langbein, Prabhu). Hydrology explicitly publishes the storage–queue connection in 1958.
- **1990s–2010s:** hydrological applications cluster around soil-water residence time, residential demand, groundwater management, runoff–runon, irrigation capacity and canal allocation.
- **2010s–2020s:** time-varying and correlated queueing matures in operations research (Tan, Whitt, Bogachev). ML-based queue parameter/state estimation is also established (Asanjarani et al. 2021).
- **2018:** Zhao et al. integrate hydrology and water management for non-stationary supply–demand reservoir reliability.
- **2026:** Acosta et al. propose a broad coupled human–water drought state-space framework with unmet accessible demand, probabilistic risk and resilience. It is a preprint and calls real-world validation and observational assimilation future work.

## Methodological landscape

- Exact queue and storage mathematics are strong.
- Hydrological demand/service parameterisation is comparatively underdeveloped.
- Most queue–drought work in this project remains synthetic or illustrative.
- Independent storage/impact observations are not yet joined to the backlog state in a validated inference model.
- Stock, flux and exposure quantities are often conflated in applied reporting; the current Python engine required a blocked-demand and unit correction.

## Data landscape

- CAMELS-IND, IMD and catchment attributes are available locally.
- Crop/canal-command records, regulation metadata and independent storage/delivery observations are incomplete.
- Gauge 4026 has unresolved zero-flow semantics.
- CMIP6 extraction exists but is uncorrected and cannot support published future numbers.

## Evidence landscape

| Claim | Evidence status |
|---|---|
| Queueing is old in hydrology | Established |
| Time-varying/correlated queueing is old | Established |
| ML-for-queues is mature | Established |
| Coupled drought state-space modelling exists | Established by Acosta et al. (2026 preprint) |
| Non-stationary supply–demand reservoir modelling exists | Established by Zhao et al. (2018) |
| Full four-part queue-specific drought combination | Not identified in the documented searches |
| Queue indicators add real-world information | Untested |
| Demand and supply are identifiable from available observations | Untested |
| Time-varying recovery probabilities improve decisions | Untested |

## Strategic implication

The defensible contribution is not a broad new theory of drought. It is a queue-specific, conservation-constrained and identification-aware deficit-state framework, validated against exact references and pre-specified drought tests. The most valuable near-term work is to make the accounting and identification contract explicit before adding model complexity.
