using DataFrames, CSV, StatsBase

hbai = CSV.File( "/mnt/data/hbai/2024-ed/UKDA-5828-tab/main/i2124e_2324prices.tab"; delim='\t', missings=["","-9","A"]) |> DataFrame
nms = lowercase.(names(hbai))
rename!(hbai, nms)
median(hbai.s_oe_ahc,Weights(hbai.gs_indpp))

hb24 = hbai[(hbai.year.==30),[:s_oe_ahc,:s_oe_bhc,:gs_indpp]]
hb23 = hbai[(hbai.year.==29),[:s_oe_ahc,:s_oe_bhc,:gs_indpp]]
hb22 = hbai[(hbai.year.==28),[:s_oe_ahc,:s_oe_bhc,:gs_indpp]]
rename!( hb24, ["after_hc_net_equivalised", "before_hc_net_equivalised", "grossing_factor"])
rename!( hb23, ["after_hc_net_equivalised", "before_hc_net_equivalised", "grossing_factor"])
rename!( hb22, ["after_hc_net_equivalised", "before_hc_net_equivalised", "grossing_factor"])

median(hb22.after_hc_net_equivalised,Weights(hb22.grossing_factor))
median(hb23.after_hc_net_equivalised,Weights(hb23.grossing_factor))
median(hb24.after_hc_net_equivalised,Weights(hb24.grossing_factor))
# should match ... these:
unique(hbai.mdoeahc)

median(hb22.before_hc_net_equivalised,Weights(hb22.grossing_factor))
median(hb23.before_hc_net_equivalised,Weights(hb23.grossing_factor))
median(hb24.before_hc_net_equivalised,Weights(hb24.grossing_factor))
# should match ... these:
unique(hbai.mdoebhc)

CSV.write( "/mnt/data/NINE/datasets/hbai-24-subset.tab", hb24; delim='\t')
