

@usingany CairoMakie
@usingany Format
@usingany PrettyTables
@usingany CSV
@usingany DataFrames
using ScottishTaxBenefitModel
using .BCCalcs

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


sbdf = CSV.File( "$(DIR)/uc-12-private-single-200.0-1-0-0.tab"; delim='\t')|>DataFrame
exdf = CSV.File( "$(DIR)/euromod-bc-summary-1.tab"; delim='\t')|>DataFrame
sbdf.char_labels = BCCalcs.get_char_labels(size(sbdf)[1])
    
exdf.gross ./= WPM
exdf.uc  ./= WPM
exdf.legacy  ./= WPM

f1 = draw_bc( "example1", sbdf, exdf )

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