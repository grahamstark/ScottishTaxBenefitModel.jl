# SCOTLAND
sys.name = "Scottish System 2023/24"
sys.it.non_savings_rates = [19.0,20.0,21.0,42.0,47.0]
sys.it.non_savings_thresholds = [2_162, 13_118, 31_092, 125_120.0]
sys.it.non_savings_basic_rate = 2 # above this counts as higher rate rate FIXME 3???

sys.nmt_bens.carers.scottish_supplement = 0.0 # FROM APRIL 2021


brmapath = joinpath(MODEL_DATA_DIR, "local", "lha_rates_scotland_2023_24.csv")

sys.hr.brmas = loadBRMAs( 4, T, brmapath )
