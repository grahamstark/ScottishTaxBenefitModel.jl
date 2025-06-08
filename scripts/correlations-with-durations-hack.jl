using StatsBase, PrettyTables, HypothesisTests,CSV,DataFrames,ActNow
using CairoMakie

function lovelevel( i :: Int )
    return if i >= 70
        "love"
    elseif i <= 30
        "hate"
    else
        "middle"
    end
end 

pols = ActNow.POLICIES
n = length(pols)
out = DataFrame( 
    policies=fill("",n), 
    correlation=zeros(n), c
    orr_pvalue = zeros(n), 
    mean_Hate_duration = zeros(n),
    mean_Middle_duration = zeros(n),
    mean_Lovers_duration = zeros(n), 
    p_hate_love_duration_eq = zeros(n))
i = 0

f = Figure()
rename(wave4, "Duration (in seconds)"=>"Duration")
r = 1
c = 0
for pol in pols
    i += 1
    # grid pos for graphs
    c += 1
    if c == 3
        r += 1
        c = 1
    end
    out.policies[i] = "$pol"
    ppost = Symbol("$(pol)_post")
    onescore = wave4[!,ppost]
    out.correlation[i] = cor( onescore, wave4.Duration)
    out.corr_pvalue[i] = pvalue( HypothesisTests.CorrelationTest( onescore, wave4.duration))
    out.hatelove = lovelevel.( onescore )
    ax = axis(r,c,title="$ppost : duration vs approval")
    dallg = Dict()
    colour = Dict(["Middle"=>:darkgrey,"Lovers"=>:green,"Haters"=>:red])
    for group in ["Middle","Lovers","Haters"]
            dallg[group] = if group == "Lovers"
                dall[onescore .> 70, : ],
            elseif group == "Haters"
                dall[onescore .< 30, : ],
            else
                dall[onescore .>= 30 .& dall[onescore .<= 70, : ],
            end
    end
    for group in ["Middle","Lovers","Haters"]
        points!( ax, dallg.duration, dallg[!,ppost]; color=colour)

    end

end
save( "durations-vs-scores.svg", f )

rename!( out, ["correlation" => "Correlation Approval (post) vs Duration", "pvalue" => "P. Value"])
pretty_table(out)
s

