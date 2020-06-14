module DataUtils
#
# FIXME messing with Generics and Show() in particular
#
import DataFrames: DataFrame
import Statistics: mean, median, std, quantile
import Parameters: @with_kw
using  ScottishTaxBenefitModel
using ScottishTaxBenefitModel.Definitions

export summarise_over_positive, add_to!
export initialise, MinMaxes, show

"""
FIXME passing a type like this can't be idiomatic ...
d needs to be some type of enum (something which instances can work with)
"""
function initialise( x :: Real, d :: DataType )
    dict = Dict{d,Real}()
    for i in instances( d )
        dict[i] = x
    end
    dict
end

@with_kw mutable struct MinMaxes{T}
    ## FIXME I don't think passing T is idiomatic ..
    max ::Dict{T,Real}=initialise( -99999999999999999.9, T )
    min ::Dict{T,Real}=initialise( 99999999999999.999, T )
    sum ::Dict{T,Real}=initialise( 0.0, T )
    poscounts ::Dict{T,Real} = initialise( 0.0, T )
    n :: Integer = 0
end

function add_to!( mms :: MinMaxes, addn :: Dict )
    kys = keys( addn )
    mms.n += 1
    for k in kys
        mms.max[k] = max( mms.max[k], addn[k] )
        mms.min[k] = min( mms.min[k], addn[k] )
        mms.sum[k] += addn[k]
        if addn[k]>0
            mms.poscounts[k]+= 1.0
        end
    end
end

function show( io::IO, mms :: MinMaxes{T} ) where T
    s = ""
    ks = sort(collect(keys(mms.poscounts)))
    for k in ks
        maxx = mms.max[k]
        minx = mms.min[k]
        pc = mms.poscounts[k]
        if pc>0
            mean = mms.sum[k] / pc
        else
            mean = 0.0
        end
        #show( io, "$k = (max=$(maxx), min=$(minx), mean=$mean poscounts=$pc) \n");
        println( io, "$k = (max=$(maxx), min=$(minx), mean=$mean poscounts=$pc)");
    end
end

function show( mms :: MinMaxes{T} ) where T
    show( stdout, mms )
end

"""
Means, etc. over just the positive and non-missing elements of a df column
"""
function summarise_over_positive( df::DataFrame, col::Symbol )::NamedTuple
   m = (df[!,col].!== missing) .&
       (df[!,col] .> 0.0)
   sz = size(df[m,col])[1]
   if sz > 0
       (
       num_positive = sz,
       frame_size = size(df[!,col])[1],
       max=maximum(df[m,col]),
       min=minimum(df[m,col]),
       mean=mean(df[m,col]),
       stdev=std(df[m,col]),
       deciles = quantile( df[m,col], [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9] )
      )
   else
      ( num_positive = 0,
        frame_size = size(df[!,col])[1],
        max=0,
        min=0,
        mean=0,
        stdev=0,
        deciles=[] )
   end
end

end
