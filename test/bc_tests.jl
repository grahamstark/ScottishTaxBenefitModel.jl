#
# As of September 19 2021
# Tests og budget constraints
#

using Test
using Dates
using ScottishTaxBenefitModel
using .ModelHousehold
using .STBParameters
using .STBIncomes
using .Definitions
using .GeneralTaxComponents
using .SingleHouseholdCalculations
using .RunSettings
using .Utils
using .BCCalcs


sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
println( "weeklyise start wpm=$PWPM wpy=52")
weeklyise!( sys21_22; wpy=52, wpm=PWPM  )
settings = DEFAULT_SETTINGS

@testset "Single Pers bc" begin

    hh = make_hh(
        adults = 1,
        children = 3,
        earnings = 0,
        rent = 150,
        rooms = 2,
        age = 30,
        tenure = Private_Rented_Furnished )
    for (pid,pers) in hh.people
        println( "age=$(pers.age) empstat=$(pers.employment_status) " )
        empty!( pers.income )
    end
    head = get_head( hh )
    
    enable!( head )
    employ!( head )
    empty!( head.income )
    settings.means_tested_routing = lmt_full 
    bc = BCCalcs.makebc(hh, sys21_22, settings )
    println( to_md_table( bc ))
    np = size(bc.points)[1]
    println(np)
    for i in 1:np
        p = bc.points[i,:]
        print("$(p[1]) : $(p[2])")
        if i < np
            print( " : $(bc.annotations[i]) ")
        end
        println()
    end
    println(eltype(bc.points))

    for i in 1:np
        for inc in [0,0.01]
            w = bc.points[i,1]+inc
            h = Int(trunc(w/10))
            head.income[wages] = w
            head.usual_hours_worked = h
            head.employment_status = if h < 5 
                Unemployed
            elseif h < 30 
                Part_time_Employee
            else
                Full_time_Employee
            end
            hres = do_one_calc( hh, sys21_22, settings )        
            println( inctostr(  hres.income ))
            println( "hours=$(head.usual_hours_worked)")
        end
    end
 
end