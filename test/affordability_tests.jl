using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, default_bu_allocation

using .ExampleHouseholdGetter
using .Definitions
using .STBIncomes
using .NationalInsuranceCalculations: 
    calculate_national_insurance!,
    calc_class1_secondary

using .STBParameters: NationalInsuranceSys,weeklyise!
using .FRSHouseholdGetter: get_household
using .Results: IndividualResult, map_incomes
using .ExampleHelpers
using .RunSettings: Settings
using .Affordability


@testset "Affordability Tests" begin
    
end