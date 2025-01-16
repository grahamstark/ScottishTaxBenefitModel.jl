module HistoricBenefits
#
# This module provided matching routines to determine whether someone who was recieving
# some benefit was getting high/low/enhanced/standard/middle/whatever levels of it.
# Greatly messed up by what seem to be to be errors in benefit imputations in the FRS;
# see the notes in `docs/` and the blog post. Not part of the model per. se..
# 
# FIXME the intention is to replace much of this
# with a series of complete parameter files, once we have 
# everything defined fully.
# 
using CSV, DataFrames, Dates, Artifacts, LazyArtifacts
using ScottishTaxBenefitModel
using .Definitions 
using .ModelHousehold: Person
using .Utils: nearesti, nearest
using .Randoms: testp
using .TimeSeriesUtils: fy_from_bits
export benefit_ratio, HISTORIC_BENEFITS, RATIO_BENS, make_benefit_ratios!
export should_switch_dla_to_pip,PIP_RECEIPTS,DLA_RECEIPTS
export switch_dla_to_pip!

const RATIO_BENS = [state_pension,bereavement_allowance_or_widowed_parents_allowance_or_bereavement]

function load_historic( file ) :: Dict
    df = CSV.File( file ) |> DataFrame
    nc = size( df )[2]
    nms = strip.(names( df ))
    db = Dict{Int,Dict}()
    for dr in eachrow(df)
        d = Dict{Symbol,Union{Missing,Float64}}()
        for i in 3:nc
            rn = Symbol(nms[i])
            # println( rn )
            # println( typeof( rn ))                
            d[rn] = dr[i]
        end
        db[dr.year] = d
    end
    return db
end

function load_pip()
    pip=CSV.File( joinpath(artifact"augdata", "pip_2002-2023_from_stat_explore.csv"),
        missingstring="..",
        types=Dict([:Date=>String]))|>DataFrame
    pip.Date = Date.( pip.Date, dateformat"yyyymm" )
    return pip
end

function load_dla()
    dla=CSV.File( joinpath(artifact"augdata","dla_2002-2023_from_stat_explore.csv" ))|> DataFrame
    dla.Date = Date.( dla.Date, dateformat"u-yy" ) .+Year(2000)
    return dla
end

const HISTORIC_BENEFITS = load_historic( 
    joinpath( 
        artifact"augdata", "historic_benefits.csv" ))

const DLA_RECEIPTS = load_dla()
const PIP_RECEIPTS =  load_pip()


function benefit_ratio( 
    finyear :: Integer, 
    amt :: Real, 
    btype :: Incomes_Type ) :: Real
    brat = HISTORIC_BENEFITS[finyear][Symbol(btype)]
    return amt/brat
end

#
# Year 1st, then 1 before and 1 after, then 2.. 
#
function get_historic( finyear :: Integer, which :: Symbol, width::Int = 1 )::Vector{Real}
    out = []
    push!(out, HISTORIC_BENEFITS[finyear][which])
    for i in 1:width
        year = finyear-i 
        push!(out, HISTORIC_BENEFITS[year][which])
        year = finyear+1
        push!(out, HISTORIC_BENEFITS[year][which]) 
    end
    return out
end

"""
  Find an exact match for some benefit level, given actual levels, -1..+1 years around finyear, or find 
  the nearest amongst the current values, since sometimes the imputation
  seems to be for the wrong year (calendar vs financial). If that fails, pick the
  index of the current values that's closest.
"""
function get_matches( v :: Real, finyear :: Int, which ... ) :: Tuple
    n = length(which)
    all_current = []
    for i in 1:n
        hvals = get_historic( finyear, which[i])
        m = size(hvals)[1]
        push!(all_current,hvals[1]) 
        for j in 1:m
            if v ≈ hvals[j]
                # println( "on $(which[i]) matched $v at pos $i j=$j vals are $hvals ")
                return (i,j)
            end
        end
    end
    # if we get here, try searching nearest
    # println( "didn't match; trying against $(all_current)")
    n = nearesti( v, all_current... )
    return (n,99)
end

"""
Kinda-sorta randomly assign a dla case as pip so that the proportion
of dla/pip in the data for some period is roughly the same as the latest
dla/pip ratio. This is needed to model the DLA->PIP transition. 
"""
function should_switch_dla_to_pip( 
    onerand  :: String,
    interview_year :: Integer, 
    interview_month :: Integer) :: Bool
    #
    # This weird-looking calculation gives the proportion of
    # dla cases we need to switch to PIP for the ratio at the
    # interview point to (roughly) match the latest DLA/PIP ratio.
    #
    latest_dla = last(DLA_RECEIPTS).Scotland
    latest_pip = last(PIP_RECEIPTS).Scotland
    d = Date( interview_year, interview_month, 1 )
    nearest_dla = DLA_RECEIPTS[nearest( d, DLA_RECEIPTS ),:Scotland]
    nearest_pip = PIP_RECEIPTS[nearest( d, PIP_RECEIPTS ),:Scotland]
    nearest_all = nearest_pip + nearest_dla
    latest_all = latest_pip + latest_dla
    # sw_prop - 70% of DLA needs to *stay* DLA -> 30% change (1-sw_prop)
    sw_prop = 1-(latest_dla/nearest_dla)*(nearest_all/latest_all)
    # println( "onerand $(onerand[Randoms.DLA_TO_PIP:Randoms.DLA_TO_PIP+Randoms.DEFAULT_CHUNK_SIZE-1])")
    # println( "sw_prop=$sw_prop latest_dla $latest_dla nearest_dla $nearest_dla latest_all $latest_all nearest_all $nearest_all" )
    # this should make 30% of DLAs change in that example
    switch = testp( onerand, sw_prop, Randoms.DLA_TO_PIP )
    # println( "switch=$switch")
    return switch
end

function switch_dla_to_pip!( 
    pers :: Person,
    interview_year :: Integer, 
    interview_month :: Integer ) 
    if (pers.dla_self_care_type != missing_lmh )||
       (pers.dla_mobility_type != missing_lmh)
        if should_switch_dla_to_pip( 
            pers.onerand, interview_year, interview_month )
            # println("switching person $(pers.pid) year=$interview_year month=$interview_month ")
            # println( "pers.dla_self_care_type $(pers.dla_self_care_type) ")
            pers.pip_daily_living_type = 
                if pers.dla_self_care_type == missing_lmh
                    no_pip
                elseif pers.dla_self_care_type in (low,mid)
                    standard_pip
                else
                    enhanced_pip
                end
            pers.pip_mobility_type = 
                if pers.dla_mobility_type == missing_lmh
                    no_pip
                elseif pers.dla_mobility_type in (low,mid)
                    standard_pip
                else
                    enhanced_pip
                end
            pers.dla_mobility_type = missing_lmh
            pers.dla_self_care_type = missing_lmh
        end
    end
end # proc

# 
# FIXME make all these names the same. Use the integer constants in `.STBIncomes.jl`.
# FIXME historic bit should be the whole parameter system eventually.
#
"""
 Return a dict of either ratios of recorded receipt to actual values or an indicator of which
 level of benefit is closest.
"""
function make_benefit_ratios!( 
    pers :: Person,
    interview_year :: Integer, 
    interview_month :: Integer ) 
    finyear :: Int = fy_from_bits( interview_year, interview_month )
    # short cut
    incd = pers.income; 
    # for pensions, etc. we just accept what's there & assign the 
    # ratio. FIXME: is this right for people who get the new state_pension
    # in the data
    for target in RATIO_BENS
        if haskey(incd, target )
            pers.benefit_ratios[target] = benefit_ratio( finyear, incd[target], target )
        end
    end
    # these seem to be usually imputed in the data. Find which one matches best.
    
    pers.pip_daily_living_type = no_pip
    if haskey( incd, personal_independence_payment_daily_living )  
        v = incd[personal_independence_payment_daily_living]
        matches = get_matches( v, finyear, :pip_daily_living_standard,  :pip_daily_living_enhanced )
        pers.pip_daily_living_type = matches[1] == 1 ? standard_pip : enhanced_pip
        if matches[2] > 1
            # println( "!! pip daily living matched at $(matches[2])")
        end
    end

    pers.pip_mobility_type = no_pip
    if haskey( incd, personal_independence_payment_mobility )  
        v = incd[personal_independence_payment_mobility]
        matches = get_matches( v, finyear, :pip_mobility_standard, :pip_mobility_enhanced )
        pers.pip_mobility_type = matches[1] == 1 ? standard_pip : enhanced_pip
        if matches[2] > 1
            # println( "!! pip mobility matched at $(matches[2])")
        end
    end
    
    pers.dla_self_care_type = missing_lmh
    if haskey( incd, dlaself_care )  
        v = incd[dlaself_care]        
        matches = get_matches( v, finyear, 
            :dla_care_low, 
            :dla_care_mid, 
            :dla_care_high )
        pers.dla_self_care_type = if matches[1] == 1 
                low
            elseif matches[1] == 2 
                mid
            else 
                high
            end
    end

    pers.dla_mobility_type = missing_lmh
    if haskey( incd, dlamobility )  
        v = incd[dlamobility] 
        matches = get_matches( v, finyear, 
            :dla_mobility_low, 
            :dla_mobility_high )
        pers.dla_mobility_type = matches[1] == 1 ? low : high # only 2 cases, despite low/mid/high
    end

    pers.attendance_allowance_type = missing_lmh
    if haskey( incd, attendance_allowance ) 
        v = incd[attendance_allowance] 
        matches = get_matches( v, 
            finyear, 
            :attendance_allowance_low,
            :attendance_allowance_high )
        pers.attendance_allowance_type = matches[1] == 1 ? low : high # only 2 cases, despite low/mid/high
    end
end
    
end # module