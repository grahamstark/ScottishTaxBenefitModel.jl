using Test
using ScottishTaxBenefitModel
import ScottishTaxBenefitModel.ModelHousehold: Household, Person, People_Dict, default_bu_allocation
# import FRSHouseholdGetter
import ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.Definitions
import Dates: Date
using ScottishTaxBenefitModel.NationalInsuranceCalculations
import ScottishTaxBenefitModel.STBParameters: NationalInsuranceSys,weeklyise!

const RUK_PERSON = 100000001001
const SCOT_HEAD = 100000001002
const SCOT_SPOUSE = 100000001003


@testset "Melville 2019 ch16 examples 1; Class 1 NI" begin
    # BASIC IT Calcaulation on
    nisys = NationalInsuranceSys()
    weeklyise!( nisys )
    @time names = ExampleHouseholdGetter.initialise()
    income = [110.0,145.0,325,755.0,1_000.0]
    nidue = [(0.0,false),(0.0,true),(19.08,true),(70.68,true),(96.28,true)]
    niclass1sec = [0.0,0.0,21.94,81.28,115.09]
    ntests = size(income)[1]
    @test ntests == size( nidue )[1]
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers.age = 50
    pers = hh.people[RUK_PERSON]
    for i in 1:ntests
        pers.income[wages] = income[i]
        println( "case $i income = $(income[i])")
        nires = calculate_national_insurance( pers, nisys )
        class1sec = calc_class1_secondary( income[i], pers, nisys )
        @test nires.class_1_primary ≈ nidue[i][1]
        @test nires.above_lower_earnings_limit == nidue[i][2]
        @test round(class1sec,digits=2) ≈ niclass1sec[i]
        print( nires )
    end
    # self employment testing
    pers.employment_status = Full_time_Self_Employed
    seinc = [6_280.0, 7_200.0]
    class2 = [0.0,3.0]
    nisys.class_2_threshold *= WEEKS_PER_YEAR
    nisys.class_4_bands *= WEEKS_PER_YEAR
    for i in 1:size(seinc)[1]
        pers.income[self_employment_income] = seinc[i]
        println( "case $i seinc = $(seinc[i])")
        nires = calculate_national_insurance( pers, nisys )
        @test nires.class_2 ≈ class2[i]
    end
    seinc = [15_140.0, 55_000.0,7_500.0]
    class4 = [585.72, 3_823.12, 0.0 ]
    for i in 1:size(seinc)[1]
        pers.income[self_employment_income] = seinc[i]
        println( "case $i seinc = $(seinc[i])")
        nires = calculate_national_insurance( pers, nisys )
        @test nires.class_4 ≈ class4[i]
    end

end # example 1
