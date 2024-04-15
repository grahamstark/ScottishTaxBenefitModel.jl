using Base.Unicode

"""
a_string_or_symbol_like_this => "A String Or Symbol Like This"
"""
function cpretty(a)
   s = string(a)
   s = strip(lowercase(s))
   s = replace(s, r"[_]" => " ")
   Unicode.titlecase(s)
end


PERS=[
    "hid::BigInt # == sernum",
    "pid::BigInt # == unique id (year * 100000)+",
    "pno:: Int # person number in household",
    "is_hrp :: Bool",
    "default_benefit_unit:: Int",
    "is_standard_child :: Bool",
    "age:: Int",
    "sex::Sex",
    "ethnic_group::Ethnic_Group",
    "marital_status::Marital_Status",
    "highest_qualification::Qualification_Type",
    "sic::SIC_2007",
    "occupational_classification::Standard_Occupational_Classification",
    "public_or_private :: Employment_Sector",
    "principal_employment_type :: Employment_Type",
    "socio_economic_grouping::Socio_Economic_Group",
    "age_completed_full_time_education:: Int",
    "years_in_full_time_work:: Int",
    "employment_status::ILO_Employment",
    "actual_hours_worked::RT",
    "usual_hours_worked::RT",
    "age_started_first_job :: Int",
    "income::Incomes_Dict{RT}",
    "benefit_ratios :: Incomes_Dict{RT}",
    "jsa_type :: JSAType # FIXME change this name",
    "esa_type :: JSAType",
    "dla_self_care_type :: LowMiddleHigh",
    "dla_mobility_type :: LowMiddleHigh",
    "attendance_allowance_type :: LowMiddleHigh",
    "pip_daily_living_type :: PIPType",
    "pip_mobility_type ::  PIPType",
    "bereavement_type :: BereavementType",
    "had_children_when_bereaved :: Bool ",
    "assets::Asset_Dict{RT}",
    "over_20_k_saving :: Bool",
    "pay_includes ::Included_In_Pay_Dict{Bool}",
    "registered_blind::Bool",
    "registered_partially_sighted::Bool",
    "registered_deaf::Bool",
    "disabilities::Disability_Dict{Bool}",
    "health_status::Health_Status",
    "has_long_standing_illness :: Bool",
    "adls_are_reduced :: ADLS_Inhibited",
    "how_long_adls_reduced :: Illness_Length",
    "relationships::Relationship_Dict",
    "relationship_to_hoh :: Relationship",
    "is_informal_carer::Bool",
    "receives_informal_care_from_non_householder::Bool",
    "hours_of_care_received::RT",
    "hours_of_care_given::RT",
    "hours_of_childcare :: RT",
    "cost_of_childcare :: RT",
    "childcare_type :: Child_Care_Type",
    "employer_provides_child_care :: Bool",
    "company_car_fuel_type :: Fuel_Type",
    "company_car_value :: RT",
    "company_car_contribution :: RT",
    "fuel_supplied :: RT",
    "work_expenses  :: RT ",
    "travel_to_work :: RT ",
    "debt_repayments :: RT ",
    "wealth_and_assets :: RT",
    "onerand :: String",
    "legal_aid_problem_probs :: Union{Nothing,DataFrameRow}"]

HHS= [
    "sequence:: Int # position in current generated dataset",
    "hid::BigInt",
    "data_year :: Int",
    "interview_year:: Int",
    "interview_month:: Int",
    "quarter:: Int",
    "tenure::Tenure_Type",
    "region::Standard_Region",
    "ct_band::CT_Band",
    "dwelling :: DwellingType",
    "council_tax::RT",
    "water_and_sewerage ::RT",
    "mortgage_payment::RT",
    "mortgage_interest::RT",
    "years_outstanding_on_mortgage:: Int",
    "mortgage_outstanding::RT",
    "year_house_bought:: Int",
    "gross_rent::RT",
    "rent_includes_water_and_sewerage::Bool",
    "other_housing_charges::RT ",
    "gross_housing_costs::RT",
    # "# total_income::RT",
    "total_wealth::RT",
    "house_value::RT",
    "weight::RT",
    "council :: Symbol",
    "nhs_board :: Symbol",
    "bedrooms :: Int",
    "head_of_household :: BigInt",
    "net_physical_wealth :: RT",
    "net_financial_wealth :: RT",
    "net_housing_wealth :: RT",
    "net_pension_wealth :: RT",
    "original_gross_income :: RT",
    "original_income_decile :: Int",
    "equiv_original_income_decile :: Int",
    # "# FIXME make a proper consumption structure here rather than just an lcf dump.",
    "expenditure :: Union{Nothing,DataFrameRow}",
    "factor_costs :: Union{Nothing,DataFrameRow}",
    "people::People_Dict{RT}",
    "onerand :: String",
    "equivalence_scales :: EQScales{RT}"]

function maketable( items :: AbstractArray, prefix )
    s = "s = \"<table class='table table-sm'>\"\n"
    s *= "s *= \"<thead><caption>Money Amounts in £s pw</caption></thead>\"\n"
    s *= "s *= \"<tbody>\"\n"
    for p in items
        m = match(r"(.*) *:: *(.*) *\#*.*", p )
        if ! isnothing(m)
            name = strip(m[1])
            pname = cpretty(m[1])
            target = "$(prefix).$(name)"     
            name_str = "$(name)_str"   
            type = m[2]
            typedec = if type == "RT"
                "$(name_str) = fmt($target)"
            elseif contains(type,r"}|_Dict")  
                "$(name_str) = html_format( $target )"
            else # if type in ["Int", "Integer", "Bool", "Symbol", "BigInt"]
                "$(name_str) = string($target)"
            end
            s *= "$typedec\n"
            s *= "s *= non_null_row( \"$(pname)\", $(name_str), $(prefix).$(name) )\n"
        end
    end
    s *= "s *= \"</tbody>\"\n"
    s *= "s *= \"</table>\"\n"
end

println( maketable(HHS, "hh"))
println( maketable(PERS, "pers"))
