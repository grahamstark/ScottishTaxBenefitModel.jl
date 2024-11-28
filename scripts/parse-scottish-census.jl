using CSV, DataFrames

function readc(filename::String)::Tuple
    d = (CSV.File( filename; normalizenames=true, header=10, skipto=12)|>DataFrame)
    if ismissing(d[1,2])
        delete!( )
    end
    label = names(d)[1]
    actuald = d[1:33,2:end]
    nms = names(actuald)
    rename!(actuald,1=>"Authority")
    actuald, label, nms
end

function read_all()
    fs = sort(readdir("."))
    n = 0
    allfs = nothing
    rows = 0
    cols = 0
    nfs = length(fs)
    labels = DataFrame( filename=fill("",nfs), label=fill("",nfs), start=zeros(Int,nfs) )
    for f in fs
        if ! isnothing(match(r"^table.*.csv$",f))
            n += 1
            println( "on $f")
            data, label, nms = readc(f)
            println(nms)
            println(label)
            println(data)
            labels.filename[n] = f
            labels.label[n]=label
            labels.start[n]=cols+2        
            if n == 1
                allfs = deepcopy( data )
            else
                n1 = String.(data[:,1])[1:8] # skip "Na hEileanan Siar", since it's sometimes edited
                n2 = String.(allfs[:,1])[1:8]
                @assert n1 == n2 "$(n1) !== $(n2)" # check in sync
                allfs = hcat( allfs, data; makeunique=true )
                rows,cols = size(allfs)                
            end
            # println( "label=$label")
        end
    end
    allfs,labels[1:n,:]
end
allfs,labels = read_all()


ctbase=CSV.File("CTAXBASE+2024+-+Tables+-+Chargeable+Dwellings.csv",normalizenames=true)|>DataFrame
allfs = hcat( allfs, ctbase; makeunique=true )

CSV.write( "labels.tab", labels; delim='\t')
CSV.write( "allfs.tab", allfs; delim='\t' )
