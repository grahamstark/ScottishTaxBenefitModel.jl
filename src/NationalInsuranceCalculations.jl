module NationalInsuranceCalculations

using BudgetConstraints #: BudgetConstraint, get_x_from_y
import Dates
import Dates: Date, now, TimeType, Year
import Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
import .ModelHousehold: Person
import .STBParameters: NationalInsuranceSys
import .GeneralTaxComponents: TaxResult, calctaxdue, RateBands, *
import .Utils: get_if_set

export calculate_national_insurance, calc_class1_secondary

@with_kw mutable struct NIResult
    above_lower_earnings_limit :: Bool = false
    total_ni :: Real = 0.0
    class_1_primary    :: Real = 0.0
    class_1_secondary  :: Real = 0.0
    class_2   :: Real = 0.0
    class_3   :: Real = 0.0
    class_4   :: Real = 0.0
    assumed_gross_wage :: Real = 0.0
end

function calc_class1_secondary( gross :: Real, pers::Person, sys :: NationalInsuranceSys ) :: Real
    rates = copy( sys.secondary_class_1_rates )
    # FIXME parameterise this
    if pers.age <= 21 # or  age <= 25 and apprentice
        rates[2] = 0.0
    end
    tres = calctaxdue(
        taxable = pers.income[wages],
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
    return makebc( data, make_one_net )
end


function calculate_national_insurance( pers::Person, sys :: NationalInsuranceSys ) :: NIResult
    nires = NIResult()

    # employer's NI on any wages
    bc = make_gross_wage_bc( pers, sys )
    gross = gross_from_net( bc, pers.income[wages])
    nires.class_1_secondary = calc_class1_secondary( gross, pers, sys )
    @assert (gross-nires.class_1_secondary) ≈ pers.income[wages]
    nires.assumed_gross_wage = gross

    # class 1 on any wages, se only on main ..
    if pers.age < sys.state_pension_age
        tres = calctaxdue(
            taxable = pers.income[wages],
            rates = sys.primary_class_1_rates,
            thresholds = sys.primary_class_1_bands )
        nires.class_1_primary = tres.due
        nires.above_lower_earnings_limit = tres.end_band > 1

        if( pers.employment_status in [Full_time_Self_Employed, Part_time_Self_Employed])
           # maybe? pers.principal_employment_type != An_Employee
           # FIXME do I need *any* check on whether someone is classed as SE, & not just se income present?
            if pers.income[self_employment_income] > sys.class_2_threshold
                nires.class_2 = sys.class_2_rate
            end
            nires.class_4 = calctaxdue(
                taxable = pers.income[self_employment_income],
                rates = sys.class_4_rates,
                thresholds = sys.class_4_bands ).due
        end # self emp
    end


    # do something random for class 3

    # don't count employers NI here
    nires.total_ni = nires.class_1_primary +
        nires.class_2 +
        nires.class_4

    return nires
end

function gross_from_net( bc :: BudgetConstraint, net :: Real )::Real
    return get_x_from_y( bc, net )
end

end # module
