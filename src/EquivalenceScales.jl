module EquivalenceScales
    
    export
        EQ_P_Type,
        EQ_Person, 
        EQScales, 
        eq_head,
        eq_other_adult,
        eq_spouse_of_head,
        get_equivalence_scales
    

    @enum EQ_P_Type eq_head eq_spouse_of_head eq_other_adult 

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

    function get_equivalence_scales( T :: Type, perss::Vector{EQ_Person}) :: EQScales{T} 
        oecd = zero(T) 
        oxford = zero(T)
        mcclements = zero(T)
        square_root = zero(T)

        return EQScales( oecd, oxford, mclements, square_root )
    end

end