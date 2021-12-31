using ScottishTaxBenefitModel
using .Utils
using .STBIncomes
using StaticArrays

@enum A a1=1 a2=2 a3=3 a4=4 a5=5 
const ASize = Int(a5)
const MyArray = MVector{ASize,Float64}

Base.getindex( X::MyArray, s::A ) = getindex(X,Int(s))
Base.setindex!( X::MyArray, x, s::A) = setindex!(X,x,Int(s))


#
# make this illegal
#

function illegal( X::MyArray, s :: Int )
    throw( ArgumentError( "You need to index an IncomesArray with an element from the Incomes Enum"))
end

function illegal( X::MyArray, x, s :: Int )
    throw(ArgumentError( "You need to index an IncomesArray with an element from the Incomes Enum"))
end

Base.setindex!( X::MyArray, x, s::Int) = illegal( X, x, s )
Base.getindex( X::MyArray, s::Int) = illegal( X, s )

v = MyArray(zeros(5))

include( "income_enum.jl")

struct NewInc
    name :: String
    value :: Int
    label :: String
end

function writeenum( n :: NewInc )
    for i in instances( L_Incomes )
      v = Int(i)
      if v == n.value
        println( "const $(n.name) = $(n.value)")  
      elseif v > n.value
        v += 1
      ned
      println( "const $i = $v")  
    end
end
