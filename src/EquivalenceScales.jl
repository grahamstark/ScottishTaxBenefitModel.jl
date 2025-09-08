module EquivalenceScales
    #
    # This module implements a set of standard-ish Equivalence Scales, mainly taken from 
    #  https://www.gov.scot/binaries/content/documents/govscot/publications/statistics/2020/01/equivalence-scales/documents/equivalence-scales-rationales-uses-and-assumptions/equivalence-scales-rationales-uses-and-assumptions/govscot%3Adocument/paper%2Bdiscussing%2Bequivalence%2Bscales%2Band%2Bunderlying%2Bassumptions.pdf
    #
    # As part of this, it describes a simple interface that can be used by any data structure than 
    # contains records of people with ages and relationships.
    #
    export
        EQ_P_Type,
        EQ_Person, 
        EQScales, 
        eq_dependent_child,
        eq_head,
        eq_other_adult,
        eq_spouse_of_head,
        get_equivalence_scales,
        get_age,
        eq_rel_to_hoh


    @enum EQ_P_Type eq_head eq_spouse_of_head eq_other_adult eq_dependent_child
    @enum Scales oecd oxford mcclements square_root per_capita
    struct EQ_Person
        age :: Int
        eqtype :: EQ_P_Type
    end

    struct EQScales{T<:Real}
        oxford :: T
        oecd_bhc :: T 
        oecd_ahc :: T
        mcclements_bhc :: T
        mcclements_ahc :: T
        square_root :: T
        per_capita :: T
    end

    function eq_rel_to_hoh( p )::EQ_P_Type
        p.eqtype
    end

    function get_age( p )::Int
        p.age        
    end

    """
    More Julian version, perhaps?
    """
    function onescale( T::Type, scale :: Scales, perss , before_hc :: Bool ) :: T
        s = zero(T)
        n = size(perss)[1]
        add = zero(T)
        eq = zero(T)
        if scale == per_capita
            return n
        elseif scale == square_root
            return sqrt(n)
        elseif scale in [oxford,oecd]
            for p in perss
                rel = eq_rel_to_hoh(p)
                if rel == eq_head
                    eq += 1
                elseif n == 1
                    eq += 1
                    println( "only 1 person; non head rel=$rel $(p.hid)")
                else
                    if get_age(p) < 14
                        add = if scale == oxford 
                            0.5
                        elseif scale == oecd 
                            before_hc ? 0.3 : 0.34
                        end
                    else
                        add = if scale == oxford 
                            0.7
                        elseif scale == oecd 
                            before_hc ? 0.5 : 0.72
                        end
                    end
                    eq += add
                end
            end # pers loop
            @assert eq >= 1 "eq is $eq num people $n scale $scale  $(perss[1].hid)"
        elseif scale == mcclements
            num_extra_adults = 0
            for p in perss
                age = get_age(p)
                rel = eq_rel_to_hoh( p )
                if rel == eq_head
                    eq += 1
                elseif rel == eq_spouse_of_head
                    eq += before_hc ? 0.64 : 0.82
                elseif rel == eq_other_adult
                    num_extra_adults += 1
                    if num_extra_adults == 1
                        eq += before_hc ? 0.75 : 0.82
                    elseif num_extra_adults == 2
                        eq += before_hc ? 0.69 : 0.82
                    else
                        eq += before_hc ? 0.59 : 0.73
                    end
                elseif rel == eq_dependent_child
                    if age in 0:1
                        eq += before_hc ? 0.148 : 0.13
                    elseif age in 2:4
                        eq += before_hc ?  0.295 : 0.33
                    elseif age in 5:7 
                        eq += before_hc ? 0.344 : 0.38
                    elseif age in 8:10 
                        eq += before_hc ? 0.377 : 0.42
                    elseif age in 11:12  
                        eq += before_hc ? 0.41 : 0.47
                    elseif age in 13:15 
                        eq += before_hc ? 0.443 : 0.51
                    elseif age in 16:21
                        eq += before_hc ? 0.59 : 0.69
                    end 
                end # dependent child
            end # mcclements
        end
        return eq
    end


    #
    # more julian? anything with get_age, get_relation_to_hoh
    #

    """
    Make a struct full of Equivalence Scales; see: 
    https://www.gov.scot/binaries/content/documents/govscot/publications/statistics/2020/01/equivalence-scales/documents/equivalence-scales-rationales-uses-and-assumptions/equivalence-scales-rationales-uses-and-assumptions/govscot%3Adocument/paper%2Bdiscussing%2Bequivalence%2Bscales%2Band%2Bunderlying%2Bassumptions.pdf
    perss is some collection of things each of which can respond to 
    `get_age` and `eq_get_rel`
    """
    function get_equivalence_scales( T :: Type, perss ) :: EQScales{T} 
        v_oecd_bhc = onescale( T, oecd, perss, true )
        v_oecd_ahc = onescale( T, oecd, perss, false )
        v_oxford = onescale( T, oxford, perss, false ) # bhc irrelevant
        v_mcclements_bhc = onescale( T, mcclements, perss, true )
        v_mcclements_ahc = onescale( T, mcclements, perss, false )
        v_square_root = onescale( T, square_root, perss, false )
        v_per_capita = onescale( T, per_capita, perss, false )
        return EQScales{T}( 
            v_oxford,
            v_oecd_bhc, 
            v_oecd_ahc,  
            v_mcclements_bhc, 
            v_mcclements_ahc, 
            v_square_root, 
            v_per_capita )
    end

end