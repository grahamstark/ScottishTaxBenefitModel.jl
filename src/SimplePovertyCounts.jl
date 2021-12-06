module SimplePovertyCounts

using DataFrames

export GroupPoverty, line_count, calc_child_poverty

   struct GroupPoverty{T<:Real}
        total :: T
        affected :: T
        pct :: T
    end

    function line_count( 
        line    :: T, 
        data  :: DataFrame;
        counter :: Symbol,
        measure :: Symbol,
        weight  :: Symbol ) :: GroupPoverty{T} where T <: Real
        tot :: Real = 0.0
        aff :: Real = 0.0
        for r in eachrow( data )
            inc = r[measure]
            w = r[weight]
            m = r[counter]
            wm = w*m
            tot += wm
            if inc <= line
                aff += wm
            end
        end
        return GroupPoverty{T}(tot, aff, aff/tot )
    end
    
    function calc_child_poverty( 
        line    :: T, 
        hhdata  :: DataFrame;
        measure :: Symbol ) :: GroupPoverty{T} where T <: Real
        return line_count( line, hhdata; 
            counter = :num_children,
            measure = measure,
            weight = :weight )
    end

end