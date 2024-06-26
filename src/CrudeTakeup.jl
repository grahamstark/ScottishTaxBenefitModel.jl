module CrudeTakeup

using ArgCheck
using StatsBase

using ScottishTaxBenefitModel
using .Definitions
using .ModelHousehold
using .Results
using .Intermediate 
using .STBIncomes
using .Randoms: testp

export correct_for_caseload_non_takeup!

# crappy https://ifs.org.uk/sites/default/files/output_url_files/ifs-takeup1b.pdf

# table 6 WTC/ assume UC
const WTC_SINGPAR = 72.0/100.0
const WTC_OTHERS = 50.0/100.0
const UC_TAKEUP = 0.8
const TARGET_BENEFITS = union(LEGACY_MTBS,[UNIVERSAL_CREDIT])

# https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/867973/income-related-benefits-estimates-of-take-up-2017-2018.pdf
const PC_CASELOAD = 0.6
const HB_CASELOAD = 0.8
const IS_CASELOAD = 0.9

function caseload_takeup_prob( 
    hh       :: Household, # not actually used ATM
    intermed ::  MTIntermediate,
    amount   :: Real, 
    btype    :: Incomes ) :: Real
    if ! ( btype in TARGET_BENEFITS )
        return 1.0
    end
    prob = if btype in [UNIVERSAL_CREDIT]
            UC_TAKEUP
        elseif btype in [WORKING_TAX_CREDIT, CHILD_TAX_CREDIT ]
            if intermed.is_sparent
                WTC_SINGPAR
            else
                WTC_OTHERS
            end
        elseif btype == HOUSING_BENEFIT
            HB_CASELOAD
        elseif btype in [INCOME_SUPPORT,NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE, NON_CONTRIB_JOBSEEKERS_ALLOWANCE]
            IS_CASELOAD
        elseif btype in [PENSION_CREDIT,SAVINGS_CREDIT]
            PC_CASELOAD
        end
    # @argcheck btype in TARGET_BENEFITS
    # @argcheck 0.0 <= amount <= 10_000.0
    @assert 0.0 <= prob <= 1.0
    return prob
end

function correct_one!( 
    pres :: IndividualResult,
    hh   :: Household,
    pers :: Person,
    intermed :: MTIntermediate )
    for inc in TARGET_BENEFITS
        if pres.income[inc] > 0
            pr = caseload_takeup_prob( hh, intermed, pres.income[inc], inc )
            takesup = testp( pers.onerand, pr, Randoms.CASELOAD_TAKEUP )
            if ! takesup
                pres.income[inc] = 0.0
            end 
        end
    end
end

function correct_for_caseload_non_takeup!( 
    hres     :: HouseholdResult,
    hh       :: Household,
    intermed :: HHIntermed )
    bus = get_benefit_units( hh )
    for buno in eachindex( bus )
        bu = bus[buno]
        head = get_head( bu )
        correct_one!( 
            hres.bus[buno].pers[head.pid],
            hh,
            head,
            intermed.buint[buno] )
        spouse = get_spouse( bu )        
        if ! isnothing(spouse)
            correct_one!( 
                hres.bus[buno].pers[spouse.pid],
                hh,
                spouse,
                intermed.buint[buno]  );
        end
    end
end

end