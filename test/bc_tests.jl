#
# As of September 19 2021
# Tests og budget constraints
#

using Test
using DataFrames
using PrettyTables

using ScottishTaxBenefitModel
using .ModelHousehold
using .STBParameters
using .STBIncomes
using .Definitions
using .GeneralTaxComponents
using .SingleHouseholdCalculations
using .RunSettings
using .Utils
using .ExampleHouseholdGetter
using .BCCalcs


sys21_22 = load_file( "../params/sys_2021_22.jl" )
load_file!( sys21_22, "../params/sys_2021-uplift-removed.jl")
println( "weeklyise start wpm=$PWPM wpy=52")
weeklyise!( sys21_22; wpy=52, wpm=PWPM  )
settings = DEFAULT_SETTINGS

# @testset "Single Pers bc" begin

    hh = ExampleHouseholdGetter.get_household( "example_hh1" )
    head = get_head(hh)
    empty!( head.income )
    spouse = get_spouse( hh )
    for (pid,pers) in hh.people
        println( "age=$(pers.age) empstat=$(pers.employment_status) " )
        empty!( pers.income )
    end
    if spouse !== nothing
        set_wage!( spouse, 0, 10 )
    end

    #=
    make_hh(
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
    =#
    settings.means_tested_routing = lmt_full 
    bc = BCCalcs.makebc(hh, sys21_22, settings )
    pretty_table( bc )
    #=
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

    println("LEGACY CASE")
    for i in 1:np
        for inc in [0,0.01]
            w = bc.points[i,1]+inc
            h = w/10
            head.income[wages] = w
            head.usual_hours_worked = h
            head.employment_status = if h < 16
                Unemployed
            elseif h < 30 
                Part_time_Employee
            else
                Full_time_Employee
            end
            hres = do_one_calc( hh, sys21_22, settings )        
            println( "hours=$(head.usual_hours_worked)")
            println( inctostr(  hres.income ))
        end
    end
    =#

    settings.means_tested_routing = uc_full 
    bcu = BCCalcs.makebc(hh, sys21_22, settings )
    println( "UC CASE ")
    # println( [ bcu.points[:,1] bcu.points[:,2]] )
    #=
    npu = size(bcu.points)[1]

    for i in 1:npu
        p = bcu.points[i,:]
        print("$(p[1]) : $(p[2])")
        if i < npu
            print( " : $(bcu.annotations[i]) ")
        end
        println()
    end
    settings.means_tested_routing = uc_full 
    for i in 1:npu
        for inc in [0,0.01]
            w = bcu.points[i,1]+inc
            h = w/10
            head.income[wages] = w
            head.usual_hours_worked = h
            head.employment_status = if h < 16
                Unemployed
            elseif h < 30 
                Part_time_Employee
            else
                Full_time_Employee
            end
            hres = do_one_calc( hh, sys21_22, settings )        
            println( "hours=$(head.usual_hours_worked)")
            println( inctostr(  hres.income ))
        end
    end
    =#
    pretty_table( bcu )
    set_wage!( head, 0, 10 )
    if spouse !== nothing 
        set_wage!( spouse, 0, 10 )
    end
    head.employment_status = Unemployed
    settings.means_tested_routing = lmt_full
    hres = do_one_calc( hh, sys21_22, settings ) 
    println( inctostr(  hres.income ))
    println( println( to_md_table( hres.bus[1] )))
# end

#=
using Plots
pyplot()
default(fontfamily="Gill Sans", 
		titlefont = (12,:grey), 
		legendfont = (11), 
		guidefont = (10), 
		tickfont = (9), 
		annotationfontsize=(8),
		annotationcolor=:blue		
	  )
p1 = plot( bc.points[:,1], bc.points[:,2] )
plot!( p1, bcu.points[:,1], bcu.points[:,2] )
=#
