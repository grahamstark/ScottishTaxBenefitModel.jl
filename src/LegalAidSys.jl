module LegalAidCalculations
using ScottishTaxBenefitModel
using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person
using .Definitions
using .STBParameters:
    LegalAidSys,
    ScottishLegalAidSys
using .Results:
    HouseholdResult,
    LegalAidResult,
    OneLegalAidResult


"""
Calculated solely at the HH level 
"""
function do_legal_aid_calc!(     
    household_result :: HouseholdResult{T},
    household        :: Household{T},
    intermed         :: HHIntermed{T} ) where T
    hr = household_result # alias
    civla = hr.legalaid.civil # alias

    

    for pid,p in household.people


    end




end

end