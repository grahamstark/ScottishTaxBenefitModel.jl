module BasicIncomes
"""

Might as well do this while we're at it.
A very basic basic income; based roughly on 

Painter, Anthony, Jamie Cooke, and Ahmed Aima. 2019. ‘A Basic Income for Scotland’. Royal Society for the encouragement of Arts, Manufactures and Commerce. https://www.thersa.org/globalassets/pdfs/rsa-a-basic-income-for-scotland.pdf.



"""
using ScottishTaxBenefitModel
using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,
    get_benefit_units
    
using .STBParameters: 
    UBISys

using .STBIncomes
using .Definitions

using .Results: BenefitUnitResult, HouseholdResult

export calc_UBI!


function calc_UBI!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit        :: BenefitUnit,
    ubisys              :: UBISys )
    scp = 0.0
    bu = benefit_unit
    bur = benefit_unit_result # shortcuts 
    for (pid,pers) in bu.people
        if pers.age < ubisys.adult_age 
            bi = ubisys.child_amount
        elseif pers.age < ubisys.retirement_age
            bi = ubisys.adult_amount
        else
            bi = ubisys.universal_pension
        end
        bur.pers[pid].income[BASIC_INCOME] = bi
     end
end

function calc_UBI( 
    household_result :: HouseholdResult,
    hh               :: Household,
    ubisys           :: UBISys )
    if ubisys.abolished
        return
    end
    bus = get_benefit_units( hh )
    for bn in eachindex( bus )
        calc_UBI!(
            household_result.bus[bn],
            bu,
            ubisys
        )
    end
end


end