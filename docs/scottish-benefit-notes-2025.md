# Scottish Benefit Notes 11/03/2025

[Primer](https://www.mygov.scot/child-disability-payment)

## ADP

maps to PIP

FRS:

* Personal_Independence_Payment_Daily_Living = 96
* Personal_Independence_Payment_Mobility = 97
  
* ADP_Daily_Living_Scotland_Only = 117
* ADP_Mobility_Scotland_Only = 118

also old DLA cases

DLAself_care = 1
DLAmobility = 2

> Many people have had their benefit moved across already. This process started in summer 2022. Not everyone's benefit is moving at the same time. It's happening in phases. It will take until 2025 to move everyone's benefit across.

> From Spring 2025, everyone still in receipt of DLA will have their benefit moved to # Scottish Adult DLA.


## Child Disability Payment 

maps to DLA (child)

DLAself_care = 1
DLAmobility = 2

Child_Disability_Payment_Care = 121
Child_Disability_Payment_Mobility = 122

December 2024:

* Total number of children in receipt: 87,475
* Number in receipt of care only:28,875
* Number in receipt of mobility only:280
* Number in receipt of both care and mobility:58,295


## Pension Age Disability Payment

Maps to Attendance Allowance

   Attendance_Allowance = 12

(not in FRS)

You’ll be able to apply from 24 March 2025 if you live in: [most areas]

> From the end of February 2025, Attendance Allowance awards will start automatically moving to Pension Age Disability Payment. Your award will move to Pension Age Disability Payment if you: 
> * already get Attendance Allowance from the Department for Work and Pensions (DWP)
> * live in Scotland 
> You do not need to do anything to start the move to Pension Age Disability Payment. 

## Carer Support Payment 
https://www.mygov.scot/carer-support-payment
maps to Carer's Allowance

> Some people’s benefits have already moved to Social Security Scotland. The process started in February 2024. It’ll take until spring 2025 to move everyone’s benefits across.

(not in FRS)

Carers_Allowance = 13 => CARERS_SUPPORT_PAYMENT => carers_support_payment = 2029

## CHILD DLA FUCKUP

FRS: ONLY 16-18 YOs have DLA receipts!

FUCK....

2017 example:

```julia

ben2017 = loadfrs( "benefits", 2017 )
ch2017 = loadfrs( "child", 2017 )
kb2017 = innerjoin( ch2017, ben2017; on=[:sernum,:benunit,:person],makeunique=true)
kb2017b = innerjoin( ch2017, ben2017; on=[:sernum,:person],makeunique=true) # same: join is right
kb2017[!,[:benefit,:age]]

   1 │       1     16
   2 │       2     16
   3 │       1     18
   4 │       1     16
   5 │       1     16
   6 │       1     16
   7 │       2     16
   8 │       1     17
   9 │       2     17
  10 │       1     16
  11 │       1     18
  12 │       1     19
  13 │       1     18
  14 │       2     18
   ...

```

Also `chdla1`, `chdla2` in child record are only for >= 16 yos.


?? Maybe infer from joint receipt of pip and dla (which would be for the kids).

```julia 
mpers[(mpers.income_dlamobility.>0).&(mpers.income_personal_independence_payment_mobility.>0),:]

27 cases in pooled UK dataset

```

## Carer's Allowance Supplement

https://www.mygov.scot/carers-allowance-supplement

SCOTTISH_CARERS_SUPPLEMENT => carers_allowance_supplement => SCOTTISH_CARERS_SUPPLEMENT

Carer's Allowance Supplement is an extra payment for people in Scotland who get Carer Support Payment or Carer's Allowance on a particular date.

Carer's Allowance Supplement is paid 2 times a year.

The Carer’s Allowance Supplement 2025 eligibility dates will be available soon.


## What's in the data
```julia 
ps1522 = CSV.File( "data/actual_data/model_people_scotland-2015-2022-w-enums-2.tab")|>DataFrame


psaa = ps1522[ps1522.income_attendance_allowance .> 0,:]

sort(countmap(psaa.age))
OrderedCollections.OrderedDict{Int64, Int64} with 16 entries:
  65 => 1
  66 => 5
  67 => 12
  68 => 8
  69 => 15
  70 => 17
  71 => 35
  72 => 28
  73 => 28
  74 => 38
  75 => 27
  76 => 35
  77 => 32
  78 => 40
  79 => 42
  80 => 321

pspip = ps1522[(ps1522.income_personal_independence_payment_daily_living .> 0) .| (ps1522.income_personal_independence_payment_mobility .>0),:]

sort( countmap( pspip.data_year))

  2015 => 47
  2016 => 100
  2017 => 158
  2018 => 225
  2019 => 236
  2020 => 98
  2021 => 163
  2022 => 180

psdla = ps1522[(ps1522.income_dlamobility .> 0) .| (ps1522.income_dlaself_care .>0),:]

sort( countmap( psdla.data_year ))
OrderedCollections.OrderedDict{Int64, Int64} with 8 entries:
  2015 => 290
  2016 => 272
  2017 => 213
  2018 => 196
  2019 => 155
  2020 => 43
  2021 => 50
  2022 => 59

spans the DLA->PIP transition

```

## ALL ZERO IN ACTUAL 2015-22 DATA

```julia
summarystats(pers.income_scottish_child_payment )
summarystats(pers.income_job_start_payment )
summarystats(pers.income_troubles_permanent_disablement )
summarystats(pers.income_child_disability_payment_care )
summarystats(pers.income_child_disability_payment_mobility )
summarystats(pers.income_pupil_development_grant )
summarystats(pers.income_adp_daily_living )
summarystats(pers.income_adp_mobility )
summarystats(pers.income_pension_age_disability )
summarystats(pers.income_carers_allowance_supplement )
summarystats(pers.income_carers_support_payment )
summarystats(pers.income_discretionary_housing_payment )
```