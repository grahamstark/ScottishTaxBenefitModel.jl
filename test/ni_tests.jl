using Test
using ScottishTaxBenefitModel
import ScottishTaxBenefitModel.ModelHousehold: Household, Person, People_Dict, default_bu_allocation
# import FRSHouseholdGetter
import ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.Definitions
import Dates: Date
using ScottishTaxBenefitModel.NationalInsuranceCalculations
import ScottishTaxBenefitModel.STBParameters: NationalInsuranceSys

const RUK_PERSON = 100000001001
const SCOT_HEAD = 100000001002
const SCOT_SPOUSE = 100000001003


@testset "Melville 2019 ch16 examples 1; Class 1 NI" begin
    # BASIC IT Calcaulation on
    nisys = NationalInsuranceSys()
    @time names = ExampleHouseholdGetter.initialise()
    income = [11_730,14_493,30_000,33_150.0,58_600,231_400]
    ntests = size(income)[1]
    for i in 1:ntests-1
        income[i] += itsys_scot.personal_allowance # weird way this is expessed in Melville
    end
    nidue = [2_346.0,2898.60,6_000,6_630.0,15_940.00,89_130.0]
    @test size( income ) == size( taxes_ruk) == size( taxes_scotland )
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    for i in size(income)[1]
        pers.income[wages] = income[i]
        println( "case $i income = $(income[i])")
        due = calc_class_1_primary( pers, itsys_ruk ).total_tax
        @test due == nidue[i]
    end
end # example 1
