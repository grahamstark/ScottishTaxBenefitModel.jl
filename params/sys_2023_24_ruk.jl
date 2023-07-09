
#
# rUK taxes 2022/3, where these are different.
#
sys.it.non_savings_rates = [20.0,40.0,45.0]
sys.it.non_savings_thresholds = [37_700, 150_000.0]
sys.it.non_savings_basic_rate = 1 # above this counts as higher rate

sys.nmt_bens.carers.scottish_supplement = 0.0 # FROM APRIL 2021

sys.scottish_child_payment.amount = 25.0
sys.scottish_child_payment.maximum_age = 15


sys.loctax.ct.band_d = Dict(
  [
    :ENGLAND  => 2_065.0,
    :WALES    => 1_879.0,
    :SCOTLAND => 1_417.0,
    :LONDON => 2_065.0,
    :NIRELAND => -99999.99
    ] )

brmapath = joinpath(MODEL_DATA_DIR, "local", "brma-2023-2024-country-averages.csv")

sys.hr.brmas = loadBRMAs( 4, T, brmapath )     
