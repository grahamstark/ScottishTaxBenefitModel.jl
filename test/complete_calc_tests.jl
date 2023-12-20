using Test
using Dates: Date

using ScottishTaxBenefitModel

using .STBIncomes
using .ModelHousehold:
    Household,
    Person,
    People_Dict,
    default_bu_allocation,
    get_benefit_units
    
using .ExampleHouseholdGetter

using .Definitions

using .STBParameters:
    TaxBenefitSystem,
    NationalInsuranceSys,
    IncomeTaxSys
    
using .SingleHouseholdCalculations:do_one_calc

using .Results:
    IndividualResult,
    BenefitUnitResult,
    HouseholdResult,
    init_household_result,
    to_string

using .GeneralTaxComponents: 
    RateBands, 
    WEEKS_PER_YEAR

using .RunSettings: Settings

using .ExampleHelpers

function hh_to_hhr_mismatch( hh :: Household, hhr :: HouseholdResult ) :: Bool
    bus = get_benefit_units( hh )
    if length(hhr.bus) != size( bus )[1]
        return true
    end
    buno = 1
    for bu in bus
        if length(hhr.bus[buno].pers) == length(bu.people)
            return true
        end
        buno += 1
    end
    false
end

init_data()

# examples from https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/812844/Income_Tax_Liabilities_Statistics_June_2019.pdf
# table 2
@testset "Reproduce HMRC 2019/20" begin
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    println( "council $(hh.council)" )
    
    hhr = init_household_result( hh )
    @test hh_to_hhr_mismatch( hh, hhr )

    sys = [get_system(year=2019, scotland=false), get_system( year=2019, scotland=true )]
    sys[1].minwage.abolished = true # wage_per_hour .= 0.0 # stop minimum wages messing up wages here
    sys[2].minwage.abolished = true # .wage_per_hour .= 0.0 # stop minimum wages messing up wages here
    wage = [50_000.0, 40_000, 10_000,16_500]./WEEKS_PER_YEAR
    savings = [0.0, 3_000, 10_000,3_000]./WEEKS_PER_YEAR
    divs = [0.0, 5_000, 0.0, 0.0]./WEEKS_PER_YEAR
    liabilities = [7_500,6_125,300,1_000]./WEEKS_PER_YEAR
    for i in 1:4
        hh.people[ RUK_PERSON ].income[wages] = wage[i]
        hh.people[ RUK_PERSON ].income[bank_interest] = savings[i]
        hh.people[ RUK_PERSON ].income[stocks_shares] = divs[i]
        println( "council $(hh.council)" )
        hres = ScottishTaxBenefitModel.SingleHouseholdCalculations.do_one_calc( hh, sys[1] )
        hres_scot = ScottishTaxBenefitModel.SingleHouseholdCalculations.do_one_calc( hh, sys[2] )
        if i == 1
            @test round(hres_scot.bus[1].pers[RUK_PERSON].income[INCOME_TAX]*WEEKS_PER_YEAR) ≈ 9_044
        end
        @test hres.bus[1].pers[RUK_PERSON].income[INCOME_TAX] ≈ liabilities[i]
    end
end

@testset "Diagnose frs households" begin
    sys = get_system( year=2019, scotland=true )
    target_hids = [1500]
    for hhno in target_hids
        hh = FRSHouseholdGetter.get_household( hhno )
        hres = do_one_calc( hh, sys )
        println(to_string( hres ))
    end    
end



