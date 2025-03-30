using CSV, DataFrames, StatsBase
p24 = CSV.File("2024/people.tab")|>DataFrame
p25 = CSV.File("2025/people.tab")|>DataFrame
pb = leftjoin(p24b,p25; on=[:data_year,:pid], makeunique=true)
n24 = intersect(names(p24), names(p25))
for n in n24[5:end]
    n1=Symbol(n)
    n2=Symbol("$(n)_1")
    ds = sum(pb[!,n1] .!== pb[!,n2])
    if ds !== 0
        println("$n = $ds")
    end
end
