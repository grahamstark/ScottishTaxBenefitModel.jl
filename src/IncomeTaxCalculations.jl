module IncomeTaxCalculations

import Dates
import Dates: Date, now, TimeType, Year
import Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
import .ModelHousehold: Person
import .STBParameters: IncomeTaxSys
import .GeneralTaxComponents: TaxResult, calctaxdue, RateBands, delete_thresholds_up_to, *

export calc_income_tax, old_enough_for_mca, apply_allowance, ITResult
export calculate_company_car_charge

@with_kw mutable struct ITResult
    total_tax :: Real = 0.0
    taxable_income :: Real = 0.0
    adjusted_net_income :: Real = 0.0
    total_income :: Real = 0.0
    non_savings :: Real = 0.0
    allowance   :: Real = 0.0
    non_savings_band :: Integer = 0
    savings :: Real = 0.0
    savings_band :: Integer = 0
    dividends :: Real = 0.0
    dividend_band :: Integer = 0
    unused_allowance :: Real = 0.0
    mca :: Real = 0.0
    transferred_allowance :: Real = 0.0
    pension_eligible_for_relief :: Real = 0.0
    pension_relief_at_source :: Real = 0.0
    modified_bands :: Vector{Real}(undef,0) = []
end

## FIXME all these constants should ultimately be parameters
const MCA_DATE = Date(1935,4,6) # fixme make this a parameter

const SAVINGS_INCOME = Incomes_Dict(
    bank_interest => 1.0,
    bonds_and_gilts => 1.0,
    other_investment_income => 1.0
)

const DIVIDEND_INCOME = Incomes_Dict(
    stocks_shares => 1.0
)
const Exempt_Income = Incomes_Dict(
    individual_savings_account=>1.0,
    local_taxes=>1.0,
    free_school_meals => 1.0,
    dlaself_care => 1.0,
    dlamobility => 1.0,
    child_benefit => 1.0,
    pension_credit => 1.0,
    bereavement_allowance_or_widowed_parents_allowance_or_bereavement=> 1.0,
    armed_forces_compensation_scheme => 1.0, # FIXME not in my list check this
    war_widows_or_widowers_pension => 1.0,
    severe_disability_allowance => 1.0,
    attendence_allowance => 1.0,
    industrial_injury_disablement_benefit => 1.0,
    employment_and_support_allowance => 1.0,
    incapacity_benefit => 1.0,## taxable after 29 weeks,
    income_support => 1.0,
    maternity_allowance => 1.0,
    maternity_grant_from_social_fund => 1.0,
    funeral_grant_from_social_fund => 1.0,
    guardians_allowance => 1.0,
    winter_fuel_payments => 1.0,
    dwp_third_party_payments_is_or_pc => 1.0,
    dwp_third_party_payments_jsa_or_esa => 1.0,
    extended_hb => 1.0,
    working_tax_credit => 1.0,
    child_tax_credit => 1.0,
    working_tax_credit_lump_sum => 1.0,
    child_tax_credit_lump_sum => 1.0,
    housing_benefit => 1.0,
    universal_credit => 1.0,
    personal_independence_payment_daily_living => 1.0,
    personal_independence_payment_mobility => 1.0 )

function make_all_taxable()::Incomes_Dict
    eis = union(Set( keys( Exempt_Income )), Definitions.Expenses )
    all_t = Incomes_Dict()
    for i in instances(Incomes_Type)
        if ! (i ∈ eis )
            all_t[i]=1.0
        end
    end
    all_t
end

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

# TODO pension contributions

function make_non_savings()::Incomes_Dict
    excl = union(Set(keys(DIVIDEND_INCOME)), Set( keys(SAVINGS_INCOME)))
    nsi = make_all_taxable()
    for i in excl
        delete!( nsi, i )
    end
    nsi
end

const NON_SAVINGS_INCOME = make_non_savings()
const ALL_TAXABLE = make_all_taxable()


"""
Very rough approximation to MCA age - ignores all months since we don't have that in a typical dataset
TODO maybe overload this with age as a Date?
"""
function old_enough_for_mca(
    age            :: Integer,
    model_run_date :: TimeType = now() ) :: Bool
    (model_run_date - Year(age)) < MCA_DATE
end

function calculate_allowance( pers::Person, sys :: IncomeTaxSys ) :: Real
    allowance = sys.personal_allowance
    if pers.registered_blind
        allowance += sys.blind_persons_allowance
    end
    allowance
end

function apply_allowance( allowance::Real, income::Real )::Tuple
    r = max( 0.0, income - allowance )
    allowance = max(0.0, allowance-income)
    allowance,r
end

"""

Complete(??) income tax calculation, based on the Scottish/UK 2019 system.
Mostly taken from Melville (2019) chs 2-4.

FIXME this is too long and needs broken up.

problems:

1. we do this in strict non-savings, savings, dividends order; see 2(11) for examples where it's now advantageous to use a different order
2.

returns a single total tax liabilty, plus multiple intermediate numbers
in the `intermediate` dict

"""
function calc_income_tax(
    pers   :: Person,
    sys    :: IncomeTaxSys,
    intermediate :: Dict,
    spouse_transfer :: Real = 0.0 ) :: ITResult
    itres :: ITResult = ITResult()
    total_income = ALL_TAXABLE*pers.income;
    non_savings = NON_SAVINGS_INCOME*pers.income;
    savings = SAVINGS_INCOME*pers.income;
    dividends = DIVIDEND_INCOME*pers.income;
    allowance = calculate_allowance( pers, sys )
    # allowance reductions goes here

    non_dividends = non_savings + savings

    adjusted_net_income = total_income
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
    intermediate["allowance"]=allowance
    intermediate["total_income"]=total_income
    intermediate["adjusted_net_income"]=adjusted_net_income
    intermediate["taxable_income"]=taxable_income
    intermediate["savings"]=savings
    intermediate["non_savings"]=non_savings
    intermediate["dividends"]=dividends

    savings_thresholds = deepcopy( sys.savings_thresholds )
    savings_rates = deepcopy( sys.savings_rates )
    # FIXME model all this with parameters
    toprate = size( savings_thresholds )[1]
    if taxable_income > 0
        allowance,non_savings_taxable = apply_allowance( allowance, non_savings )
        non_savings_tax = calctaxdue(
            taxable=non_savings_taxable,
            rates=sys.non_savings_rates,
            thresholds=sys.non_savings_thresholds )

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
            intermediate["personal_savings_allowance"] = psa
        end # we have a personal_savings_allowance
        intermediate["savings_rates"] = savings_rates
        intermediate["savings_thresholds"] = savings_thresholds
        allowance,savings_taxable = apply_allowance( allowance, savings )
        savings_tax = calctaxdue(
            taxable=savings_taxable,
            rates=savings_rates,
            thresholds=savings_thresholds )

        # Dividends
        # see around example 8-9 ch2
        allowance,dividends_taxable =
            apply_allowance( allowance, dividends )
        dividend_rates=deepcopy(sys.dividend_rates)
        dividend_thresholds=deepcopy(sys.dividend_thresholds )
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
        intermediate["dividend_rates"]=dividend_rates
        intermediate["dividend_thresholds"]=dividend_thresholds
        intermediate["add_back_zero_band"]=add_back_zero_band
        intermediate["dividends_taxable"]=dividends_taxable

        dividend_tax = calctaxdue(
            taxable=dividends_taxable,
            rates=dividend_rates,
            thresholds=dividend_thresholds )
    else # some allowance left
        allowance = -taxable_income # e.g. allowance - taxable_income
    end
    intermediate["non_savings_tax"]=non_savings_tax.due
    intermediate["savings_tax"]=savings_tax.due
    intermediate["dividend_tax"]=dividend_tax.due

    #
    # tax reducers
    #
    total_tax = non_savings_tax.due+savings_tax.due+dividend_tax.due
    if spouse_transfer > 0
        sp_reduction =
            sys.non_savings_rates[sys.non_savings_basic_rate]*spouse_transfer
        total_tax = max( 0.0, total_tax - sp_reduction )
    end
    itres.total_tax = total_tax
    itres.taxable_income = taxable_income
    itres.allowance = allowance
    itres.total_income = total_income
    itres.adjusted_net_income = adjusted_net_income
    itres.non_savings = non_savings_tax.due
    itres.non_savings_band = non_savings_tax.end_band
    itres.savings = savings_tax.due
    itres.savings_band = savings_tax.end_band
    itres.dividends = dividend_tax.due
    itres.dividend_band = dividend_tax.end_band
    itres.unused_allowance = allowance
    itres
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


function calculate_mca( pers :: Person, tax :: ITResult, sys :: IncomeTaxSys)::Real
    ## FIXME parameterise this
    mca = sys.married_couples_allowance
    if tax.adjusted_net_income > sys.mca_income_maximum
        mca = max( sys.mca_minimum, mca -
           (tax.adjusted_net_income-sys.mca_income_maximum)*sys.mca_withdrawal_rate)
    end
    mca * sys.mca_credit_rate
end

function calc_income_tax(
    head   :: Person,
    spouse :: Union{Nothing,Person},
    sys    :: IncomeTaxSys,
    intermediate :: Dict ) :: NamedTuple
    head_intermed = Dict()
    headtax = calc_income_tax( head, sys, head_intermed )
    intermediate["head_tax"] = head_intermed
    spousetax = nothing
    # FIXME the transferable stuff here
    # is not right as you can elect to transfer more than
    # the surplus allowance in some cases.
    # also - add in restrictions on transferring to
    # higher rate payers.
    if spouse != nothing
        spouse_intermed = Dict()
        intermediate["spouse_tax"] = spouse_intermed
        spousetax = calc_income_tax( spouse, sys, spouse_intermed )
        # This is not quite right - you can't claim the
        # MCA AND transfer an allowance. We're assuming
        # always MCA first (I think it's always more valuable?)
        if old_enough_for_mca( head.age ) || old_enough_for_mca( spouse.age )
            # shoud usually just go to the head but.. some stuff about partner
            # with greater income if married after 2005 and you can elect to do this if
            # married before, so:
            if headtax.adjusted_net_income > spousetax.adjusted_net_income
                headtax.mca = calculate_mca( head, headtax, sys )
                headtax.total_tax = max( 0.0, headtax.total_tax - headtax.mca )
            else
                spousetax.mca = calculate_mca( spouse, spousetax, sys )
                spousetax.total_tax = max( 0.0, spousetax.total_tax - spousetax.mca )
            end
        end
        if spousetax.mca == 0.0 == headtax.mca
            if allowed_to_transfer_allowance( sys, from=spousetax, to=headtax )
                transferable_allow = min( spousetax.unused_allowance, sys.marriage_allowance )
                headtax = calc_income_tax( head, sys, head_intermed, transferable_allow )
                intermediate["transfer_spouse_to_head"] = transferable_allow
            elseif allowed_to_transfer_allowance( sys, from=headtax, to=spousetax )
                transferable_allow = min( headtax.unused_allowance, sys.marriage_allowance )
                spousetax = calc_income_tax( spouse, sys, spouse_intermed, transferable_allow )
                intermediate["transfer_head_to_spouse"] = transferable_allow
            end
        end
    end
    ( head=headtax, spouse=spousetax )
end # calc_income_tax

end # module
