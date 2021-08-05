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
    region           :: Standard_Region
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit     :: BenefitUnit,
    intermed         :: MTIntermediate,
    caps             :: BenefitCapSys
    route            :: LegacyOrUC )

    cap = intermed.num_people == 1 ? 
        caps.outside_london_single :
        outside_london_couple
    if region == London
        cap = intermed.num_people == 1 ? 
            caps.inside_london_single :
            inside_london_couple
    end
    totbens = 0.0
    if route == legacy_bens
        if totbens > cap

        end    
    else
        if totbens > cap

        end    
    end
end

end