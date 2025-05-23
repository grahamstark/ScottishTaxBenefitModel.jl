module DataSummariser 
#=


=#

using ScottishTaxBenefitModel
using .Definitions
using .FRSHouseholdGetter
using .HouseholdFromFrame
using .Intermediate
using .ModelHousehold
using .RunSettings
using .STBParameters
using .Weighting

using CSV,DataFrames,StatsBase,DataStructures

export make_intermed_dataframe, make_data_summaries

function make_intermed_dataframe( 
    settings :: Settings, 
    sys :: TaxBenefitSystem{RT}, 
    nhhs :: Int )::DataFrame where RT <: AbstractFloat
    nobs = nhhs*2 # benefit unit level, more than we actually need.
    df = DataFrame(
        hid = zeros(BigInt, nobs ),
        data_year = zeros(Int, nobs ),
        buno = zeros(Int, nobs ),
        weight = zeros( RT,nobs ),
        benefit_unit_number = zeros( Int, nobs ),
        num_people = zeros( Int, nobs ),
        age_youngest_adult = zeros( Int, nobs ),
        age_oldest_adult = zeros( Int, nobs ),
        age_youngest_child = zeros( Int, nobs ),
        age_oldest_child = zeros( Int, nobs ),
        num_adults = zeros( Int, nobs ),
        someone_pension_age = zeros( Bool, nobs ),
        someone_pension_age_2016 = zeros( Bool, nobs ),
        all_pension_age = zeros( Bool, nobs ),
        someone_working_ft = zeros( Bool , nobs ),
        someone_working_ft_and_25_plus = zeros( Bool, nobs ),
        num_not_working = zeros( Int, nobs ),
        num_working_ft = zeros( Int, nobs ),
        num_working_pt = zeros( Int , nobs ),
        num_working_24_plus = zeros( Int , nobs ),
        num_working_16_or_less = zeros( Int, nobs ),
        total_hours_worked = zeros( Int, nobs ),
        someone_is_carer = zeros( Bool , nobs ),
        num_carers = zeros( Int, nobs ),
        is_sparent = zeros( Bool , nobs ),
        is_sing = zeros( Bool, nobs ),
        is_disabled = zeros( Bool, nobs ),
        num_disabled_adults = zeros( Int, nobs ),
        num_disabled_children = zeros( Int, nobs ),
        num_severely_disabled_adults = zeros( Int, nobs ),
        num_severely_disabled_children = zeros( Int, nobs ),
        num_job_seekers = zeros( Int, nobs ),
        num_children = zeros( Int, nobs ),
        num_allowed_children = zeros( Int, nobs ),
        num_children_born_before = zeros( Int, nobs ),
        ge_16_u_pension_age = zeros( Bool , nobs ),
        limited_capacity_for_work = zeros( Bool , nobs ),
        has_children = zeros( Bool , nobs ),
        economically_active = zeros( Bool, nobs ),
        working_disabled = zeros( Bool, nobs ),
        num_benefit_units = zeros( Int, nobs ),
        # nation = zeros( Nation, nobs ),
        all_student_bu = zeros( Bool, nobs ),
    
        net_physical_wealth = zeros( RT, nobs ),
        net_financial_wealth = zeros( RT, nobs ),
        net_housing_wealth = zeros( RT, nobs ),
        net_pension_wealth = zeros( RT, nobs ),
        total_value_of_other_property = zeros( RT, nobs ))   
    i = 0
    for hno in 1:nhhs
        hh = FRSHouseholdGetter.get_household( hno )
        intermed = make_intermediate( 
            RT,
            settings,
            hh, 
            sys.hours_limits, 
            sys.age_limits, 
            sys.child_limits )
        buno = 0
        for int in intermed.buint
            i += 1
            buno += 1
            row = df[ i, : ]
            row.hid = hh.hid
            row.buno = buno
            row.data_year = hh.data_year
            row.weight = hh.weight
            row.benefit_unit_number = int.benefit_unit_number
            row.num_people = int.num_people
            row.age_youngest_adult = int.age_youngest_adult
            row.age_oldest_adult = int.age_oldest_adult
            row.age_youngest_child = int.age_youngest_child
            row.age_oldest_child = int.age_oldest_child
            row.num_adults = int.num_adults
            row.someone_pension_age = int.someone_pension_age 
            row.someone_pension_age_2016 = int.someone_pension_age_2016
            row.all_pension_age = int.all_pension_age
            row.someone_working_ft = int.someone_working_ft 
            row.someone_working_ft_and_25_plus = int.someone_working_ft_and_25_plus                    
            row.num_not_working = int.num_not_working
            row.num_working_ft = int.num_working_ft
            row.num_working_pt = int.num_working_pt
            row.num_working_24_plus = int.num_working_24_plus
            row.num_working_16_or_less = int.num_working_16_or_less
            row.total_hours_worked = int.total_hours_worked
            row.someone_is_carer = int.someone_is_carer
            row.num_carers = int.num_carers                    
            row.is_sparent = int.is_sparent 
            row.is_sing = int.is_sing 
            row.is_disabled = int.is_disabled                    
            row.num_disabled_adults = int.num_disabled_adults
            row.num_disabled_children = int.num_disabled_children
            row.num_severely_disabled_adults = int.num_severely_disabled_adults
            row.num_severely_disabled_children = int.num_severely_disabled_children                
            row.num_job_seekers = int.num_job_seekers                    
            row.num_children = int.num_children
            row.num_allowed_children = int.num_allowed_children
            row.num_children_born_before = int.num_children_born_before
            row.ge_16_u_pension_age = int.ge_16_u_pension_age 
            row.limited_capacity_for_work = int.limited_capacity_for_work 
            row.has_children = int.has_children 
            row.economically_active = int.economically_active
            row.working_disabled = int.working_disabled
            row.num_benefit_units = int.num_benefit_units
            # row.nation = int.nation
            row.all_student_bu = int.all_student_bu                
            row.net_physical_wealth = int.net_physical_wealth
            row.net_financial_wealth = int.net_financial_wealth
            row.net_housing_wealth = int.net_housing_wealth
            row.net_pension_wealth = int.net_pension_wealth
            row.total_value_of_other_property = int.total_value_of_other_property
        end
    end 
    return df[1:i,:]
end

"""
reload data from a mapped household back into an original dataframe
"""
function writeback!( phhs :: DataFrame, hh :: Household )
    phhr = @view phhs[ (phhs.hid .== hh.hid) .& ( phhs.data_year .== hh.data_year ), :]
    @assert size(phhr)[1] >= 1
    # phhr = phhr[1,:]
    phhr.weight .= hh.weight
    phhr.water_and_sewerage .= hh.water_and_sewerage 
    phhr.mortgage_payment .= hh.mortgage_payment
    phhr.mortgage_interest .= hh.mortgage_interest
    phhr.gross_rent .= hh.gross_rent
    phhr.total_wealth .= hh.total_wealth
    phhr.house_value .= hh.house_value
    phhr.net_physical_wealth .= hh.net_physical_wealth 
    phhr.net_financial_wealth .= hh.net_financial_wealth 
    phhr.net_housing_wealth .= hh.net_housing_wealth 
    phhr.net_pension_wealth .= hh.net_pension_wealth 
    phhr.original_gross_income .= hh.original_gross_income 
    for (pid,pers) in hh.people
        persrow = @view phhs[(phhs.pid .== pers.pid),:]
        @assert size( persrow)[1] == 1
        persrow = persrow[1,:]
        for i in instances(Incomes_Type)
            ikey = Symbol("income_", i)
            persrow[ikey] = get(pers.income, i, 0.0 )
        end
        for i in instances(Asset_Type)
            if i != Missing_Asset_Type
                ikey = make_sym_for_asset(i)
                persrow[ikey] = get(pers.assets,i,0.0)
            end
        end
        persrow.cost_of_childcare = pers.cost_of_childcare
        persrow.work_expenses = pers.work_expenses 
        persrow.travel_to_work = pers.work_expenses 
        persrow.debt_repayments = pers.debt_repayments
        persrow.wealth_and_assets = pers.wealth_and_assets    
    end
end

function overwrite_raw!( phhs :: DataFrame, nhhs :: Int )
    for hno in 1:nhhs
        hh = FRSHouseholdGetter.get_household( hno )
        writeback!( phhs, hh )
    end
end

"""
summarise a single vector and return a tuple with means, medians etc.
"""
function summarise( key::Symbol, v :: AbstractVector, w :: AbstractWeights )
    v = coalesce.(v,0.0)
    n = length(v)
    wn = sum(w)
    pv = v[ v .> 0 ]
    pw = w[ v .> 0 ]
    out = (; key=key, type="allzero", msg = "No non-zeros")
    if length(pv) > 0
        u_mean = mean( pv )
        w_mean = mean( pv, pw )
        u_median = median( pv )
        w_median = median( pv, pw )
        u_non_zeros = length( pv )
        w_non_zeros = sum( pw)
        u_std = std( pv )
        w_std = std( pv, pw )
        mn = minimum( pv )
        mx = maximum(pv)
        u_hist = fit(Histogram, pv, nbins=10)
        w_hist = fit(Histogram, pv, pw, nbins=10)
        out = (; key=key, type="full", count=n,weighted_count=wn,u_mean,u_median,u_non_zeros,u_std, u_hist, w_mean,w_median,w_non_zeros,w_std, w_hist, minimum=mn, maximum=mx)
    end
    out
end

"""
internal: return 2 dataframes, one for enums with counts, and one with stats
"""
function dict_to_dataframe( out :: Vector )::Tuple
    l = length( out )
    out1 = DataFrame( 
        varname = fill( Symbol(""),l),
        notes = fill("",l),
        count=fill(0,l),
        weighted_count=fill(0.0,l),
        u_mean=fill(0.0,l),
        u_median=fill(0.0,l),
        u_non_zeros=fill(0.0,l),
        u_std=fill(0.0,l), 
        # u_hist=fill(0.0,l), 
        w_mean=fill(0.0,l),
        w_median=fill(0.0,l),
        w_non_zeros=fill(0.0,l),
        w_std=fill(0.0,l), 
        # w_hist=fill(0.0,l), 
        minimum=fill(0.0,l), 
        maximum=fill(0.0,l))
    l20 = l*20
    out2 = DataFrame(
        varname = fill( Symbol(""), l20),
        notes = fill( "", l20),
        label = fill( "", l20),
        u_count = fill(0, l20),
        w_count = fill(0.0, l20))
    o1pos = 0
    o2pos = 0
    for v in out
        if v.type == "full"
            o1pos += 1
            r = @view out1[o1pos,:]
            r.varname = v.key
            # r.notes = ""
            r.count = v.count
            r.weighted_count = v.weighted_count
            r.u_mean = v.u_mean
            r.u_median = v.u_median
            r.u_non_zeros = v.u_non_zeros
            r.u_std = v.u_std
            # r.u_hist = v.u_hist
            r.w_mean = v.w_mean
            r.w_median = v.w_median
            r.w_non_zeros = v.w_non_zeros
            r.w_std = v.w_std
            # r.w_hist = v.w_hist
            r.minimum = v.minimum
            r.maximum = v.maximum
        elseif v.type == "enum"
            ln = length( v.weighted )
            labs = collect(keys(v.weighted))
            uv = collect(values( v.unweighted ))
            wv = collect(values( v.weighted ))
            for i in 1:ln
                o2pos += 1
                if i == 1
                    out2[o2pos,:varname] = v.key
                end
                out2[o2pos,:label] = string(labs[i])
                out2[o2pos,:u_count] = uv[i]
                out2[o2pos,:w_count] = wv[i]
            end
        elseif v.type == "allzero"
            o1pos += 1
            r = @view out1[o1pos,:]
            r.varname = v.key
            r.notes = "All zero/missing."
        end
    end
    out1[1:o1pos,:], out2[1:o2pos,:]
end

"""
summarise one of our datasets, returns 2 dataframes, one for enums, one for rest
"""
function make_data_summaries( df :: DataFrame, skiplist=[:hid, :buno, :pid, :uhid, :pno,:onerand,:uhid_1, :onerand_1 ])::Tuple
    nms = setdiff(OrderedSet(Symbol.(names( df ))), Set(skiplist ))
    out = []
    for k in nms 
        print( "on $k")
        r = df[!,k]
        et = eltype(r)
        if et isa Union # {Missing,Any}
            println( "Union type $et ")
            et = et.b # Union{Missing,X}; b is 2nd one
        end
        if et <: Integer
            println( "Int")
            ss = summarise( k, r, df.weight )
        elseif et <: AbstractFloat
            println( "Float")
            ss = summarise( k, r, df.weight )
        elseif (et <: Enum) || (et <: Symbol) || (et <: Bool )
            println( "Enum")
            ss = ( ; key=k, type="enum", weighted = sort( countmap( r, df.weight)), unweighted = sort( countmap( r )))
        else
            println( "unmatched $k")
        end
        push!(out, ss)
    end
    return dict_to_dataframe( out )
end

end # module