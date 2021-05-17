module LocalLevelCalculations

using ScottishTaxBenefitModel
using .Definitions

using .ModelHousehold: Person, BenefitUnit, Household, get_head, num_people, is_severe_disability
using .Intermediate: MTIntermediate
    
using .STBParameters
    
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands
using .Results: HousingResult
using StaticArrays
using CSV,DataFrames

export apply_size_criteria, make_la_to_brma_map, LA_BRMA_MAP, lookup, calc_council_tax, apply_rent_restrictions

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
        println( "rooms before kids $rooms")
        if nkids > 0
            println( "nkids = $nkids ")
            rooms += min_kids_rooms( kids[1:nkids] )
        end 
        println( "hh.bedrooms = $(hh.bedrooms)" )
        println( "needed rooms = $rooms" )
        println( "hr.maximum_rooms = $(hr.maximum_rooms)")    
        return min( rooms, hr.maximum_rooms, hh.bedrooms )
    end

    
    function apply_rent_restrictions( 
        hh :: Household{RT}, 
        intermed :: MTIntermediate,
        hsys :: HousingRestrictions{RT} ) :: HousingResult{RT} where RT
        hres = HousingResult{RT}()
        if owner_occupier( hh.tenure )
            return hres
        end
        # You won't be affected if you - *and* your partner if you live with them - are pension age:
        if intermed.all_pension_age && social_renter( hh.tenure ) # fixme should this just be 1st bu?
            hres.allowed_rooms = hh.bedrooms
        else
            hres.allowed_rooms = apply_size_criteria( hh, intermed, hsys )
        end
        hres.excess_rooms = max( 0, hh.bedrooms - hres.allowed_rooms )            
        hres.gross_rent = hh.gross_rent
        hres.allowed_rent = hh.gross_rent
        # FIXME deductions from gross rent TODO
        if private_renter(hh.tenure)
            hr = lookup( hsys.brmas, hh.council, hres.allowed_rooms )
            hres.allowed_rent = min( hh.gross_rent, hr )
        elseif social_renter( hh.tenure )
            if hres.excess_rooms  > 0 
                # we've fixed it above so this never applies to hhlds with anyone over pension age
                l = size(hsys.rooms_rent_reduction)[1]
                m = min( hres.excess_rooms, l )
                hres.allowed_rent = hh.gross_rent * (1-hsys.rooms_rent_reduction[m])
            end
        end
        return hres
    end

	function calc_council_tax( hh :: Household ) :: AbstractFloat
	
	end

end # module
