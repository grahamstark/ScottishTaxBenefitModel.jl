using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .ExampleHouseholdGetter
using Test: @testset, @test
using StatsBase
using .ModelHousehold: Household, Person, People_Dict, BUAllocation,
      PeopleArray, printpids,
      BenefitUnit, BenefitUnits, default_bu_allocation,
      get_benefit_units, get_head, get_spouse, num_people,
      has_disabled_member, is_lone_parent, has_carer_member, num_children,
      count
using .TimeSeriesUtils: fy_from_bits
using .Definitions
using .HistoricBenefits: make_benefit_ratios, RATIO_BENS
using Plots
using PyPlot

start_year=2015
num_households = 0
total_num_people = 0
nhh2 = 0
pyplot()

rc = @timed begin
      num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise(
            household_name = "model_households_scotland",
            people_name    = "model_people_scotland",
            start_year = start_year )
end
println( "num_households=$num_households, num_people=$(total_num_people)")


@testset "ratio tests" begin
      hh = ExampleHouseholdGetter.get_household( "single_parent_1" )  
      bu = get_benefit_units( hh )[1]
      head = get_head( bu )
      fy = fy_from_bits( hh.interview_year, hh.interview_month )
      @test fy == 2019

      # pension fy 2019 = 129.2
      # wid fy 2019 = 119.9
      head.income[state_pension] = 129.20
      head.benefit_ratios = make_benefit_ratios( fy, head.income )

      @test length( head.benefit_ratios ) == 1
      @test head.benefit_ratios[state_pension] ≈ 1

      head.income[bereavement_allowance_or_widowed_parents_allowance_or_bereavement] = 129.20
      head.benefit_ratios = make_benefit_ratios( fy, head.income )
      @test length( head.benefit_ratios ) == 2
      # 129.2/119.9 \approx 1.0775646371976646
      @test head.benefit_ratios[bereavement_allowance_or_widowed_parents_allowance_or_bereavement] ≈ 1.0775646371976646

      # overall test
      num_rats = Dict()
      exact = 0
      tot = 0
      for target in RATIO_BENS
            num_rats[target] = Vector{Float64}(undef,0)
      end
      for hhno in 1:num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            fy = fy_from_bits( hh.interview_year, hh.interview_month )
            # println("people in HH")
            # printpids(hh.people)
            for (pid,pers) in hh.people 
                  for target in RATIO_BENS
                        if haskey( pers.benefit_ratios, target )
                              @test pers.income[target] > 0
                              pts = pers.benefit_ratios[target]
                              if pts ≈ 1
                                    exact += 1
                              end
                              tot += 1
                              push!(num_rats[target], pts )
                              if target == bereavement_allowance_or_widowed_parents_allowance_or_bereavement
                                    @assert pers.widows_type in [
                                          bereavement_allowance,
                                          widowed_parents,
                                          bereavement_support]                              
                              end
                        end
                  end
                  newrats = make_benefit_ratios( fy, pers.income )
                  @test length(symdiff(keys( newrats ),keys( pers.benefit_ratios ))) == 0 # all same keys
                  for k in keys( newrats )
                        @test  newrats[k] ≈ pers.benefit_ratios[k]
                  end
            end
      end
      for target in RATIO_BENS
            rat = num_rats[target]
            print(typeof(rat))
            n = length( rat )
            println( "ratios for $target n = $n")
            nb = target == state_pension ? 40 : 6
            cm = fit(Histogram,rat, nbins=nb)
            p = Plots.plot( cm, title="$target ratio of actual vs standard for year"  )
            println( "hist:\n $cm")
            fname="tmp/$(target)_hist.svg"
            Plots.svg( p, fname)
            println( "exacts = $exact tot = $tot")
      end
end

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
      @test ! has_disabled_member( bu )
      @test ! has_carer_member( bu )
      # FIXME we'll need to change this if disability no longer based on benefit receipt
      head.registered_blind = true
      @test has_disabled_member( bu )
      @test ! has_carer_member( bu )
      head.registered_blind = false
      head.income[carers_allowance] = 1.0
      @test has_carer_member( bu )
      delete!(head.income,carers_allowance)
      @test ! has_carer_member( bu )
      head.income[severe_disability_allowance] = 1.0
      @test has_disabled_member( bu )
      
end

@testset "benefit unit allocations" begin
      people_count = 0
      over_16_kids = 0
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
                        if child.age >16
                            over_16_kids += 1
                        end
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
      @test over_16_kids > 0
      println( "num people $people_count over_16_kids=$over_16_kids" )
end

