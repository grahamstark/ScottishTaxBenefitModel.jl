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

Modelled using FRS dataset (after several SNAFUs)

Mean:           379,393.622325
Minimum:        6,418.506903
1st Quartile:   70,167.589825
Median:         303,485.405193
3rd Quartile:   536,157.907387
Maximum:        4,156,325.713490


