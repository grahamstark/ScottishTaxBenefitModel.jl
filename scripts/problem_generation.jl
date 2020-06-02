# example 2
using Statistics
using Distributions
using DelimitedFiles
using VegaLite
using DataFrames

const INC_SIZE = 1_000
const activity_DIR="/home/graham_s/OU/DD226/docs/activities/"
incomes = zeros( INC_SIZE )
for i in 1:INC_SIZE
    incomes[i] = 1_000*exp(randn()) # kinda log-normal
end
sort!( incomes )
println("mean  ", mean(incomes))
println( "median ", median(incomes))
println( "kurtosis ", kurtosis(incomes))

writedlm( "$activity_DIR/activity_1.csv", incomes )

incframe = DataFrame( incomes=incomes )

plot_1 = incframe |>
 @vlplot(:bar,
    x={:incomes, bin={maxbins=40}},
    y="count()")

save( "$activity_DIR/activity_1.svg", plot_1 )

const GR_SIZE=100
incomes = zeros(GR_SIZE)
person = zeros(Int8,GR_SIZE)
for i in 1:GR_SIZE
    if rand() < (1/3) # (GR_SIZE ÷ 3)
        pt = 2
        pm = 500.0
    else
        pt = 1
        pm = 1000.0
    end
    incomes[i] = pm*exp(randn())
    person[i] = pt
end

writedlm(  "$activity_DIR/activity_2.csv", person )

non_pensioners = 5_000
pensioners = 5_000
populaton = non_pensioners + pensioners
wp = pensioners/ (sum( person.==2))
wnp = non_pensioners / (sum( person.==1))

gw = population/sum(person)

for i in 1:GR_SIZE
    global wp, wnp, pe;
    if person[i]==2
          pe += wp
    else
         pe += wnp
    end
end

print pe


wnp = 74.6268656716418

wp = 151.515151515151

gw = population/(size(person)[1])


print(sum( person.==1))


function mapep(p::Integer)::String

    if p == 0
        return "Not recorded"
    elseif p == 1
        return "Self-employed"
    elseif p in 2:3
        return "Employee"
    elseif p in 4:5
        return "Unemployed/Training Programme"
    elseif p in 6:7
        return "Retired/unoccupied"

    end
end

lcf = CSV.File( "/home/graham_s/OU/DD226/docs/activities/activity_3.csv", delim='\t' ) |> DataFrame

lcf[!,:economic_position] = mapep.(lcf.economic_pos)

plot_inc_vs_cons = lcf |> @vlplot(
    mark={:point,size=1,opacity=0.5},
    opactity=0.5,
    columns=2,
    y=:total_consumpt,
    x=:weekly_net_inc,
    wrap=:economic_position )


save( "$activity_DIR/activity_5.svg", plot_inc_vs_cons )

save( "$activity_DIR/activity_5.png", plot_inc_vs_cons )
