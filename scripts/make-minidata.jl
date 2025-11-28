using CSV
using DataFrames
using GLM
using Random

using ScottishTaxBenefitModel
using .Definitions
using .FRSHouseholdGetter
using .RunSettings
using .Utils

@enum Dwelling2 house flat
@enum Employment2 employee unemployed student retired sick inactive
@enum Sex2 male female 
@enum Health2 good_health bad_health
@enum MaritalStatus2 married single 
@enum Education2 degree higher_school lower_school no_qualification
@enum Tenure2 social_renter private_renter owner_occuper

settings = Settings()

nhhs, npers, nhhs2 = FRSHouseholdGetter.initialise( settings )

hhlds = DataFrame(
    hno = fill(0,nhhs),
    weight = fill(0.0, nhhs ),
    tenure = fill( social_renter, nhhs ),
    dwelling = fill( house, nhhs ),
    rent = fill(0.0, nhhs ),
    mortgage = fill(0.0, nhhs ),
    total_household_wealth = fill(0.0, nhhs ),
    housing_wealth = fill(0.0, nhhs ),
    financial_wealth = fill(0.0, nhhs ),
    pension_wealth = fill(0.0, nhhs ),
    other_wealth  = fill(0.0, nhhs ),
    exp_food = fill(0.0, nhhs ),
    exp_alcohol = fill(0.0, nhhs ),
    exp_tobacco = fill(0.0, nhhs ),
    exp_clothing = fill(0.0, nhhs ),
    exp_transport = fill(0.0, nhhs ),
    exp_energy  = fill(0.0, nhhs ),
    exp_other_goods = fill(0.0, nhhs ),
    num_adults = fill(0, nhhs ),
    num_children = fill(0, nhhs ),
    num_pensioners = fill(0, nhhs ))

people = DataFrame(
    hno = fill(0,npers ),
    pno = fill(0,npers ),
    age = fill(0, npers ),
    sex = fill(0, npers ),
    hours = fill(0.0, npers ),
    years_in_work = fill( 0, npers ),
    wages = fill(0.0, npers ),
    se_income = fill(0.0, npers ),
    savings_income = fill(0.0, npers ),
    pension_income = fill(0.0, npers ),
    health = fill( good_health, npers ))

pno = 0
for hno in 1:nhhs
    global pno
    hh = get_household( hno )
    hr = hhlds[hno,:]
    hr.hno = hno
    pids = sort(collect(keys( hh.people )))
    lpno = 0
    for p in pids
        pno += 1
        lpno += 1
        pers = hh.people[p]
        pr = people[pno,:]
        pr.age = pers.age
        pr.hours = pers.usual_hours_worked
        pr.hno = hno
        pr.pno = lpno        
    end

end

CSV.write( "/home/graham_s/tmp/simple_hhlds.tab", hhlds; delim='\t')
CSV.write( "/home/graham_s/tmp/simple_pers.tab", people; delim='\t')
