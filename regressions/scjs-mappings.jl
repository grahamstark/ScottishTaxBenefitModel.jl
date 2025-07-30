	
function is1( a :: Nothing, d :: Dict )::Missing
	return missing
end

function is1( a :: Missing, d :: Dict )::Missing
	return missing
end

function is1( a :: AbstractString, d :: Dict )
	return is1( tryparse( Int, a ), d )
end

function is1( a :: Integer, d :: Dict )
	if a < 0
		return missing
	end
	return get(d, a, "$a" )
end

# 
function isonestr( s :: AbstractString ) :: Bool
    s .== "1"
end
	
scjsraw.tabnssec = to_categorical( scjsraw.tabnssec, Dict([
	1 => "Manage & Prof.",
	2 => "Intermediate",
	3 => "Routine & Man.",
	4 => "NW & LTUE"]))

scjsraw.qdgen = to_categorical( scjsraw.qdgen, Dict([
	1 => "Male",
	2 => "Female"]))

# (.*)\ => "(.*)",
# $1 => "$2",
    

function agemp( age :: Int ) :: Real
    return if age == 1
        16.5
    elseif age ==  2
        19
    elseif age ==  3
        23
    elseif age ==  4
        30
    elseif age ==  5
        40
    elseif age ==  6
        50
    elseif age ==  7
        57
    elseif age ==  8
        62
    elseif age ==  9
        70
    elseif age ==  10
        80
    elseif age ==  11
        10
    elseif age == -2 # 2021 only
        rand( [16.5, 19, 23, 30, 50, 57, 62, 70, 80, 10])
    end    
end

scjsraw.is_limited = (scjsraw.qlimit .== 1) .| (scjsraw.qlimit .== 2)
scjsraw.is_carer = scjsraw.qcare .== 1
scjsraw.has_condition = scjsraw.qcondit .== 1
scjsraw.divorced_or_separated = (scjsraw.qdlegs .== 3) .| (scjsraw.qdlegs .== 4)
scjsraw.health_good_or_better = (scjsraw.qhstat .== 1) .| (scjsraw.qhstat .== 2) 
#
# 2nd
#
scjsraw.non_white = scjsraw.qdeth3 .== 4
scjsraw.lives_in_flat = scjsraw.acctype .== 3
scjsraw.single_parent = scjsraw.hhcomp .== 2
scjsraw.out_of_labour_market = scjsraw.iloclass .== 3
scjsraw.datayear = categorical( scjsraw.datayear )


scjsraw.age = map( x->agemp(x), scjsraw.qdage2 )

scjsraw.agesq = scjsraw.age.^2

scjsraw.qdlegs = to_categorical( scjsraw.qdlegs, Dict([
	1 => "Never married and never registered a same-sex civil partnership",
	2 => "Married or In a registered same-sex civil partnership",
	3 => "Separated, but still legally married or Separated, but still legally in a same-sex civil partnership",
	4 => "Divorced or Formerly in a same-sex civil partnership",
    5 => "Widowed or Surviving partner from a same-sex civil partnership"]))

scjsraw.iloclass = to_categorical( scjsraw.iloclass, Dict([
    1 => "In employment",
	2 => "ILO unemployed",
	3 => "Inactive"]))
	

scjsraw.qhstat = to_categorical( scjsraw.qhstat, Dict([
    1 => "Very good",
	2 => "Good",
	3 => "Fair",
	4 => "Bad",
    5 => "Very Bad"]))

#    DISAB 1
#    QCARE 1


scjsraw.qdeth3 = to_categorical( scjsraw.qdeth3, Dict([
    1 => "White – Scottish",
	2 => "White – British",
	3 => "White – Other",
	4 => "Minority Ethnic"]))


function incmp( inc :: Int )
    if inc ==  1
        2_600
    elseif inc ==  2
        7_000.0 # £5,200 - £10,399
    elseif inc ==  3
        13_000 # £10,400 - £15,599
    elseif inc ==  4
        18200.0 # £15,600 - £20,799
    elseif inc ==  5
        23400.0 # £20,800 - £25,999
    elseif inc ==  6
        31200.0 # £26,000 - £36,399
    elseif inc ==  7
        44200.0 # £36,400 - £51,999
    elseif inc ==  8
        65000.0 # £52,000 - £77,999
    elseif inc ==  9 
        100_000.0 #"£78,000 or more"])
    else
        missing 
    end
end 

scjsraw.hhinc = map( x->incmp(x), scjsraw.qdinc2 )

scjsraw.tenure = to_categorical( scjsraw.tenure, Dict([
	1 => "Owner occupied",
	2 => "Social rented",
	3 => "Private rented",
	4 => "Other"]))
 
scjsraw.acctype = to_categorical( scjsraw.acctype, Dict([
    1 => "Detached/ semi house",
	2 => "Terraced house",
	3 => "Flat/maisonette",
	4 => "Other"]))

scjsraw.hhcomp = to_categorical( scjsraw.hhcomp, Dict([
    1 => "Single adult",
	2 => "Single parent",
	3 => "Single pensioner",
	4 => "Small family",
	5 => "Large family",
	6 => "Small adult",
	7 => "Large adult",
	8 => "Older smaller"]))

scjsraw.simd_quint = to_categorical( scjsraw.simd_quint, Dict([
    1 => "Quintile 1",
	2 => "Quintile 2",
	3 => "Quintile 3",
	4 => "Quintile 4",
	5 => "Quintile 5"]))

scjsraw.taburbrur = to_categorical( scjsraw.taburbrur, Dict([
    1 => "Urban",
	2 => "Rural"]))
	
    

scjsraw.q_school_leaving = scjsraw.qqual_01 .== 1 
scjsraw.q_school_o_grade = scjsraw.qqual_02 .== 1
scjsraw.q_gsvq_foundation = scjsraw.qqual_03 .== 1
scjsraw.q_higher = scjsraw.qqual_04 .== 1
scjsraw.q_gsvq_advanced = scjsraw.qqual_05 .== 1
scjsraw.q_hnc = scjsraw.qqual_06 .== 1
scjsraw.q_degree = scjsraw.qqual_07 .== 1
scjsraw.q_professional= scjsraw.qqual_08 .== 1
scjsraw.q_other_school = scjsraw.qqual_09 .== 1
scjsraw.q_other_post_school = scjsraw.qqual_10 .== 1
scjsraw.q_other_he = scjsraw.qqual_11 .== 1
scjsraw.q_none = scjsraw.qqual_12 .== 1

# home, excl divorce
scjsraw.civ_neighbours = isonestr.(scjsraw.cvjneig) # Problems with neighbours in last 3 years
scjsraw.civ_child_contact = isonestr.(scjsraw.cvjchil) # problems to do with child contact, residence or maintenance in last 3 years
scjsraw.civ_housing =  isonestr.(scjsraw.cvjhou) # housing in last 3 years
scjsraw.civ_immigration =  isonestr.(scjsraw.cvjimm) #  immigration in last 3 years
scjsraw.civ_education =  isonestr.(scjsraw.cvjsch) #  education of your children in last 3 years
scjsraw.civ_family = isonestr.(scjsraw.cvjpar) #  problems or disputes concerning your home, family or living arrangements: behaviour of a partner, ex-partner or other person who is harassing you in last 3 years

scjsraw.civ_home = scjsraw.civ_neighbours .| scjsraw.civ_child_contact .| 
    scjsraw.civ_housing .| scjsraw.civ_immigration .|
    scjsraw.civ_education .| scjsraw.civ_family 


# health 
scjsraw.civ_injury = isonestr.(scjsraw.cvjinj) # problems concerning your health and well-being: injury because of an accident in last 3 years
scjsraw.civ_medical = isonestr.(scjsraw.cvjneg) #  medical negligence in last 3 years
scjsraw.civ_mental = isonestr.(scjsraw.cvjment2) # issues surrounding mental health difficulties in last 3 years
# money
scjsraw.civ_money_debt = isonestr.(scjsraw.cvjmon) #  problems concerning your money, finances or anything you’ve paid for: with money and debt in last 3 years
scjsraw.civ_benefit =  isonestr.(scjsraw.cvjben) #  benefit problems in last 3 years
scjsraw.civ_faulty_goods = isonestr.(scjsraw.cvjfau) # faulty goods or services in last 3 yea
# unfairness, excl employment
scjsraw.civ_discrimination = isonestr.(scjsraw.cvjdisc) # problems concerning someone treating you unfairly: discrimination in last 3 years
scjsraw.civ_police = isonestr.(scjsraw.cvjpol) # : unfair treatment by the police in last 3 years
scjsraw.civ_employment = isonestr.(scjsraw.cvjemp) # employment in last 3 years



# do these 
scjsraw.civ_divorce = isonestr.(scjsraw.cvjrel2)
scjsraw.civ_family = isonestr.(scjsraw.cvjpar) #  problems or disputes concerning your home, family or living arrangements: behaviour of a partner, ex-partner or other person who is harassing you in last 3 years
scjsraw.civ_children = scjsraw.civ_education .| scjsraw.civ_child_contact
scjsraw.civ_housing_neighbours = scjsraw.civ_neighbours .| scjsraw.civ_housing 
scjsraw.civ_health = scjsraw.civ_mental .| scjsraw.civ_medical .| scjsraw.civ_injury
scjsraw.civ_money = scjsraw.civ_money_debt .| scjsraw.civ_benefit .| scjsraw.civ_faulty_goods 
scjsraw.civ_unfairness = scjsraw.civ_discrimination .| scjsraw.civ_police .| scjsraw.civ_employment
scjsraw.civ_any = scjsraw.civ_family .| scjsraw.civ_children .| scjsraw.civ_housing_neighbours .| 
    scjsraw.civ_health .| scjsraw.civ_money .| scjsraw.civ_unfairness .| scjsraw.civ_divorce
