
using ScottishTaxBenefitModel
using .DataSummariser
using .Definitions
using .FRSHouseholdGetter
using .HouseholdFromFrame
using .Intermediate
using .ModelHousehold
using .RunSettings
using .STBParameters
using .Utils
using .Weighting

using CSV,DataFrames,StatsBase,DataStructures


function draw_hist( path :: String, data :: NamedTuple, year_str::String, weight_str::String, match_str::String )

    function onehist!( ax, histd, mn, md, colour )
        barplot!( ax, histd; color=colour, alpha=0.5 )
        my = maximum( histd.weights )*1.1
        lines!( ax, [mn, mn], [0.0, my]; color=:darkgreen, label="Mean")   
        # text!( ax, Point2f(mn,my); text="Mean", color=:black , align = (:left, :center), markerspace = :data, fontsize = 1 ) 
        lines!( ax, [md, md], [0.0, my]; color=:darkred, label="Median")    
        # text!( ax, Point2f(md,my); text="Median", color=:blue, align = (:left, :center), markerspace = :data, fontsize = 1)         
    end

    if data.type != "full"
        return
    end
    title = pretty( string( data.key )) * " - " * pretty(year_str) * ", " * pretty( weight_str ) * ", " * pretty( match_str )
    f = Figure(size = (1600, 800))
    Label(f[0, :], text = title, fontsize = 18)
    axu = Axis(f[1,1], xlabel="", ylabel="Sample Count", title="Unweighted", ytickformat="{:,.0f}", width = 650)
    onehist!( axu, data.u_hist, data.u_mean, data.u_median, :darkgrey )
    axw = Axis(f[1,2], xlabel="", ylabel="Population Count", title="Weighted", ytickformat="{:,.0f}", width = 650)
    onehist!( axw, data.w_hist, data.w_mean, data.w_median, :darkblue )
    k = Legend( f[1,3], axw )
    save( joinpath( path, "$(data.key).svg"), f )
end

"""

"""
function do_one_summary_set(;
    use_essex_years :: Bool,
    use_essex_weights :: Bool,
    do_matching :: Bool )    
    settings = Settings()
    settings.do_legal_aid = false
    settings.use_shs = true
    if use_essex_years
        settings.included_data_years = [2019,2021,2022]
        settings.upper_multiple=9 # doesn't converge with 7 with just these 3 years
    end
    settings.weighting_strategy = use_essex_weights ? use_supplied_weights : use_runtime_computed_weights
    if do_matching 
        settings.indirect_method = matching
        settings.wealth_method = matching
    else 
        settings.indirect_method = no_method
        settings.wealth_method = no_method
    end
    # dup load but hard to avoid..
    dataset_artifact = get_data_artifact( Settings() )
    hhs = HouseholdFromFrame.read_hh( 
        joinpath( dataset_artifact, "households.tab")) # CSV.File( ds.hhlds ) |> DataFrame
    people = HouseholdFromFrame.read_pers( 
        joinpath( dataset_artifact, "people.tab"))
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    settings.num_households, settings.num_people, nhhs2 = 
        FRSHouseholdGetter.initialise( settings; reset=true )
    if use_essex_years
        people = people[ people.data_year .∈ ( settings.included_data_years, ) , :]
        hhs = hhs[ hhs.data_year .∈ ( settings.included_data_years, ) , :]
    end
    interframe = make_intermed_dataframe( settings, 
        sys, 
        settings.num_households )
    # this seems to be what they work with.. weird
    phhs = leftjoin( hhs, people, on=[:hid,:data_year], makeunique=true)
    
    phhs.income_self_employment_net = phhs.income_self_employment_income - phhs.income_self_employment_losses
    phhs.age_band = Definitions.get_age_band.( phhs.age )
    # Write the uprated and whatevered mode hhld data back into the frame we're comparing with.
    overwrite_raw!( phhs, settings.num_households )
    if settings.weighting_strategy == use_supplied_weights # average out supplied weights if we're not recomputed.
        nyears = length( unique( phhs.data_year )) # silly count of number of data years
        phhs.weight ./= nyears
    end
    # Cast weights as StatsBase weights type - this doesn't persist well.
    phhs.weight = Weights( phhs.weight )
    interframe.weight = Weights( interframe.weight )
    df_numvars, df_enums, raw = make_data_summaries( phhs )
    year_str = use_essex_years ? "essex-data-years" : "full-data-years"
    weight_str = use_essex_weights ? "frs-weights" : "computed-weights"
    match_str = do_matching ? "matched-was-lcf-data" : "frs-data-only"
    tmpdir = joinpath( tempdir(), "output", year_str, weight_str, match_str )
    if ! isdir( tmpdir )
        path = mkpath( tmpdir )
        println( "writing to $path")
    end
    for v in raw
        draw_hist( tmpdir, v, year_str, weight_str, match_str )
    end
    CSV.write( joinpath( tmpdir, "scotben-joined-data.tab" ), phhs; delim='\t')
    CSV.write( joinpath( tmpdir, "scotben-numeric-variable-summaries.tab" ), df_numvars; delim='\t')
    CSV.write( joinpath( tmpdir, "scotben-enum-variable-summaries.tab"), df_enums; delim='\t')
end

for essex_years in [true, false ]
    for essex_weights in [true, false ]
        for matching in [true, false]
            do_one_summary_set( 
                use_essex_years = essex_years,
                use_essex_weights = essex_weights,
                do_matching = matching )
        end
    end
end