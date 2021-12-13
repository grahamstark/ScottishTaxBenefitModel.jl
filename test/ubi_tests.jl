using Test
using ScottishTaxBenefitModel
using .ModelHousehold: count,Household, le_age, ge_age
using .Results: aggregate!, init_household_result
using .Intermediate: MTIntermediate, make_intermediate    
using .UBI: calc_UBI!
using .STBIncomes
using .ExampleHelpers

sys = get_system( scotland=true )
sys.ubi.abolished = false

@testset "Basic UBI Tests" begin
    
    for (hht,hh) in get_all_examples()
        hres = init_household_result( hh )

        calc_UBI!(
            hres,
            hh,
            sys.ubi
        )
        aggregate!( hh, hres )
        numkids = ModelHousehold.count( hh, le_age, sys.ubi.adult_age-1 )
        numpens = ModelHousehold.count( hh, ge_age, sys.ubi.retirement_age)
        numpeeps = length( hh.people )[1]
        numads = numpeeps - numpens - numkids
        ubit = numkids*sys.ubi.child_amount+
            numads*sys.ubi.adult_amount+
            numpens*sys.ubi.universal_pension
        @test hres.income[BASIC_INCOME] ≈ ubit
        println( "$hht : adults=$numads pens=$numpens child=$numkids => ubi=$ubit")
    end

    # todo make_ubi_pre_adjustments
    # toto make_ubi_post_adjustments

end

@testset "UBI Pre Adjustments" begin
    sys = get_system( scotland = true )
    sys.ubi.abolished = false
    UBI.make_ubi_pre_adjustments!( sys )
    
    @assert sys.uc.abolished == false
    @assert sys.lmt.savings_credit.abolished == false
    @assert sys.lmt.ctr.abolished == false
    @assert sys.lmt.hb.abolished == false
    @assert sys.lmt.working_tax_credit.abolished == false
    @assert sys.lmt.child_tax_credit.abolished == false

    sys.ubi..mt_bens_treatment =  ub_keep_housing



end
