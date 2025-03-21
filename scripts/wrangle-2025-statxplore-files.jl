using XLSX,DataFrames,PrettyTables,CSV
#=

This aggregates all the by year group stuff into an aggregate for 16-65
year olds. So we can tra

=#

const DATADIR = joinpath( "/", "mnt","data", "ScotBen", "data", "2025-6")

function outtabname( tab::String)::String 
    fn = match(r"(.*)-table.*",tab)[1]
    return joinpath( DATADIR, "$(fn).tab" )
end

const TABLES = [
# fname, startsheet, endsheet, cols
("dla-by-age-and-region-02-18-table_2025-03-19_15-32-08.xlsx",4,13,"B:BN"),
("dla-by-age-and-region-18-24-table_2025-03-19_13-45-40.xlsx",4,13,"B:AB"),
("pip-by-age-and-region-13-19-table_2025-03-19_16-23-07.xlsx",1,10,"B:BS"),
("pip-by-age-and-region-19-25-table_2025-03-19_16-04-49.xlsx",1,10,"B:BW")]

function make_all()
    n = 0
    outtabs = []
    for tab in TABLES
        global n
        n += 1
        infname = joinpath( DATADIR, tab[1] )
        outfname = outtabname(tab[1])
        startsheet=tab[2]
        endsheet=tab[3]
        println( "Opening $infname" )
        local d1 = XLSX.readtable( infname, startsheet, tab[4]; first_row=11)|>DataFrame
        delete!(d1,1)
        println( "1st sheet data")
        pretty_table( d1 )
        nrows,ncols = size(d1)    
        for sheet in (startsheet+1):endsheet
            local d2 = XLSX.readtable( infname, sheet, tab[4]; first_row=11)|>DataFrame
            delete!(d2,1)
            @assert size(d1) == size(d2)
            for r in 1:nrows, c in 1:ncols
                if (typeof( d2[r,c] )<:Number) && (typeof(d1[r,c])<:Number)
                    d1[r,c] += d2[r,c]
                end
            end
        end # sheets
        d1 = permutedims(d1,1) # rows -> cols
        println( names(d1))
        #=
        newnames = if n in [1,3]
            [:x, :England, :Wales, :Scotland, :UnknownOrMissing, :Total]
        elseif ben == "dla"
            [:x,:DWP,:Scotland,:England,:Wales,:Abroad,:Unknown,:Scotland2,:Total]
        else
            [:x,:DWP,:Scotland,:England_Wales,:Abroad,:Unknown,:Scotland2,:Total]
        end
        rename!(d1, newnames)
        =#
        println( "final table $outfname")
        pretty_table(d1[end-20:end,:])
        push!( outtabs, d1 )
        CSV.write( outfname, d1; delim="\t")
    end # tables
    return outtabs
end

outtabs = make_all()
rename!.(outtabs, ([:missing=>:date],))

alldla = vcat(outtabs[1][!,[:date,:Scotland,:Total]], outtabs[2][!,[:date,:Scotland,:Total]] )
allpip = vcat(outtabs[3][!,[:date,:Scotland,:Total]], outtabs[4][!,[:date,:Scotland,:Total]] )
