using ShareAdd

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

@usingany  CairoMakie,CSV,DataFrames,StatsBase,DataStructures

const TEMPDIR = joinpath( "/", "home", "graham_s", "tmp")

function make_dirname( use_essex_years, use_essex_weights, do_matching )    
    year_str = use_essex_years ? "essex-data-years" : "full-data-years"
    weight_str = use_essex_weights ? "frs-weights" : "computed-weights"
    match_str = do_matching ? "matched-was-lcf-data" : "frs-data-only"
    return joinpath( TEMPDIR, "output", year_str, weight_str, match_str ), year_str, weight_str, match_str
end

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
        # weights from the commented out little loop at bottom - FIXME set up a grid search?
        settings.lower_multiple=0.640000000000000
        settings.upper_multiple=5.86000000000000
    else
        settings.lower_multiple=0.630000000000000
        settings.upper_multiple=4.72000000000000
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
    # not actually used .. 
    interframe = make_intermed_dataframe( settings, 
        sys, 
        settings.num_households )
    # this seems to be what they work with.. weird
    phhs = leftjoin( hhs, people, on=[:hid,:data_year], makeunique=true)
    # .. add some fields: 
    phhs.income_self_employment_net = phhs.income_self_employment_income - phhs.income_self_employment_losses
    phhs.age_band = Definitions.get_age_band.( phhs.age )
    # Write the uprated and whatevered mode hhld data back into the frame we're comparing with.
    overwrite_raw!( phhs, settings.num_households )
    if settings.weighting_strategy == use_supplied_weights # average out supplied weights if we've not recomputed.
        nyears = length( unique( phhs.data_year )) # silly count of number of data years
        phhs.weight ./= nyears
    end
    # Cast weights as StatsBase weights type - this doesn't persist well.
    phhs.weight = Weights( phhs.weight )
    interframe.weight = Weights( interframe.weight )
    df_numvars, df_enums, raw = make_data_summaries( phhs, FROM_ZERO_VARS )
    tmpdir, year_str, weight_str, match_str = make_dirname( use_essex_years, use_essex_weights, do_matching  )
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

function compute_all()
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
end

function merge_enums( d1::DataFrame, d2::DataFrame, leftname, rightname )

    d3 = outerjoin( d1, d2; order=:left, on=[:varname,:label], renamecols = leftname => rightname )
end

function make_merged_enums()
    d_3_frs = CSV.File(joinpath( make_dirname( true, true, true )[1], "scotben-enum-variable-summaries.tab"); delim='\t')|>DataFrame
    d_3_gen = CSV.File(joinpath( make_dirname( true, false, true )[1], "scotben-enum-variable-summaries.tab"); delim='\t')|>DataFrame
    d_5_gen = CSV.File(joinpath( make_dirname( false, false, true )[1], "scotben-enum-variable-summaries.tab"); delim='\t')|>DataFrame
    d_3_merged = merge_enums( d_3_frs, d_3_gen, "_frs_weights", "_scotben_weights" )
    allmerged = merge_enums( d_3_merged, d_5_gen, "_3_year", "_full_sample" )
    allmerged = select( allmerged, Not([
        :u_count_scotben_weights_3_year,
        :notes_frs_weights_3_year,
        :u_count_scotben_weights_3_year, 
        :notes_scotben_weights_3_year,
        :notes_full_sample ]))
    # sort!( allmerged, [:varname, :label])
    allmerged.u_count_frs_weights_3_year = coalesce.( allmerged.u_count_frs_weights_3_year, 0 )
    allmerged.w_count_frs_weights_3_year  = coalesce.(allmerged.w_count_frs_weights_3_year, 0.0 )
    allmerged.w_count_scotben_weights_3_year = coalesce.(allmerged.w_count_scotben_weights_3_year, 0.0)
    allmerged[!,:frs_sb_3] .= 100.0 .* (allmerged.w_count_scotben_weights_3_year./allmerged.w_count_frs_weights_3_year)
    allmerged[!,:sb_3_sb_full] .= 100.0 .* (allmerged.w_count_scotben_weights_3_year./allmerged.w_count_full_sample)
    allmerged.label = pretty.(allmerged.label)
    allmerged.varname = pretty.(allmerged.varname)
    rename!( allmerged,Dict([
        :varname => "Type",
        :label => "Value",
        :u_count_frs_weights_3_year  => "a) Unweighted - 3 year sample",
        :w_count_frs_weights_3_year  => "b) FRS Weighted - 3 year sample",
        :w_count_scotben_weights_3_year => "c) Scotben Weighted - 3 year sample",
        :u_count_full_sample => "d) Unweighted - Full Sample",
        :w_count_full_sample => "e) Weighted - Full Sample",
        :frs_sb_3 => "c/b (%)",
        :sb_3_sb_full => "c/e (%)"]))
    allmerged
end


const FROM_ZERO_VARS = Set([
    :registered_blind,
    :registered_partially_sighted,
    :registered_deaf,
    :disability_vision,
    :disability_hearing,
    :disability_mobility,
    :disability_dexterity,
    :disability_learning,
    :disability_memory,
    :disability_mental_health,
    :disability_stamina,
    :disability_socially,
    :disability_other_difficulty,
    :has_long_standing_illness,
    :is_informal_carer,
    :is_hrp,
    :is_bu_head,
    :from_child_record,
    :age,
    :bedrooms,
    :employer_provides_child_care,
    :age_completed_full_time_education,
    :had_children_when_bereaved,
    :pay_includes_ssp,
    :pay_includes_smp,
    :pay_includes_spp,
    :pay_includes_mileage,
    :pay_includes_motoring_expenses ])

const SELECT_COLS = [
    "varname"
    "skipnonzeros_frs_weights_3_year"

    "count_frs_weights_3_year"
    "count_full_sample"

    "u_non_zeros_frs_weights_3_year"
    "u_non_zeros_full_sample"

    "u_mean_frs_weights_3_year"
    "u_mean_full_sample"

    "u_median_frs_weights_3_year"
    "u_median_full_sample"

    "u_std_frs_weights_3_year"
    "u_std_full_sample"

    "weighted_count_frs_weights_3_year"
    "weighted_count_scotben_weights_3_year"
    "weighted_count_full_sample"

    "w_non_zeros_frs_weights_3_year"
    "w_non_zeros_scotben_weights_3_year"
    "w_non_zeros_full_sample"

    "w_mean_frs_weights_3_year"
    "w_mean_scotben_weights_3_year"
    "w_mean_full_sample"

    "w_median_frs_weights_3_year"
    "w_median_scotben_weights_3_year"
    "w_median_full_sample"

    "w_std_frs_weights_3_year"
    "w_std_scotben_weights_3_year"
    "w_std_full_sample"

    "minimum_scotben_weights_3_year"
    "minimum_full_sample"

    "maximum_scotben_weights_3_year"
    "maximum_full_sample"
    
    ]

const RENAME_COLS = Dict([
    "skipnonzeros_frs_weights_3_year" => "Skip Non-Zeros?",
    "count_frs_weights_3_year" => "Count - 3 Years",
    "count_full_sample" => "Count - All Years",
    "u_non_zeros_frs_weights_3_year" => "Non Zeros - 3 Years",
    "u_non_zeros_full_sample" => "Non Zeros - All Years",
    "u_mean_frs_weights_3_year" => "Unweighted Mean - 3 Years",
    "u_mean_full_sample" => "Unweighted Mean - All Years",
    "u_median_frs_weights_3_year" => "Unweighed Median - 3 Years",
    "u_median_full_sample" => "Unweighed Median - All Years",
    "u_std_frs_weights_3_year" => "Unweighted Std. - 3 Years",
    "u_std_full_sample" => "Unweighted Std. - All Years",
    "weighted_count_frs_weights_3_year" => "FRS Weighted Count 3 Years",
    "weighted_count_scotben_weights_3_year" => "ScotBen Weighted Count - 3 Years",
    "weighted_count_full_sample" => "ScotBen Weighted Count - Full Sample",
    "w_mean_frs_weights_3_year"=> "Mean : Frs Weights 3 Year",
    "w_mean_scotben_weights_3_year" => "Mean : Scotben Weights - 3 Year",
    "w_mean_full_sample"=> "Mean : Scotben Weights, Full Sample",
    "w_median_frs_weights_3_year"=> "Median : Frs Weights, - 3 Years",
    "w_median_scotben_weights_3_year"=> "Median : Scotben Weights - 3 Years",
    "w_median_full_sample"=> "Median : Scotben Weights, Full Sample",
    "w_non_zeros_frs_weights_3_year" => "Non Zeros : Frs Weights - 3 Years",
    "w_non_zeros_scotben_weights_3_year" => "Non Zeros : Scotben Weights - 3 Years",
    "w_non_zeros_full_sample"=> "Non Zeros : Full Sample",
    "w_std_frs_weights_3_year" => "Std : Frs Weights - 3 Years",
    "w_std_scotben_weights_3_year" => "Std : Scotben Weights - 3 Years",
    "w_std_full_sample" => "Std : Scotben Weights, Full Sample",
    "minimum_scotben_weights_3_year" => "Min value - 3 Years",
    "minimum_full_sample" => "Min value - Full Sample",
    "maximum_scotben_weights_3_year"=> "Max value - 3 Years",
    "maximum_full_sample"=> "Max value - Full Sample"])


function make_merged_stats()
    d_3_frs = CSV.File(joinpath( make_dirname( true, true, true )[1], "scotben-numeric-variable-summaries.tab"); delim='\t')|>DataFrame
    d_3_frs = d_3_frs[ ismissing.(d_3_frs.notes),:]
    d_3_gen = CSV.File(joinpath( make_dirname( true, false, true )[1], "scotben-numeric-variable-summaries.tab"); delim='\t')|>DataFrame
    d_5_gen = CSV.File(joinpath( make_dirname( false, false, true )[1], "scotben-numeric-variable-summaries.tab"); delim='\t')|>DataFrame
    allmerged = innerjoin( d_3_frs, d_3_gen, order=:left, on=:varname, renamecols="_frs_weights"=>"_scotben_weights")
    allmerged = innerjoin( allmerged, d_5_gen, order=:left, on=:varname, renamecols="_3_year"=>"_full_sample")
    select!(allmerged, SELECT_COLS)
    rename!(allmerged, RENAME_COLS)
    allmerged.varname = pretty.( allmerged.varname )
    allmerged
end