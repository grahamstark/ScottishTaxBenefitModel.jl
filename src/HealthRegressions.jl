module HealthRegressions

using Base.Threads

using ArgCheck
using DataFrames
using StatsBase 
using Observables
using ScottishTaxBenefitModel
using .Definitions
using .FRSHouseholdGetter: get_regression_dataset
using .GeneralTaxComponents:WEEKS_PER_MONTH
using .ModelHousehold
using .Monitor: Progress
using .Results
using .RunSettings
using .Utils: make_start_stops

export get_death_prob,
    get_sf6d,
    summarise_sf12,
    create_health_indicator,
    do_health_regressions!

const SFD12_REGRESSION = DataFrame([
    "q1mlog" -.0669224 .0129316 -5.18 0.000 -.0922679 -.0415769;
    "q2mlog" -.065569 .0104701 -6.26 0.000 -.0860902 -.0450479;
    "q3mlog" -.0412175 .0083636 -4.93 0.000 -.0576098 -.0248251;
    "q4mlog" -.020758 .0068287 -3.04 0.002 -.034142 -.0073741;
    "mlogbhc" .168725 .0648695 2.60 0.009 .0415827 .2958673;
#    "q1dlog" -.0625272 .1071465 -0.58 0.560 -.2725313 .1474769;
#    "q2dlog" -.5528586 .1677468 -3.30 0.001 -.8816375 -.2240796;
#    "q3dlog" -.8932082 .1628441 -5.49 0.000 -1.212378 -.5740385;
#    "q4dlog" -.6595537 .1581312 -4.17 0.000 -.9694864 -.349621;
#    "dlogbhc" .0676555 .0926011 0.73 0.465 -.11384 .2491511;
#                 |
#      sf12mcs_dv |
#    "L1." .5262758 .0015297 344.04 0.000 .5232776 .5292739;
#                 |
    "female" -.799361 .0301345 -26.53 0.000 -.8584237 -.7402983;
    "race_ms" .8272873 .2600764 3.18 0.001 .317545 1.33703;
    "race_mx" -.4235778 .117867 -3.59 0.000 -.6545937 -.1925619;
    "race_as" -.2153134 .0672696 -3.20 0.001 -.3471599 -.0834669;
    "race_bl" .8555785 .0941759 9.08 0.000 .6709964 1.040161;
    "race_ot" -.0818178 .1989814 -0.41 0.681 -.4718156 .30818;
    "born_m" -.4412494 .1317057 -3.35 0.001 -.6993888 -.1831099;
    "born_uk" -.2516825 .0552214 -4.56 0.000 -.3599147 -.1434502;
    "llsid" -1.948192 .0330161 -59.01 0.000 -2.012903 -1.883482;
    "marciv" .4932766 .04302 11.47 0.000 .4089587 .5775946;
    "divsep" -.0224856 .0580789 -0.39 0.699 -.1363186 .0913475;
    "widow" .4939777 .0767766 6.43 0.000 .3434978 .6444576;
    "age2534" -.9669299 .0686889 -14.08 0.000 -1.101558 -.8323016;
    "age3544" -.662258 .0701197 -9.44 0.000 -.7996906 -.5248254;
    "age4554" -.2041259 .0709515 -2.88 0.004 -.3431888 -.0650631;
    "age5565" .616918 .0749932 8.23 0.000 .4699335 .7639024;
    "age6574" 1.180853 .0934391 12.64 0.000 .9977149 1.363991;
    "age75" 1.327786 .1054333 12.59 0.000 1.12114 1.534432;
    "hq_deg" -.1245185 .0595372 -2.09 0.036 -.2412097 -.0078273;
    "hq_ohe" .0742798 .0635622 1.17 0.243 -.0503004 .19886;
    "hq_al" .1178647 .0589437 2.00 0.046 .0023367 .2333927;
    "hq_gcse" .2075504 .0579199 3.58 0.000 .094029 .3210718;
    "hq_oth" .1935175 .0661833 2.92 0.003 .0638001 .3232349;
    "ec_emp" 2.582286 .0618956 41.72 0.000 2.460973 2.7036;
    "ec_se" 2.979511 .0795412 37.46 0.000 2.823612 3.13541;
    "ec_fam" 2.179118 .0870071 25.05 0.000 2.008587 2.34965;
    "ec_un" .5503545 .0904333 6.09 0.000 .3731078 .7276012;
    "ec_ret" 3.087541 .0829093 37.24 0.000 2.925041 3.250041;
    "rural" .2987942 .0350712 8.52 0.000 .2300557 .3675328;
    "gor_nw" .1452431 .0864176 1.68 0.093 -.024133 .3146192;
    "gor_yh" .1790899 .0895601 2.00 0.046 .0035547 .3546252;
    "gor_em" .2360591 .090613 2.61 0.009 .0584603 .4136579;
    "gor_wm" -.0172429 .0898078 -0.19 0.848 -.1932635 .1587778;
    "gor_ee" .2282277 .0885268 2.58 0.010 .0547177 .4017376;
    "gor_lo" .0892817 .0908445 0.98 0.326 -.088771 .2673344;
    "gor_se" .1642839 .0845966 1.94 0.052 -.0015231 .330091;
    "gor_sw" .1898351 .0885738 2.14 0.032 .0162329 .3634373;
    "gor_wa" -.071062 .0921799 -0.77 0.441 -.251732 .1096079;
    "gor_sc" .2934197 .0880426 3.33 0.001 .1208587 .4659807;
    "gor_ni" .5129039 .0951431 5.39 0.000 .3264262 .6993816;
    "ten_own" .3748749 .0493456 7.60 0.000 .278159 .4715909;
    "ten_sr" -.2750053 .0597592 -4.60 0.000 -.3921317 -.1578789;
    "cons" 20.01 .5385379 37.16 0.000 18.95448 21.06552 ], 
    ["var", "coef", "stderr",  "t",   "p",  "conflow",  "confhigh"] )

# just the sf12 coefficients, as a df row
const SFD12_REGRESSION_TR = unstack(SFD12_REGRESSION[!,[:var,:coef]],:var,:coef)[1,:]

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
    "cons" .3024495 .0068728  44.01  0.000  .2889791  .31592 
], ["var", "coef", "stderr",  "t",   "p",  "conflow",  "confhigh"] )

# just the sf6 coefficients, as a df row
const SFD6_REGRESSION_TR = unstack(SFD6_REGRESSION[!,[:var,:coef]],:var,:coef)[1,:]

"""
cross-mult a row in a dataframe using just the col names in common
"""
function rmul( d1 :: DataFrameRow, d2::DataFrameRow)::Number
    nc = Symbol.(intersect( names(d1), names(d2)))
    v1 = Vector(d1[nc])
    v2 = Vector(d2[nc])
    return v1'*v2
end

function rm2( 
    names :: Vector{Symbol}, 
    d1 :: DataFrameRow, 
    v2 ::Vector{Float64}; lagvalue=0.0 )::Float64
    v1 = Vector(d1[names])
    # println( [names v1])
    v1'*v2/(1-lagvalue)
end

# note to me:
# +(.*) \| *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *([0-9\.\-]+) *

"""
    Imputes the sf_6 measure for each non-child member of a household 
    Note the regression has monthly income but the taxben stuff is weekly
"""
function get_health( 
    ; hh   :: Household, 
      eq_bhc_net_income :: Real, 
      quintile :: Int,
      regression :: DataFrame = SFD12_REGRESSION,
      lagvalue = 0.5262758 ) :: Dict{BigInt,Number}
    @argcheck quintile in 1:5

    # @assert quintile in 1:5 "quintile is $quintile for income $eq_bhc_net_income"
    # but US income is monthly 
    inc = WEEKS_PER_MONTH*eq_bhc_net_income
    l_inc = 0.0
    if inc > 0
        l_inc = log(inc)
    end

    # single row with the `var`s in the big matrix as the element names
    r = unstack(regression[!,1:2],:var,:coef)[1,:]
    r .= 0.0

    hh_results = Dict{BigInt,Float64}() # FIXME T where T where ...
    
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
    r.cons = 1.0 

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
            r.age75 = pers.age in 75:200 ? 1 : 0

            r.hq_deg = highqual_degree_equiv( pers.highest_qualification ) ? 1 : 0 
            r.hq_ohe = highqual_other_he( pers.highest_qualification ) ? 1 : 0 
            r.hq_al = highqual_alevel_equiv( pers.highest_qualification ) ? 1 : 0
            r.hq_gcse = highqual_gcse_equiv( pers.highest_qualification ) ? 1 : 0
            r.hq_oth = highqual_other( pers.highest_qualification ) ? 1 : 0
            r.ec_emp = pers.employment_status in [Full_time_Employee, Part_time_Employee] ? 1 : 0
            r.ec_se = pers.employment_status in [Full_time_Self_Employed,Part_time_Self_Employed] ? 1 : 0
            r.ec_fam = pers.employment_status in [Looking_after_family_or_home] ? 1 : 0
            r.ec_un = pers.employment_status in [Unemployed] ? 1 : 0
            r.ec_ret = pers.employment_status in [Retired] ? 1 : 0
            # cast our row as a vector, then vector product
            res = Vector(r)' * regression.coef
            # @assert 0 < res < 1 "sf6 out-of-range 0:1 $res"
            hh_results[ pers.pid ] = res/(1-lagvalue) 
            # for long-run equilibrium, divide by the lagged coef on SF6d.
        end
    end
    hh_results
end


"""
FIXME move this somewhere more sensible?
"""
function get_quintiles( decs :: Vector )::Vector
    @argcheck size(decs)[1] == 10
    quintiles = fill(0.0,5)
    q = 0
    for i in 2:2:10
        q += 1
        quintiles[q] = decs[i]
    end
    @assert size( quintiles )[1] == 5
    quintiles
end

function q_from_inc( thresh :: Vector, inc :: Real )::Int
    n = size(thresh)[1]
    for i in 1:n
        if inc <= thresh[i]
            return i;
        end
    end
    @assert false "got to end shouldn't happen"
end

function make_frame( nhhlds :: Int )::DataFrame
    N = nhhlds*5 # 5 people per hhld : should be enough
    
    return DataFrame( 
        hid=fill( BigInt(0), N ),
        pid=fill( BigInt(0), N ), 
        data_year = fill( 0, N ), 
        weight = fill( 0.0, N ), 
        hh_type = zeros( Int, N ),
        num_people = zeros( Int, N ),
        tenure = fill( Missing_Tenure_Type, N ),
        region = fill( Missing_Standard_Region, N ),
        sex = fill(Missing_Sex, N ),
        ethnic_group = fill(Missing_Ethnic_Group, N ),
        is_child = fill( false, N ),
        age_band  = zeros(Int, N ),
        employment_status = fill(Missing_ILO_Employment, N ),
        decile = zeros( Int, N ),
        sf6=fill( 0.0, N ),
        sf12=fill( 0.0, N ))
end

"""
Create a dataframe worth of sf6s.
Call after a run, for 1 system, sending in the main deciles output
"""
function create_health_indicator( 
    hhr :: DataFrame, 
    deciles :: Matrix, 
    observer :: Observable,
    settings :: Settings ) :: DataFrame
    # FIXME jamming threading off here since there's a problem runnung 2x in close succession & no time to fix it
    # settings.requested_threads )
    num_threads = min( nthreads(), 1 ) 
    quintiles = get_quintiles( deciles[:,3])
    start,stop = make_start_stops( settings.num_households, num_threads )
    println("settings.num_households=$(settings.num_households) num_threads=$num_threads")
    allout = make_frame(0)
    @time @threads for thread in 1:num_threads
        n = stop[thread] - start[thread] + 1
        ncases = 0
        out = make_frame( n )
        for hno in start[thread]:stop[thread]
            hh = FRSHouseholdGetter.get_household( hno )
            nation = nation_from_region( hh.region )
            if nation in settings.included_nations
                if hno % 100 == 0
                    observer[] = 
                        Progress( settings.uuid, "health", thread, hno, 100, settings.num_households )
                end
                # println( "hh.hid=$(hh.hid) hh.data_year=$(hh.data_year)")
                # println( "hhrs = $( hhr[1:5,[:hid,:data_year]])")
                inc = hhr[ (hhr.hid.== hh.hid) .& (hhr.data_year .== hh.data_year), :eq_bhc_net_income][1]
                quintile = q_from_inc( quintiles, inc )
                sf12 = get_health( 
                    hh = hh, 
                    eq_bhc_net_income=inc, 
                    quintile=quintile )
                sf6 = get_health( 
                    hh = hh, 
                    eq_bhc_net_income=inc, 
                    quintile=quintile,
                    regression = SFD6_REGRESSION,
                    lagvalue = 0.5337817 )
                for (pid,sf) in sf6
                    ncases += 1
                    pers = hh.people[pid]
                    out[ncases,:weight] = hh.weight
                    out[ncases,:pid] = pid
                    out[ncases,:hid] = hh.hid
                    out[ncases,:data_year] = hh.data_year
                    out[ncases,:sf6] = sf
                    out[ncases,:sf12] = sf12[pid]
                    out[ncases,:hh_type] = hhr[hno,:hh_type]
                    out[ncases,:num_people] = hhr[hno,:num_people]
                    out[ncases,:tenure] = hh.tenure
                    out[ncases,:region] = hh.region
                    out[ncases,:decile] = hhr[hno,:decile]
                    out[ncases,:sex] = pers.sex
                    out[ncases,:age_band] = age_range( pers.age )
                    out[ncases,:employment_status] = pers.employment_status
                    out[ncases,:ethnic_group] = pers.ethnic_group
                end # pids in hhld
            end # included
        end # hh loop
        allout = vcat( allout, out[1:ncases,:] )
    end # threads
    allout
end

"""
h - the dataframe made by create_health_indicator
return histogram, count of below settings.sf12_depression_limit, thresholds
for 0.025% increments 
"""
function summarise_sf12( h :: DataFrame, settings :: Settings ) :: NamedTuple
    w = weights(h[!,:weight])
    sf = h[!,:sf12]
    range = 0.025:0.025:1
    average,sdev = StatsBase.mean_and_std( sf, w )
    med = StatsBase.median( sf, w )
    thresholds = quantile( sf , w, range ) 
    hist = fit(Histogram, sf, w, 0:2:100 )
    popn = sum( h[ !, :weight ])
    depressed = sum( h[h.sf12 .<= settings.sf12_depression_limit, :weight ])
    depressed_pct = 100*depressed/popn
    (; depressed, depressed_pct, hist, thresholds, range, average, med, sdev, popn )
end

"""
Calculate sf6 & sf12 health measures, return a summary of sf12, and insert health stuff into indiv records.
"""
function do_health_regressions!( results :: NamedTuple, settings :: Settings ) :: Array{NamedTuple}
    uk_data = get_regression_dataset() # alias
    uk_data_ads = uk_data[(uk_data.from_child_record .== 0).&(uk_data.gor_ni.==0),:]
    sys = [get_system(year=2023, scotland=false), get_system( year=2023, scotland=false )]    
    results = do_one_run( settings, sys, obs )
    outf = summarise_frames!( results, settings )    
    summaries = []
    nc12 = Symbol.(intersect( names(uk_data), names(SFD12_REGRESSION_TR)))
    coefs12 = Vector{Float64}( SFD12_REGRESSION_TR[nc12] )
    nc6 = Symbol.(intersect( names(uk_data), names(SFD6_REGRESSION_TR)))
    coefs6 = Vector{Float64}( SFD6_REGRESSION_TR[nc6] )
    nsys = size( results.indiv )[1]
    @time for sysno in 1:nsys
        data_ads = innerjoin( 
            uk_data_ads, 
            results.indiv[sysno], on=[:data_year, :hid ], makeunique=true )
        data_ads.mlogbhc = log.(max.(1,WEEKS_PER_MONTH.*data_ads.eq_bhc_net_income ))
        data_ads.quintile = ((data_ads.decile .+1) .÷ 2)
        data_ads.q1mlog = (data_ads.quintile .== 1) .* data_ads.mlogbhc
        data_ads.q2mlog = (data_ads.quintile .== 2) .* data_ads.mlogbhc
        data_ads.q3mlog = (data_ads.quintile .== 3) .* data_ads.mlogbhc
        data_ads.q4mlog = (data_ads.quintile .== 4) .* data_ads.mlogbhc
        data_ads.q5mlog = (data_ads.quintile .== 5) .* data_ads.mlogbhc
        k = 0
        for h in eachrow(data_ads)
            k += 1
            pslot = get_slot_for_person( BigInt(h.pid), h.data_year )
            sf12 = rm2( nc12, h, coefs12; lagvalue = 0.526275 )            
            results.indiv[sysno][pslot,:sf12] = sf12
            sf6 = rm2( nc6, h, coefs6; lagvalue = 0.5337817 )
            results.indiv[sysno][pslot,:sf6] = sf6                
            results.indiv[sysno][pslot,:has_mental_health_problem] = 
                sf12 <= settings.sf12_depression_limit 
            results.indiv[sysno][pslot,:qualys] = -1
            results.indiv[sysno][pslot,:life_expectancy] = -1
        end
        summary = summarise_sf12( results.indiv[sysno][results.indiv[sysno].sf12 .> 0,:], settings )
        push!( summaries, summary )
    end       
    return summaries
end

function get_death_prob( 
    ;
    hh   :: Household,
    hres :: HouseholdResult )  :: Dict{BigInt,Number}
   
end

end # module