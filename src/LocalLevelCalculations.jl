module LocalLevelCalculations

using ScottishTaxBenefitModel
using .Definitions

using .ModelHousehold: Person,BenefitUnit,Household, is_lone_parent, get_benefit_units,
    is_single, pers_is_disabled, pers_is_carer, search, count, num_carers,
    has_disabled_member, has_carer_member, le_age, between_ages, ge_age,
    empl_status_in, has_children, num_adults, pers_is_disabled, is_severe_disability
    
using .STBParameters: LegacyMeansTestedBenefitSystem, IncomeRules,  
    Premia, PersonalAllowances, HoursLimits, AgeLimits, reached_state_pension_age, state_pension_age,
    WorkingTaxCredit, SavingsCredit, IncomeRules, MinimumWage, ChildTaxCredit,
    HousingBenefits, LocalHousingAllowance, LocalTaxes
    
using .GeneralTaxComponents: TaxResult, calctaxdue, RateBands

    

	export calc_lha, calc_bedroom_tax, calc_council_tax, initialise

	function load_ct()
	    
	end
	
	function calc_lha( council :: Symbol )
	
	end
	
	
	function calc_bedroom_tax(council :: Symbol, num_children :: Int )
	
	end
	
	function calc_council_tax( hh :: Household ) :: AbstractFloat
	
	end

	function initialise()
	
	end

end
