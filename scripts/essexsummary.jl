using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .HouseholdFromFrame
using .RunSettings
using .STBParameters

using CSV,DataFrames,StatsBase

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
        someone_pension_age  = zeros( Bool, nobs ),
        someone_pension_age_2016 = zeros( Bool, nobs ),
        all_pension_age = zeros( Bool, nobs ),
        someone_working_ft  = zeros( Bool , nobs ),
        #
        someone_working_ft_and_25_plus = zeros( Bool, nobs ),
        
        num_not_working = zeros( Int, nobs ),
        num_working_ft = zeros( Int, nobs ),
        num_working_pt = zeros( Int , nobs ),
        num_working_24_plus = zeros( Int , nobs ),
        num_working_16_or_less = zeros( Int, nobs ),
        total_hours_worked = zeros( Int, nobs ),
        someone_is_carer = zeros( Bool , nobs ),
        num_carers = zeros( Int, nobs ),
        
        is_sparent  = zeros( Bool , nobs ),
        is_sing  = zeros( Bool # FIXME RENAME: is_single, nobs ),
        is_disabled = zeros( Bool, nobs ),
        
        num_disabled_adults = zeros( Int, nobs ),
        num_disabled_children = zeros( Int, nobs ),
        num_severely_disabled_adults = zeros( Int, nobs ),
        num_severely_disabled_children = zeros( Int, nobs ),
    
        num_job_seekers = zeros( Int, nobs ),
        
        num_children = zeros( Int, nobs ),
        num_allowed_children = zeros( Int, nobs ),
        num_children_born_before = zeros( Int, nobs ),
        ge_16_u_pension_age  = zeros( Bool , nobs ),
        limited_capacity_for_work  = zeros( Bool , nobs ),
        has_children  = zeros( Bool , nobs ),
        economically_active = zeros( Bool, nobs ),
        working_disabled = zeros( Bool, nobs ),
        num_benefit_units = zeros( Int, nobs ),
        nation = zeros( Nation , nobs ),
        all_student_bu = zeros( Bool, nobs ),
    
        net_physical_wealth = zeros( RT, nobs ),
        net_financial_wealth = zeros( RT, nobs ),
        net_housing_wealth = zeros( RT, nobs ),
        net_pension_wealth = zeros( RT, nobs ),
        total_value_of_other_property = zeros( RT, nobs ))    
    i = 0
    for hno in
        hh = FRSHouseholdGetter.get_household( hh )
        intermed = make_intermediate( 
            RT,
            settings,
            hh, 
            sys.hours_limits, 
            sys.age_limits, 
            sys.child_limits )
        for int in intermed.buint
            i += 1
            row = df[ i, : ]
            row.hid = hh.hid
            row.data_year = hh.data_year
            row.weight = hh.weight


            
        end
    end 
    return df[1:i,:]
end

"""
reload data from a mapped household back into an original dataframe
"""
function writeback!( hhdata :: DataFrame, persdata::DataFrame, hh :: ModelHousehold )
    hhrow = hhdata[ (hhdata.hid .== hh.hid) .& ( hhdata.data_year .== hh.data_year ), :]
    @assert size(hhrow)[1] == 1
    hhrow = hhrow[1,:]
    hhrow.weight = hh.weight
    water_and_sewerage ::RT
    mortgage_payment::RT
    mortgage_interest::RT
    gross_rent::RT # rentg Gross rent including Housing Benefit  or rent Net amount of last rent payment
    total_wealth::RT
    house_value::RT
    net_physical_wealth :: RT
    net_financial_wealth :: RT
    net_housing_wealth :: RT
    net_pension_wealth :: RT
    original_gross_income :: RT
    original_income_decile :: Int
    equiv_original_income_decile :: Int

    for (pid,pers) in hh.people
        for i in instances(Incomes_Type)
            ikey = make_sym_for_frame("income", i)
            if model_person[ikey] != 0.0
                income[i] = model_person[ikey]
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
