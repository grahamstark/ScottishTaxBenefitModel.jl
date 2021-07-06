using CSV,DataFrames,SurveyDataWeighting

hhs=CSV.File( "house_info.tab" )|>DataFrame
people = CSV.File( "person_info.tab")|>DataFrame
targets = CSV.File( "pop_targets.csv")|>DataFrame
nhh = size(hhs)[1]
out = DataFrame(
    # hhid = zeros(Int,nhh),

    female_00_04=zeros(Int, nhh),
    male_00_04=zeros(Int, nhh),
    
    female_05_09=zeros(Int, nhh),
    male_05_09=zeros(Int, nhh),
    
    female_10_14=zeros(Int, nhh),
    male_10_14=zeros(Int, nhh),
    
    female_15_19=zeros(Int, nhh),
    male_15_19=zeros(Int, nhh),
    
    female_20_24=zeros(Int, nhh),
    male_20_24=zeros(Int, nhh),
    
    female_25_29=zeros(Int, nhh),
    male_25_29=zeros(Int, nhh),
    
    female_30_34=zeros(Int, nhh),
    male_30_34=zeros(Int, nhh),
    
    female_35_39=zeros(Int, nhh),
    male_35_39=zeros(Int, nhh),
    
    female_40_44=zeros(Int, nhh),
    male_40_44=zeros(Int, nhh),
    
    female_45_49=zeros(Int, nhh),
    male_45_49=zeros(Int, nhh),
    
    female_50_54=zeros(Int, nhh),
    male_50_54=zeros(Int, nhh),
    
    female_55_59=zeros(Int, nhh),
    male_55_59=zeros(Int, nhh),
    
    female_60_64=zeros(Int, nhh),
    male_60_64=zeros(Int, nhh),
    
    female_65_69=zeros(Int, nhh),
    male_65_69=zeros(Int, nhh),
    
    female_70_74=zeros(Int, nhh),
    male_70_74=zeros(Int, nhh),
    
    female_75_79=zeros(Int, nhh),
    male_75_79=zeros(Int, nhh),
    
    female_80_plus=zeros(Int, nhh),
    male_80_plus=zeros(Int, nhh)
)

ages = [
    "00_04","05_09",
    "10_14","15_19",
    "20_24","25_29",
    "30_34","35_39",
    "40_44","45_49",
    "50_54","55_59",
    "60_64","65_69",
    "70_74","75_79",
    "80_plus" ]


for i in 1:nhh
    hh = hhs[i,:]
    println( "on hh $i hh.UQNo=$(hh.UQNo)")
    hpers = people[(people.UQNo .== hh.UQNo),:]
    for hp in eachrow(hpers)
        a = hp.AgeGrp
        if (hp.Gender <= 2) && (a < 19)
            sexstr = hp.Gender == 1 ? "male" : "female"
            if a in 1:17
                agestr = ages[a]
            elseif a == 18
                agestr = ages[a-1]
            end
            s = Symbol("$(sexstr)_$agestr")
            out[i,s] += 1
        end
    end
end
nc=size(targets)[2]
p=0
ps=[]
for r in eachrow(out)
    global p,ps
    p += 1
    s = sum(r[2:nc-1])
    if s == 0
       push!(ps,p)
       println("zero")
    end
end
delete!(out,ps)
CSV.write( "popnfile.csv", out )


out_m=Matrix{Float64}(out)
nr=size(out_m)[1]
tv = Vector{Float64}(targets[30,2:nc])
nc = size(tv)[1] # no year col
iw = 530.0 # mean weight from data
initial_weights = ones(nr)*iw
# mean weight from 2019 household count
sa_hhlds = 17_100_000 # statistica
iw = sa_hhlds/nr
# @assert sum(initial_weights) ≈ sa_hhlds
initial_weighted_popn = (initial_weights' * out_m)'
println( "initial-weighted_popn vs targets" )
for c in 1:nc
        diffpc = 100*(initial_weighted_popn[c]-tv[c])/tv[c]
        println( "$c $(tv[c]) $(initial_weighted_popn[c]) $diffpc%")
end
# .. or mean weight from person counts
tp=0
for r in eachrow(out)
   global tp
   tp += sum(r)
end
ip = sum(tv)
iw = ip/tp
initial_weights = ones(nr)*iw
# ...
wchi = do_chi_square_reweighting( out_m, initial_weights, tv )
weighted_popn_chi = (wchi' * out_m)'
@assert weighted_popn_chi ≈ tv
lower_multiple = 0.25 # any smaller min and d_and_s_constrained fails on this dataset
upper_multiple = 4
for m in [constrained_chi_square] #instances( DistanceFunctionType ) all other methods fail!
      println( "on method $m")
      rw = do_reweighting(
            data               = out_m,
            initial_weights    = initial_weights,
            target_populations = tv,
            functiontype       = m,
            lower_multiple     = lower_multiple,
            upper_multiple     = upper_multiple,
            tolx               = 0.000001,
            tolf               = 0.000001 )
      println( "results for method $m = $(rw.rc)" )
      weights = rw.weights
      weighted_popn = (weights' * out_m)'
      println( "weighted_popn = $weighted_popn" )
      @assert weighted_popn ≈ tv  
      if m != chi_square
         for w in weights # check: what's the 1-liner for this?
            @assert w > 0.0
         end
      else
         @assert weights ≈ wchi # chisq the direct way should match chisq the iterative way
      end
      if m in [constrained_chi_square, d_and_s_constrained ]
         # check the constrainted methods keep things inside ll and ul
         for r in 1:nr
            @assert weights[r] <= initial_weights[r]*upper_multiple
            @assert weights[r] >= initial_weights[r]*lower_multiple
         end
      end
end