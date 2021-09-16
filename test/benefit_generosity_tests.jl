using Test

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .ModelHousehold
using .BenefitGenerosity: initialise, to_set
using .Definitions
using .RunSettings
using .STBIncomes

settings = Settings()
uksys = get_system( scotland = false )
scsys = get_system( scotland = true )

FRSHouseholdGetter.initialise( settings )

@testset "Loading Tests" begin
    
    # println( FRSHouseholdGetter.MODEL_HOUSEHOLDS.pers_map )
    ks = sort( collect( keys( FRSHouseholdGetter.MODEL_HOUSEHOLDS.pers_map )), lt=ModelHousehold.isless )
    for k in ks 
        if k.data_year == 2015
            print( k )
            if k.id == 120150847501 
                print("!!!!")
            end
            println()
        end
    end
    BenefitGenerosity.initialise( "$(MODEL_DATA_DIR)/disability/")

    for ben in [ATTENDANCE_ALLOWANCE, PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING,
        PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY, DLA_SELF_CARE]
        for peeps in [-100_000, -10_000, -1000, 0, 1000, 10_000, 100_000 ]
            s = to_set( ben, peeps )
            println( "set for $peeps $ben = $(s)")
        end
    end

end

