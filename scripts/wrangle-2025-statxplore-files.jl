using XLSX,DataFrames,PrettyTables

tables = [
# ca-by-nation-18-24-table_2025-03-19_15-40-01.xlsx                    
"dla-by-age-and-region-18-24-table_2025-03-19_13-45-40.xlsx",
"dla-by-age-and-region-02-18-table_2025-03-19_15-32-08.xlsx",
"pip-by-age-and-region-13-19-table_2025-03-19_16-23-07.xlsx",
"pip-by-age-and-region-19-25-table_2025-03-19_16-04-49.xlsx"
]

dir = joinpath( "data", "2025-6")

for tab in tables
    fname = joinpath( dir, tab )
    println( "Opening $fname" )
    d1 = XLSX.readtable( fname, 3, "B:AB"; first_row=11)|>DataFrame
    delete!(d1,1)
    println( "1st sheet data")
    pretty_table( d1 )
    nrows,ncols = size(d1)    
    for sheet in 4:12
        d2 = XLSX.readtable( fname, sheet, "B:AB"; first_row=11)|>DataFrame
        delete!(d2,1)
        @assert size(d1) == size(d2)
        for r in 1:nrows, c in 1:ncols
            if (typeof( d2[r,c] )<:Number) && (typeof(d1[r,c])<:Number)
                d1[r,c] += d2[r,c]
            end
        end
    end # sheets
    d1 = permutedims(d1,1)
    println( "final table")
    pretty_table(d1)
end # tables
