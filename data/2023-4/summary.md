# SUMMARY LHA/CTD Rates 2023/4

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

hhlds = CSV.File( "model_households-2021-2021.tab") |> DataFrame
nr,nc = size(hhlds)
hhlds.council = Vector{Symbol}(undef,nr)
hhlds.council[hhlds.region .<=  112000009] .= :ENGLAND
hhlds.council[hhlds.region .== 112000007] .= :LONDON
hhlds.council[hhlds.region .== 299999999] .= :SCOTLAND
hhlds.council[hhlds.region .== 399999999] .= :WALES
hhlds.council[hhlds.region .== 499999999] .= :NIRELAND


people = CSV.File( "model_people-2021-2021.tab")|>DataFrame

# random room allocation
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
