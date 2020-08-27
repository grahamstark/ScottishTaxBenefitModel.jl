using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .ExampleHouseholdGetter
using Test: @testset, @test
using .ModelHousehold: Household, Person, People_Dict, BUAllocation,
      PeopleArray, printpids,
      BenefitUnit, BenefitUnits, default_bu_allocation,
      get_benefit_units, get_head, get_spouse, num_people,
      is_disabled, is_lone_parent, is_carer, num_children,
      count

using .Definitions

start_year=2015

@testset "people search functions" begin
      @time names = ExampleHouseholdGetter.initialise()
      hh = ExampleHouseholdGetter.get_household( "single_parent_1" )  
      printpids( hh.people ) 
      @test num_people( hh ) == 3
      @test is_lone_parent( hh )
      bus = get_benefit_units( hh )
      @test size(bus)[1] == 1
      bu = bus[1]
      @test is_lone_parent( bu )
      @test num_people( bu ) == 3
      head = get_head( bu )
      @test ! is_disabled( bu )
      @test ! is_carer( bu )
      # FIXME we'll need to change this if disability no longer based on benefit receipt
      head.registered_blind = true
      @test is_disabled( bu )
      @test ! is_carer( bu )
      head.registered_blind = false
      head.income[carers_allowance] = 1.0
      @test is_carer( bu )
      delete!(head.income,carers_allowance)
      @test ! is_carer( bu )
      head.income[severe_disability_allowance] = 1.0
      @test is_disabled( bu )
      
end

@testset "benefit unit allocations" begin
      rc = @timed begin
            num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise(
                  household_name = "model_households_scotland",
                  people_name    = "model_people_scotland",
                  start_year = start_year )
      end
      println( "num_households=$num_households, num_people=$(total_num_people)")
      people_count = 0
      for hhno in 1:num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            # println("people in HH")
            # printpids(hh.people)

            hhsize = size(collect(keys(hh.people)))[1]
            people_count += hhsize
            bus = get_benefit_units( hh )
            buallocation = default_bu_allocation( hh )
            nbus = size( bus )[1]
            @test 0 < nbus < 10
            by_bu_people_count = 0
            by_bu_child_count = 0
            i = 0
            for bu in bus
                  # println( "from BU")
                  # printpids(bu)

                  i += 1
                  bu_people_count = 1
                  bu_children = 0
                  head = get_head( bu )
                  @test head.age >= 16
                  spouse = get_spouse( bu )
                  if spouse !== nothing
                        bu_people_count += 1
                        @test spouse.age >= 16
                  end
                  for chno in bu.children
                        child = bu.people[chno]
                        @test child.age <= 19
                        bu_people_count += 1
                        bu_children += 1
                  end
                  @test num_children( bu ) == bu_children
                  by_bu_child_count += bu_children
                  by_bu_people_count += bu_people_count
                  @test bu_people_count == num_people( bu )
                  @test bu_people_count == size( buallocation[i])[1]
            end
            @test by_bu_people_count == hhsize
            @test num_children(hh) == by_bu_child_count

            bua_people_count = 0
            for bua in buallocation
                  bua_people_count += size( bua )[1]
            end


            # println("BU Allocation")
            # printpids(buallocation)
            @test bua_people_count == hhsize
      end
      @test people_count == total_num_people
end
