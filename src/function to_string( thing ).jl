"""
Crude but more-or-less effective thing that prints out a struct (which may contain other structs) as
a markdown table. 
"""
function to_md_table( f; exclude=[], depth=0 ) :: String
    F = typeof(f)
    @assert isstructtype( F )
    names = fieldnames(F)
    prinames = []
    structnames = []

    for n in names
        v = getfield(f,n)
        if n in exclude 
            ;
        elseif isstructtype( typeof(v))
            push!(structnames, n )
        else
            push!(prinames, n )
        end
    end
    s = """
    |            |              |
    |:-----------|-------------:|
    """
    for n in prinames
        v = getfield(f,n)
        s *= "|$n|$v|\n"
    end
    s *= "\n\n"
    depth += 1
    for n in structnames
        v = getfield(f,n)
        s *= "#"*repeat( "#", depth ) * "$n\n"
        s *= to_md_table( v, exclude=exclude, depth=depth )
    end
    return s;
end
