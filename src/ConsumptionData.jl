#=
    
This module holds both the data for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO move the declarations to a Seperate module/ModelHousehold module.
TODO add mapping for example households.
TODO all uprating is nom gdp for now.

=#


module ConsumptionData

using CSV,DataFrames,StatsBase

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents
using .ModelHousehold
using .RunSettings
using .Uprating

IND_MATCHING = DataFrame()
EXPENDITURE_DATASET = DataFrame()

function find_consumption_for_hh!(  hh :: Household, settings :: Settings, which :: Int )  
    @assert settings.indirect_method == matching
    match = IND_MATCHING[(IND_MATCHING.frs_datayear .== hh.data_year).&(IND_MATCHING.frs_sernum .== hh.hid),:][1,:]
    lcf_case_sym = Symbol( "lcf_case_$which")
    lcf_datayear_sym = Symbol( "lcf_datayear_$which")
    case = match[lcf_case_sym]
    datayear = match[lcf_datayear_sym]
    hh.consumption = EXPENDITURE_DATASET[(EXPENDITURE_DATASET.case .== case).&(EXPENDITURE_DATASET.datayear.==datayear),:][1,:]
end

function uprate_expenditure( settings :: Settings )
    ## TODO much more specific uprating factors - just nom_gdp for now
    ## TODO we're just doing COICOP ones for now 
    ## TODO just add q into created dataset 
    nms = names( EXPENDITURE_DATASET )

    for r in eachrow( EXPENDITURE_DATASET)
        if r.a055 > 20 # a055 is interview Month code: > 20 is e.g January REIS and I don't know what REIS means 
            r.a055 -= 20
        end
        q = ((r.a055-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        for n in nms
            if( match( r"^c[0-9]+[a-z]*$",  n ) !== nothing) || # coicop disagregates so c1234x, for example - CIOCP code
                ( match( r"^p6[0-9]+[a-z]*$",  n ) !== nothing) || 
                ( match( r"^c[0-9a-z]+$",  n ) !== nothing)
                 # p6xxx coicop aggregates
                # println( "uprating $n")
                sym = Symbol(n)
                r[sym] = Uprating.uprate( r[sym], y, q, Uprating.upr_nominal_gdp )
                #=
                try
                    r[sym] = Uprating.uprate( r[sym], y, q, Uprating.upr_nominal_gdp )
                catch
                    println( "col $sym is int and fails")
                end
                =#
            end
        end
    end
end

function init( settings :: Settings; reset = false )
    if(settings.indirect_method == matching) && (reset || (size(EXPENDITURE_DATASET)[1] == 0 )) # needed but uninitialised
        global IND_MATCHING
        global EXPENDITURE_DATASET
        IND_MATCHING = CSV.File( "$(settings.data_dir)/$(settings.indirect_matching_dataframe).tab") |> DataFrame
        EXPENDITURE_DATASET = CSV.File("$(settings.data_dir)/$(settings.expenditure_dataset).tab" ) |> DataFrame
        nms = names( EXPENDITURE_DATASET )
        # coerce coicop int cols to floats
        for n in nms
            if match( r"^c+[0-9]+[a-z]*$",  n ) !== nothing # so c1234x, for example - CIOCP code
                sym = Symbol(n)
                EXPENDITURE_DATASET[!,sym] = Float64.(EXPENDITURE_DATASET[:,sym])
            end
        end        
        println( EXPENDITURE_DATASET[1:2,:])
        uprate_expenditure(  settings )
    end
end

end # module