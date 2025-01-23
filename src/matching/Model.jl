module Model
"""
North_East = 1
North_West = 2
Yorks_and_the_Humber = 3
East_Midlands = 4
West_Midlands = 5
East_of_England = 6
London = 7
South_East = 8
South_West = 9
Scotland = 11 
Wales = 10
Northern_Ireland = 12
"""
function frs_regionmap( gvtregn :: Union{Int,Missing}, default=9999 ) :: Vector{Int}
    out = fill( default, 3 )
    # gvtregn = parse(Int, gvtregn )
    if ismissing( gvtregn )
        ;
    elseif gvtregn == 112000007 # london
        out[1] = 7
        out[2] = 1
    elseif gvtregn in 112000001:112000009 # rEngland
        out[1] = gvtregn - 112000000
        out[2] = 2
    elseif gvtregn == 299999999 # scotland
        out[1] = 11 
        out[2] = 3
    elseif gvtregn == 399999999 # 
        out[1] = 10
        out[2] = 4
    elseif gvtregn == 499999999 # nire
        out[1] = 12
        out[2] = 5
    else
        @assert false "unmatched gvtregn $gvtregn";
    end 
    return out
end

function model_regionmap(  reg :: Standard_Region ) :: Vector{Int}
    return frs_regionmap( Int( reg ), 9998 )
end


"""
frs age group for hrp - 1st is exact, 2nd u40,40+
"""
function frs_age_hrp( hhagegr4 :: Int ) :: Vector{Int}
    out = fill( 9998, 3 )
    out[1] = hhagegr4
    if hhagegr4 <= 5
        out[2] = 1
    elseif hhagegr4 <= 13
        out[2] = 2
    else
        @assert false "mapping hhagegr4 $hhagegr4"
    end
    out
end


function frs_tenuremap( tentyp2 :: Union{Int,Missing}, default=9999 ) :: Vector{Int}
    out = fill( default, 3 )
    if ismissing( tentyp2 )

    elseif tentyp2 == 1
        out[1] = 1
        out[2] = 1
    elseif tentyp2 == 2
        out[1] = 2
        out[2] = 1
    elseif tentyp2 == 3
        out[1] = 3
        out[2] = 1
    elseif tentyp2 == 4
        out[1] = 4
        out[2] = 1
    elseif tentyp2 == 5 
        out[1] = 5
        out[2] = 2
    elseif tentyp2 == 6
        out[1] = 6
        out[2] = 2   
    elseif tentyp2 in [7,8]
        out[1] = 7
        out[2] = 3   
    else
        @assert false "unmatched tentyp2 $tentyp2";
    end 
    return out
end

function tenuremap(  t :: Tenure_Type, default=9998 ) :: Vector{Int}
    return frs_tenuremap( Int( t ), default )
end

"""
   dwell_na = -1
   detatched = 1
   semi_detached = 2
   terraced = 3
   flat_or_maisonette = 4
   converted_flat = 5
   caravan = 6
   other_dwelling = 7
"""
function accommap( dwelling :: DwellingType ):: Vector{Int}
    out = Int( dwelling )
    if out == -1
        println( "-1 dwelling ")
        out = rand(1:6)
    end
    out = min( 6, out ) # caravan=>other
    return lcf_accmap( out, 9998 )
end

function do_hh_sums( hh :: Household ) :: Tuple
    any_wages = false
    any_selfemp = false
    any_pension_income = false 
    has_female_adult = false
    income = 0.0
    for (pid,pers) in hh.people
        if get(pers.income,wages,0) > 0
            any_wages = true
        end
        if get(pers.income,self_employment_income,0) > 0
            any_selfemp = true
        end
        if (get(pers.income,private_pensions,0) > 0) || pers.age >= 66
            any_pension_income = true
        end
        if (! pers.is_standard_child) && (pers.sex == Female )
            has_female_adult = true
        end
        # income += sum( pers.income, start=wages, stop=alimony_and_child_support_received ) # FIXME
    end
    income = hh.original_gross_income
    return any_wages, any_selfemp, any_pension_income, has_female_adult, income 
end



function age_grp( age :: Int )
    return if age < 16
        1
    elseif age < 25
        2
    elseif age < 35
        3
    elseif age < 45
        4
    elseif age < 55
        5
    elseif age < 65
        6
    elseif age < 75
        7
    else
        8
    end
end


function frs_composition_map( hhcomps :: Int ) :: Vector{Int}
    mappings=(frs1=[1,3],frs2=[2,4],frs3=[9],frs4=[10],frs5=[5,6,7],frs6=[8],frs7=[12],frs8=[13],frs9=[14],frs10=[11,15,16,17])
    return composition_map( hhcomps,  mappings, default=9999 )
end

## Move to Intermediate 
function composition_map( hh :: Household ) :: Vector{Int}
    num_male_pens = 0
    num_female_pens = 0
    num_male_npens = 0
    num_female_npens = 0
    num_children = 0
    for (k,p) in hh.people 
    if p.is_standard_child
            num_children += 1
        elseif p.sex == Male
            if p.age >= 66
                num_male_pens += 1
            else 
                num_male_npens += 1
            end
        else
            if p.age >= 65
                num_female_pens += 1
            else 
                num_female_npens += 1
            end
        end
    end
    c = -1
    num_adults = num_male_npens + num_male_pens + num_female_npens + num_female_pens
    num_pens = num_male_pens + num_female_pens
    if num_adults == 1
        if num_children == 0
            c = if num_male_pens == 1
                1
            elseif num_female_pens == 1
                2
            elseif num_male_npens == 1
                3
            elseif num_female_npens == 1
                4
            end
        else
            c = if num_children == 1
                9
            elseif num_children == 2
                10
            elseif num_children >= 3
                11
            end
        end
    elseif num_adults == 2
        if num_children == 0
            c = if num_pens == 0
                7
            elseif num_pens == 1
                6
            elseif num_pens == 2
                5
            end
        else
            c = if num_children == 1
                12
            elseif num_children == 2
                13
            elseif num_children >= 3 
                14
            end
        end
    elseif num_adults >= 3
        c = if num_children == 0
            8
        elseif num_children == 1
            15
        elseif num_children == 2
            16
        elseif num_children >= 3
            17
        end
    end
    @assert c in 1:17
    return frs_composition_map( c )
end


end # module Model