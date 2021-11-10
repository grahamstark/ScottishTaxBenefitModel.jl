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
using .GeneralTaxComponents: WEEKS_PER_YEAR
using .FRSHouseholdGetter: get_household
using .Results: IndividualResult, map_incomes
using .ExampleHelpers
using .RunSettings: Settings, DEFAULT_SETTINGS


@testset "Run on actual Data" begin
    nhhs,npeople = init_data()
    nisys = NationalInsuranceSys{Float64}()
    weeklyise!( nisys )
    hh = get_household(27)
    person =  hh.people[120150022701]
    println( person )
    pres = IndividualResult{Float64}()
    calculate_national_insurance!( pres, person, nisys )
    @test pres.ni.class_1_primary >= 0.0
    @test pres.ni.class_1_secondary >= 0.0

end


@testset "Run on actual Data" begin
    nhhs,npeople = init_data()
    nisys = NationalInsuranceSys{Float64}()
    weeklyise!( nisys )
    for hno in 1:nhhs
        hh = get_household(hno)
        for (pid,person) in hh.people
            println( "on hh $hno; pid=$pid")
            pres = IndividualResult{Float64}()
            pres.income = map_incomes( person )
            calculate_national_insurance!( pres, person, nisys )
            @test pres.ni.class_1_primary >= 0.0
            @test pres.ni.class_1_secondary >= 0.0
        end # people loop
    end # hhld loop
end #



@testset "Melville 2019 ch16 examples 1; Class 1 NI" begin
    # BASIC IT Calcaulation on
    nisys = NationalInsuranceSys{Float64}()
    weeklyise!( nisys )
    @time names = ExampleHouseholdGetter.initialise( DEFAULT_SETTINGS )
    income = [110.0,145.0,325,755.0,1_000.0]
    nidue = [(0.0,false),(0.0,true),(19.08,true),(70.68,true),(96.28,true)]
    niclass1sec = [0.0,0.0,21.94,81.28,115.09]
    ntests = size(income)[1]
    @test ntests == size( nidue )[1]
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = hh.people[RUK_PERSON]
    pers.age = 50
    for i in 1:ntests
        # pers.income[wages] = income[i]
        println( "case $i income = $(income[i])")
        pres = IndividualResult{Float64}()
        pres.income[WAGES] = income[i]
        calculate_national_insurance!( pres, pers, nisys )
        class1sec = calc_class1_secondary( income[i], pers, nisys )
        @test pres.ni.class_1_primary ≈ nidue[i][1]
        @test pres.ni.above_lower_earnings_limit == nidue[i][2]
        @test round(class1sec,digits=2) ≈ niclass1sec[i]
        print( pres.ni )
    end
end


@testset "Melville 2019 ch16 examples 6,7; Class 2,4 NI" begin
    # BASIC IT Calcaulation on
    nisys = NationalInsuranceSys{Float64}()
    weeklyise!( nisys )
    # self employment testing
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = hh.people[RUK_PERSON]
    pers.age = 50
    pers.employment_status = Full_time_Self_Employed
    seinc = [6_280.0, 7_200.0]
    class2 = [0.0,3.0]
    nisys.class_2_threshold *= WEEKS_PER_YEAR
    nisys.class_4_bands *= WEEKS_PER_YEAR
    for i in 1:size(seinc)[1]
        pres = IndividualResult{Float64}()
        pres.income[SELF_EMPLOYMENT_INCOME] = seinc[i]
        println( "case $i seinc = $(seinc[i])")
        calculate_national_insurance!( pres, pers, nisys )
        @test pres.ni.class_2 ≈ class2[i]
    end
    seinc = [15_140.0, 55_000.0,7_500.0]
    class4 = [585.72, 3_823.12, 0.0 ]
    for i in 1:size(seinc)[1]
        pres = IndividualResult{Float64}()
        pres.income[SELF_EMPLOYMENT_INCOME] = seinc[i]
        println( "case $i seinc = $(seinc[i])")
        calculate_national_insurance!( pres, pers, nisys )
        @test pres.ni.class_4 ≈ class4[i]
    end

end # example 6,7