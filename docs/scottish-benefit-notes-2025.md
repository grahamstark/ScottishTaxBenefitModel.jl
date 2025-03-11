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

maps to Carer's Allowance

> Some people’s benefits have already moved to Social Security Scotland. The process started in February 2024. It’ll take until spring 2025 to move everyone’s benefits across.

(not in FRS)

Carers_Allowance = 13

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
