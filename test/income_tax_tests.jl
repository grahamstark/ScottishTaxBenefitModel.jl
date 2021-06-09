using Test
using ScottishTaxBenefitModel
using .ModelHousehold:
    Household,
    Person,
    People_Dict,
    PeopleArray,
    default_bu_allocation,
    get_benefit_units,
    get_head,
    get_spouse,
    num_people,
    make_benefit_unit

using .ExampleHouseholdGetter
using .Definitions
using Dates: Date
using .IncomeTaxCalculations: old_enough_for_mca, apply_allowance, calc_income_tax!
using .STBParameters: IncomeTaxSys
using .Results: 
    init_household_result,
    IndividualResult, 
    BenefitUnitResult, 
    ITResult, 
    NIResult

function get_tax(; scotland = false ) :: IncomeTaxSys
    it = get_default_it_system( year=2019, scotland=scotland, weekly=false )
    it.non_savings_rates ./= 100.0
    it.savings_rates ./= 100.0
    it.dividend_rates ./= 100.0
    it.personal_allowance_withdrawal_rate /= 100.0
    it.mca_credit_rate /= 100.0
    it.mca_withdrawal_rate /= 100.0
    it.pension_contrib_withdrawal_rate /= 100.0

    it
end


@testset "Melville 2019 ch2 examples 1; basic calc Scotland vs RUK" begin
    # BASIC IT Calcaulation on
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )

    @time names = ExampleHouseholdGetter.initialise()
    income = [11_730,14_493,30_000,33_150.0,58_600,231_400]
    ntests = size(income)[1]
    for i in 1:ntests-1
        income[i] += itsys_scot.personal_allowance # weird way this is expessed in Melville
    end
    taxes_ruk = [2_346.0,2898.60,6_000,6_630.0,15_940.00,89_130.0]
    taxes_scotland = [2_325.51,2_898.60,6_155.07, 7260.57,17_695.07,92_613.07]
    @test size( income ) == size( taxes_ruk) == size( taxes_scotland )
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    scottish = ExampleHouseholdGetter.get_household( "mel_c2_scot" )

    bus = default_bu_allocation( scottish )
    nbus = size(bus)[1]
    println( bus )
    # @test nbus == 1 == size( bus[1])[1]
    pers = bus[1][1]
    for i in 1:ntests
        prsc = IndividualResult{Float64}()
        prsc.income[WAGES] = income[i]
        calc_income_tax!( prsc, pers, itsys_scot )
        println( "Scotland $i : calculated $(prsc.income[INCOME_TAX]) expected $(taxes_scotland[i])")
        @test prsc.income[INCOME_TAX] ≈ taxes_scotland[i]
        pruk = IndividualResult{Float64}()
        calc_income_tax!( pruk, pers, itsys_ruk )
        println( "rUK $i : calculated $(prsc.income[INCOME_TAX]) expected $(taxes_ruk[i])")
        @test pruk.income[INCOME_TAX]  ≈ taxes_ruk[i]
        println( ruk.people[RUK_PERSON].income )
    end
end # example 1

@testset "Melville 2019 ch2 example 2; personal savings allowance" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    scottish = ExampleHouseholdGetter.get_household( "mel_c2_scot" )
    income = [20_000,37_501,64_000,375_000.0]
    psa = [1_000.0,500.0,500.0,0.0]
    @test size( income ) == size( psa ) # same Scotland and RUK
    pers = ruk.people[RUK_PERSON] # doesn't matter S/RUK

    for i in size(income)[1]
        pruk = IndividualResult{Float64}()
        pruk.income[WAGES] = income[i]
        println( "case $i income = $(income[i])")
        calc_income_tax!( pruk, pers, itsys_ruk )
        @test pruk.it.personal_savings_allowance == psa[i]
    end
end # example 2

@testset "ch2 example 3; savings calc" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    tax_due_scotland = 5680.07
    pruk = IndividualResult{Float64}()
    pruk.income[SELF_EMPLOYMENT_INCOME] = 40_000.00
    pruk.income[BANK_INTEREST] = 1_250.00
    prsc = IndividualResult{Float64}()
    prsc.income[SELF_EMPLOYMENT_INCOME] = 40_000.00
    prsc.income[BANK_INTEREST] = 1_250.00

    calc_income_tax!( prsc, pers, itsys_scot )
    #
    @test prsc.income[INCOME_TAX] ≈ tax_due_scotland

    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )
    #
    tax_due_ruk = 5_550.00
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk
end # example 3

@testset "ch2 example 4; savings calc" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )

    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    tax_due_ruk = 840.00
    tax_due_scotland = 819.51
    prsc = IndividualResult{Float64}()
    prsc.income[PROPERTY] = 16_700.00
    prsc.income[BANK_INTEREST] = 1_100.00
    calc_income_tax!( prsc, pers, itsys_scot )
    @test prsc.income[INCOME_TAX] ≈ tax_due_scotland
    pruk = IndividualResult{Float64}()
    pruk.income[PROPERTY] = 16_700.00
    pruk.income[BANK_INTEREST] = 1_100.00

    calc_income_tax!( pruk, pers, itsys_ruk )
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk
end # example 4

@testset "ch2 example 5; savings calc" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    tax_due_ruk = 11_232.00
    tax_due_scotland = 12_864.57
    prsc = IndividualResult{Float64}()
    prsc.income[SELF_EMPLOYMENT_INCOME] = 58_850.00
    prsc.income[BANK_INTEREST] = 980.00
    calc_income_tax!( prsc, pers, itsys_scot )
    @test prsc.income[INCOME_TAX] ≈ tax_due_scotland
    pruk = IndividualResult{Float64}()
    pruk.income[SELF_EMPLOYMENT_INCOME] = 58_850.00
    pruk.income[BANK_INTEREST] = 980.00

    calc_income_tax!( pruk, pers, itsys_ruk )
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk
end # example 5

@testset "ch2 example 6; savings calc" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    pers.income[self_employment_income] = 240_235.00
    pers.income[bank_interest] = 1_600.00

    tax_due_ruk = 93_825.75
    tax_due_scotland = 97_397.17
    prsc = IndividualResult{Float64}()
    calc_income_tax!( prsc, pers, itsys_scot )
    @test prsc.income[INCOME_TAX]  ≈ tax_due_scotland
    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )
    @test pruk.income[INCOME_TAX]  ≈ tax_due_ruk
end # example 6

@testset "ch2 example 7; savings calc" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    pers.income[self_employment_income] = 10_000.00
    pers.income[bank_interest] = 3_380.00
    pers.income[other_investment_income] = 36_680.00/0.8 # gross up at basic
    tax_due_ruk = 10_092.00 # inc already deducted at source
    tax_due_scotland = 10_092.00
    
    prsc = IndividualResult{Float64}()
    calc_income_tax!( prsc, pers, itsys_scot )
    @test prsc.income[INCOME_TAX] ≈ tax_due_ruk
    
    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk

end # example 7

#
# stocks_shares
#

@testset "ch2 example 8; simple stocks_shares" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    pers.income[property] = 28_590.00
    pers.income[bank_interest] = 1_050.00
    pers.income[stocks_shares] = 204_100.0 # gross up at basic
    tax_due_ruk = 74_834.94 # inc already deducted at source
    tax_due_scotland = 74_834.94+140.97

    prsc = IndividualResult{Float64}()
    calc_income_tax!( prsc, pers, itsys_scot )
    @test prsc.income[INCOME_TAX] ≈ tax_due_scotland
    
    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk

end # example 8

@testset "ch2 example 9; simple stocks_shares" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    pers.income[private_pensions] = 17_750.00
    pers.income[bank_interest] = 195.00
    pers.income[stocks_shares] = 1_600.0 # gross up at basic
    tax_due_ruk = 1_050.00 # inc already deducted at source
    tax_due_scotland = 1_050.00-20.49
    prsc = IndividualResult{Float64}()
    calc_income_tax!( prsc, pers, itsys_scot )
    @test prsc.income[INCOME_TAX] ≈ tax_due_scotland

    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk
end # example 9


@testset "ch3 personal allowances ex 1 - hr allowance withdrawal" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )

    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    pers.income[self_employment_income] = 110_520.00
    tax_due_ruk = 33_812.00
    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )

    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk
    pers.income[self_employment_income] += 100.0
    pruk = IndividualResult{Float64}()
    calc_income_tax!( pruk, pers, itsys_ruk )
    tax_due_ruk = 33_812.00+60.0
    @test pruk.income[INCOME_TAX] ≈ tax_due_ruk

    # tax_due_scotland = 33_812.00+61.5 ## FIXME actually, check this by hand

end # example1 ch3

@testset "ch3 personal allowances ex 2 - marriage allowance" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )

    names = ExampleHouseholdGetter.initialise()
    scot = ExampleHouseholdGetter.get_household( "mel_c2_scot" ) # scots are a married couple
    head = scot.people[SCOT_HEAD]
    spouse = scot.people[SCOT_SPOUSE]
    head.income[self_employment_income] = 11_290.0
    head_tax_due = 0.0
    spouse.income[self_employment_income] = 20_000.0
    spouse_tax_due_ruk = 1_258.0
    bu = make_benefit_unit( PeopleArray([head,spouse]), head.pid, spouse.pid ) 
    bruk = init_benefit_unit_result( bu )
    calc_income_tax!( bruk, head, spouse, itsys_ruk )
    println( bruk )
    @test bruk.pers[spouse.pid].income[INCOME_TAX] ≈ spouse_tax_due_ruk
end # example 2 ch3

@testset "ch3 blind person" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )

    names = ExampleHouseholdGetter.initialise()
    ruk = ExampleHouseholdGetter.get_household( "mel_c2" )
    pers = ruk.people[RUK_PERSON]
    pers.registered_blind = true
    bu = make_benefit_unit( PeopleArray([pers]), pers.pid, BigInt(-1) ) 
    bruk = init_benefit_unit_result( bu )    
    result = calc_income_tax!( bruk, pers, nothing, itsys_ruk )
    @test bruk.pers[pers.pid].it.allowance ≈ 
        itsys_ruk.personal_allowance + itsys_ruk.blind_persons_allowance
    # test that tax is 2450xmr
end

@testset "ch3 tax reducers" begin
    # check that mca is always 10% of amount
    # check marriage transfer is always basic rate tax credit
    # checl MCA only available if 1 spouse born before 6th April  1935
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )

    names = ExampleHouseholdGetter.initialise()
    scot = ExampleHouseholdGetter.get_household( "mel_c2_scot" ) # scots are a married couple
    head = scot.people[SCOT_HEAD]
    spouse = scot.people[SCOT_SPOUSE]
    bu = make_benefit_unit( PeopleArray([head,spouse]), head.pid, spouse.pid ) 
    head_ages = [75,90,90,70] # after 1935
    spouse_ages = [90,70,70,90]
    head_incomes = [19_100.0, 29_710.0,41_080.0,0.0]
    spouse_incomes = [12_450.0,0,13_950.0,49_300.0]
    for i in 1:4
        head.income[private_pensions] = head_incomes[i]
        spouse.income[private_pensions] = spouse_incomes[i]
        # head.income[private_pension] = head_incomes[i]
        head.age = head_ages[i]
        spouse.age = spouse_ages[i]
        bruk = init_benefit_unit_result( bu )    
        brscot = init_benefit_unit_result( bu )    
        calc_income_tax!( bruk, head, spouse, itsys_ruk )
        calc_income_tax!( brscot, head, spouse, itsys_scot )
        if i == 1
            @test bruk.pers[head.pid].it.mca ≈ 891.50 ≈ 
                brscot.pers[head.pid].it.mca
            @test bruk.pers[spouse.pid].it.mca ≈ 0.0 ≈ 
                brscot.pers[spouse.pid].it.mca
        elseif i == 2
            @test bruk.pers[head.pid].it.mca ≈ 886.00 ≈ 
                brscot.pers[head.pid].it.mca
            @test bruk.pers[spouse.pid].it.mca ≈ 0.0 ≈ 
                brscot.pers[spouse.pid].it.mca
        elseif i == 3
            @test bruk.pers[head.pid].it.mca ≈ 345.00 ≈ 
                brscot.pers[head.pid].it.mca
            @test bruk.pers[spouse.pid].it.mca ≈ 0.0 ≈ 
                brscot.pers[spouse.pid].it.mca
        elseif i == 4
            @test bruk.pers[head.pid].it.mca ≈ 0.0 ≈ 
                brscot.pers[head.pid].it.mca
            @test bruk.pers[spouse.pid].it.mca ≈ 345.0 ≈ 
                brscot.pers[spouse.pid].it.mca
        end
    end
end

## TODO car tax; pension contributions

@testset "pension contributions tax relief standard case:  - Melville ch14 example 2(b)" begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    scot = ExampleHouseholdGetter.get_household( "mel_c2_scot" ) # scots are a married couple
    alana = scot.people[SCOT_HEAD]
    alana.income = Incomes_Dict{Float64}() # clear
    alana.income[self_employment_income] = 62_000.0
    alana.income[pension_contributions_employee] = (400.00*12)*0.8 # net contribs per month; expressed gross in example

    bu = make_benefit_unit( PeopleArray([alana]), alana.pid, BigInt(-1)) 
    bruk = init_benefit_unit_result( bu )    
    brscot = init_benefit_unit_result( bu )    

    calc_income_tax!( bruk, alana, nothing, itsys_ruk );
    calc_income_tax!( brscot, alana, nothing, itsys_scot );
    @test bruk.pers[alana.pid].it.pension_relief_at_source ≈ 960.0
    @test bruk.pers[alana.pid].it.pension_eligible_for_relief ≈ 400.0*12*0.8
    @test brscot.pers[alana.pid].it.non_savings_thresholds[1] ≈ itsys_scot.non_savings_thresholds[1]+400.0*12
    @test brscot.pers[alana.pid].it.non_savings_thresholds[2] ≈ itsys_scot.non_savings_thresholds[2]+400.0*12
    @test brscot.pers[alana.pid].it.pension_relief_at_source ≈ 960.0
    @test brscot.pers[alana.pid].it.pension_eligible_for_relief ≈ 400.0*12*0.8

end

@testset "pension: Tax Relief Minima - Melville ch14 ex1(a)"  begin
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    names = ExampleHouseholdGetter.initialise()
    scot = ExampleHouseholdGetter.get_household( "mel_c2_scot" ) # scots are a married couple
    gordon = scot.people[SCOT_HEAD]
    gordon.income = Incomes_Dict{Float64}() # clear
    gordon.income[self_employment_income] = 27_800.0
    gordon.income[pension_contributions_employee] =  27_800.00 # net contribs per month; expressed gross in example
    bu = make_benefit_unit( PeopleArray([gordon]),gordon.pid, BigInt(-1)) 
    bruk = init_benefit_unit_result( bu )  
    brscot = init_benefit_unit_result( bu )
    calc_income_tax!( bruk, gordon, nothing, itsys_ruk )
    calc_income_tax!( brscot, gordon, nothing, itsys_scot )
    @test bruk.pers[gordon.pid].it.pension_eligible_for_relief ≈ 27_800.0
    @test brscot.pers[gordon.pid].it.pension_eligible_for_relief ≈ 27_800.0
    gordon.income[self_employment_income] = 2_500.0
    gordon.income[pension_contributions_employee] =  27_800.00 # net contribs per month; expressed gross in example
    bruk = init_benefit_unit_result( bu )  
    brscot = init_benefit_unit_result( bu )
    calc_income_tax!( bruk, gordon, nothing, itsys_ruk )
    calc_income_tax!( brscot, gordon, nothing, itsys_scot )
    @test bruk.pers[gordon.pid].it.pension_eligible_for_relief ≈ 3_600.0
    @test brscot.pers[gordon.pid].it.pension_eligible_for_relief ≈ 3_600.0
end

#
# no actual example for this and I'm not 100% sure this
#is exactly how it works, but should be near enough.
#
@testset "pension: Tax Relief Annual Allowance Charge"  begin
    itsys_ruk :: IncomeTaxSys = get_tax( scotland = false )
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    names = ExampleHouseholdGetter.initialise()
    scot = ExampleHouseholdGetter.get_household( "mel_c2_scot" ) # scots are a married couple
    gordon = scot.people[SCOT_HEAD]
    gordon.income = Incomes_Dict{Float64}() # clear
    gordon.income[self_employment_income] = 60_000.0
    gordon.income[pension_contributions_employer] =  50_000.00 # net contribs per month; expressed gross in example
    bu = make_benefit_unit( PeopleArray([gordon]),gordon.pid, BigInt(-1)) 
    bruk = init_benefit_unit_result( bu )    
    brscot = init_benefit_unit_result( bu )    

    calc_income_tax!( bruk, gordon, nothing, itsys_ruk );
    @test bruk.pers[gordon.pid].it.pension_eligible_for_relief ≈ 40_000

    gordon.income[self_employment_income] = 300_000.0
    bruk = init_benefit_unit_result( bu )    
    calc_income_tax!( bruk, gordon, nothing, itsys_ruk );
    @test bruk.pers[gordon.pid].it.pension_eligible_for_relief ≈ 10_000

    gordon.income[self_employment_income] = 150_000.0
    bruk = init_benefit_unit_result( Float64, bu )    
    res_uk = calc_income_tax!( bruk, gordon, nothing, itsys_ruk );
    # tapering thing seems really weird - this is approximarely right
    @test bruk.pers[gordon.pid].it.pension_eligible_for_relief ≈ 40_000

    # complete-ish calc from combes, tutin&rowes, 2018 edn, p199, updated to 2019/20 rates
    bruk = init_benefit_unit_result( bu )    
    gordon.income[self_employment_income] = 180_000.0
    gordon.income[pension_contributions_employer] =  14_400.00 # net contribs per month; expressed gross in example
    calc_income_tax!( bruk, gordon, nothing, itsys_ruk );
    @test bruk.pers[gordon.pid].income[INCOME_TAX] ≈ 61_500.0

end

@testset "Crude MCA Age Check" begin
    # cut-off for jan 2010 should be age 85

    d = Date( 2020, 1, 28 )
    itsys :: IncomeTaxSys = get_tax( scotland = false )
    @test old_enough_for_mca( itsys, 85, d )
    @test ! old_enough_for_mca( itsys, 84, d )
    @test old_enough_for_mca( itsys, 86, d )
end

@testset "Apply Allowance" begin
    allowance = 10_000
    allowance,t1 = apply_allowance( allowance, 5_000 )
    @test t1 == 0
    @test allowance == 5_000
    allowance,t2 = apply_allowance( allowance, 4_000 )
    @test t2 == 0
    @test allowance == 1_000
    allowance,t3 = apply_allowance( allowance, 4_000 )
    @test t3 == 3_000
    @test allowance == 0
end


@testset "Run on actual Data" begin
    nhhs,npeople = init_data()
    itsys_scot :: IncomeTaxSys = get_tax( scotland = true )
    for hno in 1:nhhs
        hh = get_household(hno)
        println( "hhno $hno")
        bus = get_benefit_units( hh )
        for bu in bus
            # income tax, with some nonsense for
            # what remains of joint taxation..
            head = get_head( bu )
            spouse = get_spouse( bu )
            bures = init_benefit_unit_result( bu )
            calc_income_tax!(
                bures,
                head,
                spouse,
                itsys_scot )
            for chno in bu.children
                child = bu.people[chno]
                calc_income_tax!(
                    bures.pers[child.pid],
                    child,
                    itsys_scot )
            end  # child loop
        end # bus loop
    end # hhld loop
end #
