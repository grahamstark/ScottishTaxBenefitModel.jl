import FRSHouseholdGetter: initialise, get_household
import Test: @testset, @test
import ModelHousehold: Household, Person, People_Dict, BUAllocation,
      PeopleArray, printpids,
      BenefitUnit, BenefitUnits, default_bu_allocation,
      get_benefit_units, get_head, get_spouse, num_people

start_year=2015

@testset "benefit unit allocations" begin
      rc = @timed begin
         num_households,total_num_people,nhh2 = initialise(
            household_name = "model_households_scotland",
            people_name    = "model_people_scotland",
            start_year = start_year )
      end
      println( "num_households=$num_households, num_people=$(total_num_people)")
      people_count = 0
      for hhno in 1:num_households
            hh = get_household( hhno )
            # println("people in HH")
            # printpids(hh.people)

            hhsize = size(collect(keys(hh.people)))[1]
            people_count += hhsize
            bus = get_benefit_units( hh )
            buallocation = default_bu_allocation( hh )
            nbus = size( bus )[1]
            @test 0 < nbus < 10
            by_bu_people_count = 0
            i = 0
            for bu in bus
                  # println( "from BU")
                  # printpids(bu)

                  i += 1
                  bu_people_count = 1
                  head = get_head( bu )
                  @test head.age >= 16
                  spouse = get_spouse( bu )
                  if spouse != nothing
                        bu_people_count += 1
                        @test spouse.age >= 16
                  end
                  for chno in bu.children
                        child = bu.people[chno]
                        @test child.age <= 19
                        bu_people_count += 1
                  end
                  by_bu_people_count += bu_people_count
                  @test bu_people_count == num_people( bu )
                  @test bu_people_count == size( buallocation[i])[1]
            end
            @test by_bu_people_count == hhsize

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
