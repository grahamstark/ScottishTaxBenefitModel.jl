module ScottishBenefits

using ScottishTaxBenefitModel
using .ModelHousehold: 
    BenefitUnit,
    Household, 
    Person,
    get_head,
    get_spouse
    search,
    count

using .STBParameters: 
    ScottishChildPayment

using .STBIncomes
using .Definitions

using .Intermediate 
using .Results: BenefitUnitResult, has_any

export calc_scottish_child_payment!

function calc_scottish_child_payment!( 
    benefit_unit_result :: BenefitUnitResult,
    benefit_unit        :: BenefitUnit,
    intermed            :: MTIntermediate,
    scpsys              :: ScottishChildPayment )
    scp = 0.0
    bu = benefit_unit
    bur = benefit_unit_result # shortcuts 
    nkids = search( bu, le_age, scpsys.maximum_age )   
    if( nkids > 0 ) && has_any( bu, scpsys.qualifying_benefits... )
        scp = nkids * scpsys.amount
        spouse = get_spouse( bu )
        target_pid = BigInt(-1)
        if spouse === nothing
            target_pid = get_head( bu ).pid
        else 
            target_pid = spouse.pid
        end
        bur.pers[target_pid].income[SCOTTISH_CHILD_PAYMENT] = scp
    end
end


end