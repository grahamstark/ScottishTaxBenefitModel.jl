module ExampleTables
#
# This will eventually contain a taxben style seekable table
#

using DataFrames

struct ExampleTable
    colrange :: Vector
    rownames :: Vector
    data :: DataFrame
    examples :: DataFrame
end

function ExampleTable( d :: DataFrame )
    d2 = deepcopy( d )
    ExampleTable( d, d2 )
end

function ExampleTable( colrange :: Vector{T<:Real}, rownames :: Vector )
    Exan

end

end
