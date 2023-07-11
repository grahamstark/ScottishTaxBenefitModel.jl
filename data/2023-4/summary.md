# HACKY SUMMARY LHA/CTD Rates 2023/4

## BRMA

Unweighted Averages 2023/4

### England

https://www.gov.uk/government/publications/local-housing-allowance-lha-rates-applicable-from-april-2023-to-march-2024

* London

CAT A	CAT B	CAT C	CAT D	CAT E

118.726923076923	247.395384615385	305.462307692308	373.617692307692	471.603846153846

* Not London

76.3435251798561	118.556115107914	146.757985611511	176.499424460432	231.558057553957


### WALES

https://www.gov.wales/local-housing-allowance-lha-rates-april-2023-march-2024

96000 Swansea - use this for now
Shared Accommodation	70.77	62.50
1 bedroom	109.32	103.56
2 bedroom	120.82	113.92
3 bedroom	126.58	120.82
4 bedroom	172.60	165.70


### SCOTLAND 

https://www.gov.scot/publications/local-housing-allowance-rates-2022-2023/



CAT A	CAT B	CAT C	CAT D	CAT E

71.485	94.4833333333333	120.375	147.606666666667	225.662222222222


## CT BAND D

### ENGLAND

https://www.gov.uk/government/statistics/council-tax-levels-set-by-local-authorities-in-england-2023-to-2024/council-tax-levels-set-by-local-authorities-in-england-2023-to-2024

£2,065

### WALES

https://www.gov.wales/sites/default/files/statistics-and-research/2023-03/council-tax-levels-april-2023-march-2024-080.pdf

note wider bands

£1,879

### Scotland 

https://www.gov.scot/publications/council-tax-datasets/

£1,417


### HACK CODE

```julia 

hhlds = CSV.File( "model_households-2021-2021.tab") |> DataFrame
nr,nc = size(hhlds)
hhlds.council = Vector{Symbol}(undef,nr)
hhlds.council[hhlds.region .<=  112000009] .= :ENGLAND
hhlds.council[hhlds.region .== 112000007] .= :LONDON
hhlds.council[hhlds.region .== 299999999] .= :SCOTLAND
hhlds.council[hhlds.region .== 399999999] .= :WALES
hhlds.council[hhlds.region .== 499999999] .= :NIRELAND


people = CSV.File( "model_people-2021-2021.tab")|>DataFrame

# garbagy random room allocation
for hh in eachrow( hhlds )
    hhpeeps = people[((people.data_year .== hh.data_year).&(people.hid .== hh.hid)),:]
    hhkids = hhpeeps[hhpeeps.from_child_record .== 1,:]
    np = size(hhpeeps)[1]
    nk = size(hhkids)[1]
    hrooms = max(1, np + rand(-2:2))
    if nk > 0 
        hrooms = max(2, nk + rand(-2:2) + 1)
    end
    println( "np $np nk $nk hrooms $hrooms" )
    hh.bedrooms = hrooms
end

```

## Legacy -> UC Transition

https://commonslibrary.parliament.uk/constituency-data-universal-credit-roll-out/

* WALES: 
   - children 71
   - hcosts 69
   - incapacity  53
   - jobseekers 97
* ENGLAND:
   - children 74
   - hcosts 73
   - incapacity  53
   - jobseekers 98
* SCOŦLAND:
   - children 71
   - hcosts 71
   - incapacity  54
   - jobseekers 97
NIRELAND:  ????

```julia

# missing cols in old data

function makessamecols( old::DataFrame, new::DataFrame)
         targ = Symbol.(setdiff(names(new),names(old)))
         println( "targ = $targ");rows,cols = size(old)
         for t in targ
            old[:,t] = zeros(rows)
         end
end
```

### CREATE RUN

sys is: sys_2023-24_ruk.jl

settings: get_all_uk_settings_2023()

test harness:  all_uk_runner_tests.jl

testutils.jl get_uk_system( year :: Int )

### FIXMES

6 ethnic code !! - this is OK: another missing

### WEALTH

WAS regression `r6` in `weath_regressions.jl`. Going to ignore income since it's going to be easier to implement for now. Figures are big. Predictions have fewer small wealth values than actual:

```
Mean:           807,684.116504
Minimum:        15.333333
1st Quartile:   163,521.716450
Median:         488,257.709664
3rd Quartile:   1,057,610.432064
Maximum:        7,852,1163.638965

```

linear one `p7` behaves worse. Much lower 3rd quartile/max w

``` 
predicted (linear):
 Summary Stats:
Length:         13137
Missing Count:  0
Mean:           1019672.598609
Minimum:        -720382.174779
1st Quartile:   571362.265471
Median:         991733.467818
3rd Quartile:   1480206.099492
Maximum:        3152044.379579

```
We understate quite a bit in the FRS:

Modelled using FRS dataset (after several SNAFUs)
Mean:           414,401.397522
Minimum:        6,418.506903
1st Quartile:   80,159.525749
Median:         326,179.786283
3rd Quartile:   596,375.630477
Maximum:        5,020,388.102829

FUCK IT. Best I can do.

regressor comparisons:

### WAS

    north_east:0.05013117371963043
    north_west:0.11777118740732291
    yorkshire:0.10128892437549904
    east_midlands:0.08611839853997946
    west_midlands:0.08891296908862781
    east_of_england:0.1028858218318695
    london:0.07522527660545227
    south_east:0.13505189916733204
    south_west:0.10305691798790921
    wales:0.05321090452834493
    scotland:0.08634652674803239

    hrp_u_25:0.007414166761720087
    hrp_u_35:0.06461731493099122
    hrp_u_45:0.11856963613550815
    hrp_u_55:0.17195163681989278
    hrp_u_65:0.20383255389528915
    hrp_u_75:0.23611269533477813

    hrp_75_plus:0.19750199612182046
    weekly_net_income:697.1977417651677

    owner:0.49087487167788296
    mortgaged:0.2659404585376982
    renter:0.23303296452606365

    detatched:0.3140184783848523
    semi:0.3038097410744839
    terraced:0.24512375955286872
    purpose_build_flat:0.11115546937378806
    converted_flat:0.022014372077107335
    bedrooms:2.973366031709821

    managerial:0.4596213071746321
    intermediate:0.2153530284019619
    routine:0.2951979012204859

    total_wealth:800913.639159522
    num_children:0.35023383141325426
    num_adults:1.8657465495608532

### FRS

    avg(reg[(Intercept)]) = 1.0
    avg(reg[north_west]) = 0.10432961754018599
    avg(reg[yorkshire]) = 0.07753895424031533
    avg(reg[east_midlands]) = 0.06454394284658496
    avg(reg[west_midlands]) = 0.07322781301964648
    avg(reg[east_of_england]) = 0.08874792141405433
    avg(reg[london]) = 0.07365892714171338
    avg(reg[south_east]) = 0.1147995319332389
    avg(reg[south_west]) = 0.08499106977890004
    avg(reg[wales]) = 0.04982447496458706
    avg(reg[scotland]) = 0.11670875161667796
    avg(reg[owner]) = 0.4471885200468067
    avg(reg[mortgaged]) = 0.2594075260208166
    avg(reg[detatched]) = 0.29500523495719655
    avg(reg[semi]) = 0.29968590256820843
    avg(reg[terraced]) = 0.22411775574305598
    avg(reg[purpose_build_flat]) = 0.14627086284412144
    avg(reg[HBedrmr7]) = 2.2790540124407217
    avg(reg[hrp_u_25]) = 0.014781055613721747
    avg(reg[hrp_u_35]) = 0.10285151197881381
    avg(reg[hrp_u_45]) = 0.14503910820964463
    avg(reg[hrp_u_55]) = 0.16228367309232
    avg(reg[hrp_u_65]) = 0.19658803966249924
    avg(reg[hrp_u_75]) = 0.2076122436410667
    avg(reg[managerial]) = 0.450144731169551
    avg(reg[intermediate]) = 0.2610088070456365
    avg(reg[num_adults]) = 1.6847939890373838
    avg(reg[num_children]) = 0.43487097370203853
