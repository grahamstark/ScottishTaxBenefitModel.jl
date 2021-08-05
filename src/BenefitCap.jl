module BenefitCap


using ScottishTaxBenefitModel

using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person

using .STBParameters: 
    BenefitCapSys

using Definitions

export cap_benefits!

function cap_benefits!( 
    
    route :: LegacyOrUC
)

end

end