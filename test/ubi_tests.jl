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

end
