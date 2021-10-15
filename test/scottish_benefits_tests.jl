using Test
using ScottishTaxBenefitModel
using .ModelHousehold
using .Results
using .Intermediate: MTIntermediate, make_intermediate    
using .ScottishBenefits
using .STBIncomes
using .ExampleHelpers

sys = get_system( scotland=true )

@testset "Scottish Child Payment" begin
    
    for (hht,hh) in get_all_examples()
        bus = get_benefit_units( hh )
        intermed = make_intermediate( 
            hh,  
            sys.hours_limits,
            sys.age_limits,
            sys.child_limits )
        hres = init_household_result( hh )
        hhead = get_head( hh )
        hpid = hhead.pid
        for buno in eachindex(bus)
            bures = hres.bus[buno]
            bu = bus[buno]
            bint = intermed.buint[buno]
            ncs = num_children( bu )
            bhead = get_head( bus[buno ])
            bspouse = get_spouse( bus[buno ])
            if ncs > 0
                println( "on hhld $(hht)")
                # no qualifying benefit
                ages = fill( 6, ncs ) # 1 year too old
                set_childrens_ages!( hh, ages... )
                calc_scottish_child_payment!(
                    bures,
                    bu,
                    bint,
                    sys.scottish_child_payment 
                )
                aggregate!( bures )
                @test ! has_any( bures, SCOTTISH_CHILD_PAYMENT )
                ti = rand( sys.scottish_child_payment.qualifying_benefits )
                bures.pers[bhead.pid].income[ti] = 1.0
                calc_scottish_child_payment!(
                    bures,
                    bu,
                    bint,
                    sys.scottish_child_payment 
                )
                aggregate!( bures )
                # still should be zero since all over age
                @test ! has_any( bures, SCOTTISH_CHILD_PAYMENT )
                # all qualify on age
                ages = fill( 3, ncs ) 
                set_childrens_ages!( hh, ages... )
                calc_scottish_child_payment!(
                    bures,
                    bu,
                    bint,
                    sys.scottish_child_payment 
                )
                aggregate!( bures )
                @test bures.income[SCOTTISH_CHILD_PAYMENT] == ncs*10
                # 1 qualifying 
                set_childrens_ages!( hh, 3,8,9,10,12 )
                calc_scottish_child_payment!(
                    bures,
                    bu,
                    bint,
                    sys.scottish_child_payment 
                )
                aggregate!( bures )
                @test bures.income[SCOTTISH_CHILD_PAYMENT] == 10
            end # with children
        end
    end

end