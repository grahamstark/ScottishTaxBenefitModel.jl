using CSV,DataFrames,Statistics,StatsBase

frs_all_years_scot_he = create_frs( 2015:2018 )
shs_all_years = create_shs( 2016:2018 ) 
    
donor,recip = create_donor_and_recip_datasets( frs_all_years_scot_he, shs_all_years )


include( "matching/matching_funcs.jl")
#
# save everything
#
CSV.write( "data/merging/shs_donor_data.tab", donor )
CSV.write( "data/merging/frs_recip_data.tab", recip )
CSV.write( "data/merging/shs_all_years.tab", shs_all_years )
CSV.write( "data/merging/frs_all_years_scot_he.tab", frs_all_years_scot_he )

make_initial_match!( recip, donor )
CSV.write( "data/merging/shs_donor_data.tab", donor; quotestrings=true, delim='\t' )
CSV.write( "data/merging/frs_shs_merging_indexes.tab", recip; quotestrings=true, delim='\t' )

donor = CSV.File( "data/merging/shs_donor_data.tab"; types=Dict(:uniqidnew => String))|>DataFrame
recip = CSV.File( "data/merging/frs_recip_data.tab" ) |> DataFrame


unmatched = recip[(recip.shs_datayear_1 .== 0),:]
unmatched[!,critmatche1]

# match shelter on random shelter
unmatched = Vector(((recip.shs_datayear_1 .== 0).&(recip.shelter_1 .== 1)))
n = match_up_unmatched!( recip, donor, [:shelter], unmatched )


CSV.write( "data/merging/shs_donor_data.tab", donor; quotestrings=true, delim='\t' )
CSV.write( "data/merging/frs_shs_merging_indexes.tab", recip; quotestrings=true, delim='\t' )

"""


final missing 7 cases after matching any sheltered home:

 Row │ sernum  datayear  shelter_1  singlepar_1  numadults_2  numkids_2  empstathigh_1  agehigh_1 
     │ Int64   Int64     Int64      Int64        Int64        Int64      Int64          Int64     
─────┼────────────────────────────────────────────────────────────────────────────────────────────
   1 │   6171        16          0            1            1          2              1         62
   2 │  16510        16          0            0            3          1              1         19
   3 │  10973        17          0            0            3          4              1         42
   4 │  18803        17          0            0            3          2              5         80
   5 │   4861        18          0            0            3          2              1         19
   6 │   5234        18          0            0            3          0              6         18
   7 │  14536        18          0            0            2          2              5         80

   
"""

# reload so we can just start the script here 
donor = CSV.File( "data/merging/shs_donor_data.tab"; delim='\t' ) |> DataFrame
#
# no idea whatsoever why the 1st uniq needs cast, but it does seem to ..
#
recip = CSV.File( "data/merging/frs_shs_merging_indexes.tab"; delim='\t', types=Dict("shs_uniqidnew_1"=>String) ) |> DataFrame

# 1) so drop age & emp status for last 7

final_unmatched = recip[(recip.shs_datayear_1 .== 0),:]

final_targets = [:singlepar,:numadults,:numkids]

# get rid of this cast
final_unmatched = Vector((recip.shs_datayear_1 .== 0))

#
# matching the remaining 7 on sp, ads, kids 
#
n = match_up_unmatched!( recip, donor, final_targets, final_unmatched )
# 
# & we're down to 1 unmatched .. 
#
"""
 Row │ sernum  datayear  shelter_1  singlepar_1  numadults_2  numkids_2  empstathigh_1  agehigh_1 
     │ Int64   Int64     Int64      Int64        Int64        Int64      Int64          Int64     
─────┼────────────────────────────────────────────────────────────────────────────────────────────
   1 │  10973        17          0            0            3          4              1         42

"""

# try with just kids, no adults
final_targets_2 = [:tenure,:singlepar,:numkids,:datayear]
final_unmatched_2 = Vector(recip.shs_datayear_1 .== 0)
n = match_up_unmatched!( recip, donor, final_targets_2, final_unmatched_2 )

# no more than 4 children in SHS
# maximum( donor.numkids_1 ) => 4
# maximum( donor.

CSV.write( "data/merging/shs_donor_data.tab", donor; quotestrings=true, delim='\t' )
CSV.write( "data/merging/frs_shs_merging_indexes.tab", recip; quotestrings=true, delim='\t' )
mhh = CSV.File( "data/model_households_scotland.tab"; delim='\t') |> DataFrame

shs_councils = CSV.File( "data/merging/la_mappings.csv"; delim=',') |> DataFrame

target_pops = CSV.File( "data/merging/hhlds_and_people_2019_nrs_estimates.csv" ) |> DataFrame
shs_hhn = count_councils(shs_all_years, shs_councils )
#
# actual sampling frequencies by council, pooled over all shs years
# we use these as probability weights
#
inv_freqs = Dict()

for p in eachrow( target_pops )
    inv_freqs[p.code] = p.hhlds_2019/shs_hhn[p.code]
end
#
# idiot check that we sum back up
#
s = 0.0
for p in eachrow( target_pops )
    global s
    s += inv_freqs[p.code]*shs_hhn[p.code]
end

add_in_las_to_recip!( recip, shs_all_years, shs_councils )

@assert s  ≈ 2495622

tot_hhlds_19 = 2_495_622

n = add_council_to_frs!(
    ;
    mhh   = mhh,
    recip = recip,
    shs_councils = shs_councils,
    inv_freqs = inv_freqs )


aw = tot_hhlds_19/sum(values(n))

println( "|code|name|shs sample freq| n |" )
println( "|----|----|-----------|------|" )
for p in eachrow( shs_councils )
    v = inv_freqs[p.Code]
    c = n[p.Code]*aw
    println( "| $(p.Code) | $(p.name) | $v | $c")
end

for r in eachrow(mhh)
    n[r.council] += 1
end

CSV.write( "data/model_households_scotland.tab", mhh; delim='\t') 

#
# todo : add bedrooms bedroom6 frs capped at 6 hc4 shs
# 