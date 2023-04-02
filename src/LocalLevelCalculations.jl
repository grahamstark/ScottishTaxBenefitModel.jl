module LocalLevelCalculations
#
# This module provides routines for various possible local taxation schemes, 
# the bedroom tax, and local housing allowances. Housing Benefit and 
# CTC reduction schemes are in the means-tested benefit modules.
#
# FIXME we need to improve the mapping between LAs and local housing allowances.
#

using StaticArrays
using CSV,DataFrames

using ScottishTaxBenefitModel
using .Definitions

using .ModelHousehold: 
    BenefitUnit, 
    Household, 
    Person, 
    get_head, 
    is_severe_disability,
    num_people

using .Intermediate: 
    MTIntermediate
    
using .STBParameters
    
using .GeneralTaxComponents: 
    RateBands,
    TaxResult, 
    calctaxdue

using .Results: 
    HousingResult

export 
    LA_BRMA_MAP, 
    LA_CODES, 
    LA_NAMES,
    apply_rent_restrictions,
    apply_size_criteria, 
    calc_council_tax, 
    calc_proportional_property_tax,
    lookup, 
    make_la_to_brma_map

    # la codes in order
    const LA_CODES = [
        :S12000033,
        :S12000034,
        :S12000041,
        :S12000035,
        :S12000036,
        :S12000005,
        :S12000006,
        :S12000042,
        :S12000008,
        :S12000045,
        :S12000010,
        :S12000011,
        :S12000014,
        :S12000047,
        :S12000049,
        :S12000017,
        :S12000018,
        :S12000019,
        :S12000020,
        :S12000013,
        :S12000021,
        :S12000050,
        :S12000023,
        :S12000048,
        :S12000038,
        :S12000026,
        :S12000027,
        :S12000028,
        :S12000029,
        :S12000030,
        :S12000039,
        :S12000040
    ]

    const LA_NAMES = Dict(
        :S12000033 => "Aberdeen City",
        :S12000034 => "Aberdeenshire",
        :S12000041 => "Angus",
        :S12000035 => "Argyll and Bute",
        :S12000036 => "City of Edinburgh",
        :S12000005 => "Clackmannanshire",
        :S12000006 => "Dumfries and Galloway",
        :S12000042 => "Dundee City",
        :S12000008 => "East Ayrshire",
        :S12000045 => "East Dunbartonshire",
        :S12000010 => "East Lothian",
        :S12000011 => "East Renfrewshire",
        :S12000014 => "Falkirk",
        :S12000047 => "Fife",
        :S12000049 => "Glasgow City",
        :S12000017 => "Highland",
        :S12000018 => "Inverclyde",
        :S12000019 => "Midlothian",
        :S12000020 => "Moray",
        :S12000013 => "Na h-Eileanan Siar",
        :S12000021 => "North Ayrshire",
        :S12000050 => "North Lanarkshire",
        :S12000023 => "Orkney Islands",
        :S12000048 => "Perth and Kinross",
        :S12000038 => "Renfrewshire",
        :S12000026 => "Scottish Borders",
        :S12000027 => "Shetland Islands",
        :S12000028 => "South Ayrshire",
        :S12000029 => "South Lanarkshire",
        :S12000030 => "Stirling",
        :S12000039 => "West Dunbartonshire",
        :S12000040 => "West Lothian"
    )

    # FIXME hard code this in
    function make_la_to_brma_map()
        lacsv = CSV.File( "$(MODEL_DATA_DIR)/local/la_to_brma_approx_mappings.csv" ) |> DataFrame
        out = Dict{Symbol,Symbol}()
        for r in eachrow( lacsv )
            out[Symbol(r.ccode)] = Symbol(r.bcode)
        end
        return out
    end



    struct LA_To_BRMA_Wrap
        map :: Dict{Symbol,Symbol}
    end

    const LA_BRMA_MAP = LA_To_BRMA_Wrap( make_la_to_brma_map() )

    function lookup( data , key :: Symbol ) :: T where T
        return data[key]
    end

    function lookup( x :: BRMA{N,T}, n :: Int ) :: T where T where N
        if n == 0
           return x.room
        end
        x.bedrooms[n]
    end

    function lookup( brmas :: Dict{Symbol,BRMA{N,T}}, ccode :: Symbol, i :: Int ) :: T where T where N
        bcode = LA_BRMA_MAP.map[ccode]
        return lookup( brmas[bcode], i )
    end

    #
    # local stuff for numbers of rooms. A hack, almost certainly 
    # not completely right, but near enough I hope
    # cpag ch6 p94-
    # Smallest number of rooms for U15s with the following rules:
    # 1. any u10s can share
    # 2. 10+s of same sex can share
    #
    struct P
        sex :: Sex
        age :: Int
        disabled :: Bool
        pid :: BigInt
    end
    
    function match( p1::P, p2::P )::Bool
        if p1.disabled || p2.disabled
            return false
        elseif p1.age < 10 && p2.age < 10
            return true
        elseif p1.sex == p2.sex 
            return true
        end
        return false
    end
    
    function pairup!( prs :: Array, unpaired :: Array{P} )
        n = size( unpaired )[1]
        # println( "initial unpaired = $(unpaired) n = $n " )
        # println( "initial prs $prs" )
        if n == 1
            push!( prs, unpaired[1] )  
            deleteat!( unpaired, 1 )
            return
        elseif n == 0
            return
        elseif (n == 2) && !( match( unpaired[1], unpaired[2] ))
            push!( prs, unpaired[1] )  
            deleteat!( unpaired, 1 )
            push!( prs, unpaired[1] )  
            deleteat!( unpaired, 1 )    
            return
        end
        found = false
        for i in 2:n
            p1 = unpaired[1]
            p2 = unpaired[i]
            if match( p1, p2 )
                # println( "matched 1 and $i " )
                push!( prs, [ p1, p2 ])
                # println( "prs now $prs ")
                deleteat!( unpaired, 1 )
                deleteat!( unpaired, i-1 )
                # println( "unpaired now $(unpaired)" )
                found = true
                break
           end
        end
        if ! found 
            push!( prs, unpaired[1])
            deleteat!( unpaired, 1 )
        end
        pairup!( prs, unpaired )    
    end
    
    function swap!(a::Vector,p1,p2::Int )
        tmp = a[p1]
        a[p1] = a[p2]
        a[p2] = tmp
    end
    
    """
    Smallest number of rooms for U15s with the following rules:
    1. any u10s can share
    2. 10+s of same sex can share
    FIXME This is NOT COMPLETELY RIGHT and very hacky but might be close enough
    Find someone who knows combinatorics....
    """
    function min_kids_rooms( children :: Vector{P} ) :: Int
        mr = 9999
        n = size( children )[1]    
        if n < 2 # no kids, or 1 kid
            return n
        end
        prs = []
        for i in 2:n
            prs = []
            un = copy(children)
            swap!(un, 2, i )
            pairup!( prs, un )
            sz = size( prs )[1]
            mr = min( mr, sz )
            # println(sz)
            # println( prs )
        end
        #for p in prs
        #    println(p)
        #end
        mr
    end    
    
    """
    See CPAG Part 2 ch.6; Assume here this is identical between UC and HB.
    Number of rooms is this bestial calculation for children, plus one per 
    adult not related to the HoH. Returns 0 for single people aged 35 or under in default state
    """
    function apply_size_criteria( hh :: Household, intermed :: MTIntermediate, hr :: HousingRestrictions ) :: Int
        kids = Vector{P}(undef,30)
        nkids = 0
        rooms = 0
        if intermed.num_people > 1
            for (pid,pers) in hh.people
                if pers.age < 16
                    nkids += 1
                    kids[nkids] = P( pers.sex, pers.age, is_severe_disability( pers ), pers.pid )
                else
                    if ! (pers.relationship_to_hoh in [Spouse,Cohabitee]) # some exceptions to this - see p 96
                        rooms += 1
                    end
                end
            end
        else
            rooms = get_head( hh ).age <= hr.single_room_age ? 0 : 1 # single person
        end
        # println( "rooms before kids $rooms")
        if nkids > 0
            # println( "nkids = $nkids ")
            rooms += min_kids_rooms( kids[1:nkids] )
        end 
        # println( "hh.bedrooms = $(hh.bedrooms)" )
        # println( "needed rooms = $rooms" )
        # println( "hr.maximum_rooms = $(hr.maximum_rooms)")    
        return min( rooms, hr.maximum_rooms ) #, hh.bedrooms )
    end

    """

    """
    function apply_rent_restrictions( 
        hh :: Household{RT}, 
        intermed :: MTIntermediate,
        hsys :: HousingRestrictions{RT} ) :: HousingResult{RT} where RT
        hres = HousingResult{RT}()
        if is_owner_occupier( hh.tenure )
            return hres
        end
        # You won't be affected if you - *and* your partner if you live with them - are pension age:
        if intermed.all_pension_age && is_social_renter( hh.tenure ) # fixme should this just be 1st bu?
            hres.allowed_rooms = hh.bedrooms
        else
            hres.allowed_rooms = apply_size_criteria( hh, intermed, hsys )
        end
        hres.excess_rooms = max( 0, hh.bedrooms - hres.allowed_rooms )            
        hres.gross_rent = hh.gross_rent
        hres.allowed_rent = hh.gross_rent
        # FIXME deductions from gross rent TODO
        if is_private_renter(hh.tenure)
            hr = lookup( hsys.brmas, hh.council, hres.allowed_rooms )
            hres.allowed_rent = min( hh.gross_rent, hr )
        elseif is_social_renter( hh.tenure )
            if hres.excess_rooms > 0 
                # we've fixed it above so this never applies to hhlds with anyone over pension age
                l = size(hsys.rooms_rent_reduction)[1]
                m = min( hres.excess_rooms, l )
                hres.allowed_rent = hh.gross_rent * (1-hsys.rooms_rent_reduction[m])
                hres.rooms_rent_reduction = hh.gross_rent -
                    hres.allowed_rent
            end
        end
        return hres
    end

    function calc_proportional_property_tax( 
        hh :: Household{RT}, 
        intermed :: MTIntermediate,
        pptsys :: ProportionalPropertyTax ) :: RT where RT 
        return hh.house_value * pptsys.rate        
    end

    function band_from_prices(
        band_values :: Dict,
        house_price :: Real ) :: CT_Band
        for b in enumerate( CT_Band )
            if house_price <= band_values[b]
                return b
            end
        end
        @assert false "failed to match CT Band for value $house_price"
    end


    """
    Very simple implementation of the CT scheme
    note this doesn't include rebates apart from single
    person rebate
    """
	function calc_council_tax( 
        hh :: Household{RT}, 
        intermed :: MTIntermediate,
        ctsys :: CouncilTax{RT} ) :: RT where RT 
        ctres = zero(RT)
        if hh.region != Wales
            @assert hh.ct_band != Band_I # We're not Welsh
        end
        ct_band = hh.ct_band
        if ctsys.revalue 
            ct_band = band_from_price( 
                hh.house_value, 
                ctsys.house_prices ) 
        end
        ctres = ctsys.band_d[hh.council] * 
            ctsys.relativities[ct_band]
        if intermed.num_adults == 1
            ctres *= (1-ctsys.single_person_discount)
        end
        ## TODO disabled discounts. See CT note.
        return ctres
    end
end # module