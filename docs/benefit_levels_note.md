# AA/PIP/DLA levels

2019/20 levels

DLA Levels

* high 87.65
* med  58.70
* low  23.20

DLA Mobility

* High 61.20
* Low 23.20


## Combined UK 2015-18 Data 

```julia

ukp = CSV.File( "model_people.tab" ) |> DataFrame
dropmissing!( ukp, [:income_attendence_allowance] )

```


```Julia

ukp[(ukp.income_dlaself_care .> 0), [:data_year,:income_dlaself_care,:income_dlamobility ]]

│ Row  │ data_year │ income_dlaself_care │ income_dlamobility │
│      │ Int64?    │ Float64?            │ Float64?           │
├──────┼───────────┼─────────────────────┼────────────────────┤
│ 1    │ 2015      │ 82.3                │ 0.0                │
│ 2    │ 2015      │ 55.1                │ 21.8               │
│ 3    │ 2015      │ 82.3                │ 57.45              │
│ 4    │ 2015      │ 55.1                │ 57.45              │
│ 5    │ 2015      │ 21.8                │ 0.0                │
│ 6    │ 2015      │ 55.1                │ 21.8               │
│ 7    │ 2015      │ 82.3                │ 57.45              │
│ 8    │ 2015      │ 82.3                │ 21.8               │
│ 9    │ 2015      │ 21.8                │ 0.0                │
│ 10   │ 2015      │ 21.8                │ 57.45              │
│ 11   │ 2015      │ 55.1                │ 21.8               │
│ 12   │ 2015      │ 82.3                │ 21.8               │
│ 13   │ 2015      │ 110.2               │ 114.9              │
│ 14   │ 2015      │ 55.1                │ 57.45              │
│ 15   │ 2015      │ 55.1                │ 57.45              │
│ 16   │ 2015      │ 21.8                │ 21.8               │
│ 17   │ 2015      │ 82.3                │ 0.0                │
│ 18   │ 2015      │ 55.1                │ 21.8               │
│ 19   │ 2015      │ 21.8                │ 0.0                │
│ 20   │ 2015      │ 55.1                │ 57.45              │
│ 21   │ 2015      │ 82.3                │ 0.0                │
⋮
│ 5387 │ 2018      │ 57.3                │ 0.0                │
│ 5388 │ 2018      │ 22.65               │ 0.0                │
│ 5389 │ 2018      │ 85.6                │ 59.75              │
│ 5390 │ 2018      │ 22.65               │ 59.75              │
│ 5391 │ 2018      │ 85.6                │ 0.0                │
│ 5392 │ 2018      │ 22.65               │ 59.75              │
│ 5393 │ 2018      │ 85.6                │ 59.75              │
│ 5394 │ 2018      │ 85.6                │ 59.75              │
│ 5395 │ 2018      │ 85.6                │ 59.75              │
│ 5396 │ 2018      │ 57.3                │ 0.0                │
│ 5397 │ 2018      │ 85.6                │ 22.65              │
│ 5398 │ 2018      │ 171.9               │ 67.95              │
│ 5399 │ 2018      │ 57.3                │ 22.65              │
│ 5400 │ 2018      │ 22.65               │ 0.0                │
│ 5401 │ 2018      │ 85.6                │ 22.65              │
│ 5402 │ 2018      │ 57.3                │ 22.65              │
│ 5403 │ 2018      │ 85.6                │ 59.75              │
│ 5404 │ 2018      │ 57.3                │ 0.0                │
│ 5405 │ 2018      │ 57.3                │ 59.75              │
│ 5406 │ 2018      │ 57.3                │ 0.0                │
│ 5407 │ 2018      │ 85.6                │ 59.75              │
│ 5408 │ 2018      │ 85.6                │ 59.75              │

```

### More on big DLAs

`114.9`  `110.2` etc. are roughly double amounts

Probably a simpler way in [Cheat Sheet](https://ahsmart.com/pub/data-wrangling-with-data-frames-jl-cheat-sheet/index.html).

```julia

println( "hid,data year,income dlaself care,age,employment status,hours of care received,health status=,adls are reduced,has long standing illness," );
println( ",---,-------------------,---,-----------------,----------------------,--------------,----------------,-------------------------," );
for r in eachrow(ukp[(ukp.income_dlaself_care .> 100), [:data_year,:hid ]])
    peeps = ukp[((ukp.hid.==r.hid).&(ukp.data_year.==r.data_year)),:]
    for p in eachrow( peeps )
        println( "$(p.hid),$(p.data_year),$(p.income_dlaself_care),$(p.age),$(p.employment_status),$(p.hours_of_care_received),$(p.health_status),$(p.adls_are_reduced),$(p.has_long_standing_illness)" )
    end
end;

```
See: large_dla_breakdown.ods

Conclusion from that: God knows. Only a few appear to be payments for a couple rolled into one.

## AA

2019/20

* High 87.65
* Low 58.70

```julia

ukp[(ukp.income_attendence_allowance .> 0), [:data_year,:income_attendence_allowance ]]

2442-element Array{Float64,1}:
│ Row  │ data_year │ income_attendence_allowance │
│      │ Int64?    │ Float64                     │
├──────┼───────────┼─────────────────────────────┤
│ 1    │ 2015      │ 55.1                        │
│ 2    │ 2015      │ 82.3                        │
│ 3    │ 2015      │ 82.3                        │
│ 4    │ 2015      │ 82.3                        │
│ 5    │ 2015      │ 82.3                        │
│ 6    │ 2015      │ 82.3                        │
│ 7    │ 2015      │ 82.3                        │
│ 8    │ 2015      │ 55.1                        │
│ 9    │ 2015      │ 55.1                        │
│ 10   │ 2015      │ 55.1                        │
│ 11   │ 2015      │ 82.3                        │
│ 12   │ 2015      │ 82.3                        │
│ 13   │ 2015      │ 82.3                        │
│ 14   │ 2015      │ 55.1                        │
│ 15   │ 2015      │ 55.1                        │
│ 16   │ 2015      │ 82.3                        │
│ 17   │ 2015      │ 82.3                        │
│ 18   │ 2015      │ 82.3                        │
│ 19   │ 2015      │ 55.1                        │
│ 20   │ 2015      │ 55.1                        │
│ 21   │ 2015      │ 55.1                        │
⋮
│ 2421 │ 2018      │ 85.6                        │
│ 2422 │ 2018      │ 85.6                        │
│ 2423 │ 2018      │ 85.6                        │
│ 2424 │ 2018      │ 85.6                        │
│ 2425 │ 2018      │ 85.6                        │
│ 2426 │ 2018      │ 85.6                        │
│ 2427 │ 2018      │ 85.6                        │
│ 2428 │ 2018      │ 57.3                        │
│ 2429 │ 2018      │ 85.6                        │
│ 2430 │ 2018      │ 85.6                        │
│ 2431 │ 2018      │ 85.6                        │
│ 2432 │ 2018      │ 85.6                        │
│ 2433 │ 2018      │ 57.3                        │
│ 2434 │ 2018      │ 85.6                        │
│ 2435 │ 2018      │ 85.6                        │
│ 2436 │ 2018      │ 85.6                        │
│ 2437 │ 2018      │ 57.3                        │
│ 2438 │ 2018      │ 85.6                        │
│ 2439 │ 2018      │ 85.6                        │
│ 2440 │ 2018      │ 85.6                        │
│ 2441 │ 2018      │ 85.6                        │
│ 2442 │ 2018      │ 85.6                        │
 
 
ukp[(ukp.income_attendence_allowance .> 100), [:data_year,:income_attendence_allowance ]]
(no cases)

```

## PIP

2019/20

daily:

* Standard: 58.70
* Enhanced: 87.65

mob:

* S: 23.20
* E: 61.20

```

ukp[(ukp.income_personal_independence_payment_daily_living .> 0), 
    [:data_year,:income_personal_independence_payment_daily_living,:income_personal_independence_payment_mobility ]]

│ Row  │ data_year │ income_personal_independence_payment_daily_living │ income_personal_independence_payment_mobility │
│      │ Int64?    │ Union{Missing, Float64}                           │ Union{Missing, Float64}                       │
├──────┼───────────┼───────────────────────────────────────────────────┼───────────────────────────────────────────────┤
│ 1    │ 2015      │ 82.3                                              │ 0.0                                           │
│ 2    │ 2015      │ 55.1                                              │ 21.8                                          │
│ 3    │ 2015      │ 82.3                                              │ 57.45                                         │
│ 4    │ 2015      │ 82.3                                              │ 57.45                                         │
│ 5    │ 2015      │ 55.1                                              │ 0.0                                           │
│ 6    │ 2015      │ 82.3                                              │ 0.0                                           │
│ 7    │ 2015      │ 82.3                                              │ 0.0                                           │
│ 8    │ 2015      │ 55.1                                              │ 0.0                                           │
│ 9    │ 2015      │ 55.1                                              │ 0.0                                           │
│ 10   │ 2015      │ 82.3                                              │ 21.8                                          │
│ 11   │ 2015      │ 82.3                                              │ 21.8                                          │
│ 12   │ 2015      │ 55.1                                              │ 21.8                                          │
│ 13   │ 2015      │ 82.3                                              │ 21.8                                          │
│ 14   │ 2015      │ 55.1                                              │ 21.8                                          │
│ 15   │ 2015      │ 55.1                                              │ 0.0                                           │
│ 16   │ 2015      │ 55.1                                              │ 21.8                                          │
│ 17   │ 2015      │ 55.1                                              │ 0.0                                           │
│ 18   │ 2015      │ 55.1                                              │ 21.8                                          │
│ 19   │ 2015      │ 82.3                                              │ 57.45                                         │
│ 20   │ 2015      │ 55.1                                              │ 0.0                                           │
│ 21   │ 2015      │ 82.3                                              │ 0.0                                           │
⋮
│ 2662 │ 2018      │ 85.6                                              │ 0.0                                           │
│ 2663 │ 2018      │ 85.6                                              │ 0.0                                           │
│ 2664 │ 2018      │ 85.6                                              │ 0.0                                           │
│ 2665 │ 2018      │ 57.3                                              │ 59.75                                         │
│ 2666 │ 2018      │ 85.6                                              │ 0.0                                           │
│ 2667 │ 2018      │ 57.3                                              │ 59.75                                         │
│ 2668 │ 2018      │ 85.6                                              │ 59.75                                         │
│ 2669 │ 2018      │ 57.3                                              │ 59.75                                         │
│ 2670 │ 2018      │ 57.3                                              │ 59.75                                         │
│ 2671 │ 2018      │ 85.6                                              │ 59.75                                         │
│ 2672 │ 2018      │ 57.3                                              │ 22.65                                         │
│ 2673 │ 2018      │ 57.3                                              │ 0.0                                           │
│ 2674 │ 2018      │ 85.6                                              │ 59.75                                         │
│ 2675 │ 2018      │ 57.3                                              │ 22.65                                         │
│ 2676 │ 2018      │ 57.3                                              │ 59.75                                         │
│ 2677 │ 2018      │ 85.6                                              │ 0.0                                           │
│ 2678 │ 2018      │ 57.3                                              │ 22.65                                         │
│ 2679 │ 2018      │ 57.3                                              │ 22.65                                         │
│ 2680 │ 2018      │ 85.6                                              │ 59.75                                         │
│ 2681 │ 2018      │ 85.6                                              │ 22.65                                         │
│ 2682 │ 2018      │ 85.6                                              │ 59.75                                         │
│ 2683 │ 2018      │ 57.3                                              │ 22.65                                         │


ukp[(ukp.income_personal_independence_payment_daily_living .> 100), 
           [:data_year,:income_personal_independence_payment_daily_living,:income_personal_independence_payment_mobility 
           
(2 cases).


    
```

## So

39 DLA cases which appear to be joint payments. No problem for the other twp 