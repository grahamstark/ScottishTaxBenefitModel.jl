using CSV,DataFrames

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

CSV.write( "popnfile.csv", out )
