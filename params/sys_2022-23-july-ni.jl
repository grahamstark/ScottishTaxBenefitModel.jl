"""
national insurance changes from 6th July 2022
see: https://www.gov.uk/government/publications/spring-statement-2022-factsheet-on-personal-tax/spring-statement-2022-personal-tax-factsheet

see fn 5 in that doc on why they say 11,908 and we say 12_570
for class 4
"""
function load_sys_2022_23_july_ni!( sys :: TaxBenefitSystem )
    sys.name *= " with July NI Changes"
    #sys.ni.primary_class_1_bands = [123.0, 242.0, 967.0, 9999999999999.9] # the '-1' here is because json can't write inf
    sys.ni.class_4_bands = [12_570.0 , 50_270.0, 99999999999999.9 ]
end