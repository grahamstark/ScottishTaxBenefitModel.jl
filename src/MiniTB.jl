module MiniTB

import ScottishTaxBenefitModel.GeneralTaxComponents: calctaxdue, RateBands, TaxResult

import Parameters: @with_kw
#
# A toy tax-benefit system with outlines of the components
# a real model would need: models of people (and households)
# a parameter system, a holder for results, and some calculations
# using those things.
# Used in test building budget constraints.
# There's also some experiments of mine with constructors
# and copying strucs.
#

export calculate, DEFAULT_PERSON, modifiedcopy, TBParameters, Person, getnet
export modifiedcopy, DEFAULT_PARAMS, ZERO_PARAMS
export Gender, Male, Female, DEFAULT_WAGE, DEFAULT_HOURS
export NetType, NetIncome, TotalTaxes, BenefitsOnly
export calculatetax, calculatebenefit1, calculatebenefit2, calculate_internal
export equal,==

@enum NetType NetIncome TotalTaxes BenefitsOnly
@enum Gender Male Female

# experiment with types
const NullableFloat = Union{Missing,Float64}
const NullableInt = Union{Missing,Integer}
const NullableArray = Union{Missing,Array{Float64}}

const DEFAULT_HOURS = 30
const DEFAULT_WAGE = 5.0


@with_kw mutable struct Person
   pid::BigInt = 1
   wage::Float64 = DEFAULT_WAGE
   hours::Float64 = DEFAULT_HOURS
   age::Integer = 40
   sex::Gender = Male
end

@with_kw mutable struct Household
   hid :: Integer = 1
   rent::Float64 = 100.0
   people::Vector{Person} = [Person()]
end

const DEFAULT_PERSON = Person()
const DEFAULT_HOUSEHOLD = Household()

function weeklyise( x :: Real ) :: Real
   x / (365.25/7)
end

@with_kw mutable struct TBParameters
   it_allow::Float64 = weeklyise(12_500)
   it_rate = [0.20, 0.4]
   it_band = [weeklyise(50_000), 9999999999999999999.99]

   benefit1::Float64 = 73.00
   benefit2::Float64 = 101.0
   ben2_min_hours::Float64 = 30.0
   ben2_taper::Float64 = 0.41
   ben2_u_limit::Float64 = 123.0
   basic_income::Float64 = 0.0

end


const DEFAULT_PARAMS = TBParameters()

const ZERO_PARAMS = TBParameters(
   it_allow = 0.0,
   it_rate = [0.0,0.0],
   it_band = [weeklyise(50_000),99999999999999999999.99],
   benefit1 = 0.0,
   benefit2 = 0.0,
   ben2_min_hours = 0.0,
   ben2_taper = 0.0,
   ben2_u_limit = 0.0,
   basic_income = 0.0
)

import Base.==

function equal( l :: TBParameters, r :: TBParameters ) :: Bool
   (l.it_allow == r.it_allow) &&
   (l.it_rate == r.it_rate) &&
   (l.it_band == r.it_band) &&
   (l.benefit1 == r.benefit1) &&
   (l.benefit2 == r.benefit2) &&
   (l.ben2_min_hours == r.ben2_min_hours) &&
   (l.ben2_taper == r.ben2_taper) &&
   (l.ben2_u_limit == r.ben2_u_limit) &&
   (l.basic_income == r.basic_income)
end


import Base.==

function ==( l::TBParameters, r::TBParameters)::Bool
   equal( l, r )
end

const Results = Dict{Symbol,Any}

function calculatetax(pers::Person, params::TBParameters)::Float64
   taxable = max(0.0, pers.wage - params.it_allow)
   tc::TaxResult = calctaxdue(
      taxable    = taxable,
      rates      = params.it_rate,
      thresholds = params.it_band,
   )
   return tc.due
end

function calculatebenefit1(pers::Person, params::TBParameters)::Float64
   ben = params.benefit1 - pers.wage
   return max(0.0, ben )
end

function calculatebenefit2(pers::Person, params::TBParameters)::Float64
   b = pers.hours >= params.ben2_min_hours ? params.benefit2 : 0.0
   if pers.wage > params.ben2_u_limit
      b = max(0.0, b - (params.ben2_taper * (pers.wage - params.ben2_u_limit)))
   end
   return b
end

INCR = 0.001

function calculate_internal(pers::Person, params::TBParameters)::Results
   res = Results()
   res[:tax] = calculatetax(pers, params)
   res[:benefit1] = calculatebenefit1(pers, params)
   res[:benefit2] = calculatebenefit2(pers, params)
   res[:basic_income] = params.basic_income

   res[:netincome] = pers.wage + res[:benefit1] + res[:benefit2]+res[:basic_income] - res[:tax]
   return res
end

function calculate( pers::Person, params::TBParameters)::Results
   res1 = calculate_internal( pers, params )
   pers.wage += INCR
   res2 = calculate_internal( pers, params )
   m_metr = (res2[:netincome]-res1[:netincome])/INCR
   res1[:metr] = round( 1.0-m_metr, digits=4)
   tax_credit = res1[:netincome] - (m_metr*pers.wage)
   res1[:tax_credit] = round( tax_credit, digits=4)
   pers.wage -= INCR
   res1
end

end
