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

const RT = Float64

function make_intermed_dataframe( 
    settings :: Settings, 
    sys :: TaxBenefitSystem, 
    nhhs :: Int )::DataFrame 
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
function writeback!( hhdata :: DataFrame, persdata::DataFrame, hh :: Household )
    hhrow = hhdata[ (hhdata.hid .== hh.hid) .& ( hhdata.data_year .== hh.data_year ), :]
    @assert size(hhrow)[1] == 1
    hhrow = hhrow[1,:]
    hhrow.weight = hh.weight
    hhrow.water_and_sewerage  = hh.water_and_sewerage 
    hhrow.mortgage_payment = hh.mortgage_payment
    hhrow.mortgage_interest = hh.mortgage_interest
    hhrow.gross_rent = hh.gross_rent
    hhrow.total_wealth = hh.total_wealth
    hhrow.house_value = hh.house_value
    hhrow.net_physical_wealth  = hh.net_physical_wealth 
    hhrow.net_financial_wealth  = hh.net_financial_wealth 
    hhrow.net_housing_wealth  = hh.net_housing_wealth 
    hhrow.net_pension_wealth  = hh.net_pension_wealth 
    hhrow.original_gross_income  = hh.original_gross_income 
        #=
 hhrow.original_income_decile  = hh.original_income_decile 
 hhrow.equiv_original_income_decile  = hh.equiv_original_income_decile 
    =#

    for (pid,pers) in hh.people
        persrow =  persdata[(persdata.hid .== pers.hid) .& ( persdata.data_year .== pers.data_year ) .& (persdata.pno .== pers.pno ),:]
        @assert size( persrow)[1] == 1
        persrow = persrow[1,:]

        for i in instances(Incomes_Type)
            ikey = make_sym_for_frame("income", i)
            if model_person[ikey] != 0.0
                persrow[ikey] = pers.income[i]
            end
        end



        #
        # override wages and se
        # wage needs to be set
        if settings.income_data_source == ds_frs
            income[wages] = model_person.wages_frs
            income[self_employment_income] = model_person.self_emp_frs
        else # not really needed since hbai is the default
            income[wages] = model_person.wages_hbai
            income[self_employment_income] = model_person.self_emp_hbai
        end
        assets = Dict{Asset_Type,Float64}() # fixme asset_type_dict
        for i in instances(Asset_Type)
            if i != Missing_Asset_Type
                ikey = make_sym_for_asset( i )
                # println(ikey)
                if model_person[ikey] != 0
                    assets[i] = model_person[ikey]
                end
            end
        end

    end
end

function summarise( v :: Vector, w :: AbstractWeights )
    v = coalesce.(v,0.0)
    n = length(v)
    wn = sum(w)
    pv = v[ v .> 0 ]
    pw = w[ v .> 0 ]
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
    (; count=n,weighted_count=wn,u_mean,u_median,u_non_zeros,u_std, u_hist, w_mean,w_median,w_non_zeros,w_std, w_hist, minimum=mn, maximum=mx)
end

function make_summaries( df :: DataFrame, skiplist=[:hid, :buno, :pid, :pno])::DataFrame
    nms = setdiff(OrderedSet(Symbol.(names( df ))), Set(skiplist ))
    weights = Weights( df.weight )
    for k in nms 
        r = df[!,k]
        et = eltype(r)
        print( "on $k")
        if et <: Integer
            println( "Int")
            ss = summaries( r )
            w_ss = summar(r, weights=weights)
                
            if match(r"age.*",string(k)) != nothing # an age of some kind - convert to 10 year intervals
                r = 10 * (r .÷ 10) # 10 year ages
            end
            u_cm = sort(countmap( r ))
            w_cm = sort(countmap( r ), weights=weights)
        elseif et <: AbstractFloat
            u_ss = summarystats( r )
            w_ss = summarystats(r, weights=weights)
            u_hist = hist
            println( "Float")
        elseif et <: Enum 
            println( "Enum")
        else
            println( "unmatched $k")
        end
        typeof(a) <: Enum
    end
end

function initialise(; 
    wealth_method = no_method, 
    indirect_method = no_method, 
    weighing_strategy = use_runtime_computed_weights,
    included_data_years = [],
    lower_multiple = 0.15,
    upper_multiple = 7.0 )::Tuple
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    settings = Settings()
    settings.indirect_method = indirect_method
    settings.do_legal_aid = false
    settings.wealth_method = wealth_method
    settings.use_shs = true
    settings.weighting_strategy = use_runtime_computed_weights
    settings.lower_multiple = lower_multiple
    settings.upper_multiple = upper_multiple
    settings.included_data_years = included_data_years # [2019,2020,2022] # match Essex
    nhhs, npeople, nhhs2 = FRSHouseholdGetter.initialise( settings; reset=true )
    settings, sys, nhhs
end 

included_data_years = [2019,2021,2022]
# dup load but hard to avoid..
dataset_artifact = get_data_artifact( Settings() )
hhs = HouseholdFromFrame.read_hh( 
    joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
people = HouseholdFromFrame.read_pers( 
    joinpath( dataset_artifact, "people.tab"))

settings, sys, nhhs = initialise( included_data_years=included_data_years, lower_multiple=0.15, upper_multiple=9)

people = people[ people.data_year .∈ ( included_data_years, ) , :]
hhs = hhs[ hhs.data_year .∈ ( included_data_years, ) , :]
interframe = make_intermed_dataframe( settings, 
    sys, 
    nhhs )
phhs = leftjoin( hhs, people, on=[:hid,:data_year], makeunique=true)
# won't work phhs = leftjoin( hpps, people, on=[:hid,:data_year], makeunique=true)

sum( interframe.num_people)

# settings, sys, nhhs = initialise() #  included_data_years=[2019,2020,2022], lower_multiple=0.15, upper_multiple=8.2)