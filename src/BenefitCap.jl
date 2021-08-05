module BenefitCap


using ScottishTaxBenefitModel

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person

using .STBParameters: 
    BenefitCapSys

using .Definitions

export cap_benefits!

function cap_benefits!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit     :: BenefitUnit,
    intermed         :: MTIntermediate,
    caps             :: BenefitCapSys
    route            :: LegacyOrUC )



end

end