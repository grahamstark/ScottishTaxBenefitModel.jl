using XLSX,DataFrames,PrettyTables,CSV
#=

This aggregates all the by year group stuff into an aggregate for 16-65
year olds. So we can tra

=#
tables = [
# fname, startsheet, endsheet, cols
("dla-by-age-and-region-02-18-table_2025-03-19_15-32-08.xlsx",4,13,"B:BN"),
("dla-by-age-and-region-18-24-table_2025-03-19_13-45-40.xlsx",4,13,"B:AB"),
("pip-by-age-and-region-13-19-table_2025-03-19_16-23-07.xlsx",1,10,"B:BS"),
("pip-by-age-and-region-19-25-table_2025-03-19_16-04-49.xlsx",1,10,"B:BW")
]

dir = joinpath( "/", "mnt","data", "ScotBen", "data", "2025-6")

for tab in tables
    infname = joinpath( dir, tab[1] )
    fn = match(r"(.*)-table.*",tab[1])[1]
    outfname = joinpath( dir, "$(fn).tab" )
    startsheet=tab[2]
    endsheet=tab[3]
    println( "Opening $infname" )
    d1 = XLSX.readtable( infname, startsheet, tab[4]; first_row=11)|>DataFrame
    delete!(d1,1)
    println( "1st sheet data")
    pretty_table( d1 )
    nrows,ncols = size(d1)    
    for sheet in (startsheet+1):endsheet
        d2 = XLSX.readtable( infname, sheet, tab[4]; first_row=11)|>DataFrame
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
    CSV.write( outfname, d1; delim="\t")
end # tables
