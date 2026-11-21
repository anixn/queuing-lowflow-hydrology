import pandas as pd

OUT = r"C:\Users\ankit.deshmukh\AppData\Local\Temp\opencode\record_rows.md"
EXP = r"D:\Research\queuing-lowflow-hydrology\analysis\P01\exports"

def rows_of(fname, offset=0):
    df = pd.read_excel(f"{EXP}\\{fname}")
    return [(offset+i+1, r) for i, r in df.iterrows()]

extraA = rows_of("wos_extraA_2026-11-21.xls")
s4 = rows_of("wos_s4_2026-11-21.xls")
s5a = rows_of("wos_s5_2026-11-21.xls")
s5b = rows_of("wos_s5_p2_2026-11-21.xls", 50)
extraC = rows_of("wos_extraC_2026-11-21.xls")

reasons_A = {
 1: "Plant drought-memory physiology; no queueing, no water-quantity deficit. DROP",
 2: "Bird behavioural ecology; 'drought' is habitat, no queue model. DROP",
 3: "Forest-fragmentation ecology; no queue model. DROP",
 4: "Advanced Message Queuing Protocol (AMQP) for grid computing; IT message queues, not water. DROP",
 5: "Water-rights review; notes 'queuing principles' in prior-appropriation allocation as institutional context, no queue-state drought model. DROP",
 6: "Tunisian allocation runs on a priority 'queuing system' as an institutional rule; no stochastic queue state, indicators or learned rates. DROP",
 7: "Water insecurity as social science; no queue model. DROP",
 8: "Statistics of gamma samples; matched 'queue' in an unrelated sense. DROP",
}
reasons_S4 = {
 1: "OFDMA subcarrier allocation; 'water-filling' metaphor, telecom. DROP",
 2: "Cache-update scheduling via water-filling; telecom. DROP",
 3: "Bogachev et al. 2024: waiting times with variable cross-correlated arrival rates — OR literature already recorded for P3's benchmark, not drought prior art. DROP",
 4: "UAV underwater optical communication; telecom. DROP",
 5: "HVAC heat-pump/chiller ML models; 'queue' incidental. DROP",
 6: "UAV flight/power scheduling; telecom-OR. DROP",
}
special_S5 = {
 42: "Deep-learning drought prediction from climate indices; no queue or deficit state. DROP",
 50: "Healthcare emergency-care queueing (capacity expansion); 'unmet demand' is patients, not water. DROP",
 43: "Graph-model conflict resolution for water allocation; no queueing. DROP",
 46: "Renewable-electricity droughts; not water demand. DROP",
 3: "Urban water vulnerability incl. institutional friction; abstract scanned, no queueing model. DROP",
 8: "Multi-objective supply-system design; abstract scanned, no queueing model. DROP",
 12: "Scenario framework for water-scarcity risk; abstract scanned, no queueing model. DROP",
 27: "Joint allocation/route interconnection under low flow; optimisation, no queue-state deficit. DROP",
}
def reason_S5(n):
    return special_S5.get(n, "WEAP-type demand/supply scenario or assessment study; 'unmet demand' = modelled supply shortfall, no queueing model. DROP")

reasons_C = {
 1: "Make-to-stock production-inventory backorders; 'unmet demand' is industrial orders, not water. DROP",
 2: "Queuing-inventory production control; not water. DROP",
 3: "Highway fast-charging configuration; transport. DROP",
 4: "Datacenter RPC overload control; IT. DROP",
 5: "Healthcare logistics capacity expansion with queueing; not water/drought. DROP",
 6: "Vaccine supply-chain design; healthcare. DROP",
 7: "EV charging infrastructure agent-based model; transport. DROP",
 8: "M/M/c/c and M/M/c/K queueing for hospital inpatient flow; healthcare. DROP",
 9: "Physiotherapy screening clinics for unmet demand; healthcare. DROP",
 10: "EV charging-station siting with queueing pressure; transport. DROP",
 11: "Taxi fleet size optimisation; transport. DROP",
 12: "Warehouse space-utilisation stochastic model; logistics. DROP",
 13: "Taxi/ridehailing fleet size; transport. DROP",
}

def fmt(n, r, setname, reason):
    t = str(r.get('Article Title','')).replace('|', '/')
    t = ' '.join(t.split())
    if len(t) > 110:
        t = t[:107] + '...'
    y = str(r.get('Publication Year',''))
    doi = r.get('DOI','')
    doi = '' if pd.isna(doi) else str(doi)
    return f"| {setname} | {t} | {y} | {doi} | DROP | {reason} |"

lines = []
for n, r in extraA: lines.append(fmt(n, r, "Extra A", reasons_A[n]))
for n, r in s4: lines.append(fmt(n, r, "S4", reasons_S4[n]))
for n, r in (s5a + s5b): lines.append(fmt(n, r, "S5", reason_S5(n)))
for n, r in extraC: lines.append(fmt(n, r, "Extra C", reasons_C[n]))

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print(len(lines), "rows written")
