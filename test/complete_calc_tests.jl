using Test
using ScottishTaxBenefitModel
import ScottishTaxBenefitModel.ModelHousehold:
    Household,
    Person,
    People_Dict,
    default_bu_allocation,
    get_benefit_units
# import FRSHouseholdGetter
import ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.Definitions
import Dates: Date
import ScottishTaxBenefitModel.STBParameters:
    TaxBenefitSystem,
    NationalInsuranceSys,
    IncomeTaxSys,
    get_default_it_system
import ScottishTaxBenefitModel.SingleHouseholdCalculations:do_one_calc
using ScottishTaxBenefitModel.Results:
    IndividualResult,
    BenefitUnitResult,
    HouseholdResult,
    init_household_result
using ScottishTaxBenefitModel.GeneralTaxComponents: RateBands, WEEKS_PER_YEAR
using ScottishTaxBenefitModel.SingleHouseholdCalculations: do_one_calc

include( "testutils.jl")

function get_system(; scotland = false ) :: TaxBenefitSystem
    tb = TaxBenefitSystem{Int,Float64}()
    println( tb.it )
    # overwrite IT to get RuK system as needed
    itn :: IncomeTaxSys{Int,Float64} = get_default_it_system( year=2019, scotland=scotland, weekly=true )
    println( itn )
    tb.it = itn
end

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

ExampleHouseholdGetter.initialise()

# examples from https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/812844/Income_Tax_Liabilities_Statistics_June_2019.pdf
# table 2
@testset "Reproduce HMRC 2019/20" begin
    hh = ExampleHouseholdGetter.get_household( "mel_c2" )
    pid = 100000001001
    hhr = init_household_result( hh )
    @test hh_to_hhr_mismatch( hh, hhr )

    sys = [get_system(), get_system( true )]

    wage = [50_000.0, 40_000, 10_000]./WEEKS_PER_YEAR
    savings = [0.0, 3_000, 10_000]./WEEKS_PER_YEAR
    dividends = [0.0, 5_000, 0.0]./WEEKS_PER_YEAR
    liabilities = [7_500,9_044,6_125,1_000]./WEEKS_PER_YEAR
    for i in 1:3 loop
        hh.people[ pid ].income[wages] = wage[i]
        hh.people[ pid ].income[bank_interest] = savings[i]
        hh.people[ pid ].income[dividends] = dividends[i]
        hres = do_one_calc( hh, sys[1] )
        hres_scot = do_one_calc( hh, sys[2] )
        @test hres.bu[1].pers[pid].it.total_tax ≈ liabilities[i]
    end

end
