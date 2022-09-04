#
# imputations
#
module Expenditure

using ScottishTaxBenefitModel

using .Intermediate
using .ModelHousehold
using .Results

const COEFS = [1.6828173937157354, 0.0435596075343851, -0.5871109496468505, 
    0.06857117295491019, -0.0026985222962243797, 0.006247381738514693, 
    0.0047354846618714, 0.0017097645144521962, 0.002936094795804745, 
    0.0034117003997959573, 0.008951483467790098, -0.0022912744657734387, 
   -0.015820321931804122, 0.0047597568228447545, 0.004610832589291722, 
    0.007806445502617293, 0.006976750844514854, 0.005244815182982568, 
    0.005089342448939115, -0.0006378208885813217, -0.0012328905821025248]

    #= FROM regressions/heating_regressions.jl eqn 4.6

    sh_fuel_inc ~ 1 + l_fuel_price + l_net_inc + :(l_net_inc ^ 2) + :(l_net_inc ^ 3) + scotland + owner + mortgaged + privrent + larent + detatched + terraced + flat + other_accom + age_u_18 + age_18_69 + age_70_plus + winter + spring + summer + t_trend

    Coefficients:
    ──────────────────────────────────────────────────────────────────────────────────────
                          Coef.   Std. Error       t  Pr(>|t|)     Lower 95%     Upper 95%
    ──────────────────────────────────────────────────────────────────────────────────────
    (Intercept)     1.68282      0.0493872     34.07    <1e-99   1.58602       1.77962
    l_fuel_price    0.0435596    0.00375923    11.59    <1e-30   0.0361915     0.0509277
    l_net_inc      -0.587111     0.0257956    -22.76    <1e-99  -0.63767      -0.536551
    l_net_inc ^ 2   0.0685712    0.0044539     15.40    <1e-52   0.0598415     0.0773009
    l_net_inc ^ 3  -0.00269852   0.000253824  -10.63    <1e-25  -0.00319602   -0.00220103
    scotland        0.00624738   0.000526097   11.87    <1e-31   0.00521623    0.00727854
    owner           0.00473548   0.000636536    7.44    <1e-12   0.00348787    0.0059831
    mortgaged       0.00170976   0.00064743     2.64    0.0083   0.000440797   0.00297873
    privrent        0.00293609   0.000682028    4.30    <1e-04   0.00159931    0.00427288
    larent          0.0034117    0.000744397    4.58    <1e-05   0.00195268    0.00487073
    detatched       0.00895148   0.000435753   20.54    <1e-92   0.0080974     0.00980556
    terraced       -0.00229127   0.000420449   -5.45    <1e-07  -0.00311536   -0.00146719
    flat           -0.0158203    0.000544317  -29.06    <1e-99  -0.0168872    -0.0147535
    other_accom     0.00475976   0.00109538     4.35    <1e-04   0.00261281    0.0069067
    age_u_18        0.00461083   0.000186594   24.71    <1e-99   0.00424511    0.00497656
    age_18_69       0.00780645   0.00026655    29.29    <1e-99   0.007284      0.00832889
    age_70_plus     0.00697675   0.000390551   17.86    <1e-70   0.00621127    0.00774223
    winter          0.00524482   0.00044307    11.84    <1e-31   0.00437639    0.00611324
    spring          0.00508934   0.000444408   11.45    <1e-29   0.0042183     0.00596039
    summer         -0.000637821  0.000444062   -1.44    0.1509  -0.00150819    0.000232544
    t_trend        -0.00123289   6.52395e-5   -18.90    <1e-78  -0.00136076   -0.00110502
    ──────────────────────────────────────────────────────────────────────────────────────
    
    =#

"""
fuel price should be e.g. 1.2 if 20% above uprated to value
"""
function impute_fuel(
    household_result :: HouseholdResult{T},
    household        :: Household{T},
    intermed         :: HHIntermed,
    fuel_price       :: T, # these should all be point differences from base forecast data
    cpi              :: T,
    rem_cpi          :: T,
    modelled_year    :: Int ) :: NamedTuple where T
    v = zeros(T,21)
    v[1] = 1.0 # intercept
    v[2] = log( fuel_price / rem_cpi ) # rel pr fuel``
    v[3] = household_result.bhc_net_income / cpi ## FIXME make a price index with fuel
    v[4] = v[3]^2
    v[5] = v[3]^3
    v[6] = hh.region == Scotland ? 1 : 0
    v[7] = hh.tenure == Owned_outright ? 1 : 0
    v[8] = hh.tenure == Mortgaged_Or_Shared ? 1 : 0
    v[9] = hh.tenure in [Private_Rented_Unfurnished, Private_Rented_Furnished] ?  1 : 0
    v[10] = hh.tenure == Council_Rented ? 1 : 0
    v[11] = hh.dwelling == detatched ? 1 : 0 
    v[12] = hh.dwelling == terraced ? 1 : 0 
    v[13] = hh.dwelling == flat ? 1 : 0 
    v[14] = hh.dwelling in [caravan, other_dwelling] ? 1 : 0
    v[15] = count( hh, le_age, 17 ) 
    v[16] = count( hh, between_ages, 18, 69 ) 
    v[17] = count( hh, ge_age, 70 ) 
    @assert sum(v[15:17]) == intermed.num_people
    v[18] = hh.interview_month in [12,1,2] ? 1 : 0 # winter dec-feb
    v[19] = hh.interview_month in [3,4,5] ? 1 : 0  # spring mar-may
    v[20] = hh.interview_month in [6,7,8] ? 1 : 0  # summer june-aug
    v[21] = modelled_year - 2008
    pred_share : T = v'COEFS
    @assert pred_share > 0 && pred_share < 1
    pred_spend = fuel_price*pred_share*household_result.bhc_net_income
    return (pred_share=pred_share, pred_spend=pred_spend)
end

end # module