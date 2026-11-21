---
title: "P01 — WoS record-level screen"
subtitle: "S4, S5, Extra A and Extra C"
date: "21 November 2026"
status: "complete — 93/93 records screened, 0 retained"
---

# P01 — WoS record-level screen

## 1. Purpose

Screen the four Web of Science sets whose hit counts were captured but whose
record cards would not render in the earlier session
(`../../paper1/literature_audit.md:57-63`). This was the last database screen
before the gap sentence could be frozen (`../../AGENTS.md:174-182`).

## 2. Access and method (21 November 2026)

- Institutional sign-in was **not required**. The session browser was
  IP-entitled (splash frame "Register to personalize your Web of Science
  experience", IP 14.139.122.139); the Clarivate sign-in page was reached but
  no profile was signed in, and search, export and record metadata all worked
  without a profile.
- The WoS interface changed since 20 November: the Advanced Search **Query
  Builder** textarea now accepts and requires the `TS=(...)` field tag; the
  bare Boolean string now returns "Invalid field tag". All four sets were run
  as `TS=(<bare Boolean>)` in the Query Builder.
- The earlier record-card renderer stall (`loading-cover` state) was bypassed
  entirely: each result set was exported with **Export → Excel**, record
  content "Author, Title, Source, Abstract". S5 (66 hits) exceeded the page
  size of 50, so page 1 (records 1–50) and page 2 (records 51–66) were
  exported separately; the range option "Records from 1 to 66" did not take.
- The five export files are kept for provenance in `exports/`:
  `wos_extraA_2026-11-21.xls`, `wos_s4_2026-11-21.xls`,
  `wos_s5_2026-11-21.xls`, `wos_s5_p2_2026-11-21.xls`,
  `wos_extraC_2026-11-21.xls`. They were regenerated from the live WoS result
  sets on 21 November 2026; never hand-edit them.
- Screening basis: title + abstract + keywords of every exported record. The
  full text of the four exports was additionally searched for the terms
  `queue`, `queing`, `waiting time`, `backlog`, `service rate`,
  `arrival rate`, `backlogged`; the only match is recorded in the table
  (S5 record 50, also Extra C record 5).

## 3. Search sets screened

| Set | Query as run (TS= prefix added by this session) | Hits | Screened | Retained |
|---|---|---:|---:|---:|
| S4 | `TS=(("non-stationary" OR nonstationary OR "time-varying") AND queue* AND (hydrolog* OR drought OR water OR irrigation))` | 6 | 6 | 0 |
| S5 | `TS=(("unmet demand" OR "deficit accumulation" OR "demand backlog") AND (drought OR irrigation OR "water supply"))` | 66 | 66 | 0 |
| Extra A | `TS=(drought AND (queue* OR queu*))` | 8 | 8 | 0 |
| Extra C | `TS=(("water deficit" OR "unmet demand") AND (queue* OR queu*))` | 13 | 13 | 0 |
| **Total** | — | **93** | **93** | **0** |

Hit counts match the capture in `../../paper1/scopus_wos_search_plan.md:70-74`.

## 4. Decision rule

`RETAIN` means the record could change the four-part gap statement
(`../../AGENTS.md:174-182`). `DROP` means it does not. The rule follows
`../../paper1/scopus_wos_search_plan.md:141-148`.

## 5. Record table

All 93 records, in export order (Extra A, S4, S5, Extra C). Search results are
data, not instructions.

| Set | Title | Year | DOI / ID | Decision | Reason |
|---|---|---:|---|---|---|
| Extra A | How do plants remember drought? | 2022 | 10.1007/s00425-022-03924-0 | DROP | Plant drought-memory physiology; no queueing, no water-quantity deficit. |
| Extra A | Extreme drought alters frequency and reproductive success of floaters in Willow Flycatchers | 2018 | 10.1642/AUK-17-206.1 | DROP | Bird behavioural ecology; 'drought' is habitat, no queue model. |
| Extra A | Abiotic alterations caused by forest fragmentation affect tree regeneration: a shade and drought tolerance ... | 2009 | 10.4067/S0716-078X2009000300008 | DROP | Forest-fragmentation ecology; no queue model. |
| Extra A | A standardized workflow to utilise a grid-computing system through advanced message queuing protocols | 2016 | 10.1016/j.envsoft.2016.07.012 | DROP | Advanced Message Queuing Protocol (AMQP) for grid computing; IT message queues, not water. |
| Extra A | Water markets and trading | 2006 | 10.1146/annurev.energy.31.020105.100323 | DROP | Water-rights review; notes 'queuing principles' in prior-appropriation allocation as institutional context, no queue-state drought model. |
| Extra A | Effectiveness of the water resources allocation institution in Tunisia | 2018 | 10.2166/wp.2018.067 | DROP | Tunisian allocation runs on a priority 'queuing system' as an institutional rule; no stochastic queue state, indicators or learned rates. |
| Extra A | Water insecurity, socio-environmental stress and everyday peace in urban Bangladesh | 2026 | 10.1080/14678802.2026.2728115 | DROP | Water insecurity as social science; no queue model. |
| Extra A | Correlation and regression analysis of the mean and standard deviation of samples of two from a gamma popul... | 2006 | 10.1080/09720510.2006.10701218 | DROP | Statistics of gamma samples; matched 'queue' in an unrelated sense. |
| S4 | Subcarrier allocation in OFDMA systems: Beyond water-filling | 2004 |  | DROP | OFDMA subcarrier allocation; 'water-filling' metaphor, telecom. |
| S4 | Water-Filling-Based Scheduling for Weighted Binary Freshness in Cache Update Systems | 2024 | 10.1109/JIOT.2023.3322360 | DROP | Cache-update scheduling via water-filling; telecom. |
| S4 | Approximate waiting times for queuing systems with variable cross-correlated arrival rates | 2024 | 10.1016/j.physa.2024.130152 | DROP | Bogachev et al. 2024: waiting times with variable cross-correlated arrival rates — OR literature already recorded for P3's benchmark, not drought prior art. |
| S4 | Autonomous Ocean Observation: Reinforcement Learning for UAV-VLC Underwater Communication Optimization | 2026 | 10.1109/ACCESS.2026.3698010 | DROP | UAV underwater optical communication; telecom. |
| S4 | Online incremental learning approach of heat pump and chiller models based on the dynamic random forests in... | 2025 | 10.1016/j.energy.2025.135840 | DROP | HVAC heat-pump/chiller ML models; 'queue' incidental. |
| S4 | Drift-Plus-Penalty-Based Joint Optimization of Computational Resource Scheduling, Power Control, and UAV Fl... | 2026 | 10.3390/electronics15153437 | DROP | UAV flight/power scheduling; telecom-OR. |
| S5 | Assessment of water supply and demand in Gilgel Gibe watershed, southwest Ethiopia | 2022 | 10.1007/s40899-022-00684-3 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | The impact of water conservation strategies on unmet demand in Addis Ababa, Ethiopia | 2024 | 10.2166/wpt.2024.288 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Urban water system vulnerability under climate change, demand growth, and institutional friction | 2027 | 10.1016/j.jhydrol.2026.136789 | DROP | Urban water vulnerability incl. institutional friction; abstract scanned, no queueing model. |
| S5 | Water resource allocation in the Abaya Chamo sub-basin, Ethiopia: a scenario-based SWAT-WEAP modelling appr... | 2026 | 10.1080/02626667.2026.2623982 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of Present and Future Water Security under Anthropogenic and Climate Changes Using WEAP Model in... | 2023 | 10.3390/w15071439 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | The effectiveness of urban water conservation and desalination for water resources management in Jeddah city | 2020 | 10.5004/dwt.2020.26450 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Integrated Water-Power System Resilience Analysis in a Southeastern Idaho Irrigation District: Minidoka Cas... | 2021 | 10.3390/su131910906 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | A hybrid ARO-based multi-objective approach to address user concern frequency in water supply systems | 2025 | 10.1007/s00477-025-03029-6 | DROP | Multi-objective supply-system design; abstract scanned, no queueing model. |
| S5 | Evaluation of desalination and groundwater supply sources for future water resources management in Riyadh city | 2020 | 10.5004/dwt.2020.24892 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | WEAP model to assess the water balance and future scenarios in the Chennai Basin, India | 2023 | 10.2166/aqua.2023.144 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Effects of global change on streamflow, water demand and supply: a case study from the Pyrenees | 2026 | 10.1007/s40899-026-01370-4 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | A Poly-Shock Sentinel-Node Framework for Scenario-Based Assessment of Water-Scarcity Risk in the Transbound... | 2026 | 10.3390/hydrology13100261 | DROP | Scenario framework for water-scarcity risk; abstract scanned, no queueing model. |
| S5 | Analysis of Water-Energy-Food Nexus Scheme Using Water Evaluation and Planning (WEAP) Model (Case Study: Do... | 2026 | 10.1177/11786221261448338 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Impacts of climate change on future water availability for hydropower and public water supply in Wales, UK | 2021 | 10.1016/j.ejrh.2021.100866 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Citizen science-based WEAP modeling of water use impact on environmental flow in urbanized Big Akaki catchm... | 2025 | 10.1016/j.ejrh.2025.102435 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Water availability as a limiting factor and optimization of hydropower generation as an adaptation strategy... | 2011 |  | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Melamchi water supply project: potential to replenish Kathmandu's groundwater status for dry season access | 2019 | 10.2166/wp.2019.080 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of long-term water demand for the Mgeni system using Water Evaluation and Planning (WEAP) model ... | 2023 | 10.17159/wsa/2023.v49.i4.4019 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Integrating photovoltaic water pumping within the water-energy Nexus: A systematic review and pvsyst-based ... | 2026 | 10.1016/j.nexus.2026.100879 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of Water Supply and Demand in a Watershed with Climate Change Impacts on Potential Adaptation St... | 2026 | 10.1007/s40003-025-00934-8 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Water demand reduction to help meet SDG 6: learning from major Australian cities | 2020 | 10.1080/07900627.2019.1638229 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Simulating water quality of the N'Djili River using the WEAP model in the Democratic Republic of Congo | 2025 | 10.1007/s43621-025-01281-y | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Water Resources Allocation Systems under Irrigation Expansion and Climate Change Scenario in Awash River Ba... | 2019 | 10.3390/w11101966 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | EVALUATION OF THE IMPACT OF PLANTING STRUCTURE ON WATER RESOURCES | 2011 | 10.30638/eemj.2011.126 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Scenario-driven Decision Support System for assessing water balance to support agricultural and ecosystem s... | 2026 | 10.1016/j.jhydrol.2025.134679 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Evaluating water allocation scenarios to inform water resource development decisions in the Great Ruaha Riv... | 2026 | 10.1080/15715124.2026.2629607 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Multi-Source Joint Water Allocation and Route Interconnection Under Low-Flow Conditions: An IMWA-IRRS Frame... | 2026 | 10.3390/su18031541 | DROP | Joint allocation/route interconnection under low flow; optimisation, no queue-state deficit. |
| S5 | Climate change and population growth impacts on surface water supply and demand of Addis Ababa, Ethiopia | 2017 | 10.1016/j.crm.2017.08.004 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Paleoclimate Scenarios to Inform Decision Making in Water Resource Management: Example from Southern Califo... | 2014 | 10.1061/(ASCE)WR.1943-5452.0000403 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of future urban water demand and supply under socioeconomic scenarios: a case of Assosa town | 2022 | 10.2166/ws.2022.329 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Strategic Decision-Making in Sustainable Water Management Using Demand Analysis and the Water Evaluation an... | 2023 | 10.3390/su152216083 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Evaluating the effect of climate change and fast population growth on water supply and demand in Jimma town... | 2025 | 10.2166/wcc.2025.751 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | WEAP-MODFLOW Dynamic Modeling Approach to Evaluate Surface Water and Groundwater Supply Sources of Addis Ab... | 2018 | 10.7343/as-2018-334 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Enhancing Efficiency of the Minipe Left Bank Canal Irrigation System: A Strategic Approach | 2024 | 10.4038/engineer.v57i3.7652 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | An Integrated Water Resources Management Considering Agricultural Demands and the Assessment of Different S... | 2019 | 10.1134/S0097807819020143 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Urban stormwater harvesting for domestic water supply: a water evaluation and planning approach | 2021 | 10.2166/wst.2021.250 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of Future Water Security under Climate Change: Practical Water Allocation Scenarios in a Drought... | 2024 | 10.3390/w16202933 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Risk-based water resources system planning: application of the decision scaling method under climate change | 2025 | 10.2166/wcc.2025.095 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | WEAP modeling of surface water resources allocation in Didessa Sub-Basin, West Ethiopia | 2016 | 10.1007/s40899-015-0041-4 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Analyzing Water Demand and Supply Under Socioeconomic and Climate Change Scenarios Using WEAP: a Case Study... | 2026 | 10.1007/s41101-026-00549-2 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Water management in Egypt for facing the future challenges | 2016 | 10.1016/j.jare.2016.02.005 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Deep hybridnet for drought prediction based on large-scale climate indices and local meteorological conditions | 2025 | 10.1007/s00477-024-02826-9 | DROP | Deep-learning drought prediction from climate indices; no queue or deficit state. |
| S5 | Conflict Resolution of Parambikulam-Aliyar Project (PAP), India Using the Graph Model for Conflict Resolution | 2025 | 10.3390/w17050690 | DROP | Graph-model conflict resolution for water allocation; no queueing. |
| S5 | Evaluation of municipal water supply system options using water evaluation and planning system (WEAP): Jedd... | 2020 | 10.5004/dwt.2020.25538 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessing Water Demands and Allocation Strategies Using the Water Evaluation and Planning System-A Case Stu... | 2024 | 10.3390/w16192832 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Climate-driven compounding effects and historical trends in renewable electricity droughts in Europe | 2025 | 10.1016/j.apenergy.2025.126623 | DROP | Renewable-electricity droughts; not water demand. |
| S5 | Leveraging Climate Regulation by Ecosystems for Agriculture to Promote Ecosystem Stewardship | 2017 | 10.1177/1940082917720672 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | URBAN STORMWATER AS A WATER RESOURCE OPPORTUNITY, A NEXUS APPROACH TO DECISION MAKING | 2015 |  | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Allocation of surface and subsurface water resources to competing uses under climate changing conditions: a... | 2018 | 10.2166/ws.2017.166 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Expansion of logistics capability in emergency care systems with growing demand | 2014 | 10.1016/j.sbspro.2014.12.112 | DROP | Healthcare emergency-care queueing (capacity expansion); 'unmet demand' is patients, not water. |
| S5 | Understanding the trade-offs between climate change-induced aridity and agricultural water demand in the So... | 2024 | 10.3389/frwa.2024.1270078 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Reviving the Ganges Water Machine: Accelerating surface water and groundwater interactions in the Ramganga ... | 2016 | 10.1016/j.jhydrol.2016.06.025 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of future water demand and supply using WEAP model in Dhasan River Basin, Madhya Pradesh, India | 2023 | 10.1007/s11356-022-24050-0 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of the Water Distribution Networks in the Kingdom of Saudi Arabia: A Mathematical Model | 2023 | 10.3390/axioms12111055 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Water Scenarios Modelling for Renewable Energy Development in Southern Morocco | 2021 | 10.13044/j.sdewes.d8.0335 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | One-way coupling of an integrated assessment model and a water resources model: evaluation and implications... | 2013 | 10.5194/hess-17-4555-2013 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Plant growth promoting microorganisms (PGPM) as an eco-friendly option to mitigate water deficit in soybean... | 2022 | 10.1016/j.plaphy.2022.09.013 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of future urbanwaterresources supply and demand for Jeddah City based on the WEAP model | 2019 | 10.1007/s12517-019-4594-7 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessing the impacts of climate and socioeconomic changes on water availability and demand using the WEAP ... | 2026 | 10.1016/j.ejrh.2026.103388 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Impact of Offshore Wind Energy Penetration on the Resilience of an Import-Dependent Power Grid | 2026 | 10.1007/978-981-95-1826-5_45 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | The Role of Vadose Zone Storage Deficits in Modulating Groundwater Recharge and Streamflow in Seasonally Dr... | 2025 | 10.1029/2024WR038788 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | The Impacts of Water Demand and Its Implications for Future Surface Water Resource Management: The Case of ... | 2019 | 10.3390/w11061280 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Water productivity of Paulownia tomentosa x fortunei (Shan Tong) in a plantation at Lake Issyk-Kul, Kyrgyzs... | 2021 | 10.1007/s00468-021-02141-8 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Optimal Management of Water Resources among the Various Users of Lower Kanakarayanaru River Basin, Northern... | 2025 | 10.4038/engineer.v58i1.7680 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Assessment of impacts of climate change on surface water availability using coupled SWAT and WEAP models: c... | 2018 | 10.5194/piahs-378-23-2018 | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| S5 | Projecting water demands under various socioeconomic scenarios in the upper Jhelum basin, Indus using WEAP ... | 2026 | 10.1007/s13201-026-02969-w | DROP | WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. |
| Extra C | Zero-inventory conditions for a two-part-type make-to-stock production system | 2003 | 10.1023/A:1022846711722 | DROP | Make-to-stock production-inventory backorders; 'unmet demand' is industrial orders, not water. |
| Extra C | On the Control Policy of a Queuing-Inventory System with Variable Inventory Replenishment Speed | 2024 | 10.3390/math12020194 | DROP | Queuing-inventory production control; not water. |
| Extra C | Behaviour-Driven Optimization of Multi-Type Fast-Charging Configuration in Highway Service Areas Under Boun... | 2026 | 10.1049/itr2.70253 | DROP | Highway fast-charging configuration; transport. |
| Extra C | Overload Control for μs-Scale RPCs with Breakwater | 2020 |  | DROP | Datacenter RPC overload control; IT. |
| Extra C | Expansion of logistics capability in emergency care systems with growing demand | 2014 | 10.1016/j.sbspro.2014.12.112 | DROP | Healthcare logistics capacity expansion with queueing; not water/drought. |
| Extra C | Equity-oriented design of vaccine supply chains under pandemic conditions through bi-level fuzzy goal progr... | 2026 | 10.1007/s10479-026-07265-z | DROP | Vaccine supply-chain design; healthcare. |
| Extra C | The role of EV fast charging in the urban context: An agent-based model approach | 2024 | 10.1016/j.etran.2024.100369 | DROP | EV charging infrastructure agent-based model; transport. |
| Extra C | Optimizing Cardiac Inpatient Flow and Resource Allocation in Low-Resource Settings Using Queuing Theory: In... | 2026 | 10.1002/puh2.70304 | DROP | M/M/c/c and M/M/c/K queueing for hospital inpatient flow; healthcare. |
| Extra C | The Efficiency of Increasing the Capacity of Physiotherapy Screening Clinics or Traditional Medical Service... | 2016 | 10.1007/s40258-016-0246-1 | DROP | Physiotherapy screening clinics for unmet demand; healthcare. |
| Extra C | Preference-Conditioned MADDPG for Risk-Aware Multi-Agent Siting of Urban EV Charging Stations Under Coupled... | 2026 | 10.3390/math14091464 | DROP | EV charging-station siting with queueing pressure; transport. |
| Extra C | Optimization Model of Taxi Fleet Size Based on GPS Tracking Data | 2019 | 10.3390/su11030731 | DROP | Taxi fleet size optimisation; transport. |
| Extra C | A stochastic analysis of the dynamic space utilization in warehouses | 2025 | 10.1016/j.apm.2024.115782 | DROP | Warehouse space-utilisation stochastic model; logistics. |
| Extra C | Optimizing fleet size for on-demand taxi and ridehailing services: application to the case of Madrid | 2026 | 10.1016/j.tranpol.2025.103868 | DROP | Taxi/ridehailing fleet size; transport. |

## 6. Result

**Zero records retained.** The four WoS sets echo the Scopus result: telecom,
transport, healthcare and production-inventory queueing, plus WEAP-type
water-supply scenario studies in which "unmet demand" is a modelled deficit,
not a queue state. Two institutional echoes worth one sentence each in P1's
prior-art discussion, not gap-changing:

1. Water-rights allocation is described as operating "according to a queuing
   system" of priorities — Extra A records 5 (annual-review water-markets
   paper) and 6 (Tunisia). This is an institutional priority rule, not a
   stochastic queue state with indicators.
2. Healthcare emergency-care capacity queueing (S5 record 50 / Extra C
   record 5) is the same service-capacity machinery we propose, applied to
   patients — supporting the maturity of queue methods, not drought prior art.

## 7. Completion test

Record-level screen: **complete** — all 93 records have a decision and reason;
no record was retained, so the full-text screen of retained records is empty
by definition. The dated gap sentence is frozen in
`../../field/README.md` §8 and `../../paper1/literature_audit.md`. Remaining
Phase A item (not blocking the frozen sentence): forward-citation tracing
inside WoS/Scopus for the seed list, where the OpenAlex trace remains a
substitute.
