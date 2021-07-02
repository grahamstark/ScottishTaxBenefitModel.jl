module ParamsIO
#
# This is a failed experiment in reading and writing the model parameters in JSON - one
# of several time-consuming failures. Kept around because json I/O would be lovely
# if it could be made to work.
# 
# THIS DOESN'T WORK !!!1
# json3 turns the structures below the top-level into Dicts
# and I don't know why.
#
# See scripts/serialisation_experiments.jl 
# 

    using ScottishTaxBenefitModel
    using .STBParameters
    using .Definitions
    
    using JSON3
    using JSON
    using StructTypes
    using TimeSeries
    
    const T = Float64 # FIXME change this as needed
    
    
    export load, to_file, from_file, toJSON, fromJSON
    
    StructTypes.StructType(::Type{TimeSeries.TimeArray}) = StructTypes.ArrayType()
    
    StructTypes.StructType(::Type{TimeSeries.TimeArray{Int64,2,Dates.Date,Array{Int64,2}}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{IncomeTaxSys{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{AgeLimits}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{NationalInsuranceSys{T}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{PersonalAllowances{T}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{Premia{T}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{WorkingTaxCredit{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{ChildTaxCredit{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{HoursLimits}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{IncomeRules{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{MinimumWage{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{SavingsCredit{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{HousingBenefits{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{LegacyMeansTestedBenefitSystem{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{HousingRestrictions{T}}) = StructTypes.Struct()
    
    ## .. and so on
    
    StructTypes.StructType(::Type{TaxBenefitSystem{T}}) = StructTypes.Struct()

        
    function to_file( filename :: String, t :: TaxBenefitSystem )  
        io = open( filename, "w")
        JSON3.pretty( io, JSON3.write( t ), 4 )
        close( io )
    end
    
    function from_file( filename :: String )::TaxBenefitSystem   
        io = open( filename, "r")
        t = JSON3.read( io, TaxBenefitSystem{T} )
        close( io )
        return t                            
    end    
    
    function toJSON( t :: TaxBenefitSystem{T}) :: String
        JSON3.write( t )
    end
    
    function fromJSON( s :: String ) :: TaxBenefitSystem
        t = TaxBenefitSystem{T}()# JSON3.read( s, TaxBenefitSystem{T} ) 
        #sp :: Dict = JSON.parse( s )
        #t.it = JSON3.read( sp["it"], IncomeTaxSys{T} )
    end
end