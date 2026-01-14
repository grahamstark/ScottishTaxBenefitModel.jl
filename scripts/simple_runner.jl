using CSV
using ArgCheck
using DataFrames
using StatsBase
using BenchmarkTools
using PrettyTables
using Observables
using Format
using ScottishTaxBenefitModel
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Runner: do_one_run
using ScottishTaxBenefitModel.RunSettings
using .Utils
using .Monitor: Progress
using .RunSettings
using .ExampleHelpers
using .STBOutput: make_poverty_line, summarise_inc_frame, 
    dump_frames, summarise_frames!, make_gain_lose

tot = 0

settings = Settings()

# observer = Observer(Progress("",0,0,0))
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    println(tot)
end

function do_basic_run( systems ) 
    global tot
    tot = 0
    settings = Settings()
    settings.run_name="scp-sims-$(date_string())"
    settings.requested_threads = 4
    settings.do_legal_aid = false
    settings.means_tested_routing = modelled_phase_in
    results = do_one_run( settings, systems, obs )
    # h1 = results.hh[1]
    # pretty_table( h1[:,[:weighted_people,:bhc_net_income,:eq_bhc_net_income,:ahc_net_income,:eq_ahc_net_income]] )
    settings.poverty_line = 381.0 # 630*0.6 # 
    settings.poverty_line_source = pl_from_settings
    mypl = make_poverty_line( results.hh[1], settings )
    dump_frames( settings, results )
    println( "poverty line = $(settings.poverty_line)")
    outf = summarise_frames!( results, settings )
    println( outf )
    gl = make_gain_lose( results.hh[1], results.hh[2], settings )
    return (outf,gl,mypl)
end 

function do_scottish_child_payments()::Tuple
    systems = TaxBenefitSystem{Float64}[]
    for inc in 0:5:55
        sys = get_default_system_for_fin_year(2024; scotland=true)
        if inc == 55
            sys.scottish_child_payment.amounts = [0.0]
        else
            sys.scottish_child_payment.amounts .+= inc
        end
        push!( systems, sys)
    end
    return do_basic_run( systems )
end

function povform( v, row, col )
    if col == 3
        return format(v,precision=1,commas=false)
    elseif col == 1
        return v
    elseif v == 0.0
        return ""
    else
        return format(v,precision=0,commas=true )
    end
end 

function poverty_to_df( povs :: Vector )
    incr = 0.0
    n = length(povs)
    df = DataFrame( 
        Increase=fill("",n),
        Children_In_Poverty=zeros(n),
        Pct=zeros(n))
    i = 0
    for p in povs 
        i += 1
        df[i,:Increase] = if incr == 0.0
            ""
        elseif incr == 55
            "SCP Abolished"
        else
            "+$(incr)"
        end
        df[i,:Children_In_Poverty] = p.affected
        df[i,:Pct] = p.prop*100
        incr += 5
        # df[]
    end
    df
end

function glform( v, row, col )
    if col == 7
        return format(v,precision=2,commas=false)
    elseif col == 1
        return v
    elseif v == 0.0
        return ""
    else
        return format(v,precision=0,commas=true )
    end
end

function pretty_gainlose( gl :: DataFrame, label1::String, output_format=:markdown )::AbstractString
    headers = [
        label1, 
        "Lose £10 or more", 
        "Lose £1.01-£10",
        "No Change",
        "Gain £1.01-£10",
        "Gain £10.01+",
        "Average Change",
        "Total Transfer to/from group"]
    aligns = [
        :l,:r,:r,:r,:r,:r,:r,:r
    ]
    pretty_table(String, gl; 
        header=headers,
        alignment=aligns,
        backend=Val(output_format),
        cell_first_line_only=true,
        formatters=glform)
end


function pretty_poverty( povs :: Vector; output_format=:markdown )::AbstractString
    headers = [
        "Increment £s pw", 
        "Children in Poverty",
        "%"]
    aligns = [
        :l,:r,:r
    ]
    pf = poverty_to_df( povs )
    pretty_table(String, pf; 
        header=headers,
        alignment=aligns,
        backend=Val(output_format),
        cell_first_line_only=true,
        formatters=povform)
end

#=
if print_test
    summary_output = summarise_results!( results=results, base_results=base_results )
    print( "   deciles = $( summary_output.deciles)\n\n" )
    print( "   poverty_line = $(summary_output.poverty_line)\n\n" )
    print( "   inequality = $(summary_output.inequality)\n\n" )        
    print( "   poverty = $(summary_output.poverty)\n\n" )
    print( "   gainlose_by_sex = $(summary_output.gainlose_by_sex)\n\n" )
    print( "   gainlose_by_thing = $(summary_output.gainlose_by_thing)\n\n" )
    print( "   metr_histogram= $(summary_output.metr_histogram)\n\n")
    println( "SUMMARY OUTPUT")
    println( summary_output )
    println( "as JSON")
    println( JSON.json( summary_output ))
end

=#