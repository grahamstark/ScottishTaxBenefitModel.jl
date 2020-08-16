module LegacyMeansTestedBenefits

using Parameters: @with_kw

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold: Person,BenefitUnit,Household
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules, 
    Premia, PersonalAllowances
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands
using .Results: BenefitUnitResult, HouseholdResult, IndividualResult
using .Utils: mult

export calc_legacy_means_tested_benefits, LMTResults

@with_kw mutable struct LMTResults{RT<:Real}
    esa :: RT = zero(RT)
    hb  :: RT = zero(RT)
    is :: RT = zero(RT)
    jsa :: RT = zero(RT)
    pc  :: RT = zero(RT)
    ndds :: RT = zero(RT)
    wtc  :: RT = zero(RT)
    ctc  :: RT = zero(RT)
    intermediate :: Dict = Dict()
end

@with_kw struct LMTIncomes{RT<:Real}
    gross_earnings :: RT
    net_earnings   :: RT
    total_income   :: RT
end

function calc_incomes( 
    bu :: BenefitUnit, 
    bur :: BenefitUnitResult, 
    sys :: IncomeRules ) :: LMTIncomes 
    T = typeof( sys.permitted_work )
    gross = zero(T)
    net = zero(T)
    total = zero(T)
    return LMTIncomes{T}(gross,net,total)
end

function calc_credits()

end

function calc_ESA()

end

function calc_HB()

end

function calc_JSA()

end

function calc_PC()

end

function calc_CTC()

end

function calc_NDDS()

end

function calc_LHA()

end

function calc_WTC()

end

function calc_legacy_means_tested_benefits(
    pers   :: Person,
    sys    :: LegacyMeansTestedBenefitSystem ) :: LMTResults

end

end # module LegacyMeansTestedBenefits
