#
# model dataset-specific mappings for matching
#
module Model


using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold
using .Definitions
    
import ScottishTaxBenefitModel.MatchingLibs.Common as Common

function age_hrp( age :: Int )::Int
    head = get_head( hh )
    Common.age_hrp( age_grp(age))
end

"""
@enum Socio_Economic_Group begin  # mapped from nssec
   Missing_Socio_Economic_Group = -1
   Employers_in_large_organisations = 1
   Higher_managerial_occupations = 2
   Higher_professional_occupations_New_self_employed = 3
   Lower_prof_and_higher_technical_Traditional_employee = 4
   Lower_managerial_occupations = 5
   Higher_supervisory_occupations = 6
   Intermediate_clerical_and_administrative = 7
   Employers_in_small_organisations_non_professional = 8
   Own_account_workers_non_professional = 9
   Lower_supervisory_occupations = 10
   Lower_technical_craft = 11
   Semi_routine_sales = 12
   Routine_sales_and_service = 13
   Never_worked = 14
   Full_time_student = 15
   Not_classified_or_inadequately_stated = 16
   Not_classifiable_for_other_reasons = 17
end
"""
function map_socio( socio :: Socio_Economic_Group )::Vector{Int}
    return Common.map_socio( Int( socio ))
end

"""
   Council_Rented = 1
   Housing_Association = 2
   Private_Rented_Unfurnished = 3
   Private_Rented_Furnished = 4
   Mortgaged_Or_Shared = 5
   Owned_outright = 6
   Rent_free = 7
   Squats = 8
"""
function map_tenure(  t :: Tenure_Type ) :: Vector{Int}
    if t == Missing_Tenure_Type
        return rand(Int,2)
    else 
        return Common.map_tenure( Int( t ) )
    end
end

function map_accom( acc :: DwellingType ) :: Vector{Int}
    i = Int( acc )
    if i in 1:6
        return Common.map_accom( i )
    else
        return rand(Int,2)
    end
end

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
function map_region( gvtregn :: Union{Int,Missing} ) :: Vector{Int}
    out = rand(Int,3)
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

function map_region(  reg :: Standard_Region ) :: Vector{Int}
    return map_region( Int( reg ) )
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
    return Common.accommap( out, 9998 )
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

#= to correspond WAS AGE BANDS - HRPDVAge8r7
Pos. = 88Variable = HRPDVAge8r7Variable label = Grouped Age of HRP (8 categories)
This variable is  numeric, the SPSS measurement level is NOMINAL
Value label information for HRPDVAge8r7
Value = -9.0Label = Don t know
Value = -8.0Label = Refusal
Value = -7.0Label = Does not apply
Value = -6.0Label = Error/partial
Value = 1.0Label = 0 to 15
Value = 2.0Label = 16 to 24
Value = 3.0Label = 25 to 34
Value = 4.0Label = 35 to 44
Value = 5.0Label = 45 to 54
Value = 6.0Label = 55 to 64
Value = 7.0Label = 65 to 74
Value = 8.0Label = 75 and over
=#
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

function counts_for_match( hh :: Household )::NamedTuple
    num_people = ModelHousehold.num_people(hh)
    num_adults = 0
    has_female_adult = false
    num_children = 0
    num_employees = 0   
    num_pensioners = 0
    num_fulltime = 0
    num_parttime = 0
    num_selfemp = 0
    num_unemployed = 0
    num_unoccupied = 0
    hrp_has_partner = false
    any_wages = false
    any_pension_income = false
    any_selfemp = false
    has_disabled_member = false
    head = get_head( hh )

    for (pid, pers) in hh.people
        if pers.is_standard_child
            num_children += 1    
        elseif pers.sex == Female        
            has_female_adult = true
        end
        if get(pers.relationships,head.pid, Missing_Relationship ) in [ Spouse, Civil_Partner ]
            hrp_has_partner = true
        end
        if pers.employment_status in [Full_time_Employee, Part_time_Employee]
            num_employees += 1
        end
        if pers.employment_status in [Retired]
            num_pensioners += 1
            any_pension_income = true # fixme not really
        end
        if pers.employment_status in [Full_time_Employee, Full_time_Self_Employed]
            num_fulltime += 1
        end
        if pers.employment_status in [Part_time_Employee, Part_time_Self_Employed]
            num_parttime += 1
        end
        if pers.employment_status in [Full_time_Self_Employed, Part_time_Self_Employed]
            num_selfemp += 1
        end
        if pers.employment_status in [Unemployed]
            num_unemployed += 1
        end
        if pers.employment_status in [Looking_after_family_or_home,
            Permanently_sick_or_disabled, Other_Inactive]
            num_unoccupied += 1
        end
        if get(pers.income,wages,0.0) > 0
            any_wages = true
        end
        if get(pers.income,self_employment_income,0.0) > 0
            any_selfemp = true
        end
        if pers_is_disabled( pers )
            has_disabled_member = true
        end
    end
    num_adults = num_people - num_children
    return (;
            num_people,
            num_adults,
            num_children,
            num_employees,
            num_pensioners,
            num_fulltime,
            num_parttime,
            num_selfemp,
            num_unemployed,
            num_unoccupied,
            hrp_has_partner,
            any_wages,
            any_pension_income,
            any_selfemp,
            has_female_adult,
            has_disabled_member )
end


function frs_composition_map( hhcomps :: Int ) :: Vector{Int}
    mappings=(frs1=[1,3],frs2=[2,4],frs3=[9],frs4=[10],frs5=[5,6,7],frs6=[8],frs7=[12],frs8=[13],frs9=[14],frs10=[11,15,16,17])
    return composition_map( hhcomps,  mappings, default=9999 )
end

## Move to Intermediate 
#
# 
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

"""
Missing_Marital_Status = -1
   Married_or_Civil_Partnership = 1
   Cohabiting = 2
   Single = 3
   Widowed = 4
   Separated = 5
   Divorced_or_Civil_Partnership_dissolved = 6
"""
function map_marital( mar :: Marital_Status ):: Vector{Int} 
    im = Int( mar )
    @assert im in 1:6 "im missing $mar = $im"
    return Common.map_marital(im)
end


"""
   Missing_ILO_Employment = -1
   Full_time_Employee = 1
   Part_time_Employee = 2
   Full_time_Self_Employed = 3
   Part_time_Self_Employed = 4
   Unemployed = 5
   Retired = 6
   Student = 7
   Looking_after_family_or_home = 8
   Permanently_sick_or_disabled = 9
   Temporarily_sick_or_injured = 10
   Other_Inactive = 11
"""
function map_empstat( ie :: ILO_Employment  ) :: Vector{Int} #  
    out = if ie in [Full_time_Employee,Part_time_Employee]
        1
    elseif ie in [Full_time_Self_Employed,Part_time_Self_Employed ]
        2
    elseif ie == Unemployed
        3
    elseif ie == Retired 
        7
    elseif ie == Student
        4
    elseif ie == Looking_after_family_or_home
        5
    elseif ie in [Permanently_sick_or_disabled,Temporarily_sick_or_injured]
        6
    elseif ie in [Other_Inactive,Missing_ILO_Employment]
        8
    else
        @assert false "unmapped empstat $empstat = $ie"
    end
    return map_empstat( Int(out) )
end



end # module Model