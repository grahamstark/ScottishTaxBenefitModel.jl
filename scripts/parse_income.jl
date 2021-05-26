#
# some stuff for generating the incomes module
# output will need hand-editing.
#
n = 0
items = []
for line in eachline("etc/incomes.txt")
    global n, items
    m = match(r" *(.*?) *=.*", line )
    if m !== nothing
        # print(m[1])
        s = m[1]
        su = uppercase(s)
        if s[1] !== '#'
            push!(items,(s,su))
        end
    end
end
println("\n\n# declarations  ----------------")
n = size(items)[1]
for i in 1:n
    println("    const $(items[i][2]) = $i")
end

println("\n\n# names ----------------")
for i in 1:n
    censored = titlecase(replace(items[i][1], r"[_]" => " "))
    print("    elseif i == $(items[i][2])
            return \"$censored\"
    ")
end

println("\n\n# mappings ----------------")
for i in 1:n
    k = items[i][2]
    j = items[i][1]
    if match( r"SPARE.*", k ) == nothing
        print( "
        if haskey(incd, Definitions.$j )
            out[$k] = incd[Definitions.$j]
        end")
    end
end

println("\n\n# exports ----------------")
for i in 1:n
    k = items[i][2]
    println("export $k")
end

