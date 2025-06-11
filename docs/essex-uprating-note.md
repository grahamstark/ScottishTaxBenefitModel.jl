# Scotben Uprating
11/June/2025

Data is uprated to 2025 Q2. The attached bundle has [the code](Uprating.jl), the [price index file](indexes.tab), and the two main sources used:

* OBR: [Economy_Detailed_forecast_tables_October_2024.xlsx](https://obr.uk/efo/economic-and-fiscal-outlook-october-2024/)
* SFC: [May-2025-SEFF-Publication-Chapter-3-Economy-Supplementary-figures.xlsx](https://fiscalcommission.scot/publications/scotlands-economic-and-fiscal-forecasts-may-2025/)

* Wages/Self Employment Income: (Scottish) Nominal average hourly wage (£/hour) SFC sheet s3.5 
* All unearned income except shares: (Scottish) Nominal GDP (index with base 1998 Q1) - SFC sheet s3.3 (I can't remember why I rebased to Q11998 - possibly it was something to do with our ScotGov child poverty forecasts)
* Rents: (UK Wide) actual rents for housing - OBR: Table 1.7
* Shares: (UK Wide) equity prices (OBR table 1.9)
* Misc income (alimony, foster care payments, etc.) (UK Wide) CPI - OBR: Table 1.7

Benefits in the dataset are not uprated.

I've noticed that, while the numbers in `targets.tab` are updated to the latest available, some of the headers refer to previous versions of the SFC and OBR data. I'll fix that.

