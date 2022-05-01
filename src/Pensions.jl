module Pensions

using StatsBase

using ScottishTaxBenefitModel
using .ModelHousehold
using .Definitions
using .Randoms
export impute_employer_pension!

#
# In time, lots of stuff here. 
# For now, one simple function that solves a big problem in the FRS and likely
# other datasets, in a very rough way
#

# 
# Employer contribution bands by industry and pension type: 
# Table P10 - Office for National Statistics (no date). 
# Available at: https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/workplacepensions/datasets/annualsurveyofhoursandearningspensiontablesemployercontributionbandsbyindustryandbypensiontypep10 (Accessed: 23 November 2021).
#
# Data is broken down FT/PT M/F and by industry and contribution type.
# But this will do for a 1st attempt.
# This is the 2019 Final version, all employees 
#
# const FREQS = ProbabilityWeights([1.1,34.5,20.1,4.8,3.6,10.9,13.4,11.6]./100.0)
const FREQS = cumsum( [1.1,34.5,20.1,4.8,3.6,10.9,13.4,11.6]./100.0 )
const CONTRIBS = [0:0,0.01:0.01:4,4.01:0.01:8,8.01:0.01:10,10.01:0.01:12,12.01:0.01:15,15.01:0.01:20,20.01:25]./100.0

function impute_employer_pension!( pers :: Person )
    if pers.employment_status in [Full_time_Employee,Part_time_Employee]
        if ! haskey(pers.income,pension_contributions_employer) # CHECK this means zeros but present stay as zeros
            f = pickfirst( pers.onerand, R_EMPLOYERS_PENSION, FREQS )
            contrate = median( CONTRIBS[f] )
            pers.income[pension_contributions_employer] = pers.income[wages]*contrate
        end # no contrib already recorded
        
    end # employee
end

end # module Pensions