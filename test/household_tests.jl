using Test: @testset, @test

using StatsBase

using ScottishTaxBenefitModel
using .FRSHouseholdGetter

using .ExampleHouseholdGetter
using .ModelHousehold: 
      BenefitUnit, 
      BenefitUnits, 
      BUAllocation,
      Household, 
      People_Dict, 
      PeopleArray, 
      Person,       
      count,
      default_bu_allocation,
      get_benefit_units, 
      get_head, 
      get_spouse, 
      has_carer_member, 
      has_disabled_member, 
      is_lone_parent, 
      num_children,
      num_people,
      printpids

using .RunSettings: Settings, DEFAULT_SETTINGS
using .TimeSeriesUtils: fy_from_bits

using .Definitions

using .HistoricBenefits: 
      RATIO_BENS,
      make_benefit_ratios!
      using .ExampleHelpers

using DataFrames


start_year=2015
num_households = 0
total_num_people = 0
nhh2 = 0
# pyplot()

rc = @timed begin
      num_households,total_num_people,nhh2 = FRSHouseholdGetter.initialise( DEFAULT_SETTINGS )
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
      empty!(head.income)
      empty!(head.benefit_ratios)
      head.income[state_pension] = 129.20
      make_benefit_ratios!(head, hh.interview_year, hh.interview_month )
      println( "head.benefit_ratios = $(head.benefit_ratios)")
      @test length( head.benefit_ratios ) == 1
      @test head.benefit_ratios[state_pension] ≈ 1

      head.income[bereavement_allowance_or_widowed_parents_allowance_or_bereavement] = 129.20
      make_benefit_ratios!(head, hh.interview_year, hh.interview_month )
      @test length( head.benefit_ratios ) == 2
      # 129.2/119.9 \approx 1.0775646371976646
      @test head.benefit_ratios[bereavement_allowance_or_widowed_parents_allowance_or_bereavement] ≈ 1.0775646371976646

      head.income[dlamobility] = 62.25
      head.income[attendance_allowance] = 89.15
      head.income[dlaself_care] = 89.15
      make_benefit_ratios!(head, hh.interview_year, hh.interview_month )
      @test head.dla_mobility_type == high
      @test head.attendance_allowance_type == high
      @test head.dla_self_care_type == high

      head.income[dlamobility] = 23.60
      head.income[attendance_allowance] = 59.7
      head.income[dlaself_care] = 23.60
      make_benefit_ratios!(head, hh.interview_year, hh.interview_month )
      @test head.dla_mobility_type == low
      @test head.attendance_allowance_type == low
      @test head.dla_self_care_type == low
      head.income[dlaself_care] = 59.7
      make_benefit_ratios!(head, hh.interview_year, hh.interview_month )
      @test head.dla_self_care_type == mid
      

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
                                    @test pers.bereavement_type in [
                                          bereavement_allowance,
                                          widowed_parents,
                                          bereavement_support]                              
                              end
                        end
                  end
                  #=
                  newrats = make_benefit_ratios( fy, pers.income )
                  @test length(symdiff(keys( newrats ),keys( pers.benefit_ratios ))) == 0 # all same keys
                  for k in keys( newrats )
                        @test  newrats[k] ≈ pers.benefit_ratios[k]
                  end
                  =#
            end
      end
      for target in RATIO_BENS
            rat = num_rats[target]
            print(typeof(rat))
            n = length( rat )
            println( "ratios for $target n = $n")
            nb = target == state_pension ? 40 : 6
            cm = fit(Histogram,rat, nbins=nb)
            #=
            p = Plots.plot( cm, title="$target ratio of actual vs standard for year"  )
            println( "hist:\n $cm")
            fname="tmp/$(target)_hist.svg"
            Plots.svg( p, fname)
            =#
            println( "exacts = $exact tot = $tot")
      end
end

@testset "people search functions" begin
      @time names = ExampleHouseholdGetter.initialise( DEFAULT_SETTINGS )
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
      @time for hhno in 1:num_households
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

            #
            # Test splitting up PIDs into source, year, etc.
            #
            for (pid,pers) in hh.people
                  bits = from_pid( pid )
                  @test pid == pers.pid
                  @test bits.year == hh.data_year
                  @test bits.datasource == FRS
                  @test bits.hid == hh.hid
            end
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

@testset "aggregate nmt bens" begin
      n = num_households
      cases = DataFrame(
            hid = zeros(BigInt, n ),
            year = zeros(Int,n),
            weight = zeros(n),

            pip_daily_living_enhanced = zeros(n),
            pip_daily_living_standard = zeros(n),
            pip_mobility_enhanced = zeros(n),
            pip_mobility_standard = zeros(n),
            carers_allowance = zeros(n),
            attendance_allowance_high = zeros(n),
            attendance_allowance_low = zeros(n),
            dla_care_high = zeros(n),
            dla_care_mid = zeros(n),
            dla_care_low = zeros(n),
            dla_mobility_high = zeros(n),
            dla_mobility_low  = zeros(n))
      r = 0
      @time for hhno in 1:num_households
            hh = FRSHouseholdGetter.get_household( hhno )
            r += 1
            row = cases[r,:]
            row.weight = hh.weight;
            row.hid = hh.hid
            row.year = hh.interview_year
            println( "on hh $(hh.hid)")
            for (pid, pers) in hh.people
                  print( "mobtype $(pers.dla_mobility_type)")
                  if pers.dla_self_care_type == low
                        row.dla_care_low += 1
                  elseif pers.dla_self_care_type == mid
                        row.dla_care_mid += 1
                  elseif pers.dla_self_care_type == high
                        row.dla_care_high += 1
                  end
                  if pers.dla_mobility_type == low
                        row.dla_mobility_low += 1
                  elseif pers.dla_mobility_type == mid
                        @assert 1==2 "mobility mid should never happen"
                  elseif pers.dla_mobility_type == high
                        row.dla_mobility_high += 1
                  end
                  if pers.attendance_allowance_type == low
                        row.attendance_allowance_low += 1
                  elseif pers.attendance_allowance_type == mid
                        @assert 3==4 "attendance mid should never happen"
                  elseif pers.attendance_allowance_type == high
                        row.attendance_allowance_high += 1
                  end
                  if pers.pip_daily_living_type == standard_pip
                        row.pip_daily_living_standard += 1
                  elseif pers.pip_daily_living_type == enhanced_pip
                        row.pip_daily_living_enhanced += 1
                  end
                  if pers.pip_mobility_type == standard_pip
                        row.pip_mobility_standard += 1
                  elseif pers.pip_mobility_type == enhanced_pip
                        row.pip_mobility_enhanced += 1
                  end
                  if haskey( pers.income, carers_allowance )
                        row.carers_allowance += 1
                  end
            end
      end            
      
      pip_daily_living_enhanced_tot = cases.pip_daily_living_enhanced'cases.weight
      println( "pip_daily_living_enhanced total = $pip_daily_living_enhanced_tot" )

      pip_daily_living_standard_tot = cases.pip_daily_living_standard'cases.weight
      println( "pip_daily_living_standard total = $pip_daily_living_standard_tot" )

      pip_mobility_enhanced_tot = cases.pip_mobility_enhanced'cases.weight
      println( "pip_mobility_enhanced total = $pip_mobility_enhanced_tot" )

      pip_mobility_standard_tot = cases.pip_mobility_standard'cases.weight
      println( "pip_mobility_standard total = $pip_mobility_standard_tot" )

      carers_allowance_tot = cases.carers_allowance'cases.weight
      println( "carers_allowance total = $carers_allowance_tot" )

      attendance_allowance_high_tot = cases.attendance_allowance_high'cases.weight
      println( "attendance_allowance_high total = $attendance_allowance_high_tot" )

      attendance_allowance_low_tot = cases.attendance_allowance_low'cases.weight
      println( "attendance_allowance_low total = $attendance_allowance_low_tot" )

      dla_care_high_tot = cases.dla_care_high'cases.weight
      println( "dla_care_high total = $dla_care_high_tot" )

      dla_care_mid_tot = cases.dla_care_mid'cases.weight
      println( "dla_care_mid total = $dla_care_mid_tot" )

      dla_care_low_tot = cases.dla_care_low'cases.weight
      println( "dla_care_low total = $dla_care_low_tot" )

      dla_mobility_high_tot = cases.dla_mobility_high'cases.weight
      println( "dla_mobility_high total = $dla_mobility_high_tot" )

      dla_mobility_low_tot = cases.dla_mobility_low'cases.weight 
      println( "dla_mobility_low  total = $dla_mobility_low_tot" )

      CSV.write( "bencounts.csv", cases )

end

