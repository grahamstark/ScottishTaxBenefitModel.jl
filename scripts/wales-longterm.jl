
#
# a simple long-term weighting scheme for wales
#
#
using ScottishTaxBenefitModel
using .Definitions
using CSV,DataFrames

const WDIR = joinpath(MODEL_DATA_DIR, "wales", "projections")

function loaddfs()::DataFrame
    males = CSV.File( joinpath(WDIR,"males-proj-edited.csv")) |> DataFrame
    females = CSV.File( joinpath(WDIR,"females-proj-edited.csv")) |> DataFrame
    popn=hcat(males,females;makeunique=true)
    popn = popn[(popn.year .>= 2020).& (popn.year .<= 2040),:]
    select!( popn, Not( [:".", :"._1", :"._2", :"year_1", :"._3", "._1_1", "._2_1"]))

    hhlds = CSV.File( joinpath(WDIR,"household-projections-by-household-type-and-year-edited.csv"))|> DataFrame
    select!( hhlds, Not(:Column1))

    hhlds_long = stack( hhlds, Not(:type))
    hhlds_wide = unstack( hhlds_long, :type, :value )
    rename!( hhlds_wide, [    
        :"variable" => :year,
        :"all hhlds" => :v_all_hhlds,
        :"1 person " => :v_1_adult,
        :"2 person (No children) " => :v_2_adults,
        :"2 person (1 adult, 1 child) " => :v_1_adult_1_child, 
        :"3 person (No children) " => :v_3_adults,
        :"3 person (2 adults, 1 child) " => :v_2_plus_adults_1_child,
        :"3 person (1 adult, 2 children) " => :v_1_adult_2_children,
        :"4 person (No children) " => :v_4_adults,
        :"4 person (2+ adults, 1+ children) " => :v_2_adults_2_children,
        :"4 person (1 adult, 3 children) " => :v_1_adult_3_children,
        :"5+ person (No children) " => :v_5_adults,
        :"5+ person (2+ adults, 1+ children) " => :v_5_plus_w_children,
        :"5+ person (1 adult, 4+ children) " => :v_1_adult_4_plus_children,
        :"total w/kids" => :v_tot_w_kids,
        :"1 adult household with children " => :v_1_adult_1_plus_children,
        :"2+ adult household with children " => :v_2_plus_adults_1_plus_children
    ])
    hhlds_wide.year = parse.( Int, hhlds_wide.year )
    hhlds_wide = hhlds_wide[(hhlds_wide.year .>= 2020).& (hhlds_wide.year .<= 2040),:]
    popn = hcat(popn,hhlds_wide;makeunique=true)
    popn.v_3_plus_adults = popn.v_3_adults + popn.v_4_adults + popn.v_5_adults
    select!( popn, 
        :year, 
        :m_u16, 
        :m_age16_64,
        :m_age65_plus, 
        :f_u16, 
        :f_age16_64, 
        :f_age65_plus,
        :v_1_adult,
        :v_2_adults,
        :v_1_adult_1_plus_children,
        :v_3_plus_adults,
        :v_2_plus_adults_1_plus_children )
    popn
end

popn = loaddfs()
CSV.write( joinpath(WDIR, "popn-targets-2020-2040.csv"), popn )