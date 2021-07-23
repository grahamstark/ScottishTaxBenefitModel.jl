using Test
using ScottishTaxBenefitModel.Uprating
using DataFrames
using ScottishTaxBenefitModel.ModelHousehold
using ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.FRSHouseholdGetter
using ScottishTaxBenefitModel.Definitions

prfr = Uprating.load_prices()

print( prfr )

@time thesenames = ExampleHouseholdGetter.initialise()

## NOTE this test has the 2019 OBR data and 2019Q4 as a target jammed on - will need
## changing with update versions

@testset "uprating tests" begin
    hh = ExampleHouseholdGetter.get_household( "mel_c2_scot" )
    hh.quarter = 1
    hh.interview_year = 2008
    pers = hh.people[SCOT_HEAD]
    # average index 2008 q1=100; 2019 Q4 = 125.9812039916
    pers.income[wages] = 100.0
    uprate!( hh )
    @test pers.income[wages] ≈ 125.9812039916 # 2019q4 av wages index
end
