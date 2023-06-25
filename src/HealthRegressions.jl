module HealthRegressions

using ArgCheck
using DataFrames

using ScottishTaxBenefitModel
using .Definitions
using .GeneralTaxComponents:WEEKS_PER_MONTH
using .ModelHousehold
using .Results

export get_death_prob
export get_sf6d

const SFD6_REGRESSION = DataFrame([
    "q1mlog" -.0004121 .0001645  -2.51  0.012  -.0007345  -.0000898;
    "q2mlog" -.0007313 .0001332  -5.49  0.000  -.0009923  -.0004702;
    "q3mlog" -.000679 .0001064  -6.38  0.000  -.0008875  -.0004705;
    "q4mlog" -.0003551 .0000869  -4.09  0.000  -.0005254  -.0001849;
    "mlogbhc" .0051953 .0008252  6.30  0.000  .003578  .0068126;
#    "q1dlog" .0005124 .0013629  0.38  0.707  -.0021588  .0031836;
#    "q2dlog" -.0034277 .0021336  -1.61  0.108  -.0076094  .000754;
#    "q3dlog" -.0081074 .0020713  -3.91  0.000  -.0121671  -.0040477;
#    "q4dlog" -.0096112 .0020113  -4.78  0.000  -.0135533  -.0056691;
#    "dlogbhc" .0001985 .0011779  0.17  0.866  -.00211  .0025071;
    "female" -.010241 .0003834  -26.71  0.000  -.0109924  -.0094895;
    "race_ms" .0073831 .003308  2.23  0.026  .0008996  .0138665;
    "race_mx" -.0051334 .0014992  -3.42  0.001  -.0080719  -.002195;
    "race_as" -.0113549 .0008564  -13.26  0.000  -.0130334  -.0096764;
    "race_bl" .0072463 .0011977  6.05  0.000  .0048989  .0095936;
    "race_ot" -.009669 .002531  -3.82  0.000  -.0146297  -.0047082;
    "born_m" .0009416 .0016751  0.56  0.574  -.0023415  .0042247;
    "born_uk" .0018567 .0007023  2.64  0.008  .0004802  .0032331;
    "llsid" -.0506025 .0004371  -115.78  0.000  -.0514592  -.0497459;
    "marciv" .0044845 .000547  8.20  0.000  .0034124  .0055567;
    "divsep" -.0023306 .0007388  -3.15  0.002  -.0037786  -.0008826;
    "widow" -.0005617 .0009765  -0.58  0.565  -.0024756  .0013523;
    "age2534" -.0152145 .0008739  -17.41  0.000  -.0169274  -.0135017;
    "age3544" -.0145724 .0008926  -16.33  0.000  -.0163218  -.012823;
    "age4554" -.0137875 .0009037  -15.26  0.000  -.0155588  -.0120163;
    "age5565" -.0091562 .0009548  -9.59  0.000  -.0110275  -.0072849;
    "age6574" -.0056498 .001188  -4.76  0.000  -.0079782  -.0033215;
    "age75" -.0170103 .0013407  -12.69  0.000  -.0196381  -.0143826;
    "hq_deg" .0071459 .0007576  9.43  0.000  .005661  .0086308;
    "hq_ohe" .0065171 .0008087  8.06  0.000  .0049321  .0081022;
    "hq_al" .0070895 .00075  9.45  0.000  .0056195  .0085596;
    "hq_gcse" .0071972 .0007371  9.76  0.000  .0057526  .0086418;
    "hq_oth" .0045121 .0008419  5.36  0.000  .002862  .0061622;
    "ec_emp" .0398993 .0007906  50.47  0.000  .0383498  .0414489;
    "ec_se" .0436185 .001014  43.02  0.000  .0416312  .0456059;
    "ec_fam" .0326606 .0011079  29.48  0.000  .0304891  .034832;
    "ec_un" .0161176 .0011512  14.00  0.000  .0138613  .0183739;
    "ec_ret" .0375567 .0010544  35.62  0.000  .0354901  .0396233;
    "rural" .003955 .0004461  8.87  0.000  .0030807  .0048293;
    "gor_nw" -.0001711 .0010992  -0.16  0.876  -.0023255  .0019833;
    "gor_yh" .0007933 .0011391  0.70  0.486  -.0014394  .003026;
    "gor_em" .0017145 .0011525  1.49  0.137  -.0005444  .0039734;
    "gor_wm" -.0016317 .0011423  -1.43  0.153  -.0038706  .0006072;
    "gor_ee" .00248 .001126  2.20  0.028  .0002731  .0046869;
    "gor_lo" .0011987 .0011555  1.04  0.300  -.001066  .0034633;
    "gor_se" .002256 .001076  2.10  0.036  .000147  .0043649;
    "gor_sw" .0024576 .0011266  2.18  0.029  .0002495  .0046657;
    "gor_wa" -.0030937 .0011725  -2.64  0.008  -.0053917  -.0007956;
    "gor_sc" .003073 .0011198  2.74  0.006  .0008782  .0052679;
    "gor_ni" .0001698 .0012101  0.14  0.888  -.002202  .0025415;
    "ten_own" .0072883 .0006278  11.61  0.000  .0060578  .0085189;
    "ten_sr" -.00562 .0007603  -7.39  0.000  -.0071102  -.0041298;
    "_cons" .3024495 .0068728  44.01  0.000  .2889791  .31592 
], ["var", "coef", "stderr",  "t",   "p",  "conflow",  "confhigh"] )

## TODO
const QUINTILE_LIMITS = [
    1,
    2,
    3,
    4,
    5
]

# +(.*) \| *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *

"""
    Imputes the sf_6 measure for each non-child member of a household 
    Note the regression has monthly income by the taxben stuff is weekly
"""
function get_sf_6d( 
    ; hh   :: Household, 
      eq_bhc_net_income :: Real, 
      quintile :: Int ) :: Dict{BigInt,Number}
    @argcheck quintile in 1:5

    # @assert quintile in 1:5 "quintile is $quintile for income $eq_bhc_net_income"
    # but US income is monthly 
    inc = WEEKS_PER_MONTH*eq_bhc_net_income
    l_inc = 0.0
    if inc > 0
        l_inc = log(inc)
    end

    # single row with the `var`s in the big matrix as the element names
    r = unstack(SFD6_REGRESSION[!,1:2],:var,:coef)[1,:]
    r .= 0.0

    sf_6ds = Dict{BigInt,Float64}() # FIXME T where T where ...
    
     # household level
    r.q1mlog = quintile == 1 ? l_inc : 0.0
    r.q2mlog = quintile == 2 ? l_inc : 0
    r.q3mlog = quintile == 3 ? l_inc : 0
    r.q4mlog = quintile == 4 ? l_inc : 0
    # r.q5mlog = quintile == 5 ? inc : 0
    r.mlogbhc = l_inc
    r.gor_nw = hh.region == North_West ? 1 : 0
    r.gor_yh = hh.region == Yorks_and_the_Humber ? 1 : 0
    r.gor_em = hh.region == East_Midlands ? 1 : 0
    r.gor_wm = hh.region == West_Midlands ? 1 : 0
    r.gor_ee = hh.region == East_of_England ? 1 : 0
    r.gor_lo = hh.region == London ? 1 : 0
    r.gor_se = hh.region == South_East ? 1 : 0
    r.gor_sw = hh.region == South_West ? 1 : 0
    r.gor_wa = hh.region == Wales ? 1 : 0
    r.gor_sc = hh.region == Scotland ? 1 : 0
    r.gor_ni = hh.region == Northern_Ireland ? 1 : 0
    r.ten_own = hh.tenure in [Owned_outright, Mortgaged_Or_Shared ] ? 1 : 0
    r.ten_sr = hh.tenure in [Council_Rented, Housing_Association] ? 1 : 0
    r._cons = 1.0 

    # person (non child) level
    for (pid,pers) in hh.people
        if ! pers.is_standard_child
            r.female = pers.sex == Female ? 1 : 0
            r.race_ms = pers.ethnic_group == Missing_Ethnic_Group ? 1 : 0
            r.race_mx = pers.ethnic_group == Mixed_or_Multiple_ethnic_groups ? 1 : 0
            r.race_as = pers.ethnic_group == Asian_or_Asian_British ? 1 : 0
            r.race_bl = pers.ethnic_group == Black_or_African_or_Caribbean_or_Black_British ? 1 : 0
            r.race_ot = pers.ethnic_group == Other_ethnic_group ? 1 : 0
            r.born_m = 0
            r.born_uk = 0
            r.llsid = 
                if pers.has_long_standing_illness
                    1.0
                elseif (pers.adls_are_reduced in [reduced_a_lot]) &&
                    (pers.how_long_adls_reduced in [Between_six_months_and_12_months, v_12_months_or_more])
                    1.0
                else
                    0.0
                end

            r.marciv = pers.marital_status == Married_or_Civil_Partnership ? 1.0 : 0
            r.divsep = pers.marital_status in [Separated,Divorced_or_Civil_Partnership_dissolved] ? 1 : 0
            r.widow = pers.marital_status == Widowed
            r.age2534 = pers.age in 25:34 ? 1 : 0
            r.age3544 = pers.age in 35:44 ? 1 : 0
            r.age4554 = pers.age in 45:54 ? 1 : 0
            # FIXME check HR 5564
            r.age5565 = pers.age in 55:64 ? 1 : 0
            r.age6574 = pers.age in 65:74 ? 1 : 0
            r.age75 = pers.age in [75:200]

            r.hq_deg = highqual_degree_equiv( pers.highest_qualification ) ? 1 : 0 
            r.hq_ohe = highqual_other_he( pers.highest_qualification ) ? 1 : 0 
            r.hq_al = highqual_alevel_equiv( pers.highest_qualification ) ? 1 : 0
            r.hq_gcse = highqual_gcse_equiv( pers.highest_qualification ) ? 1 : 0
            r.hq_oth = highqual_other( pers.highest_qualification ) ? 1 : 0
            r.ec_emp = pers.employment_status in [Full_time_Employee, Part_time_Employee] ? 1 : 0
            r.ec_se = pers.employment_status in [Full_time_Self_Employed,Part_time_Self_Employed] ? 1 : 0
            r.ec_fam = pers.employment_status in [Looking_after_family_or_home] ? 1 : 0
            r.ec_un = pers.employment_status in [Unemployed] ? 1 : 0
            ec_ret = pers.employment_status in [Retired] ? 1 : 0
            # cast our row as a vector, then vector product
            sf6 = Vector(r)' * SFD6_REGRESSION.coef
            @assert 0 < sf6 < 1 "sf6 out-of-range 0:1 $sf6"
            sf_6ds[ pers.pid ] = sf6
        end
    end
    sf_6ds
end

function get_death_prob( 
    ;
    hh   :: Household,
    hres :: HouseholdResult )  :: Dict{BigInt,Number}
    
end

end # module