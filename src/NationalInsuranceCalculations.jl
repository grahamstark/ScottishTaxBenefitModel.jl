module NationalInsuranceCalculations
#
# This module calculates National Insurance for an individual.
# It's based mainly on the descriptions and examples in the excellent Melville's Taxation:
# Melville, Alan. 2019. Melville’s Taxation: Finance Act 2019. 25th ed. London. (and 2020 edition).
#
using BudgetConstraints #: BudgetConstraint, get_x_from_y
using Dates
using Dates: Date, now, TimeType, Year
using Parameters: @with_kw

using ScottishTaxBenefitModel
using .STBIncomes
using .Definitions
using .ModelHousehold: Person
using .STBParameters: NationalInsuranceSys
using .GeneralTaxComponents: 
    RateBands, 
    TaxResult, 
    *,
    calctaxdue;

using .Utils: 
    BC_SETTINGS, 
    eq_nearest_p,
    get_if_set
    
using .Results: 
    IndividualResult,
    NIResult
    
export 
    calc_class1_secondary,
    calculate_national_insurance!

function calc_class1_secondary( gross :: Real, pers::Person, sys :: NationalInsuranceSys ) :: Real
    rates = copy( sys.secondary_class_1_rates )
    # FIXME parameterise this
    if pers.age <= 21 # or  age <= 25 and apprentice
        rates[2] = 0.0
    end
    tres = calctaxdue(
        taxable = gross, # get(pers.income,wages, 0.0)
        rates = rates,
        thresholds = sys.secondary_class_1_bands )
    tres.due
    ## TODO apprentiships
end

function make_one_net( data :: Dict, gross :: Real ) :: Real
    pers = data[:pers]
    sys  = data[:sys]
    # pers.income[wage] = gross
    ni = calc_class1_secondary( gross, pers, sys )
    return gross - ni
end

function make_gross_wage_bc( pers :: Person, sys :: NationalInsuranceSys ) :: BudgetConstraint
    data = Dict(
        :pers=>pers,
        :sys=>sys
    )
    return makebc( data, make_one_net, Utils.BC_SETTINGS)
end

"""
FIXME pass in AgeLimits record 
"""
function calculate_national_insurance!( 
    pres :: IndividualResult,
    pers :: Person, 
    sys  :: NationalInsuranceSys )
    # employer's NI on any wages
    if pers.age < 16 || sys.abolished # must be 16+
        return
    end
    bc = make_gross_wage_bc( pers, sys )
    wage = isum( 
        pres.income, 
        sys.class_1_income )
    
    wage = max(0.0, wage)
    gross = gross_from_net( bc, wage )
    pres.ni.class_1_secondary = calc_class1_secondary( gross, pers, sys )
    @assert isapprox(gross - wage, pres.ni.class_1_secondary, atol=3 ) "gross $gross wage $wage pres.ni.class_1_secondary $(pres.ni.class_1_secondary)"
    pres.ni.assumed_gross_wage = gross

    # class 1 on any wages, se only on main ..
    if pers.age < sys.state_pension_age # FIXME pass in the age limit thing
        tres = calctaxdue(
            taxable = wage,
            rates = sys.primary_class_1_rates,
            thresholds = sys.primary_class_1_bands )
        pres.ni.class_1_primary = tres.due
        pres.ni.above_lower_earnings_limit = tres.end_band > 1

        if( pers.employment_status in [Full_time_Self_Employed, Part_time_Self_Employed])
            seinc = isum( 
                pres.income, 
                sys.class_4_income )
            # maybe? pers.principal_employment_type != An_Employee
            # FIXME do I need *any* check on whether someone is classed as SE, & not just se income present?
            if seinc > sys.class_2_threshold
                pres.ni.class_2 = sys.class_2_rate
            end
            pres.ni.class_4 = calctaxdue(
                taxable = seinc,
                rates = sys.class_4_rates,
                thresholds = sys.class_4_bands ).due
        end # self emp
    end


    # do something random for class 3

    # don't count employers NI here
    pres.income[NATIONAL_INSURANCE] = 
        pres.ni.class_1_primary +
        pres.ni.class_2 +
        pres.ni.class_4

 end

function gross_from_net( bc :: BudgetConstraint, net :: Real )::Real
    return get_x_from_y( bc, net )
end

end # module
