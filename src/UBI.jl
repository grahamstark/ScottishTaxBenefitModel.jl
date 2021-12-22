module UBI
#=
Might as well do this while we're at it.
A very basic basic income; based roughly on 

Painter, Anthony, Jamie Cooke, and Ahmed Aima. 2019. ‘A Basic Income for Scotland’. Royal Society for the encouragement of Arts, Manufactures and Commerce. https://www.thersa.org/globalassets/pdfs/rsa-a-basic-income-for-scotland.pdf.
=#

using ScottishTaxBenefitModel
using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,
    get_benefit_units
    
using .STBParameters: 
    UBISys,
    TaxBenefitSystem

using .STBIncomes
using .Definitions

using .Results: BenefitUnitResult, HouseholdResult

export 
    calc_UBI!, 
    make_ubi_post_adjustments!

function make_ubi_post_adjustments!( 
    hres   :: HouseholdResult,
    ubisys :: UBISys )
    for bn in eachindex( hres.bus )
        bres = household_result.bus[bn]
        if ubisys.mt_bens_treatment == ub_keep_housing
            # TODO add assertions that things are correctly turned off
            if bres.uc.recipient > 0
                uc = bres.pers[bres.uc.recipient].income[UNIVERSAL_CREDIT]
                uc = min( uc, bres.uc.housing_element )
                bres.pers[bres.uc.recipient].income[UNIVERSAL_CREDIT] = uc
            end
            #
            # I think these have to be left on so we can do hb passporting
            # so we set them to zero ex post
            for (pid,pers) in bres.pers
                pers.income[INCOME_SUPPORT] = 0.0
                pers.income[NON_CONTRIB_JOBSEEKERS_ALLOWANCE] = 0.0
                pers.income[NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE] = 0.0
            end
        end
    end
end

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

function calc_UBI!( 
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
            bus[bn],
            ubisys
        )
    end
end

end # module