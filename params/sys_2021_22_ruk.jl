"""
RUK 2021/22
"""
function load_sys_2021_22_ruk!( sys :: TaxBenefitSystem )
    sys.name = "rUK System 2021/22"
    sys.it.non_savings_rates = [20.0,40.0,45.0]
    sys.it.non_savings_thresholds = [37_500, 150_000.0]
    sys.it.non_savings_basic_rate = 1
end