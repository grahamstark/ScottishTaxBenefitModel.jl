


@usingany CairoMakie
@usingany Format
@usingany PrettyTables
@usingany CSV
@usingany DataFrames
using ScottishTaxBenefitModel
using .STBIncomes
using .BCCalcs
using .Results

include( "generate_bcs_for_essex.jl")

const WPM = 4.354
const DIR = joinpath("/","mnt", "data", "FES-Project", "Essex", "bc-comparisons" ) 

# convoluted way of making pairs of (0,-10),(0,10) for label offsets
const OFFSETS = collect( Iterators.flatten(fill([(0,-10),(0,10)],100)))

function draw_bc( title :: String, sbdf :: DataFrame, exdf :: DataFrame )::Figure
    f = Figure(size=(1200,1200))
    nrows = size(sbdf)[1]
    xmax = max(  maximum(exdf.gross), maximum(sbdf.gross))*1.1
    ymax = max(  maximum(exdf.uc), maximum(sbdf.net))*1.1
    ymin = min( minimum(exdf.uc), minimum(sbdf.net))
    
    ax = Axis(f[1,1]; xlabel="Earnings &pound;s pw", ylabel="Net Income (AHC) &pound;s pw", title=title)
    ylims!( ax, ymin, xmax ) # make this one square
    xlims!( ax, -10, xmax )
    lines!( ax, sbdf.gross, sbdf.net; color=:darkgreen, label="ScotBen" )
    scatter!( ax, 
        sbdf.gross, 
        sbdf.net; 
        marker=sbdf.char_labels,
        marker_offset=OFFSETS[1:nrows], 
        markersize=15, 
        color=:black )
    lines!( ax, [0,xmax], [0, xmax]; color=:lightgrey ) # 45° line
    scatter!( ax, sbdf.gross, sbdf.net, markersize=5, color=:darkgreen )
    lines!(ax, exdf.gross, exdf.uc; color=:darkblue, label="Essex" )
    f[1,2] = Legend( f, ax, framevisible = false )
    f
end


function various_tests()

    function interpolate( sbdf::AbstractDataFrame, tgross :: Number )::Number
        n = size(sbdf)[1]
        gross = 9999999999999.99
        interp = 0.0
        for r in n:-1:1
            row = sbdf[r,:]
            gross = row.gross
            net = row.net
            lgross = 0.0
            lnet = 0.0
            if gross < tgross 
                if (r > 1) & (r < n)
                    lgross = sbdf[r+1,:gross]
                    lnet = sbdf[r+1,:net]
                end
                dx = (lgross - gross)
                dy = (lnet - net)
                δ = dy/dx
                println( "dx=$dx dy=$dy δ=$δ gross=$gross tgross=$tgross lgross=$lgross lnet=$lnet")
                interp = (δ*(tgross - lgross))+lnet
                break
            end
        end
        interp 
    end

    for row in eachrow( sbdf )
        gross = row.gross
        net = row.net
        computed = gross
        for i in 1:30
            ik = Symbol( "item_$(i)")
            vk = Symbol( "value_$(i)")
            k = row[ik]
            v = row[vk]
            if ! ismissing(k)
                # println( "gross $gross net = $net $k=$v")
                if k == "Wages"
                    ;
                elseif k in ["Income Tax", "National Insurance", "Local Taxes"]
                    computed -= v
                else
                    computed += v
                end            
            end        
        end
        computed -= 200
        @assert isapprox(net,computed; atol=0.02) "Net: $net Computed $computed"
        println( "gross = $gross net=$net OK")
    end

    for r in eachrow( exdf )
        sbn = interpolate( sbdf, r.gross )
        diff = sbn - r.uc
        println( "r.gross=$(r.gross) sbnet=$(sbn) exnet=$(r.uc) diff=$(diff)")
    end
end # junk

function match_essex( exdf :: DataFrame ) :: Tuple
    hh =  get_hh( ;
            country = "scotland",
            tenure  =  "private",
            bedrooms = 1,
            hcost    = 200,
            marrstat = "single", 
            chu6     = 0, 
            ch6p     = 0 )
    settings = Settings()
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    head = get_head( hh )
    data = Dict([
        :pid  => head.pid,
        :wage => 12.0,
        :hh   => deepcopy(hh),
        :sys  => sys,
        :settings => settings ])
    outd = deepcopy( exdf )
    n = size(outd)[1]
    outd.INCOME_TAX = zeros(n)
    outd.NATIONAL_INSURANCE  = zeros(n)
    outd.LOCAL_TAXES  = zeros(n)
    outd.UNIVERSAL_CREDIT  = zeros(n)
    outd.COUNCIL_TAX_BENEFIT = zeros(n)
    outd.Scotben_Net_UC = zeros(n)
    outx = Vector{Any}(undef,n)
    i = 0
    for r in eachrow( outd )
        i += 1
        hres = BCCalcs.local_getnet( data, r.gross )
        r.Scotben_Net_UC = get_net_income( hres; target = data[:settings].target_bc_income )
        for i in [INCOME_TAX, NATIONAL_INSURANCE, LOCAL_TAXES, UNIVERSAL_CREDIT, COUNCIL_TAX_BENEFIT ]
            c = Symbol(string(i))
            r[c] = hres.income[i]
        end
        outx[i] = hres
    end
    outd, outx
end

sbdf = CSV.File( "$(DIR)/uc-12-private-single-200.0-1-0-0.tab"; delim='\t')|>DataFrame
exdf = CSV.File( "$(DIR)/euromod-bc-summary-1.tab"; delim='\t')|>DataFrame
sbdf.char_labels = BCCalcs.get_char_labels(size(sbdf)[1])    
exdf.gross ./= WPM
exdf.uc  ./= WPM
exdf.legacy  ./= WPM

f1 = draw_bc( "example1", sbdf, exdf )

outd, outx = match_essex( exdf )

for c in eachcol(outd)
    c .*= WPM
    c .= round.(c; digits=2)
end

outd.uc_diff = outd.Scotben_Net_UC - outd.uc
rename!( pretty, outd )

CSV.write( "$(DIR)/euromod-sb-comparison-1.tab", outd; delim='\t' )
save( "$(DIR)/euromod-sb-comparison-1.svg", f1 )
