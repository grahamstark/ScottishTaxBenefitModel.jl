#=
see:
This is the benefit/tax credit/IT/MinWage/NI rates for rUK, excluding NI,

from As of May, 2024
sources:
IT: 

https://www.gov.uk/government/publications/spring-budget-2024-overview-of-tax-legislation-and-rates-ootlar/annex-a-rates-and-allowances
* - allowances: https://www.gov.uk/government/publications/rates-and-allowances-income-tax/income-tax-rates-and-allowances-current-and-past
*   - https://www.gov.uk/marriage-allowance
*   - pension:https://www.gov.uk/government/publications/abolition-of-lifetime-allowance-and-increases-to-pension-tax-limits/pension-tax-limits
* NI: https://www.gov.uk/government/publications/rates-and-allowances-national-insurance-contributions/rates-and-allowances-national-insurance-contributions
* Benefits: https://www.gov.uk/government/publications/benefit-and-pension-rates-2023-to-2024/benefit-and-pension-rates-2023-to-2024
* Tax Credits, CB etc.:https://www.gov.uk/government/publications/rates-and-allowances-tax-credits-child-benefit-and-guardians-allowance/tax-credits-child-benefit-and-guardians-allowance

##  Local Taxes: 

* ENGLAND https://www.gov.uk/government/statistics/council-tax-levels-set-by-local-authorities-in-england-2023-to-2024/council-tax-levels-set-by-local-authorities-in-england-2023-to-2024
* WALES https://www.gov.wales/council-tax-levels-april-2023-march-2024
* SCOTLAND http://www.gov.scot/publications/council-tax-datasets/

## LHA 

* ENGLAND https://www.gov.uk/government/publications/local-housing-allowance-lha-rates-applicable-from-april-2023-to-march-2024
* WALES https://www.gov.wales/local-housing-allowance
* SCOTLAND: 

=#


function load_sys_2024_25_ruk!( sys :: TaxBenefitSystem{T} ) where T
    sys.name = "rUK System 2024/5"

    sys.it.non_savings_rates = [20.0,40.0,45.0]
    sys.it.non_savings_thresholds = [37_700, 125_140.0]
    sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???
  
    sys.it.savings_rates = [0, 20.0, 40.0, 45.0]
    sys.it.savings_thresholds = [5_000.0, 37_700.0, 125_000.0]
    sys.it.savings_basic_rate = 2 # above this counts as higher rate
  
    sys.it.dividend_rates = [0.0, 8.75,33.75,39.35]
    sys.it.dividend_thresholds = [500.0, 37_700.0, 150_000.0] # FIXME this gets the right answers & follows Melville, but the 500 is called 'dividend allowance in HMRC docs'
    sys.it.dividend_basic_rate = 2 # above this counts as higher 
  
    sys.it.personal_allowance   = 12_570.00
    sys.it.personal_allowance_income_limit = 100_000.00
    sys.it.personal_allowance_withdrawal_rate = 50.0
    sys.it.blind_persons_allowance  = 2_870.00
  
    sys.it.married_couples_allowance = 11_080.0
    sys.it.mca_minimum     = 4_080.00
    sys.it.mca_income_maximum   = 37_000.00
    sys.it.mca_credit_rate    = 10.0
    sys.it.mca_withdrawal_rate  = 50.0
  
    sys.it.marriage_allowance   = 1_260.00
    sys.it.personal_savings_allowance = 1_000.00
  
  # 29/2022 CHECK
  # FIXME better to have it straight from
  # the book with charges per CO2 range
  # and the data being an estimate of CO2 per type
  merge( sys.it.company_car_charge_by_CO2_emissions,
  Dict([ 
    Missing_Fuel_Type=>0.1,
    No_Fuel=>0.1,
    Other=>0.1,
    Dont_know=>0.1,
    Petrol=>0.25,
    Diesel=>0.37,
    Hybrid_use_a_combination_of_petrol_and_electricity=>0.16,
    Electric=>0.02,
    LPG=>0.02,
    Biofuel_eg_E85_fuel=>0.02 ]))

  
  sys.it.fuel_imputation = 27_800.00 # 22/23 # CHECK THIS

  #
  # TODO CHECK THIS WORKED EXAMPLE 2024/5 system change check
  # 
  sys.it.pension_contrib_basic_amount = 10_000.00
  sys.it.pension_contrib_annual_allowance = 60_000.00
  sys.it.pension_contrib_annual_minimum = 10_000.00
  sys.it.pension_contrib_threshold_income = 260_000.00
  sys.it.pension_contrib_withdrawal_rate = 50.0

  # NI
  # FREEPORTS ??? WTF ???
  sys.ni.abolished = false
  sys.ni.primary_class_1_rates = [0.0, 0.0, 8.0, 2.0 ]
  sys.ni.primary_class_1_bands = [123.0, 242.0, 967.0, 9999999999999.9] # the '-1' here is because json can't write inf
  sys.ni.secondary_class_1_rates = [0.0, 13.8, 13.8 ] # keep 2 so
  sys.ni.secondary_class_1_bands = [175.0, 967.0, 99999999999999.9 ]
  sys.ni.state_pension_age = 66; # fixme move
  # https://www.gov.uk/self-employed-national-insurance-rates
  sys.ni.class_2_threshold = 6_725.0;
  sys.ni.class_2_rate = 1.45;
  sys.ni.class_4_rates = [0.0, 6.0, 2.0 ]
  # TODO CHECK 50_270
  sys.ni.class_4_bands = [12_570.0, 50_270.0, 99999999999999.9 ]
  
  #
  # TODO CHECK APPRENTICE, U21 
  #


end