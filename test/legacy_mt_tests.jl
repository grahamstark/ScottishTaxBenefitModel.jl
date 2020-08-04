using Test
using ScottishTaxBenefitModel
import ScottishTaxBenefitModel.ModelHousehold: Household, Person, People_Dict, default_bu_allocation
# import FRSHouseholdGetter
import ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.Definitions
using ScottishTaxBenefitModel.NationalInsuranceCalculations
import ScottishTaxBenefitModel.STBParameters: NationalInsuranceSys,weeklyise!
import .GeneralTaxComponents: WEEKS_PER_YEAR

const RUK_PERSON = 100000001001


@testset "CPAG" begin
    # BASIC IT Calcaulation on

    @time names = ExampleHouseholdGetter.initialise()
    income = [110.0,145.0,325,755.0,1_000.0]

    ntests = size(income)[1]
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = hh.people[RUK_PERSON]
    pers.age = 50
    for i in 1:ntests
        pers.income[wages] = income[i]
        

    end
end # t1
