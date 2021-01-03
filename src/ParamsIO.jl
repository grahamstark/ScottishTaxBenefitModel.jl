#
# See scripts/serialisation_experiments.jl this one always works but has an ugly global variable
# I'm using this for now.
# 
module ParamsIO
    
    using JSON3
    using StructTypes

    const T = Float64 # FIXME change this as needed
    
    using ScottishTaxBenefitModel
    using .STBParameters
    using .Definitions
    
    export to_file, from_file, toJSON, fromJSON
    
    StructTypes.StructType(::Type{IncomeTaxSys{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{AgeLimits{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{NationalInsuranceSys{T}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{PersonalAllowances{T}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{Premia{T}}) = StructTypes.Struct()
    
    StructTypes.StructType(::Type{WorkingTaxCredit{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{ChildTaxCredit{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{HoursLimits{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{IncomeRules{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{MinimumWage{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{SavingsCredit{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{HousingBenefits{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{LegacyMeansTestedBenefitSystem{T}}) = StructTypes.Struct()
        
    StructTypes.StructType(::Type{LocalHousingAllowance{T}}) = StructTypes.Struct()
    
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
    
    function toJSON( t :: TaxBenefitSystem ) :: String
        JSON3.write( t )
    end
    
    function fromJSON( s :: String ) :: TaxBenefitSystem
        t3 = JSON3.read( s, TaxBenefitSystem{T} ) 
    end
end