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
    println( hh.tenure )
    hh.tenure = Private_Rented_Unfurnished
    println( sys.hr.maximum_rooms )
    bus = get_benefit_units(hh)
    bu = bus[1]
    # single_parent_hh single_hh childless_couple_hh
    nbeds = apply_size_criteria( hh, sys.hr )
    println( "got nbeds as $nbeds " )
    oldnbeds = 0
    age = 4
    # base case: 2 children aged 2 and 5: different genders (sexes?)
    nbeds = apply_size_criteria( hh, sys.hr )
    @test nbeds == 2 # so 1 bed for adults + 1 shared
    sys.hr.maximum_rooms = 5 # add 1 so we can test a bit more`
    np = add_child!( hh, 11, Female )
    nbeds = apply_size_criteria( hh, sys.hr )
    @test nbeds == 3 # so 1 bed for adults + 1 shared + 1 for 11 yo
    
    np = add_child!( hh, 11, Male )
    nbeds = apply_size_criteria( hh, sys.hr )
    @test nbeds == 3 # so 1 bed for adults + 1 shared 11,2 yo male + 1 F

    np = add_child!( hh, 12, Male )
    nbeds = apply_size_criteria( hh, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 2 shared + 1 for 11 M and F
    
    np = add_child!( hh, 13, Female )
    nbeds = apply_size_criteria( hh, sys.hr )
    @test nbeds == 4 # so 1 bed for adults + 2 shared + 1 for 11 M and F
  
    np = add_child!( hh, 15, Female )
    nbeds = apply_size_criteria( hh, sys.hr )
    @test nbeds == 5 # same as above - max should kick in 
    hh = deepcopy(EXAMPLES[cpl_w_2_children_hh]) 
    
    for i in 1:0
        age += 1
        sex = iseven(i) ? Male : Female
        np = add_child!( hh, age, sex )
        oldnbeds = nbeds
        nbeds = apply_size_criteria( hh, sys.hr )
        nc = num_children( hh )
    end
end

@testset "Local Housing Allowance" begin
    @test sys.hr.rooms_rent_reduction ≈ [0.14, 0.25]
    for (name,hh) in EXAMPLES
        println( "on hhld $name")
        hh.tenure = Private_Rented_Furnished
        hh.gross_rent = 300.0
        rr = apply_rent_restrictions( hh, sys.hr )
        println( rr )
    end
end

@testset "Council Tax" begin


end