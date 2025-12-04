using Test
using Pkg, LazyArtifacts
using ScottishTaxBenefitModel
using Observables

using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer, printpids
using .ExampleHelpers
using .ExampleHouseholdGetter
using .Definitions
using .LocalWeightGeneration
using .Results: HousingResult
using .FRSHouseholdGetter
using .RunSettings: Settings
using .LocalLevelCalculations: apply_size_criteria, apply_rent_restrictions,
    make_la_to_brma_map, LA_BRMA_MAP, lookup, apply_rent_restrictions, calc_council_tax,
    calc_proportional_property_tax
using .Monitor: Progress
using .WeightingData: LA_NAMES, LA_CODES

using .STBParameters
using .Intermediate: make_intermediate, MTIntermediate
using .ExampleHelpers
using .Utils

using CSV,DataFrames

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( year=2019, scotland=true )
settings = Settings()

rc = @timed begin
    settings.num_households,settings.num_people,nhh2 = FRSHouseholdGetter.initialise( Settings(), reset=true )

end

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end

@testset "Local Proportional Property Tax" begin
    # create a new system
    sys1 = get_default_system_for_fin_year( 2025, scotland=true, autoweekly=false )
	sys2 = deepcopy( sys1 )		
    settings = Settings()
	# turn on the ppt ... 
	sys2.loctax.ppt.abolished = false
    sys2.loctax.ppt.fixed_sum = false
	# .. and turn off CT
	sys2.loctax.ct.abolished = true
	# applied across all Scotland: 0.25% on 1st 50,000, 0.67% above
    sys2.loctax.ppt.local_bands = [500_000]
	sys2.loctax.ppt.local_rates = [0.44,0]
	
	sys2.loctax.ppt.national_rates = [0,0.54,(0.54+0.278)]
    sys2.loctax.ppt.national_bands = [500_000,1_000_000]
	sys2.loctax.ppt.single_person_discount = 0.0 # 25 # pct
	sys2.loctax.ppt.local_minimum_payment = 800.0
	sys2.loctax.ppt.national_minimum_payment = 0.0
	weeklyise!(sys1)	
	weeklyise!(sys2)	
    results = do_one_run( settings, [sys1,sys2], obs )    
end

@testset "Mansion Tax" begin
    hh = get_example( cpl_w_2_children_hh )
    hval = [500_000.0, 1_000_001, 6_000_001]
    due = [0.0, 2500, 7_500 ]
    sys = get_default_system_for_fin_year( 2025, scotland=true, autoweekly=false )
    sys.loctax.ppt.local_rates = [0, 2_500.0, 7_500.0] # ann
    sys.loctax.ppt.local_bands = [1_000_000, 6_000_000] 
    sys.loctax.ppt.fixed_sum = true
	sys.loctax.ppt.abolished = false
	weeklyise!(sys)
    for i in eachindex(hval)
        hh.house_value = hval[i]
        intermed = make_intermediate( 
            Float64,
            settings,
            hh, 
            sys.hours_limits, 
            sys.age_limits, 
            sys.child_limits )
        lt, nt = calc_proportional_property_tax( hh, intermed.hhint, sys.loctax.ppt ) 
        @test nt == 0.0
        println( "Test $i ")
        @test lt*WEEKS_PER_YEAR ≈ due[i] 
    end
end

@testset "LHA and assoc. mappings" begin
    # basic test/retrieve 
    # println( LA_BRMA_MAP )
    @test LA_BRMA_MAP.map[:S12000049] == :S33000009
    lmt
    @test lookup( sys.hr.brmas, :S12000049, 4 ) == 322.19
end

@testset "Rooms Restrictions" begin

    hh = get_example( cpl_w_2_children_hh ) 
    hh.bedrooms = 12 # set to a big number 
    delete_child!( hh ) # start with 1

    println( hh.tenure )
    hh.tenure = Private_Rented_Unfurnished

    println( sys.hr.maximum_rooms )
    bus = get_benefit_units(hh)
    bu = bus[1]
    
    # single_parent_hh single_hh childless_couple_hh
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "got nbeds as $nbeds " )
    oldnbeds = 0
    @test nbeds == 2 # so 1 bed for adults + 1 shared 

    np = add_child!( hh, 11, Female )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "got nbeds as $nbeds " )
    oldnbeds = 0
    age = 4
    # base case: 2 children aged 2 and 5: different genders (sexes?)
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 2 # so 1 bed for adults + 1 shared
    
    sys.hr.maximum_rooms = 5 # add 1 so we can test a bit more`
    np = add_child!( hh, 11, Female )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 3 # so 1 bed for adults + 1 shared + 1 for 11 yo
    
    np = add_child!( hh, 11, Male )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 1 shared 11,2 yo male + 1 F

    np = add_child!( hh, 12, Male )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 2 shared + 1 for 11 M and F
    
    np = add_child!( hh, 13, Female )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 2 shared + 1 for 11 M and F
  
    np = add_child!( hh, 15, Female )
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 5 # same as above - max should kick in 
    hh = get_example( cpl_w_2_children_hh ) 
    
    for i in 1:0
        age += 1
        sex = iseven(i) ? Male : Female
        np = add_child!( hh, age, sex )
        oldnbeds = nbeds
        intermed = make_intermediate( 
            DEFAULT_NUM_TYPE,
            settings,
            hh, 
            sys.hours_limits, 
            sys.age_limits,
            sys.child_limits )
        nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
        nc = num_children( hh )
    end

    hh = make_hh() # all at defaults 
    head = get_head( hh )
    head.age = 20
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "beds for under 35s $nbeds ")
    @test nbeds == 0 # single room
    head.age = 40

    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "beds for over 35s $nbeds ")
    @test nbeds == 1 # single room + bed for over 35
end

@testset "Local Housing Allowance" begin
    @test sys.hr.rooms_rent_reduction ≈ [0.14, 0.25]
    sys.hr.maximum_rooms = 4 # set this back to actual
    for (name,hh) in get_all_examples()
        println( "on hhld $name")
        hh.tenure = Private_Rented_Furnished
        hh.gross_rent = 300.0
        intermed = make_intermediate( 
            DEFAULT_NUM_TYPE,
            settings,
            hh, 
            sys.hours_limits , 
            sys.age_limits,
            sys.child_limits )                
        rr = apply_rent_restrictions( hh, intermed.hhint, sys.hr )
        println( rr )
    end
    # this hhld is in Glasgow
    # 
    for tenure in [Private_Rented_Furnished, Council_Rented]
        for adults in 1:2
            for kids in 0:5
                for age in [30,40,70]
                    if adults == 1                    
                        hh = make_hh( 
                            adults=adults, 
                            children=kids, 
                            age=age, 
                            tenure=tenure, 
                            rent=500.0,
                            council=:S12000049 )
                    else
                        hh = make_hh( 
                            adults=adults, 
                            children=kids, 
                            age=age, 
                            spouse_age=age, 
                            tenure=tenure, 
                            rent=500.0,
                            council=:S12000049 )
                    end
                    intermed = make_intermediate( 
                        DEFAULT_NUM_TYPE,
                        settings,            
                        hh, 
                        sys.hours_limits , 
                        sys.age_limits,
                        sys.child_limits )
                    rr = apply_rent_restrictions( hh, intermed.hhint, sys.hr )
                    if adults == 1
                        if age == 70 && tenure == Council_Rented
                            # no bedroom tax for hhls all ads over pension age socially renting
                            @test intermed.hhint.all_pension_age
                            println( "intermed.all_pension_age $(intermed.hhint.all_pension_age)")
                            @test rr.allowed_rooms == hh.bedrooms
                        elseif kids == 0
                            if age == 30
                                @test rr.allowed_rooms == 0
                            else
                                @test rr.allowed_rooms == 1
                            end
                        elseif kids == 1
                            @test rr.allowed_rooms == 2 # you & the child, regardless of age
                        elseif kids == 2
                            @test rr.allowed_rooms == 3
                        elseif 2 < kids > 4
                            @test rr.allowed_rooms ∈ [3,4] # depends on ages
                        elseif kids > 4
                            @test rr.allowed_rooms == 4
                        end
                        
                    else # 2 adults
                        if age == 70 && tenure == Council_Rented
                            # no bedroom tax for hhls all ads over pension age socially renting
                            @test intermed.hhint.all_pension_age
                            println( "intermed.all_pension_age $(intermed.hhint.all_pension_age)")
                            @test rr.allowed_rooms == hh.bedrooms
                        elseif kids == 0
                            @test rr.allowed_rooms == 1
                        elseif kids == 1
                            @test rr.allowed_rooms == 2 # you & the child, regardless of age
                        elseif kids == 2
                            @test rr.allowed_rooms ∈ [2,3] # this depends on whether kids can share
                        elseif 2 < kids > 4
                            @test rr.allowed_rooms ∈ [3,4] # depends on kids can share
                        elseif kids > 4
                            @test rr.allowed_rooms == 4
                        end
                    end
                end
            end # kids
        end # adults
    end # tenure

    for tenure in [Private_Rented_Furnished, Council_Rented]
        for adults in 1:2
            for kids in 0:5
                for age in [30,40,70]
                    if adults == 1                    
                        hh = make_hh( 
                            adults=adults, 
                            children=kids, 
                            age=age, 
                            tenure=tenure, 
                            rent=500.0, 
                            council=:S12000049 ) # Glasgow
                    else
                        hh = make_hh( 
                            adults=adults, 
                            children=kids, 
                            age=age, 
                            spouse_age=age, 
                            tenure=tenure, 
                            rent=500.0,
                            council=:S12000049 ) # Glasgow
                    end
                    intermed = make_intermediate( 
                        DEFAULT_NUM_TYPE,
                        settings,
                        hh, 
                        sys.hours_limits , 
                        sys.age_limits,
                        sys.child_limits )
                    rr = apply_rent_restrictions( hh, intermed.hhint, sys.hr )
                    
                    if tenure == Private_Rented_Furnished
                        # GLASGOW 2020/1 
                        allowed = [80.55 113.92 149.59 172.6 322.19]  
                        @test rr.allowed_rent ≈ allowed[rr.allowed_rooms+1]                         
                        @test rr.allowed_rooms ∈ 0:4                
                    else
                        if age != 70
                            @test rr.allowed_rooms ∈ 0:4  
                        end
                        if rr.excess_rooms == 0
                            @test rr.allowed_rent == 500
                        elseif rr.excess_rooms == 1
                            @test rr.allowed_rent ≈ 500*(1-0.14)
                        else
                            @test rr.allowed_rent ≈ 500*(1-0.25)
                        end
                    end
                end
            end
        end
    end

    num_restricted = 0
    bedroom_tax = 0
    for hhno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hhno )
        # TODO UPRATE
        if hhno % 500 == 0
            println( "on hhld $hhno")
        end
        intermed = make_intermediate( 
            DEFAULT_NUM_TYPE,
            settings,
            hh, 
            sys.hours_limits , 
            sys.age_limits,
            sys.child_limits )
        rr = apply_rent_restrictions( hh, intermed.hhint, sys.hr )
        if rr.excess_rooms > 0
            num_restricted += hh.weight
            if is_social_renter( hh.tenure )
                bedroom_tax += hh.weight
            end
        end
    end
    println( "initial run: number with excess rooms $num_restricted bedroom tax $bedroom_tax" )
end

@testset "Council Tax" begin
    by_band = Dict{CT_Band, Real}()
    by_la = Dict()
    for c in instances( CT_Band )
        by_band[c] = 0.0
    end
    for c in LA_CODES
        by_la[c] = [0.0, 0.0]
    end
    println( by_la[:S12000019][1] )
    value = 0.0
    dwellings = 0.0
    for hhno in 1:settings.num_households
        hh = FRSHouseholdGetter.get_household( hhno )
        intermed = make_intermediate( 
            DEFAULT_NUM_TYPE,
            settings,
            hh, 
            sys.hours_limits , 
            sys.age_limits,
            sys.child_limits )
        println( "ct band $(hh.ct_band) council $(hh.council)")
        ct = calc_council_tax( hh, intermed.hhint, sys.loctax.ct )
        by_band[hh.ct_band] += hh.weight
        by_la[hh.council][2] += ct*hh.weight*WEEKS_PER_YEAR
        by_la[hh.council][1] += hh.weight
        value += ct*hh.weight*WEEKS_PER_YEAR
        dwellings +=hh.weight
    end
    println( "band,num dwellings")
    for c in instances( CT_Band )
        println( "$c,$(trunc(by_band[c]))")
    end

    println( "name,ccode,hhlds,raised,av")
    for c in LA_CODES
        name = LA_NAMES[c]
        raised = trunc( by_la[c][2] )
        hhlds = trunc( by_la[c][1] )
        av = trunc( by_la[c][2]/by_la[c][1])
        println( "$(name),$c,$hhlds,$raised,$av")
    end
    

    println( "total raised $(trunc(value/1_000_000))m pa before rebates")
    println( "dwellings $(trunc(dwellings)) ")
    println( "av per dwelling, before ctrebate $(trunc(value/dwellings))")
    hh = make_hh(adults=2, council=:S12000049)
    intermed = make_intermediate( 
        DEFAULT_NUM_TYPE,
        settings,
        hh, 
        sys.hours_limits, 
        sys.age_limits,
        sys.child_limits )
    println( "ct band $(hh.ct_band) council $(hh.council)")
    ct = calc_council_tax( hh, intermed.hhint, sys.loctax.ct )
    @test hh.ct_band == Band_B
    @test ct ≈ 1_078.00/WEEKS_PER_YEAR # glasgow 2020/1 CT band b per week
end

@testset "Local reweighing" begin
    n = length(LA_CODES)
    settings.do_local_run = true
    d = DataFrame()
    nkeys = 0
    for i in 1:n
        reset = i==1
        settings.ccode = LA_CODES[i]
        FRSHouseholdGetter.restore()
        @show settings.ccode
        dict = FRSHouseholdGetter.create_local_income_ratios( settings, reset=false )
        # @show dict
        @show keys(dict)
        if i == 1
            d[!,:keys] = collect(keys(dict))
            nkeys = length(d.keys)
        end
        @show d
        d[!,settings.ccode] = zeros(nkeys)
        for j in 1:nkeys 
            k = d.keys[j]
            @show k
            d[j,settings.ccode]=dict[k].ratio
        end
    end
    CSV.write( joinpath( tmpdir, "local-nomis-frs-wage-relativities.tab"), d; delim='\t')
    # /mnt/data/ScotBen/artifacts
    @show d
end


@testset "Base Local Runs" begin
    n = length(LA_CODES)
    settings.do_local_run = true
    d = DataFrame()
    nkeys = 0
    weighted_data = DataFra = settings.num_households
    adf = LocalWeightGeneration.initialise_model_dataframe_scotland_la( n )
    insertcols!( adf, 1, :ccode => fill( Symbol(""), n ))
    adf.wage = zeros(n)
    adf.se = zeros(n)
    adf.popn = zeros(n)
    adf.nearners = zeros(n)
    adf.nses = zeros(n)
    adf.num_hhlds = zeros(n)
    for i in 1:n
        reset = i == 1
        settings.ccode = LA_CODES[i]
        FRSHouseholdGetter.restore()
        FRSHouseholdGetter.set_local_weights_and_incomes!( settings, reset=false )
        ldf = LocalWeightGeneration.initialise_model_dataframe_scotland_la( settings.num_households )
        popn = 0.0
        wage = 0.0
        se = 0.0
        nses = 0.0
        nearners = 0.0
        num_hhlds = 0.0
        println( "on $(settings.ccode)")
        for hno in 1:settings.num_households
            hh = FRSHouseholdGetter.get_household(hno)
            num_hhlds += hh.weight
            LocalWeightGeneration.make_model_dataframe_row!( 
                ldf[hno,:], hh, hh.weight )
            for (pid,pers) in hh.people
                w = get(pers.income,wages,0.0)
                if w > 0
                    wage += w*hh.weight 
                    nearners += hh.weight
                end
                s = get(pers.income,self_employment_income,0.0) 
                if s != 0.0
                    se += s*hh.weight
                    nses += hh.weight
                end
                popn += hh.weight
            end
        end
        for n in names(ldf)
            adf[i,n] = sum( ldf[!,n])
        end
        adf[i,:ccode] = settings.ccode
        adf[i,:wage] = wage/nearners
        adf[i,:se] = se/nses
        adf[i,:popn] = popn
        adf[i,:nses] = nses
        adf[i,:nearners] = nses
        adf[i,:num_hhlds] = num_hhlds
    end
    aug = qualified_artifact( "augdata" )
    ld = CSV.File( joinpath( aug, "scottish-la-targets-2024.tab"))|>DataFrame
    for i in 1:(n-1)
        ccode = LA_CODES[i]
        i += 1
        lr = ld[i,:]
        ar = adf[i,:]
        @test ar.ccode == Symbol(lr.authority_code)
        @test abs(ar.popn - lr.total_people) < 10 # rounding errors
        @test abs(ar.num_hhlds - lr.total_hhlds) < 10 # - within 10 hhls/people is OK, I hope
        println( "on $(ccode) name=$(lr.Authority) target=$(lr.total_hhlds)")
    end
    @show adf
end