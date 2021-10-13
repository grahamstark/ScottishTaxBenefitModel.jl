#
# tests of test stuff!, exp .ExampleHelpers
#
using Test
using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions
using .ExampleHelpers

@testset "Adding/Removing people tests" begin
    
    hh = get_example( single_hh )
    head = get_head( hh )
    @test num_people( hh ) == 1
    @test num_adults( hh ) == 1
    @test num_children( hh ) == 0
    @test get_spouse( hh ) === nothing 

    add_spouse!( hh, 30, Female )
    @test num_people( hh ) == 2
    @test num_adults( hh ) == 2
    @test num_children( hh ) == 0
    @test get_spouse( hh ) !== nothing 

    spouse = get_spouse( hh )
    @test spouse.age == 30
    @test spouse.sex == Female 

    bus = get_benefit_units( hh )
    @test size(bus)[1] == 1
    bu = bus[1]
    @test num_people( bu ) == 2
    @test num_adults( bu ) == 2
    @test num_children( bu ) == 0
    spb = get_spouse( bu )
    @test spb !== nothing 

    @test spb.sex == spouse.sex
    @test spb.age == spouse.age
    @test spb.relationships[head.pid] == Spouse
    @test head.relationships[spouse.pid] == Spouse

    add_child!( hh, 3, Female )
    bus = get_benefit_units( hh )
    @test size(bus)[1] == 1
    bu = bus[1]
    @test num_people( bu ) == 3
    @test num_adults( bu ) == 2
    @test num_children( bu ) == 1
    for pid in bu.children
        @test spb.relationships[pid] == Parent
        @test head.relationships[pid] == Parent
    end
    ch1 = bu.people[bu.children[1]]
    @test ch1.relationships[spb.pid] == Son_or_daughter_incl_adopted
    @test ch1.relationships[head.pid] == Son_or_daughter_incl_adopted
    @test ch1.age == 3
    @test ch1.sex == Female

    add_child!( hh, 5, Male )
    bus = get_benefit_units( hh )
    bu = bus[1]
    @test num_people( bu ) == 4
    @test num_adults( bu ) == 2
    @test num_children( bu ) == 2

    # ch1 is ELDEST in bus, always..
    ch1 = bu.people[bu.children[1]]
    @test ch1.relationships[spb.pid] == Son_or_daughter_incl_adopted
    @test ch1.relationships[head.pid] == Son_or_daughter_incl_adopted
    @test ch1.age == 5
    @test ch1.sex == Male
    for pid in bu.children
        @test spb.relationships[pid] == Parent
        @test head.relationships[pid] == Parent 
    end
    @test size(bu.children)[1] == 2

    ## TODO TEST REMOVING
end
