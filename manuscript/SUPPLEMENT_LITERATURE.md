# Literature review: the queueing lineage in hydrology and the drought-deficit question

## 1. The index tradition and its blind spot

Drought is usually introduced as a hazard of deficit: precipitation below a climatological norm, soil moisture below an expectation, streamflow below an exceedance threshold. The index tradition — the Standardized Precipitation Index (McKee et al., 1993), the Standardized Precipitation Evapotranspiration Index (Vicente-Serrano et al., 2010) and their hydrological counterparts — made drought comparable across places and across time. It also fixed the intellectual frame. A drought became an anomaly to be measured, and drought propagation became a question about lags and correlations between anomaly series (van Loon, 2015).

The frame has a blind spot, and it concerns the object of study rather than the method. Water scarcity becomes damaging not when an anomaly is first detected but when demand that cannot be met accumulates faster than supply can clear it. Two catchments with the same rainfall deficit can diverge sharply: one holds storage and delivers reliably, the other does not. The difference between them is not an anomaly magnitude. It is a service-capacity constraint and a trajectory of accumulated unmet demand. A standardised index does not represent that accumulation, does not return a recovery time as a model output, and does not separate shortage caused by unusually high demand pressure from shortage caused by degraded supply. It can tell an analyst that a drought is in progress, but not how long the system will need to recover or how much demand will be abandoned while it does.

This is a statement about what the indices were designed to do, not a criticism of how they were built. Comparability across climates required a climatological reference, and the reference is precisely what removes the mechanism. The mechanism needs its own state variable: unmet demand, together with the capacity that serves it. Demand-versus-supply attribution has precedent in structural decomposition of the forces behind urban water scarcity (Sun et al., 2019), but that work decomposes observed scarcity rather than carrying a deficit state forward in time. The missing object is therefore dynamical, and it is the object queueing theory is built to describe.

## 2. The queueing lineage in hydrology

Queueing theory is the mathematics of arrival streams, finite service capacity, congestion and waiting. Its core objects — queue length, busy period, waiting time, utilisation, loss probability — are close to the objects a drought manager is implicitly asking about when asking how severe a shortage is, when it will end, and who will be cut off. The connection is not a metaphor imported into hydrology from operations research late in the day. Langbein (1958) published "Queuing Theory and Water Storage" in the *Journal of the Hydraulics Division*, setting out the queue–storage analogy inside a hydraulics journal, with discussion and closure following in 1959.

In parallel, probability theory built dams as random storage systems. Moran (1954) established the probability theory of dams and storage systems, Gani (1957, 1969) developed it further, and Prabhu (1998) unified queues, insurance risk and dams within a single theory of stochastic storage processes. Klemeš (1987) reviewed a century of applied storage reservoir theory, in which reliability and first passage are the working quantities. These were never separate disciplines so much as two applications of one recursion.

That identity determines how any later argument has to be framed. The waiting-time recursion of the GI/G/1 queue and Moran's dam recursion are, up to notation and reflection, the same equation:

$$W_{n+1}=\max(0,\;W_n+B_n-A_n), \qquad X_{n+1}=\min\big(K_s,\;\max(0,\;X_n+I_n-R_n)\big),$$

where $B_n$ is the work brought by the $n$th claim, $A_n$ the service opportunity before the next claim, $I_n$ inflow and $R_n$ release. Everything that makes drought hard — episodic supply, seasonal demand, finite storage, abandonment — is a term that queueing theory already knows how to place inside this recursion. First-passage and busy-period quantities, read as recovery time and deficit duration, likewise have a long history (Moran, 1954; Prabhu, 1998).

The lineage therefore has to be reclaimed rather than discovered. Storage theory was queueing theory before the two drifted apart, and hydrology said so explicitly in 1958. What remains unshown is whether the storage-side quantities can be turned into data-driven drought diagnostics: whether a deficit state can be estimated from observations, whether its recovery statistics are calibrated, and whether they add information to a standardised index. That is a narrower question than the historical one.

## 3. Hydrological queue applications

Between the 1958 analogy and the present there is a real but thin body of application, worth enumerating rather than summarising.

**Soil water as a queue.** Gamble, Eckstein and Edwards (1990a, 1990b) applied queueing disciplines to water-budget data to evaluate soil-water residence time, in paired theoretical and monolith-lysimeter papers in the *Journal of Hydrology*. Storage-as-queue therefore has direct hydrological precedent at the pedon scale.

**Demand as arrivals.** Buchberger and Schade (1997) modelled residential water demands as a Poisson pulse queueing process. This is the closest precedent for treating demand as an arrival stream, although the setting is urban demand without a supply constraint or a drought state.

**Runoff and overland flow.** Harel and Mouche (2013) recast the one-dimensional steady runoff–runon equation as a single-server waiting time, with heterogeneity, connectivity and scale entering through service; Harel and Mouche (2014) extended the connectivity analysis. Mouche and Harel (2016) represented overland flow as a B/D/1 queue with arbitrary service time, and Jones, Lane and Sheridan (2016) extended the queue-based stochastic runoff–runon theory to a finite hillslope, with a further mathematical treatment for rooted trees (Jones, 2019). This runoff line is the most mathematically active branch, and it concerns runoff generation, not deficit accumulation.

**Irrigation and allocation.** Prajamwong, Merkley and Allen (1997) used a queuing system inside a decision-support model to allocate available water to command areas and fields, with root-zone water deficit entering the yield response. Palková and Hennyeyová (2012), Palková and Rodný (2010, 2011) and Palková, Rodný and Kiedrowicz (2012) developed queueing models for irrigation-system capacity, process control and design. Yang, Guo, Li and Li (2016) formulated conjunctive surface-water and groundwater allocation in an irrigation district as a queueing model, and Yang, Li and Huo (2019) built queueing-based decision support for canal management under groundwater-utilisation uncertainty. The irrigation line is sustained across three decades and is not a one-off.

**Groundwater and supply reliability.** Batabyal (1996) took a queueing-theoretic approach to groundwater management, and Al-Sifao et al. (2026) applied an M/M/c//N/Y finite-source multi-server queue with spares to well-field pump reliability. Groundwater queueing is established at both levels.

**High flows and controlled release.** Lefebvre (2019) analysed high river flows on the Delaware River as an M/M/1/c continuous-time Markov chain — the same machinery a low-flow study would use, applied at the opposite end of the flow distribution. Gordienko and Ruiz de Chávez (2012) studied a controlled GI/D/1/∞ queue and its analogue in water release from a simple dam, and Unami et al. (2015) applied stochastic modelling and control to rainwater harvesting for irrigation during dry spells.

Three observations follow. The niche is thin, not empty: storage, residence time, runoff, irrigation capacity, groundwater reliability, high flows and small-system control are all occupied. What these studies share is either a stationary framing, an operational-allocation purpose, or both; none reports a drought-specific backlog state with indicators, recovery statistics and validation against held-out events. And keyword search alone undercounts the niche: Mouche and Harel (2016), Yang et al. (2016) and Jones et al. (2016) were located through citation tracing rather than title or abstract queries, which is a caution for any argument built on search strings.

## 4. Non-stationary and time-varying queues

Time-varying queueing is mature, and its maturity constrains what can be claimed. Early work addressed non-stationary landing congestion for aircraft (Galliher & Wheeler, 1958); closure approximations followed for the non-stationary M/M/s queue (Rothkopf & Oren, 1979); peak congestion under slowly varying arrival rates was characterised by Massey and Whitt (1997); finite-capacity queues with time-dependent arrivals were analysed by Tan, Knessl and Yang (2013); and waiting times under variable, long-range-correlated arrival rates were treated by Bogachev et al. (2023, 2024). Whitt (2018) provides a modern synthesis of the field.

The hydrological argument must therefore import this machinery rather than present it. The substance of the point survives the borrowing. When arrival and service rates vary, the stationary formulae no longer apply, and the instantaneous load ratio is at best a local warning signal. Backlog depends on the integrated history of the difference between arrivals and service, so the same nominal load can correspond to very different backlogs on the rising and falling limbs of a seasonal cycle. Non-stationary queues have hysteresis, and averaging a seasonal signal is not a neutral simplification.

The same logic applies to the arrival process itself. Correlated and non-Poisson arrivals are studied in their own right (Bogachev et al., 2023, 2024), so a Poisson assumption is a choice to be tested and reported, not a default inherited from textbook formulas.

## 5. Coupled storage-demand and state-space drought work

Representing a human–water system as a coupled state space is not confined to queueing. Acosta et al. (2026), in a preprint that has not been peer reviewed, propose a coupled state-space framework with storage, accessibility, demand, transfer and loss, define drought intensity as unmet accessible demand, and formulate probabilistic risk together with a recovery timescale. They leave real-world validation and observational assimilation explicitly as future work. Their framework contains no queue-state backlog model, no non-stationary rates learned from hydroclimatic covariates, and no exact queue benchmarks.

On the system-modelling side, Zhao et al. (2018) integrate hydrological processes with water management to evaluate the drought resilience of a surface water supply system, tracking reservoir storage and supply reliability under non-stationary supply and demand. That is the closest system-modelling precedent, but it is deterministic system modelling rather than a finite-state stochastic deficit queue, and it offers no exact queue validation.

The consequence for framing is direct. Both the broad coupled state-space picture of drought and non-stationary supply–demand resilience modelling are established. Presenting either as a contribution would be wrong on the record. What remains open is the specifically queue-shaped part: backlog dynamics as a state, the identification of that state from available observations, exact validation of the queue mathematics, and drought tests specified in advance.

## 6. Machine learning for queues (a mature field)

Parameter and state estimation in queues has a survey literature of its own (Asanjarani et al., 2021). Learning-based methods are equally established: deep generative models for queuing systems (Ojeda et al., 2021), deep reinforcement learning for queueing network control (Dai & Gluzman, 2022), deep-learning approximations for G(t)/GI/1 queues (Sherzer et al., 2024), online learning and optimisation with unknown arrival rate and service distribution (Chen et al., 2026), deep learning for the transient behaviour of non-Markovian non-stationary systems (Garyfallos, 2026), and contextual queueing bandits (Bae & Lee, 2026).

Machine learning for queues, learned arrival rates and non-stationary queueing are therefore all occupied territory. A hydrological study that estimates time-varying rates from covariates is not contributing to queueing methodology; it is applying it. The defensible contribution lies elsewhere: in the hydrological covariates that give the rates physical meaning, in the interpretation of the state as unmet demand rather than as customers, and in validation against exact reference solutions and pre-specified drought events.

One search artefact is a trap: Hamza, Ouarda, Durrans and Bobée (2001) appears in "queue + low flow" searches, but *queues* there is the French *queue de distribution*, the tail of a distribution, not queueing theory. The paper is a regional low-flow frequency analysis and is not queueing prior art.

## 7. The scoped gap

The gap is specific. A drought study would fill it only if four things came together: drought treated as an accumulated unmet-demand backlog with a finite-capacity state; queue-state indicators reported as drought quantities; rates that are non-stationary and estimated from hydroclimatic covariates; and validation against exact reference solutions and pre-specified drought tests. Each element has an antecedent above — the storage buffer in Langbein (1958) and Moran (1954), soil-water queues in Gamble et al. (1990a, 1990b), demand arrivals in Buchberger and Schade (1997), non-stationary machinery in Whitt (2018), learned rates in Asanjarani et al. (2021), coupled state spaces in Acosta et al. (2026). The combination, and its validation, is what the search did not return:

> "Within Crossref, OpenAlex, the complete WoS S1–S5 / Extra A/B/C screens (142 records) and the completed Scopus S1–S5 / Extra A/C screens (295 records), plus the citation traces, we found no study that puts all four of these together: (1) drought as an accumulated unmet-demand backlog with a finite-capacity state; (2) queue-state indicators reported as drought quantities; (3) non-stationary rates estimated from hydroclimatic covariates; (4) validation against exact reference solutions and pre-specified drought tests."

This is a scoping-review finding, not a claim that no such study exists. The evidence behind it is bounded. Crossref and OpenAlex were searched on 20–21 November 2026; the Web of Science Core Collection sets S1–S5 and Extra A/B/C were screened to 142 records and the Scopus sets S1–S5 and Extra A/C to 295 records, 437 records in total, with zero gap-changing records retained. WoS records were screened from exported titles, abstracts and keywords, Scopus records at title level. Forward-citation tracing was run inside both databases for every seed they index. Known prior-art records were checked individually, but this was not a systematic review and not every hit received full-text screening.

Two limitations belong on the record. Two citing-set exports are absent from the working archive and two citation-count discrepancies remain unreconciled; these are reproducibility limitations, not evidence of absence. A refresh on 25 November 2026 returned one further WoS record, screened under the same criteria, which retained nothing. A supplementary targeted search on the same day retained Acosta et al. (2026) as the closest conceptual precedent and Zhao et al. (2018) as the closest non-stationary supply–demand precedent; neither contains the four-part combination. Because this literature moves — three of the queueing-in-hydrology papers found here came from citation tracing rather than keyword search — the searches should be repeated before submission.

The open question is therefore specific. It is not whether queues and water storage are related, which Langbein settled in 1958; not whether queueing has been applied in hydrology, which it has, for soil water, runoff, irrigation, groundwater and high flows; not whether non-stationary queueing or machine learning for queues is developed, which both are. It is whether a drought-specific deficit-backlog parameterisation can be built with an explicit demand-conservation accounting, whether its parameters and latent state can be identified from the observations actually available — physiographic and comparative-hydrology covariates included (Deshmukh & Singh, 2016, 2019) — and whether the resulting indicators carry incremental information under pre-specified drought tests. If they do not, the honest report is a null or a non-identifiability result. The task of a review in this area is synthesis and a falsifiable programme, not a claim to have invented the junction.

## References

Acosta, G. A. J. G., Colili, J. V. C., Abalus Jr., R. O., & Malolos, J. V. (2026). Toward a dynamical network theory of drought: Functional water accessibility in coupled human–water systems. *SSRN Electronic Journal* [Preprint, not peer reviewed]. https://doi.org/10.2139/ssrn.6835758

Al-Sifao, A. A., Petrović, N. V., Jovanović, R. Ž., & Bugarić, U. S. (2026). Application of queuing theory in the reliability and risk assessment of the water supply system: Case study of the Jabal Hasouna well-field. *Applied Sciences*, 16(3), 1608. https://doi.org/10.3390/app16031608

Asanjarani, A., Nazarathy, Y., & Taylor, P. (2021). A survey of parameter and state estimation in queues. *Queueing Systems*, 97(1–2), 39–80. https://doi.org/10.1007/s11134-021-09688-w

Bae, S., & Lee, D. (2026). Algorithm for contextual queueing bandits with rate-optimal queue length regret. *arXiv*. https://doi.org/10.48550/arxiv.2606.09668

Batabyal, A. A. (1996). The queuing theoretic approach to groundwater management. *Ecological Modelling*, 85, 219–224. https://doi.org/10.1016/0304-3800(94)00178-2

Bogachev, M. I., Kuzmenko, A. S., Markelov, O. A., et al. (2023). Approximate waiting times for queuing systems with variable long-term correlated arrival rates. *Physica A*, 614, 128513. https://doi.org/10.1016/j.physa.2023.128513

Bogachev, M. I., Pyko, N. S., Tymchenko, D. A., et al. (2024). Approximate waiting times for queuing systems with variable cross-correlated arrival rates. *Physica A*, 654, 130152. https://doi.org/10.1016/j.physa.2024.130152

Buchberger, S. G., & Schade, T. (1997). Poisson pulse queueing model for residential water demands. In *Managing Water: Coping with Scarcity and Abundance* (pp. 488–493). American Society of Civil Engineers. [OpenAlex W2464114327; no DOI located]

Chen, X., Hong, G., & Liu, Y. (2026). Online learning and optimization for queues with unknown arrival rate and service distribution. *Operations Research*, 74(4), 2053–2074. https://doi.org/10.1287/opre.2023.0304

Dai, J. G., & Gluzman, M. O. (2022). Queueing network controls via deep reinforcement learning. *Stochastic Systems*, 12(1), 30–67. https://doi.org/10.1287/stsy.2021.0081

Deshmukh, A., & Singh, R. (2016). Physio-climatic controls on vulnerability of watersheds to climate and land use change across the United States. *Water Resources Research*, 52(11), 8775–8793. https://doi.org/10.1002/2016WR019189

Deshmukh, A., & Singh, R. (2019). A Whittaker biome-based framework to account for the impact of climate change on catchment behavior. *Water Resources Research*, 55(12), 11208–11224. https://doi.org/10.1029/2018WR023113

Galliher, H. P., & Wheeler, R. C. (1958). Nonstationary queuing probabilities for landing congestion of aircraft. *Operations Research*, 6(2), 264–277. https://doi.org/10.1287/opre.6.2.264

Gamble, B. F., Eckstein, Y., & Edwards, W. M. (1990a). Principles of evaluation of soil water residence time using queueing disciplines with water budget data (Theoretical background—I). *Journal of Hydrology*, 113(1–4), 1–25. https://doi.org/10.1016/0022-1694(90)90164-S

Gamble, B. F., Eckstein, Y., & Edwards, W. M. (1990b). Evaluation of soil water residence time in a monolith lysimeter from the application of queueing disciplines to water budget data (Demonstration—II). *Journal of Hydrology*, 113(1–4), 27–49. https://doi.org/10.1016/0022-1694(90)90165-T

Gani, J. (1957). Problems in the probability theory of storage systems. *Journal of the Royal Statistical Society: Series B*, 19.

Gani, J. (1969). Recent advances in storage and flooding theory. *Advances in Applied Probability*, 1.

Garyfallos, S. (2026). *Deep learning methods for transient performance analysis and optimization of non-Markovian nonstationary queueing systems* [Doctoral dissertation, Universitat Politècnica de Catalunya]. https://doi.org/10.5821/dissertation-2117-457092

Gordienko, E. I., & Ruiz de Chávez, J. (2012). Quantitative estimates of stability in controlled GI/D/1/∞ queueing systems and in control of water release in a simple dam model. In *Proceedings of the 9th International Conference on Informatics in Control, Automation and Robotics (ICINCO)*. https://doi.org/10.5220/0004012603090312

Hamza, A., Ouarda, T. B. M. J., Durrans, S. R., & Bobée, B. (2001). Développement de modèles de queues et d'invariance d'échelle pour l'estimation régionale des débits d'étiage. *Canadian Journal of Civil Engineering*. https://doi.org/10.1139/l00-121

Harel, M.-A., & Mouche, E. (2013). 1-D steady state runoff production in light of queuing theory: Heterogeneity, connectivity, and scale. *Water Resources Research*. https://doi.org/10.1002/2013WR013596

Harel, M.-A., & Mouche, E. (2014). Is the connectivity function a good indicator of soil infiltrability distribution and runoff flow dimension? *Earth Surface Processes and Landforms*, 39(11), 1514–1525. https://doi.org/10.1002/esp.3604

Jones, O. D. (2019). Runoff on rooted trees. *Journal of Applied Probability*, 56(4), 1065–1085. https://doi.org/10.1017/jpr.2019.61

Jones, O. D., Lane, P. N. J., & Sheridan, G. J. (2016). The stochastic runoff-runon process: Extending its analysis to a finite hillslope. *Journal of Hydrology*, 541, 677–688. https://doi.org/10.1016/j.jhydrol.2016.06.056

Klemeš, V. (1987). One hundred years of applied storage reservoir theory. *Water Resources Management*, 1(3), 159–175. https://doi.org/10.1007/BF00429941

Langbein, W. B. (1958). Queuing theory and water storage. *Journal of the Hydraulics Division*, 84(5), 1–24. https://doi.org/10.1061/JYCEAJ.0000222

Lefebvre, M. (2019). An application of queueing theory in hydrology. *Atti della Accademia Peloritana dei Pericolanti*, 97(S2). https://doi.org/10.1478/aapp.97s2a18

Massey, W. A., & Whitt, W. (1997). Peak congestion in multi-server service systems with slowly varying arrival rates. *Queueing Systems*, 25. https://doi.org/10.1023/a:1019156418862

McKee, T. B., Doesken, N. J., & Kleist, J. (1993). The relationship of drought frequency and duration to time scales. In *Proceedings of the Eighth Conference on Applied Climatology* (pp. 179–184). American Meteorological Society.

Moran, P. A. P. (1954). A probability theory of dams and storage systems. *Australian Journal of Applied Science*, 5, 116–124.

Mouche, E., & Harel, M.-A. (2016). Overland flow as a queueing process: The B/D/1 queue with an arbitrary service time. *Performance Evaluation*. https://doi.org/10.1016/j.peva.2016.10.001

Ojeda, C., Cvejoski, K., Georgiev, B., Bauckhage, C., Schuecker, J., & Sánchez, R. J. (2021). Learning deep generative models for queuing systems. *Proceedings of the AAAI Conference on Artificial Intelligence*, 35(10), 9214–9222. https://doi.org/10.1609/aaai.v35i10.17112

Palková, Z., & Hennyeyová, K. (2012). Determination of optimal capacity of irrigation system using queuing theory. *Acta Universitatis Bohemiae Meridionalis*, 11, 67–72. https://doi.org/10.32725/acta.2008.011

Palková, Z., & Rodný, T. (2010). Analytical model of the optimal capacity of an irrigation system. *Scientific Papers—Series Management, Economic Engineering in Agriculture and Rural Development*, 10(1), 155–158. [No DOI located]

Palková, Z., & Rodný, T. (2011). Analytical model of the optimal capacity of an irrigation system. *Scientific Papers—Series Management, Economic Engineering in Agriculture and Rural Development*, 14(1). [No DOI located]

Palková, Z., Rodný, T., & Kiedrowicz, M. (2012). Principles of process controlling of irrigation systems using queuing theory. *Rocznik Ochrona Środowiska*, 14, 161–171. [No DOI located]

Prabhu, N. U. (1998). *Stochastic storage processes: Queues, insurance risk, and dams* (2nd ed.). Springer.

Prajamwong, S., Merkley, G. P., & Allen, R. G. (1997). Decision support model for irrigation water management. *Journal of Irrigation and Drainage Engineering*, 123(2), 106. https://doi.org/10.1061/(ASCE)0733-9437(1997)123:2(106)

Rothkopf, M. H., & Oren, S. S. (1979). A closure approximation for the nonstationary M/M/s queue. *Management Science*, 25(6), 522–534. https://doi.org/10.1287/mnsc.25.6.522

Sherzer, E., Baron, O., Krass, D., & Resheff, Y. S. (2024). Approximating G(t)/GI/1 queues with deep learning. *European Journal of Operational Research*, 322(3), 889–907. https://doi.org/10.1016/j.ejor.2024.12.030

Sun, S., Fu, G., Bao, C., & Fang, C. (2019). Identifying hydro-climatic and socioeconomic forces of water scarcity through structural decomposition analysis: A case study of Beijing city. *Science of the Total Environment*, 687, 590–600. https://doi.org/10.1016/j.scitotenv.2019.06.143

Tan, X., Knessl, C., & Yang, Y. P. (2013). On finite capacity queues with time dependent arrival rates. *Stochastic Processes and their Applications*. https://doi.org/10.1016/j.spa.2013.02.002

Unami, K., Mohawesh, O., Sharifi, E., et al. (2015). Stochastic modelling and control of rainwater harvesting systems for irrigation during dry spells. *Journal of Cleaner Production*, 88, 185–195. https://doi.org/10.1016/j.jclepro.2014.03.100

van Loon, A. F. (2015). Hydrological drought explained. *Water Resources Research*, 51(6), 4067–4092. https://doi.org/10.1002/2015WR017141

Vicente-Serrano, S. M., Beguería, S., & López-Moreno, J. I. (2010). A multiscalar drought index sensitive to global warming: The Standardized Precipitation Evapotranspiration Index. *Journal of Climate*, 23(7), 1696–1718. https://doi.org/10.1175/2009JCLI2909.1

Whitt, W. (2018). Time-varying queues. *Queueing Models and Service Management*, 1(2). http://qmsm.nchu.edu.tw/index.php/qmsm/article/view/33

Yang, G., Guo, P., Li, R., & Li, M. (2016). Optimal allocation model of surface water and groundwater based on queuing theory in irrigation district. *Transactions of the Chinese Society of Agricultural Engineering*, 32(6). https://doi.org/10.11975/j.issn.1002-6819.2016.06.016

Yang, G., Li, M., & Huo, L. (2019). Decision support system based on queuing theory to optimize canal management. *Water Resources Management*, 33(12), 4367–4384. https://doi.org/10.1007/s11269-019-02372-y

Zhao, G., Gao, H., Kao, S.-C., Voisin, N., & Naz, B. S. (2018). A modeling framework for evaluating the drought resilience of a surface water supply system under non-stationarity. *Journal of Hydrology*, 563, 22–32. https://doi.org/10.1016/j.jhydrol.2018.05.037
