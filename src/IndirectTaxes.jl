#=
    
This module holds both the data and calculations for indirect tax calculations. Quickie pro tem thing
for Northumberland, but you know how that goes..

TODO move the declarations to a Seperate module/ModelHousehold module.
TODO add mapping for example households.
TODO all uprating is nom gdp for now.

=#


module IndirectTaxes

using CSV,DataFrames,StatsBase

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents
using .ModelHousehold
using .RunSettings
using .STBParameters
using .Uprating

IND_MATCHING = DataFrame()
EXPENDITURE_DATASET = DataFrame()

const COICOPDict = Dict{Symbol,T} where T <: Real

function broad_to_COICOP( ) :: COICOPDict

end

function match_in_consumption!( hh :: Household, settings :: Settings, which :: Int )

end

function uprate_expenditure( settings :: Settings )
    ## TODO much more specific uprating factors - just nom_gdp for now
    ## TODO we're just doing COICOP ones for now 
    ## TODO just add q into created dataset 
    nm = names( EXPENDITURE_DATASET )
    for r in eachrow( EXPENDITURE_DATASET)
        if r.a055 > 20 # a055 is interview Month code: > 20 is e.g January REIS and I don't know what REIS means 
            r.a055 -= 20
        end
        q = ((r.a055-1) ÷ 3) + 1 # 1,2,3=q1 and so on
        # lcf year seems to be actual interview year 
        y = r.year
        for n in nms
            if match( r"c[0-9]+[a-z]*",  n ) !== nothing # so c1234x, for example - CIOCP code
                sym = Symbol(n)
                r[sym] = Uprating.uprate( r[sym], y, q, Uprating.upr_nominal_gdp )
            end
        end
    end
end

function init( settings :: Settings )
    if settings.indirect_method == matching
        IND_MATCHING = CSV.File( "$(settings.data_dir)/$(settings.indirect_matching_dataframe).tab") |> DataFrame
        EXPENDITURE_DATASET = CSV.File("$(settings.data_dir)/$(settings.expenditure_dataset).tab" ) |> DataFrame
        uprate_expendtiture(  settings )
    end
end


end