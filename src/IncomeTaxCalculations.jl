module IncomeTaxCalculations

using Dates
using Dates: Date, now, TimeType, Year
using Parameters: @with_kw

using ScottishTaxBenefitModel

using .Definitions

using .ModelHousehold: 
    Person

using .STBParameters: 
    IncomeTaxSys

using .GeneralTaxComponents: 
    RateBands, 
    TaxResult, 
    calctaxdue, 
    delete_thresholds_up_to
    # , *

using .Utils: 
    get_if_set

using .Incomes

using .Results: 
    BenefitUnitResult,
    IndividualResult, 
    ITResult

export 
    apply_allowance,
    calc_income_tax!, 
    calculate_company_car_charge,
    old_enough_for_mca

## FIXME just use the dict..
function guess_car_percentage_2020_21( sys :: IncomeTaxSys, company_car_fuel_type :: Fuel_Type )
    return sys.company_car_charge_by_CO2_emissions[company_car_fuel_type]
end

function calculate_company_car_charge(
    pers   :: Person,
    sys    :: IncomeTaxSys,
    calculator :: Function = guess_car_percentage_2020_21 ) :: Real
    value = max(0.0, pers.company_car_value-
        pers.company_car_contribution )
    if pers.fuel_supplied > 0.0
        value += sys.fuel_imputation
    end
    prop = calculator( sys, pers.company_car_fuel_type )
    value * prop
end

"""
Very rough approximation to MCA age - ignores all months since we don't have that in a typical dataset
TODO maybe overload this with age as a Date?
"""
function old_enough_for_mca(
    sys            :: IncomeTaxSys,
    age            :: Integer,
    model_run_date :: TimeType = now() ) :: Bool
    (model_run_date - Year(age)) < sys.mca_date
end

function calculate_allowance( pers::Person, sys :: IncomeTaxSys ) :: Real
    allowance = sys.personal_allowance
    if pers.registered_blind
        allowance += sys.blind_persons_allowance
    end
    allowance
end

function apply_allowance( allowance::Real, income::Real )::Tuple where RT<:Real
    r = max( 0.0, income - allowance )
    allowance = max(0.0, allowance-income)
    allowance,r
end

"""
  from Melville, ch13.
  Changes are in itres: add to pension fields and extend bands
  notes:
  Melville talks of "earned income" - using non-savings income
  FIXME: check: does the personal_allowance_income_limit get bumped up?
"""
function calculate_pension_taxation!(
    itres  ::ITResult,
    sys    :: IncomeTaxSys,
    pers   ::Person,
    total_income::Real,
    earned_income:: Real )

    itres.savings_thresholds = copy( sys.savings_thresholds )
    itres.dividend_thresholds = copy( sys.dividend_thresholds )
    itres.non_savings_thresholds = copy( sys.non_savings_thresholds )
    # fixme check avs here
    # FIXME use the incomes array & constants here
    avc = get_if_set(pers.income, avcs, 0.0)
    pen = get_if_set(pers.income, pension_contributions_employee, 0.0)
    pen += get_if_set(pers.income, pension_contributions_employer, 0.0)
    eligible_contribs = avc + pen
    if eligible_contribs <= 0.0
        return
    end

    max_relief = sys.pension_contrib_annual_allowance
    if total_income < sys.pension_contrib_basic_amount
        max_relief = sys.pension_contrib_basic_amount
    end
    if total_income > sys.pension_contrib_threshold_income
        excess = total_income - sys.pension_contrib_threshold_income
        max_relief = max( sys.pension_contrib_annual_minimum,
            sys.pension_contrib_annual_allowance - excess*sys.pension_contrib_withdrawal_rate )
    end
    eligible_contribs = min( eligible_contribs, max_relief );
    itres.pension_eligible_for_relief = eligible_contribs
    basic_rate = sys.non_savings_rates[ sys.non_savings_basic_rate ]
    # println("total_income=$total_income max_relief=$max_relief eligible_contribs=$eligible_contribs basic_rate=$basic_rate sys.pension_contrib_withdrawal_rate=$(sys.pension_contrib_withdrawal_rate)")
    gross_contribs = eligible_contribs/(1-basic_rate)
    itres.pension_relief_at_source = gross_contribs - eligible_contribs
    itres.non_savings_thresholds .+= gross_contribs
    itres.savings_thresholds .+= gross_contribs
    itres.dividend_thresholds .+= gross_contribs

end

"""

Complete(??) income tax calculation, based on the Scottish/UK 2019 system.
Mostly taken from Melville (2019) chs 2-4.

FIXME this is too long and needs broken up.

problems:

1. we do this in strict non-savings, savings, dividends order; see 2(11) for examples where it's now advantageous to use a different order
2.


"""
function calc_income_tax!(
    pres   :: IndividualResult,
    pers   :: Person,
    sys    :: IncomeTaxSys,
    spouse_transfer :: Real = 0.0 )

    total_income = isum( pres.income, sys.all_taxable )
    non_savings_income = isum( pres.income, sys.non_savings_income )
    savings_income = isum( pres.income, sys.savings_income )
    dividends_income = isum( pres.income, sys.dividend_income )

    allowance = calculate_allowance( pers, sys )
    # allowance reductions goes here

    adjusted_net_income = total_income

    calculate_pension_taxation!( pres.it, sys, pers, total_income, non_savings_income )

    # adjusted_net_income -= pres.it.pension_eligible_for_relief

    adjusted_net_income += calculate_company_car_charge(pers, sys)
    # ...

    non_savings_tax = TaxResult(0.0, 0)
    savings_tax = TaxResult(0.0, 0)
    dividend_tax = TaxResult(0.0, 0)

    if adjusted_net_income > sys.personal_allowance_income_limit
        allowance =
            max(0.0,
                allowance -
                    sys.personal_allowance_withdrawal_rate*(
                        adjusted_net_income - sys.personal_allowance_income_limit ))
    end
    taxable_income = adjusted_net_income-allowance
    # note: we copy from the expanded versions from pension_contributions
    savings_thresholds = deepcopy( pres.it.savings_thresholds )
    savings_rates = deepcopy( sys.savings_rates )
    # FIXME model all this with parameters
    toprate = size( savings_thresholds )[1]
    non_savings_taxable = 0.0
    savings_taxable = 0.0
    dividends_taxable = 0.0
    
    if taxable_income > 0
        allowance,non_savings_taxable = apply_allowance( allowance, non_savings_income )
        non_savings_tax = calctaxdue(
            taxable=non_savings_taxable,
            rates=sys.non_savings_rates,
            thresholds=pres.it.non_savings_thresholds )

        # horrific savings calculation see Melville Ch2 "Savings Income" & examples 2-3
        # FIXME Move to separate function
        # delete the starting bands up to non_savings taxabke icome
        savings_rates, savings_thresholds = delete_thresholds_up_to(
            rates=savings_rates,
            thresholds=savings_thresholds,
            upto=non_savings_taxable );
        if sys.personal_savings_allowance > 0
            psa = sys.personal_savings_allowance
            # println( "taxable income $taxable_income sys.savings_thresholds[2] $(sys.savings_thresholds[2])")
            if taxable_income > sys.savings_thresholds[toprate]
                psa = 0.0
            elseif taxable_income > sys.savings_thresholds[2] # above the basic rate
                psa *= 0.5 # FIXME parameterise this
            end
            if psa > 0.0 ## if we haven't deleted the zero band already, just widen it
                if savings_rates[1] == 0.0
                    savings_thresholds[1] += psa;
                else ## otherwise, insert a  new one.
                    savings_thresholds = vcat([psa], savings_thresholds )
                    savings_rates = vcat([0.0], savings_rates )
                end
            end
            pres.it.personal_savings_allowance = psa
        end # we have a personal_savings_allowance
        pres.it.savings_rates = savings_rates
        pres.it.savings_thresholds= savings_thresholds
        allowance,savings_taxable = apply_allowance( allowance, savings_income )
        savings_tax = calctaxdue(
            taxable=savings_taxable,
            rates=savings_rates,
            thresholds=savings_thresholds )

        # Dividends
        # see around example 8-9 ch2
        allowance,dividends_taxable =
            apply_allowance( allowance, dividends_income )
        dividend_rates=deepcopy(sys.dividend_rates)
        dividend_thresholds=deepcopy(pres.it.dividend_thresholds )
        # always preserve any bottom zero rate
        add_back_zero_band = false
        zero_band = 0.0
        used_thresholds = non_savings_taxable+savings_taxable
        copy_start = 1
        # handle the zero rate
        if dividend_rates[1] == 0.0
            add_back_zero_band = true
            zero_band = dividend_thresholds[1]
            used_thresholds += min( zero_band, dividends_taxable )
            copy_start = 2
        end
        dividend_rates, dividend_thresholds =
            delete_thresholds_up_to(
                rates=dividend_rates[copy_start:end],
                thresholds=dividend_thresholds[copy_start:end],
                upto=used_thresholds );
        if add_back_zero_band
            dividend_rates = vcat( [0.0], dividend_rates )
            dividend_thresholds .+= zero_band # push all up
            dividend_thresholds = vcat( zero_band, dividend_thresholds )
        end
        pres.it.dividend_rates = dividend_rates
        pres.it.dividend_thresholds= dividend_thresholds
        
        dividend_tax = calctaxdue(
            taxable=dividends_taxable,
            rates=dividend_rates,
            thresholds=dividend_thresholds )
    else # some allowance left
        allowance = -taxable_income # e.g. allowance - taxable_income
    end
   
    #
    # tax reducers
    #
    total_tax = non_savings_tax.due+savings_tax.due+dividend_tax.due
    if spouse_transfer > 0
        sp_reduction =
            sys.non_savings_rates[sys.non_savings_basic_rate]*spouse_transfer
        total_tax = max( 0.0, total_tax - sp_reduction )
    end
    pres.income[INCOME_TAX] = total_tax
    pres.it.taxable_income = taxable_income
    pres.it.allowance = allowance
    pres.it.total_income = total_income
    pres.it.adjusted_net_income = adjusted_net_income
    
    pres.it.non_savings_tax = non_savings_tax.due
    pres.it.non_savings_income = non_savings_income
    pres.it.non_savings_band = non_savings_tax.end_band
    pres.it.non_savings_taxable = non_savings_taxable
    
    pres.it.savings_tax = savings_tax.due
    pres.it.savings_band = savings_tax.end_band
    pres.it.savings_income = savings_income
    pres.it.savings_taxable = savings_taxable
    
    pres.it.dividends_tax = dividend_tax.due
    pres.it.dividend_band = dividend_tax.end_band
    pres.it.dividends_income = dividends_income
    pres.it.dividends_taxable = dividends_taxable
    
    pres.it.unused_allowance = allowance
end

function allowed_to_transfer_allowance(
    sys  :: IncomeTaxSys;
    from :: ITResult,
    to   :: ITResult ) :: Bool

    can_transfer :: Bool = true
    if ! (from.unused_allowance > 0.0 &&
        to.unused_allowance <= 0.0)
         # nothing to transfer - this is actually wrong since
         # you can opt to transfer some allowance even if you
         # can technically use it.
        can_transfer = false
    elseif to.savings_band > sys.savings_basic_rate ||
        to.non_savings_band > sys.non_savings_basic_rate ||
        to.dividend_band > sys.dividend_basic_rate
        can_transfer = false
    end
    ## TODO disallow if mca claimed
    can_transfer
end # can_transfer


function calculate_mca( 
    pers :: Person, 
    tax :: ITResult, 
    sys :: IncomeTaxSys)::Real
    ## FIXME parameterise this
    mca = sys.married_couples_allowance
    if tax.adjusted_net_income > sys.mca_income_maximum
        mca = max( sys.mca_minimum, mca -
           (tax.adjusted_net_income-sys.mca_income_maximum)*sys.mca_withdrawal_rate)
    end
    mca * sys.mca_credit_rate
end

"""
 FIXME maybe send an actual benefit unit in here? With kids..
"""
function calc_income_tax!(
    bres   :: BenefitUnitResult,
    head   :: Person,
    spouse :: Union{Nothing, Person},
    sys    :: IncomeTaxSys )
    hdres = bres.pers[head.pid]
    calc_income_tax!( hdres, head, sys )
    # FIXME the transferable stuff here
    # is not quite right as you can elect to transfer more than
    # the surplus allowance in some cases.
    # also - add in restrictions on transferring to
    # higher rate payers.
    if spouse !== nothing
        spres = bres.pers[spouse.pid]
        calc_income_tax!( spres, spouse, sys )
        # This is not quite right - you can't claim the
        # MCA AND transfer an allowance. We're assuming
        # always MCA first (I think it's always more valuable?)
        if old_enough_for_mca( sys, head.age ) || old_enough_for_mca( sys, spouse.age )
            # shoud usually just go to the head but.. some stuff about partner
            # with greater income if married after 2005 and you can elect to do this if
            # married before, so:
            if hdres.it.adjusted_net_income > spres.it.adjusted_net_income
                hdres.it.mca = calculate_mca( head, hdres.it, sys )
                hdres.income[INCOME_TAX]= max( 0.0, hdres.income[INCOME_TAX]- hdres.it.mca )
            else
                spres.it.mca = calculate_mca( spouse, spres.it, sys )
                spres.income[INCOME_TAX] = max( 0.0, spres.income[INCOME_TAX] - spres.it.mca )
            end
        end
        if spres.it.mca == 0.0 == hdres.it.mca
            if allowed_to_transfer_allowance( sys, from=spres.it, to=hdres.it )
                transferable_allow = min( spres.it.unused_allowance, sys.marriage_allowance )
                calc_income_tax!( hdres, head, sys, transferable_allow )
                hdres.it.transferred_allowance = transferable_allow
            elseif allowed_to_transfer_allowance( sys, from=hdres.it, to=spres.it )
                transferable_allow = min( hdres.it.unused_allowance, sys.marriage_allowance )
                calc_income_tax!( spres, spouse, sys, transferable_allow )
                spres.it.transferred_allowance = transferable_allow
            end
        end
    end
end # calc_income_tax

end # module