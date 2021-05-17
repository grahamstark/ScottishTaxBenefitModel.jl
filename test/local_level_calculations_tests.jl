using Test
using ScottishTaxBenefitModel
using .ModelHousehold: Household, Person, People_Dict, is_single,
    default_bu_allocation, get_benefit_units, get_head, get_spouse, search,
    pers_is_disabled, pers_is_carer, printpids
using .ExampleHouseholdGetter
using .Definitions
using .Results: HousingResult

using .LocalLevelCalculations: calc_lha, calc_bedroom_tax, apply_size_criteria, 
    make_la_to_brma_map, LA_BRMA_MAP, lookup, apply_rent_restrictions

using .STBParameters
using .Intermediate: make_intermediate, MTIntermediate

## FIXME don't need both
lmt = LegacyMeansTestedBenefitSystem{Float64}()
sys = get_system( scotland=true )

@testset "LHA and assoc. mappings" begin
    # basic test/retrieve 
    # println( LA_BRMA_MAP )
    @test LA_BRMA_MAP.map[:S12000049] == :S33000009
    lmt
    @test lookup( sys.hr.brmas, :S12000049, 4 ) == 322.19
end

@testset "Rooms Restrictions" begin

    hh = deepcopy(EXAMPLES[cpl_w_2_children_hh]) 
    hh.bedrooms = 12 # set to a big number 
    delete_child!( hh ) # start with 1

    println( hh.tenure )
    hh.tenure = Private_Rented_Unfurnished

    println( sys.hr.maximum_rooms )
    bus = get_benefit_units(hh)
    bu = bus[1]
    
    # single_parent_hh single_hh childless_couple_hh
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "got nbeds as $nbeds " )
    oldnbeds = 0
    @test nbeds == 2 # so 1 bed for adults + 1 shared 

    np = add_child!( hh, 11, Female )
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "got nbeds as $nbeds " )
    oldnbeds = 0
    age = 4
    # base case: 2 children aged 2 and 5: different genders (sexes?)
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 2 # so 1 bed for adults + 1 shared
    
    sys.hr.maximum_rooms = 5 # add 1 so we can test a bit more`
    np = add_child!( hh, 11, Female )
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 3 # so 1 bed for adults + 1 shared + 1 for 11 yo
    
    np = add_child!( hh, 11, Male )
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 1 shared 11,2 yo male + 1 F

    np = add_child!( hh, 12, Male )
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 2 shared + 1 for 11 M and F
    
    np = add_child!( hh, 13, Female )
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 2 shared + 1 for 11 M and F
  
    np = add_child!( hh, 15, Female )
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    @test nbeds == 5 # same as above - max should kick in 
    hh = deepcopy(EXAMPLES[cpl_w_2_children_hh]) 
    
    for i in 1:0
        age += 1
        sex = iseven(i) ? Male : Female
        np = add_child!( hh, age, sex )
        oldnbeds = nbeds
        intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
        nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
        nc = num_children( hh )
    end

    hh = make_hh() # all at defaults 
    head = get_head( hh )
    head.age = 20
    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "beds for under 35s $nbeds ")
    @test nbeds == 0 # single room
    head.age = 40

    intermed = make_intermediate( hh, sys.hours_limits, sys.age_limits )
    nbeds = apply_size_criteria( hh, intermed.hhint, sys.hr )
    println( "beds for over 35s $nbeds ")
    @test nbeds == 1 # single room + bed for over 35

   

end

@testset "Local Housing Allowance" begin
    @test sys.hr.rooms_rent_reduction ≈ [0.14, 0.25]
    for (name,hh) in EXAMPLES
        println( "on hhld $name")
        hh.tenure = Private_Rented_Furnished
        hh.gross_rent = 300.0
        intermed = make_intermediate( hh, sys.hours_limits , sys.age_limits )                
        rr = apply_rent_restrictions( hh, intermed.hhint, sys.hr )
        println( rr )
    end
    # this hhld is in Glasgow
    # 
    for tenure in [Private_Rented_Furnished, Council_Rented]
        for adults in 1:2
            for kids in 0:5
                for age in [30,40,70]
                    hh = make_hh( adults=adults, children=kids, age=age, tenure=tenure, rent=500.0 )
                    intermed = make_intermediate( hh, sys.hours_limits , sys.age_limits )
                    rr = apply_rent_restrictions( hh, intermed.hhint, sys.hr )
                    if adults == 1
                        if age == 70 
                            @test rr.allowed_rooms == hh.bedrooms
                        elseif kids == 0
                            if age == 30
                                @test rr.allowed_rooms == 0
                            else
                                @test rr.allowed_rooms == 1
                            end
                        elseif kids == 1
                            @test rr.allowed_rooms == 2 # you & the child, regardless of age
                        end
                        
                    else # 2 adults
                        
                    end
                end # age
                if tenure == Private_Rented_Furnished

                else
                    if adults == 1

                    else

                    end

                end
            end # kids
        end # adults
    end # tenure

end

@testset "Council Tax" begin


end