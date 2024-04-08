"""
 NI
 From Jan 6 2024-5th April 2024
 https://www.gov.uk/national-insurance-rates-letters
"""
function load_ni_rates_jan_2024!( sys :: TaxBenefitSystem )
    sys.ni.abolished = false
    sys.ni.primary_class_1_rates = [0.0, 0.0, 10.0, 2.0 ]
    sys.ni.primary_class_1_bands = [123.0, 242.0, 967.0, 9999999999999.9] 
    sys.ni.secondary_class_1_rates = [0.0, 13.8, 13.8 ] # keep 2 so
    sys.ni.secondary_class_1_bands = [175.0, 967.0, 99999999999999.9 ]
    sys.ni.state_pension_age = 66; # fixme move
    # https://www.gov.uk/self-employed-national-insurance-rates
    sys.ni.class_2_threshold = 6_725.0;
    sys.ni.class_2_rate = 3.45;
    sys.ni.class_4_rates = [0.0, 9.0, 2.0 ]
    sys.ni.class_4_bands = [12_570.0, 50_270.0, 99999999999999.9 ]
end

