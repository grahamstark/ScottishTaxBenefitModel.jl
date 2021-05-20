---
layout: post
date:   2021-05-20
category: Blog
tag: Tax Benefit Model
tag: Scotland
tag: Programming
tag: Local Taxes
title: Local Matters
author: graham_s
nav_exclude: true
---

Now that I have merged in SHS data, with postcodes, I've been doing something with it.

<!--more-->

## Local Housing Allowances and Bedroom Tax

I have a problem implementing the rules for the bedroom tax exactly - it needs someone better at maths than I am. 

Problem here is that [Broad Rental Market Areas](https://www.gov.scot/publications/local-housing-allowance-rates-2019-2020/) (BHMA) are [not the same as local authority areas](https://datashare.ed.ac.uk/handle/10283/2618) (or anything else). I think the only really important difference is Glasgow City/Greater Glasgow, since the allowed rents are much much higher.

### BRMA Rates 2020/21 Scotland

| BRMA                     | Room  | 1 Bed  | 2 Bed  | 3 Bed  | 4 Bed  |
| ------------------------ | ----- | ------ | ------ | ------ | ------ |
| Aberdeen and Shire       | 74.79 | 97.81  | 136.93 | 172.6  | 230.14 |
| Argyll and Bute          | 72.74 | 86.3   | 115.07 | 126.58 | 207.12 |
| Ayrshires                | 76.99 | 80.55  | 97.81  | 115.07 | 159.95 |
| Dumfries and Galloway    | 59.84 | 85.15  | 103.56 | 115.03 | 155.34 |
| Dundee and Angus         | 69.04 | 84     | 115.07 | 149.59 | 241.64 |
| East Dunbartonshire      | 71.34 | 103.56 | 136.93 | 182.96 | 298.03 |
| Fife                     | 70.19 | 86.3   | 109.32 | 132.33 | 195.62 |
| Forth Valley             | 74.12 | 90.9   | 115.07 | 149.59 | 218.63 |
| Greater Glasgow          | 80.55 | 113.92 | 149.59 | 172.6  | 322.19 |
| Highland and Islands     | 74.79 | 97.81  | 126.58 | 146.14 | 184.11 |
| Lothian                  | 94.82 | 158.79 | 189.86 | 253.15 | 390.08 |
| North Lanarkshire        | 65.59 | 82.85  | 103.56 | 113.92 | 182.96 |
| Perth and Kinross        | 65.01 | 92.05  | 115.07 | 149.59 | 205.97 |
| Renfrewshire/ Inverclyde | 67.66 | 80.55  | 103.56 | 126.58 | 230.14 |
| Scottish Borders         | 62.14 | 74.79  | 97.81  | 120.82 | 184.11 |
| South Lanarkshire        | 69.04 | 86.3   | 109.32 | 143.84 | 218.63 |
| West Dunbartonshire      | 69.04 | 86.3   | 103.56 | 126.58 | 218.63 |
| West Lothian             | 69.04 | 112.77 | 138.08 | 159.95 | 218.63 |

Source [Local Housing Allowance Rates: 2020-2021](https://www.gov.scot/publications/local-housing-allowance-rates-2020-2021/)

## Council Tax

This is more straightforward and just a few lines of code gets pleasing close to the Scottish Average. At the LA level, it's a bit more mixed:

|                       |           |           | Modelled      |              |                     |                     |
| --------------------- | ---------:| ---------:| -------------:| ------------:| -------------------:| -------------------:|
| name                  | ccode     | hhlds/dwellings | raised £pa       | average £ | actual average      | %Diff               |
| Aberdeen City         | S12000033 | 89,759    | 108,144,651   | 1,204        | 1,258                | \-4.29 |
| Aberdeenshire         | S12000034 | 112,114   | 144,572,931   | 1,289        | 1,372                | \-6.05  |
| Angus                 | S12000041 | 54,221    | 64,370,462    | 1,187        | 1,044                | 13.70  |
| Argyll and Bute       | S12000035 | 41,788    | 53,200,034    | 1,273        | 1,282                | \-0.70 |
| City of Edinburgh     | S12000036 | 238,269   | 291,624,113   | 1,223        | 1,361                | \-10.14   |
| Clackmannanshire      | S12000005 | 23,890    | 26,780,061    | 1,120        | 1,152                | \-2.78  |
| Dumfries and Galloway | S12000006 | 69,699    | 80,473,252    | 1,154        | 1,075                | 7.35    |
| Dundee City           | S12000042 | 70,685    | 79,500,506    | 1,124        | 1,076                | 4.46    |
| East Ayrshire         | S12000008 | 55,387    | 71,544,247    | 1,291        | 1,133                | 13.94    |
| East Dunbartonshire   | S12000045 | 46,228    | 64,371,959    | 1,392        | 1,566                | \-11.11  |
| East Lothian          | S12000010 | 46,771    | 54,449,337    | 1,164        | 1,384                | \-15.89  |
| East Renfrewshire     | S12000011 | 39,344    | 52,439,870    | 1,332        | 1,578                | \-15.59  |
| Falkirk               | S12000014 | 72,672    | 82,189,182    | 1,130        | 1,081                | 4.53    |
| Fife                  | S12000047 | 169,238   | 201,815,980   | 1,192        | 1,147                | 3.92    |
| Glasgow City          | S12000049 | 294,622   | 345,953,492   | 1,174        | 1,137                | 3.25    |
| Highland              | S12000017 | 109,514   | 148,810,954   | 1,358        | 1,226                | 10.77    |
| Inverclyde            | S12000018 | 37,614    | 45,377,341    | 1,206        | 1,078                | 11.87     |
| Midlothian            | S12000019 | 39,733    | 56,353,186    | 1,418        | 1,397                | 1.50    |
| Moray                 | S12000020 | 42,931    | 54,057,702    | 1,259        | 1,171                | 7.51    |
| Na h-Eileanan Siar    | S12000013 | 12,832    | 16,202,306    | 1,262        | 886                 | 42.43   |
| North Ayrshire        | S12000021 | 64,140    | 76,090,669    | 1,186        | 1,096                | 8.21    |
| North Lanarkshire     | S12000050 | 152,443   | 169,548,479   | 1,112        | 1,016                | 9.44    |
| Orkney Islands        | S12000023 | 10,589    | 12,454,054    | 1,176        | 986                 | 19.27    |
| Perth and Kinross     | S12000048 | 69,003    | 83,214,674    | 1,205        | 1,344                | \-10.34  |
| Renfrewshire          | S12000038 | 86,683    | 102,714,536   | 1,184        | 1,190                | \-0.50 |
| Scottish Borders      | S12000026 | 54,715    | 67,140,166    | 1,227        | 1,184                | 3.63    |
| Shetland Islands      | S12000027 | 10,439    | 11,554,919    | 1,106        | 1,019                | 8.54    |
| South Ayrshire        | S12000028 | 52,588    | 64,547,705    | 1,227        | 1,305                | \-5.98 |
| South Lanarkshire     | S12000029 | 147,434   | 167,089,775   | 1,133        | 1,107                | 2.35     |
| Stirling              | S12000030 | 39,653    | 50,270,654    | 1,267        | 1,483                | \-14.56  |
| West Dunbartonshire   | S12000039 | 43,029    | 45,940,996    | 1,067        | 1,093                | \-2.38  |
| West Lothian          | S12000040 | 78,966    | 91,686,747    | 1,161        | 1,133                | 2.47    |
| **Scotland**          |           | **2,476,993** | **2,984,484,940** | **1,204**        | **1,201**           | **0.25**   |

First 3 output cols here are results from test case runs of the model over 3 years Scottish FRS, next col is [actual Council Tax per dwelling](https://www.gov.scot/publications/council-tax-datasets/). Not bad, except the small LAs are quite a bit out at times. Whether this is just sample variation or a problem with the matching algorithm I'm not sure.

Lots of things to be improved, like the distinction between a household and a dwelling, cases where CT is payable by owners and not tenants, and discounts for disabled people.

* [Local Calculation Code](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/src/LocalLevelCalculations.jl) (latest);
* [Test Code](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/test/local_level_calculations_tests.jl) (latest);
* [Repository](https://github.com/grahamstark/ScottishTaxBenefitModel.jl).

Thanks to [John Franey](https://johnfraney.ca/) for the nice [Markdown Table Converter](https://tabletomarkdown.com/convert-spreadsheet-to-markdown/).