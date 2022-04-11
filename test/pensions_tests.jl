using Test

using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, default_bu_allocation
using .Pensions: impute_employer_pension!
using .Definitions

@testset "Employer's Pension Imputation" begin

    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    cpl= get_example( cpl_w_2_children_hh )
    head = get_head( cpl )

    @test head.employment_status == Full_time_Employee
    @test get(head.income,pension_contributions_employer,0.0) == 0.0
    head.income[wages] = 1_000;
    impute_employer_pension!( head )    
    @test head.income[wages]*0.3 > head.income[pension_contributions_employer]
    

end

@testset "Pension correction test on full dataset" begin
    settings = DEFAULT_SETTINGS
    nhhs,npeople = init_data( reset = true, settings )
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )

    for hno in 1:nhhs
                

    end
end
