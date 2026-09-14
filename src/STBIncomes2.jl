module STBIncomes2

"""
Stolen from:
https://discourse.julialang.org/t/export-enum/5396/5
"""

#=
macro exported_enum(name, args...)
    if length(args) == 1 && args[1] isa Expr && args[1].head == :block
        # Handle the begin ... end block syntax
        block = args[1] 
        # Filter out comments from the block
        enum_members = filter(x -> x isa Symbol, block.args)
        return esc(quote
            @enum $name begin
                $(enum_members...)
            end
            export $name
            $([:(export $arg) for arg in enum_members]...)
        end)
    else
        # Handle the standard @enum syntax
        return esc(quote
            @enum($name, $(args...))
            export $name
            $([:(export $arg) for arg in args]...)
        end)
    end
end
=#

#=
*** missing_in_stb_incomes

s/BEREAVEMENT_ALLOWANCE bereavement_allowance//g
s/DLA_MOBILITY/dla_mobility/g
s/DLA_SELF_CARE/dla_self_care/g
s/CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE/contrib_employment_and_support_allowance/g
s/NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE/non_contrib_employment_and_support_allowance/g
s/SAVINGS_CREDIT/savings_credit/g
s/CONTRIB_JOBSEEKERS_ALLOWANCE/contrib_job_seekers_allowance/g
s/NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE non_contrib_job_seekers_allowance//g
s/COUNCIL_TAX_BENEFIT /council_tax_benefit/g
s/OTHER_TAX/other_tax/g
s/INDUSTRIAL_INJURY_BENEFIT/industrial_injury_disablement_benefit/g
s/maternity_grant_from_social_fund/maternity_grant/g
s/MATERNITY_GRANT/maternity_grant/g
s/war_widows_or_widowers_pension/war_widows_pension/g
s/WAR_WIDOWS_PENSION/war_widows_pension/g
s/OTHER_SCOTTISH_BENEFITS/other_scottish_benefits/g
s/BASIC_INCOME/basic_income/g
s/FUNERAL_GRANT/funeral_grant/g
1,$s/ACCIDENT_INSURANCE_SCHEME_BENEFITS/accident_insurance_scheme_benefits/g
1,$s/ADP_DAILY_LIVING/adp_daily_living/g
1,$s/ADP_MOBILITY/adp_mobility/g
1,$s/ALIMONY_AND_CHILD_SUPPORT_PAID/alimony_and_child_support_paid/g
1,$s/ALIMONY_AND_CHILD_SUPPORT_RECEIVED/alimony_and_child_support_received/g
1,$s/ANY_OTHER_NI_OR_STATE_BENEFIT/any_other_ni_or_state_benefit/g
1,$s/ANY_OTHER_SICKNESS_INSURANCE/any_other_sickness_insurance/g
1,$s/ARMED_FORCES_COMPENSATION_SCHEME/armed_forces_compensation_scheme/g
1,$s/ATTENDANCE_ALLOWANCE/attendance_allowance/g
1,$s/AVCS/avcs/g
1,$s/BANK_INTEREST/bank_interest/g
1,$s/BONDS_AND_GILTS/bonds_and_gilts/g
1,$s/CARERS_ALLOWANCE/carers_allowance/g
1,$s/CARERS_ALLOWANCE_SUPPLEMENT/carers_allowance_supplement/g
1,$s/CARERS_SUPPORT_PAYMENT/carers_support_payment/g
1,$s/CARE_INSURANCE/care_insurance/g
1,$s/CHILD_BENEFIT/child_benefit/g
1,$s/CHILD_DISABILITY_PAYMENT_CARE/child_disability_payment_care/g
1,$s/CHILD_DISABILITY_PAYMENT_MOBILITY/child_disability_payment_mobility/g
1,$s/CHILD_TAX_CREDIT/child_tax_credit/g
1,$s/CRITICAL_ILLNESS_COVER/critical_illness_cover/g
1,$s/DISCRETIONARY_HOUSING_PAYMENT/discretionary_housing_payment/g
1,$s/EDUCATION_ALLOWANCES/education_allowances/g
1,$s/FOSTER_CARE_PAYMENTS/foster_care_payments/g
1,$s/FREE_SCHOOL_MEALS/free_school_meals/g
1,$s/FRIENDLY_SOCIETIES/friendly_societies/g
1,$s/FRIENDLY_SOCIETY_BENEFITS/friendly_society_benefits/g
1,$s/GOVERNMENT_TRAINING_ALLOWANCES/government_training_allowances/g
1,$s/GUARDIANS_ALLOWANCE/guardians_allowance/g
1,$s/HEALTH_INSURANCE/health_insurance/g
1,$s/HOSPITAL_SAVINGS_SCHEME_BENEFITS/hospital_savings_scheme_benefits/g
1,$s/HOUSING_BENEFIT/housing_benefit/g
1,$s/INCAPACITY_BENEFIT/incapacity_benefit/g
1,$s/INCOME_SUPPORT/income_support/g
1,$s/INCOME_TAX/income_tax/g
1,$s/INDIVIDUAL_SAVINGS_ACCOUNT/individual_savings_account/g
1,$s/LOAN_REPAYMENTS/loan_repayments/g
1,$s/LOCAL_TAXES/local_taxes/g
1,$s/MATERNITY_ALLOWANCE/maternity_allowance/g
1,$s/NATIONAL_INSURANCE/national_insurance/g
1,$s/NATIONAL_SAVINGS/national_savings/g
1,$s/ODD_JOBS/odd_jobs/g
1,$s/OTHER_BENEFITS/other_benefits/g
1,$s/OTHER_DEDUCTIONS/other_deductions/g
1,$s/OTHER_INCOME/other_income/g
1,$s/OTHER_INVESTMENT_INCOME/other_investment_income/g
1,$s/PENSION_AGE_DISABILITY/pension_age_disability/g
1,$s/PENSION_CONTRIBUTIONS_EMPLOYEE/pension_contributions_employee/g
1,$s/PENSION_CONTRIBUTIONS_EMPLOYER/pension_contributions_employer/g
1,$s/PENSION_CREDIT/pension_credit/g
1,$s/PERMANENT_HEALTH_INSURANCE/permanent_health_insurance/g
1,$s/PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING/personal_independence_payment_daily_living/g
1,$s/PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY/personal_independence_payment_mobility/g
1,$s/PRIVATE_PENSIONS/private_pensions/g
1,$s/PRIVATE_SICKNESS_SCHEME_BENEFITS/private_sickness_scheme_benefits/g
1,$s/PROPERTY/property/g
1,$s/ROYALTIES/royalties/g
1,$s/SCOTTISH_CHILD_PAYMENT/scottish_child_payment/g
1,$s/SELF_EMPLOYMENT_INCOME/self_employment_income/g
1,$s/SEVERE_DISABILITY_ALLOWANCE/severe_disability_allowance/g
1,$s/STATE_PENSION/state_pension/g
1,$s/STOCKS_SHARES/stocks_shares/g
1,$s/STUDENT_GRANTS/student_grants/g
1,$s/STUDENT_LOANS/student_loans/g
1,$s/STUDENT_LOAN_REPAYMENTS/student_loan_repayments/g
1,$s/TRADE_UNIONS_ETC/trade_unions_etc/g
1,$s/TRADE_UNION_SICK_OR_STRIKE_PAY/trade_union_sick_or_strike_pay/g
1,$s/UNEMPLOYMENT_OR_REDUNDANCY_INSURANCE/unemployment_or_redundancy_insurance/g
1,$s/UNIVERSAL_CREDIT/universal_credit/g
1,$s/WAGES/wages/g
1,$s/WIDOWS_PAYMENT/widows_payment/g
1,$s/WINTER_FUEL_PAYMENTS/winter_fuel_payments/g
1,$s/WORKING_TAX_CREDIT/working_tax_credit/g
1,$s/WORK_EXPENSES/work_expenses/g

** OTHER BENEFITS TO DICT**

** TARGETS **

# vim -e [file] < m2pas.vim
# vim -e src/STBIncomes.jl < etc/incomes-edits.vim
# vim -e src/STBIncomes2.jl < etc/incomes-edits.vim
vim -e params/budget_2021_uc_changes.jl < etc/incomes-edits.vim
vim -e params/ni_rates_april_2024.jl < etc/incomes-edits.vim
vim -e params/ni_rates_jan_2024.jl < etc/incomes-edits.vim
vim -e params/sys_2019_20_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2020_21_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2020_21.jl < etc/incomes-edits.vim
vim -e params/sys_2021_22_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2021_22.jl < etc/incomes-edits.vim
vim -e params/sys_2021-uplift-removed.jl < etc/incomes-edits.vim
vim -e params/sys_2021a.jl < etc/incomes-edits.vim
vim -e params/sys_2022-23_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2022-23-july-ni.jl < etc/incomes-edits.vim
vim -e params/sys_2022-23.jl < etc/incomes-edits.vim
vim -e params/sys_2023_24_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2023_24_scotland.jl < etc/incomes-edits.vim
vim -e params/sys_2024_25_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2024_25_scotland.jl < etc/incomes-edits.vim
vim -e params/sys_2025_26_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2025_26_scotland.jl < etc/incomes-edits.vim
vim -e params/sys_2026_27_ruk.jl < etc/incomes-edits.vim
vim -e params/sys_2026_27_scotland.jl < etc/incomes-edits.vim
vim -e scripts/add_one_random_field.jl < etc/incomes-edits.vim
vim -e scripts/add_source_path.jl < etc/incomes-edits.vim
vim -e scripts/add-house-prices-to-indexs.jl < etc/incomes-edits.vim
vim -e scripts/artifacts-bulk-upload.jl < etc/incomes-edits.vim
vim -e scripts/budget-2026-calcs.jl < etc/incomes-edits.vim
vim -e scripts/bulk-upload-windows-hack.jl < etc/incomes-edits.vim
vim -e scripts/check-old-new-pers.jl < etc/incomes-edits.vim
vim -e scripts/code_snippets.jl < etc/incomes-edits.vim
vim -e scripts/comparisons_skeleton.jl < etc/incomes-edits.vim
vim -e scripts/correlations-with-durations-hack.jl < etc/incomes-edits.vim
vim -e scripts/create_all_disability_regressions.jl < etc/incomes-edits.vim
vim -e scripts/create_data.jl < etc/incomes-edits.vim
vim -e scripts/create_enums.jl < etc/incomes-edits.vim
vim -e scripts/create_full_artifacts_set.jl < etc/incomes-edits.vim
vim -e scripts/create_longterm_welsh_weights.jl < etc/incomes-edits.vim
vim -e scripts/create_scottish_subset.jl < etc/incomes-edits.vim
vim -e scripts/create_wales_subset.jl < etc/incomes-edits.vim
vim -e scripts/create_welsh_weights.jl < etc/incomes-edits.vim
vim -e scripts/create-scottish-la-weights.jl < etc/incomes-edits.vim
vim -e scripts/ct-calculations-draft.jl < etc/incomes-edits.vim
vim -e scripts/dla_pluto.jl < etc/incomes-edits.vim
vim -e scripts/dump_hhlds_t_json.jl < etc/incomes-edits.vim
vim -e scripts/essex-sb-bc-compares.jl < etc/incomes-edits.vim
vim -e scripts/essexsummary.jl < etc/incomes-edits.vim
vim -e scripts/fes-script-1.jl < etc/incomes-edits.vim
vim -e scripts/fixup_synth_data_v2.jl < etc/incomes-edits.vim
vim -e scripts/fixup_synth_data.jl < etc/incomes-edits.vim
vim -e scripts/frs_subset_creation_2020.jl < etc/incomes-edits.vim
vim -e scripts/frs_subset_creation.jl < etc/incomes-edits.vim
vim -e scripts/generate_bcs_for_essex.jl < etc/incomes-edits.vim
vim -e scripts/hack_regions_to_councils.jl < etc/incomes-edits.vim
vim -e scripts/hbai-20245.jl < etc/incomes-edits.vim
vim -e scripts/hbai-scotben-compares.jl < etc/incomes-edits.vim
vim -e scripts/holy_traits.jl < etc/incomes-edits.vim
vim -e scripts/income_editor.jl < etc/incomes-edits.vim
vim -e scripts/income_enum.jl < etc/incomes-edits.vim
vim -e scripts/infer_wealth.jl < etc/incomes-edits.vim
vim -e scripts/julcon.jl < etc/incomes-edits.vim
vim -e scripts/kernel_tests.jl < etc/incomes-edits.vim
vim -e scripts/la_costs_sketch.jl < etc/incomes-edits.vim
vim -e scripts/la-admin-stats.jl < etc/incomes-edits.vim
vim -e scripts/landman-scotben-compares.jl < etc/incomes-edits.vim
vim -e scripts/lcf_handler.jl < etc/incomes-edits.vim
vim -e scripts/lcfexample2.jl < etc/incomes-edits.vim
vim -e scripts/legal_aid_pluto_2.jl < etc/incomes-edits.vim
vim -e scripts/lorenz_example.jl < etc/incomes-edits.vim
vim -e scripts/make-minidata.jl < etc/incomes-edits.vim
vim -e scripts/makehtml.jl < etc/incomes-edits.vim
vim -e scripts/microsim_notebook_01.jl < etc/incomes-edits.vim
vim -e scripts/on_activate.jl < etc/incomes-edits.vim
vim -e scripts/panddocker.jl < etc/incomes-edits.vim
vim -e scripts/parse_income.jl < etc/incomes-edits.vim
vim -e scripts/performance_experiments.jl < etc/incomes-edits.vim
vim -e scripts/performance/getters.jl < etc/incomes-edits.vim
vim -e scripts/performance/globals.jl < etc/incomes-edits.vim
vim -e scripts/performance/hhld_example.jl < etc/incomes-edits.vim
vim -e scripts/performance/stability.jl < etc/incomes-edits.vim
vim -e scripts/performance/structs.jl < etc/incomes-edits.vim
vim -e scripts/plotter.jl < etc/incomes-edits.vim
vim -e scripts/pluto_experminents.jl < etc/incomes-edits.vim
vim -e scripts/pluto_get_hh backup 1.jl < etc/incomes-edits.vim
vim -e scripts/pluto_get_hh.jl < etc/incomes-edits.vim
vim -e scripts/pluto_tb_runner.jl < etc/incomes-edits.vim
vim -e scripts/pluto-importing-stb-example.jl < etc/incomes-edits.vim
vim -e scripts/problem_generation.jl < etc/incomes-edits.vim
vim -e scripts/reload_all_packages.jl < etc/incomes-edits.vim
vim -e scripts/rename-incomes-2026.jl < etc/incomes-edits.vim
vim -e scripts/rent-hb-calculations.jl < etc/incomes-edits.vim
vim -e scripts/retriever_notebook.jl < etc/incomes-edits.vim
vim -e scripts/retriever_web.jl < etc/incomes-edits.vim
vim -e scripts/retriever.jl < etc/incomes-edits.vim
vim -e scripts/run_skel.jl < etc/incomes-edits.vim
vim -e scripts/sa_merger.jl < etc/incomes-edits.vim
vim -e scripts/scottish-local-runs-2024.jl < etc/incomes-edits.vim
vim -e scripts/serialisation_experiments.jl < etc/incomes-edits.vim
vim -e scripts/simd_example.jl < etc/incomes-edits.vim
vim -e scripts/simple_runner.jl < etc/incomes-edits.vim
vim -e scripts/stboutput-cairo-plots-drafts.jl < etc/incomes-edits.vim
vim -e scripts/sugar.jl < etc/incomes-edits.vim
vim -e scripts/synth_file_libs.jl < etc/incomes-edits.vim
vim -e scripts/testinit.jl < etc/incomes-edits.vim
vim -e scripts/tidier_legalaid_expenses.jl < etc/incomes-edits.vim
vim -e scripts/wales-longterm.jl < etc/incomes-edits.vim
vim -e scripts/walestax.jl < etc/incomes-edits.vim
vim -e scripts/was-hacks.jl < etc/incomes-edits.vim
vim -e scripts/wb_get_data.jl < etc/incomes-edits.vim
vim -e scripts/wrangle-2025-statxplore-files.jl < etc/incomes-edits.vim
vim -e src/Affordability.jl < etc/incomes-edits.vim
vim -e src/BCCalcs.jl < etc/incomes-edits.vim
vim -e src/BenefitCap.jl < etc/incomes-edits.vim
vim -e src/BenefitGenerosity.jl < etc/incomes-edits.vim
vim -e src/ConsumptionData.jl < etc/incomes-edits.vim
vim -e src/CrudeTakeup.jl < etc/incomes-edits.vim
vim -e src/CTR.jl < etc/incomes-edits.vim
vim -e src/DataSummariser.jl < etc/incomes-edits.vim
vim -e src/DataUtils.jl < etc/incomes-edits.vim
vim -e src/Definitions.jl < etc/incomes-edits.vim
vim -e src/EnumeratedArrays.jl < etc/incomes-edits.vim
vim -e src/EquivalenceScales.jl < etc/incomes-edits.vim
vim -e src/ExampleHelpers.jl < etc/incomes-edits.vim
vim -e src/ExampleHouseholdGetter.jl < etc/incomes-edits.vim
vim -e src/ExampleTable.jl < etc/incomes-edits.vim
vim -e src/Expenditure.jl < etc/incomes-edits.vim
# vim -e src/frs_hbai_creation_libs.jl < etc/incomes-edits.vim
vim -e src/FRSHouseholdGetter.jl < etc/incomes-edits.vim
vim -e src/GeneralTaxComponents.jl < etc/incomes-edits.vim
vim -e src/HealthRegressions.jl < etc/incomes-edits.vim
vim -e src/HistoricBenefits.jl < etc/incomes-edits.vim
vim -e src/HouseholdAdjuster.jl < etc/incomes-edits.vim
vim -e src/HouseholdFromFrame.jl < etc/incomes-edits.vim
# vim -e src/HouseholdMappingFRS_Only.jl < etc/incomes-edits.vim
vim -e src/HTMLLibs.jl < etc/incomes-edits.vim
vim -e src/Incomes_New_Start.jl < etc/incomes-edits.vim
vim -e src/IncomeTaxCalculations.jl < etc/incomes-edits.vim
vim -e src/IncomeTypeSketch.jl < etc/incomes-edits.vim
vim -e src/IndirectTaxes.jl < etc/incomes-edits.vim
vim -e src/Intermediate.jl < etc/incomes-edits.vim
vim -e src/LegacyMeansTestedBenefits.jl < etc/incomes-edits.vim
vim -e src/legal_aid_costs_runner.jl < etc/incomes-edits.vim
vim -e src/legal_aid_parameters.jl < etc/incomes-edits.vim
vim -e src/LegalAidCalculations.jl < etc/incomes-edits.vim
vim -e src/LegalAidCostsModel.jl < etc/incomes-edits.vim
vim -e src/LegalAidData.jl < etc/incomes-edits.vim
vim -e src/LegalAidOutput.jl < etc/incomes-edits.vim
vim -e src/LegalAidRunner.jl < etc/incomes-edits.vim
vim -e src/LocalLevelCalculations.jl < etc/incomes-edits.vim
vim -e src/LocalTaxRunner.jl < etc/incomes-edits.vim
vim -e src/LocalWeightGeneration.jl < etc/incomes-edits.vim
vim -e src/matching/Common.jl < etc/incomes-edits.vim
vim -e src/matching/LCF.jl < etc/incomes-edits.vim
vim -e src/matching/Model.jl < etc/incomes-edits.vim
vim -e src/matching/old_code.jl < etc/incomes-edits.vim
vim -e src/matching/SHS.jl < etc/incomes-edits.vim
vim -e src/matching/WAS.jl < etc/incomes-edits.vim
vim -e src/MatchingLibs.jl < etc/incomes-edits.vim
vim -e src/MiniTB.jl < etc/incomes-edits.vim
vim -e src/ModelHousehold.jl < etc/incomes-edits.vim
vim -e src/Monitor.jl < etc/incomes-edits.vim
vim -e src/NationalInsuranceCalculations.jl < etc/incomes-edits.vim
vim -e src/NonMeansTestedBenefits.jl < etc/incomes-edits.vim
vim -e src/other_scottish_benefits.jl < etc/incomes-edits.vim
vim -e src/OtherTaxes.jl < etc/incomes-edits.vim
vim -e src/ParamsIO.jl < etc/incomes-edits.vim
vim -e src/Pensions.jl < etc/incomes-edits.vim
vim -e src/Randoms.jl < etc/incomes-edits.vim
vim -e src/Results.jl < etc/incomes-edits.vim
vim -e src/Runner.jl < etc/incomes-edits.vim
vim -e src/RunSettings.jl < etc/incomes-edits.vim
vim -e src/ScottishBenefits.jl < etc/incomes-edits.vim
vim -e src/ScottishTaxBenefitModel.jl < etc/incomes-edits.vim
vim -e src/server.jl < etc/incomes-edits.vim
vim -e src/SFCBehavioural.jl < etc/incomes-edits.vim
vim -e src/SHSData.jl < etc/incomes-edits.vim
vim -e src/SimplePovertyCounts.jl < etc/incomes-edits.vim
vim -e src/SingleHouseholdCalculations.jl < etc/incomes-edits.vim
vim -e src/STBOutput.jl < etc/incomes-edits.vim
vim -e src/STBParameters.jl < etc/incomes-edits.vim
vim -e src/STBUnits.jl < etc/incomes-edits.vim
vim -e src/targets/scotland-2020.jl < etc/incomes-edits.vim
vim -e src/targets/scotland-2021.jl < etc/incomes-edits.vim
vim -e src/targets/scotland-2022.jl < etc/incomes-edits.vim
vim -e src/targets/scotland-2025.jl < etc/incomes-edits.vim
vim -e src/targets/scotland-2026.jl < etc/incomes-edits.vim
vim -e src/targets/scotland-localities-2024.jl < etc/incomes-edits.vim
vim -e src/targets/wales-2023.jl < etc/incomes-edits.vim
vim -e src/targets/wales-longterm.jl < etc/incomes-edits.vim
vim -e src/TheEqualiser.jl < etc/incomes-edits.vim
vim -e src/TimeSeriesUtils.jl < etc/incomes-edits.vim
vim -e src/UBI.jl < etc/incomes-edits.vim
vim -e src/UCTransition.jl < etc/incomes-edits.vim
vim -e src/UniversalCredit.jl < etc/incomes-edits.vim
vim -e src/Uprating.jl < etc/incomes-edits.vim
vim -e src/Utils.jl < etc/incomes-edits.vim
vim -e src/WealthData.jl < etc/incomes-edits.vim
vim -e src/WebModelLibs.jl < etc/incomes-edits.vim
vim -e src/WebModelLibsOldVersion.jl < etc/incomes-edits.vim
vim -e src/Weighting.jl < etc/incomes-edits.vim
vim -e src/WeightingData.jl < etc/incomes-edits.vim
vim -e test/affordability_tests.jl < etc/incomes-edits.vim
vim -e test/all_uk_runner_tests.jl < etc/incomes-edits.vim
vim -e test/bc_tests.jl < etc/incomes-edits.vim
vim -e test/behavioural_tests.jl < etc/incomes-edits.vim
vim -e test/benefit_cap_tests.jl < etc/incomes-edits.vim
vim -e test/benefit_generosity_tests.jl < etc/incomes-edits.vim
vim -e test/complete_calc_tests.jl < etc/incomes-edits.vim
vim -e test/complete_mt_bens_tests.jl < etc/incomes-edits.vim
vim -e test/consumption_data_tests.jl < etc/incomes-edits.vim
vim -e test/crude_takeup_tests.jl < etc/incomes-edits.vim
vim -e test/ctr_tests.jl < etc/incomes-edits.vim
vim -e test/enumerated_arrays_tests.jl < etc/incomes-edits.vim
vim -e test/equaliser_tests.jl < etc/incomes-edits.vim
vim -e test/equivence_scale_tests.jl < etc/incomes-edits.vim
vim -e test/expenditure_tests.jl < etc/incomes-edits.vim
vim -e test/gainlose-test-driver.jl < etc/incomes-edits.vim
vim -e test/general_tests.jl < etc/incomes-edits.vim
vim -e test/health_regressions_tests.jl < etc/incomes-edits.vim
vim -e test/historic_benefits_tests-with-pip-transitions.jl < etc/incomes-edits.vim
vim -e test/historic_benefits_tests.jl < etc/incomes-edits.vim
vim -e test/household_adjuster_tests.jl < etc/incomes-edits.vim
vim -e test/household_tests.jl < etc/incomes-edits.vim
vim -e test/html_libs_tests.jl < etc/incomes-edits.vim
vim -e test/income_tax_tests_2023-24.jl < etc/incomes-edits.vim
vim -e test/income_tax_tests.jl < etc/incomes-edits.vim
vim -e test/incomes_tests.jl < etc/incomes-edits.vim
vim -e test/legacy_mt_tests.jl < etc/incomes-edits.vim
vim -e test/legal_aid_calculations_tests.jl < etc/incomes-edits.vim
vim -e test/local_level_calculations_tests.jl < etc/incomes-edits.vim
vim -e test/matching_tests.jl < etc/incomes-edits.vim
vim -e test/metr-tests.jl < etc/incomes-edits.vim
vim -e test/minimum_wage_tests.jl < etc/incomes-edits.vim
vim -e test/new_style_matching_tests.jl < etc/incomes-edits.vim
vim -e test/ni_tests.jl < etc/incomes-edits.vim
vim -e test/non_means_tested_bens_tests.jl < etc/incomes-edits.vim
vim -e test/output_tests.jl < etc/incomes-edits.vim
vim -e test/parameter_tests.jl < etc/incomes-edits.vim
vim -e test/pensions_tests.jl < etc/incomes-edits.vim
vim -e test/quikietest.jl < etc/incomes-edits.vim
vim -e test/randoms_tests.jl < etc/incomes-edits.vim
vim -e test/results_tests.jl < etc/incomes-edits.vim
vim -e test/root_finding_demo.jl < etc/incomes-edits.vim
vim -e test/runtests.jl < etc/incomes-edits.vim
vim -e test/scottish_benefits_tests.jl < etc/incomes-edits.vim
vim -e test/simple_runner_tests.jl < etc/incomes-edits.vim
vim -e test/social_security_age_tests.jl < etc/incomes-edits.vim
vim -e test/stboutput_tests.jl < etc/incomes-edits.vim
vim -e test/synthetic_data_tests.jl < etc/incomes-edits.vim
vim -e test/test_load_parameters.jl < etc/incomes-edits.vim
vim -e test/test_utils_tests.jl < etc/incomes-edits.vim
vim -e test/testutils.jl < etc/incomes-edits.vim
vim -e test/ubi_tests.jl < etc/incomes-edits.vim
vim -e test/uc_transition_tests.jl < etc/incomes-edits.vim
vim -e test/universal_credit_tests.jl < etc/incomes-edits.vim
vim -e test/uprating_tests.jl < etc/incomes-edits.vim
vim -e test/utils_tests.jl < etc/incomes-edits.vim
vim -e test/vs_age_uk_tests.jl < etc/incomes-edits.vim
vim -e test/vs_policy_in_practice_tests.jl < etc/incomes-edits.vim
vim -e test/wealth_tests.jl < etc/incomes-edits.vim
vim -e test/weighting_tests.jl < etc/incomes-edits.vim
vim -e test/wierd_results_replication.jl < etc/incomes-edits.vim

*** missing_in_def_incomes










=#
# from FRS Benefit names to our income names, where they aren't the same
const BEN_NAME_HACKS = Dict([
   :maternity_grant_from_social_fund=>:maternity_grant,
   :war_widows_or_widowers_pension=>:war_widows_pension,
   :dwp_third_party_payments_is_or_pc => :other_benefits,
   :dwp_third_party_payments_jsa_or_esa => :other_benefits,
   :extended_hb => :other_benefits,
   :funeral_grant_from_social_fund => :other_benefits,
   :child_tax_credit_lump_sum => :other_benefits,
   :child_winter_heating_assistance_payment => :other_benefits,
   :job_start_payment => :other_benefits,
   :pupil_development_grant => :other_benefits,
   :self_employment_expenses => :other_benefits,
   :self_employment_losses => :other_benefits,
   :social_fund_loan_repayment_from_is_or_pc => :other_benefits,
   :social_fund_loan_repayment_from_jsa_or_esa => :other_benefits,
   :troubles_permanent_disablement => :other_benefits,
   :working_tax_credit_lump_sum => :other_benefits,
])

macro exported_enum(name, args...)
    # Helper function to extract the symbol name from an enum member definition.
    # This correctly handles both `ValueA` and `ValueA = 1`.
    function get_enum_symbol(arg)
        if arg isa Symbol
            return arg
        elseif arg isa Expr && arg.head == :(=) && arg.args[1] isa Symbol
            return arg.args[1]
        else
            return nothing # Ignore things like LineNumberNodes or comments
        end
    end

    local enum_definition_args # The raw arguments for the @enum macro
    local member_names         # The clean symbols for the export list

    if length(args) == 1 && args[1] isa Expr && args[1].head == :block
        # Handle the `begin ... end` block syntax
        block = args[1]
        enum_definition_args = block
        member_names = filter(!isnothing, [get_enum_symbol(arg) for arg in block.args])
    else
        # Handle the standard `@enum(name, ValueA, ValueB=2)` syntax
        enum_definition_args = args
        member_names = filter(!isnothing, [get_enum_symbol(arg) for arg in enum_definition_args])
    end

    # The @enum macro can take the block or the splatted args directly.
    # We construct the appropriate call based on the syntax used.
    enum_definition = if enum_definition_args isa Expr && enum_definition_args.head == :block
        :(@enum $name $enum_definition_args)
    else
        :(@enum $name $(enum_definition_args...))
    end

    # We escape the final generated code block to ensure it is executed
    # in the scope where the macro was called.
    return esc(quote
        $enum_definition
        export $name
        $([:(export $name) for name in member_names]...)
    end)
end

@exported_enum Incomes_Type_2 begin
    wages  = 100
    self_employment_income = 101
    odd_jobs = 102
    work_expenses = 103
    avcs = 104
    other_deductions = 105
    pension_contributions_employee = 106
    pension_contributions_employer = 107

    private_pensions = 150

    national_savings = 200
    bank_interest  = 201
    stocks_shares  = 202
    individual_savings_account = 203
    property = 204
    royalties = 205
    bonds_and_gilts = 206 
    other_investment_income = 207 
    
    other_income = 300

    alimony_and_child_support_received = 400
    private_sickness_scheme_benefits = 401
    accident_insurance_scheme_benefits = 402
    hospital_savings_scheme_benefits = 403
    unemployment_or_redundancy_insurance = 404
    permanent_health_insurance = 405
    any_other_sickness_insurance = 406
    critical_illness_cover = 407
    trade_union_sick_or_strike_pay = 408
    health_insurance = 409
    alimony_and_child_support_paid = 410
    trade_unions_etc = 411
    friendly_societies = 412
    loan_repayments = 413
    
    income_tax = 1000
    national_insurance = 1001
    local_taxes = 1002
    social_fund_loan_repayment = 1003
    student_loan_repayments = 1004
    care_insurance = 1005

    child_benefit = 2000
    state_pension = 2001
    bereavement_allowance = 2002
    armed_forces_compensation_scheme = 2003
    war_widows_pension = 2004
    severe_disability_allowance = 2005
    attendance_allowance = 2006
    carers_allowance = 2007
    industrial_injury_benefit = 2008
    incapacity_benefit = 2009
    personal_independence_payment_daily_living = 2010
    personal_independence_payment_mobility = 2011
    dla_self_care = 2012
    dla_mobility = 2013
    education_allowances = 2014
    foster_care_payments = 2015
    maternity_allowance = 2016
    maternity_grant = 2017
    funeral_grant = 2018
    any_other_ni_or_state_benefit = 2019
    friendly_society_benefits = 2020
    government_training_allowances = 2021
    
    guardians_allowance = 2022
    widows_payment = 2023

    winter_fuel_payments = 2024        
    housing_benefit = 2025
    
    non_contrib_employment_and_support_allowance = 2050
    contrib_jobseekers_allowance = 2051
    non_contrib_jobseekers_allowance = 2052
    contrib_employment_and_support_allowance = 2053

    
    free_school_meals = 2026
    universal_credit  = 2027
    student_grants = 2028
    student_loans = 2029

    council_tax_benefit = 2060
    
    working_tax_credit = 3000
    child_tax_credit = 3001
    income_support = 3002
    pension_credit = 3003
    savings_credit = 3004

    scottish_child_payment = 4000
    carers_allowance_supplement = 4001
     
    discretionary_housing_payment = 4002  # not just scottish, but, hey..
    carers_support_payment = 4003
    child_disability_payment_care = 4004
    child_disability_payment_mobility = 4005
    pension_age_disability = 4006
    adp_daily_living = 4007
    adp_mobility = 4008

    other_benefits = 6000
    basic_income = 6001
    other_scottish_benefits = 6002

    other_tax = 7000
end


#=
@enum Incomes_Type begin
   wages = 1
   self_employment_income = 2
   self_employment_expenses = 3
   self_employment_losses = 4
   odd_jobs = 5
   private_pensions = 6
   national_savings = 7
   bank_interest = 8
   stocks_shares = 9
   individual_savings_account = 10
   # dividends = 11 ### FIXME NOT USED NEEDS DELETED. Use stocks_shares instead
   property = 12
   royalties = 13
   bonds_and_gilts = 14
   other_investment_income = 15
   other_income = 16
   alimony_and_child_support_received = 17
   health_insurance = 18
   alimony_and_child_support_paid = 19
   care_insurance = 20
   trade_unions_etc = 21
   friendly_societies = 22
   work_expenses = 23
   avcs = 24
   other_deductions = 25
   loan_repayments = 26
   student_loan_repayments = 27
   pension_contributions_employee = 28
   pension_contributions_employer = 29
   education_allowances = 30
   foster_care_payments = 31
   student_grants = 32
   student_loans = 33
   income_tax = 34
   national_insurance = 35
   local_taxes = 36
   free_school_meals = 37

   dla_self_care = 2001
   dla_mobility = 2002
   child_benefit = 2003
   pension_credit = 2004
   state_pension = 2005

   savings_credit = 2031
   contrib_employment_and_support_allowance = 2032
   non_contrib_employment_and_support_allowance = 2033
   contrib_job_seekers_allowance = 2034
   non_contrib_job_seekers_allowance = 2035

   council_tax_benfit = 2030

   bereavement_allowance = 2006
   armed_forces_compensation_scheme = 2008
   war_widows_or_widowers_pension = 2009
   severe_disability_allowance = 2010
   attendance_allowance = 2012
   carers_allowance = 2013
   jobseekers_allowance = 2014
   industrial_injury_disablement_benefit = 2015
   employment_and_support_allowance = 2016
   incapacity_benefit = 2017
   income_support = 2019
   maternity_allowance = 2021
   maternity_grant_from_social_fund = 2022
   funeral_grant = 2024
   any_other_ni_or_state_benefit = 2030
   trade_union_sick_or_strike_pay = 2031
   friendly_society_benefits = 2032
   private_sickness_scheme_benefits = 2033
   accident_insurance_scheme_benefits = 2034
   hospital_savings_scheme_benefits = 2035
   government_training_allowances = 2036
   guardians_allowance = 2037
   widows_payment = 2060
   unemployment_or_redundancy_insurance = 2061
   winter_fuel_payments = 2062
   child_winter_heating_assistance_payment = 2063
   dwp_third_party_payments_is_or_pc = 2065
   dwp_third_party_payments_jsa_or_esa = 2066
   social_fund_loan_repayment_from_is_or_pc = 2069
   social_fund_loan_repayment_from_jsa_or_esa = 2070
   extended_hb = 2078
   permanent_health_insurance = 2081
   any_other_sickness_insurance = 2082
   critical_illness_cover = 2083
   working_tax_credit = 2090
   child_tax_credit = 2091
   working_tax_credit_lump_sum = 2092
   child_tax_credit_lump_sum = 2093
   housing_benefit = 2094
   universal_credit = 2095
   personal_independence_payment_daily_living = 2096
   personal_independence_payment_mobility = 2097

   scottish_child_payment = 2112
   job_start_payment = 2115
   troubles_permanent_disablement = 2116
   child_disability_payment_care = 2121
   child_disability_payment_mobility = 2122
   pupil_development_grant = 2123
   adp_daily_living = 2124
   adp_mobility = 2125
   pension_age_disability = 2126
   carers_allowance_supplement = 2028
   carers_support_payment = 2029

   other_scottish_benefits = 2888
   other_tax = 2900

   discretionary_housing_payment = 2999
   other_benefits = 3000

end
=#

end
