module EquivalenceScales
    
    export
        EQ_P_Type,
        EQ_Person, 
        EQScales, 
        eq_dependent_child,
        eq_head,
        eq_other_adult,
        eq_spouse_of_head,
        get_equivalence_scales


    @enum EQ_P_Type eq_head eq_spouse_of_head eq_other_adult eq_dependent_child
    @enum Scales oecd oxford mcclements square_root
    struct EQ_Person
        age :: Int
        eqtype :: EQ_P_Type
    end

    struct EQScales{T<:Real}
        oecd :: T 
        oxford :: T
        mcclements :: T
        square_root :: T
    end

    function onescale( T::Type, scale :: Scales, perss::Vector{EQ_Person}) :: T
        s = zero(T)
        n = size(perss)[1]
        add = zero(T)
        eq = zero(T)
        if scale == square_root
            return sqrt(n)
        elseif scale in [oxford,oecd]
            for p in perss
                if p.eqtype == eq_head
                    eq += 1
                else
                    if p.age <= 14
                        add = scale == oxford ? 0.5 : 0.3
                    else
                        add = scale == oxford ? 0.5 : 0.3
                    end
                    eq += add
                end
            end # pers loop
            @assert eq >= 1
        elseif scale == mcclements
            num_extra_adults = 0
            for p in perss
                if p.eqtype == eq_head
                    eq += 1
                elseif p.eq_type == eq_spouse_of_head
                    eq += 0.64
                elseif p.eqtype == eq_other_adult
                    num_extra_adults += 1
                    if num_extra_adults == 1
                        eq += 0.75
                    elseif num_extra_adults == 2
                        eq += 0.69
                    else
                        eq += 0.59
                    end
                elseif p.eqtype == eq_dependent_child
                    if p.age in 0:1 => 
                        eq += 0.148
                    elseif p.age in 2:4 => 
                        eq += 0.295
                    elseif p.age in 5:7 => 
                        eq += 0.344
                    elseif p.age in 8:10 => 
                        eq += 0.377
                    elseif p.age in 11:12 => 
                        eq += 0.41
                    elseif p.age in 13:15 => 
                        eq += 0.443
                    elseif p.age in 16:21
                        eq += 0.59
                    end 
                end # dependent child
            end # mcclements
            
        end
        return eq
    end

    function get_equivalence_scales( T :: Type, perss::Vector{EQ_Person}) :: EQScales{T} 
        oecd = onescale( T, oecd, perss )
        oxford = onescale( T, oxford, perss )
        mcclements = onescale( T, mcclements, perss )
        square_root = onescale( T, square_root, perss )
        return EQScales{T}( oecd, oxford, mclements, square_root )
    end

end