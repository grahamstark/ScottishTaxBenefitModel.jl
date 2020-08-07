# notes on weighting

Code: [Weighting.jl](/src/Weighting.jl). Uses []()

4 years 2015/18 11,048 hhlds
initial: 2,477,000 hhlds => 224.203 avg weight
4,541,903 16+ popn (NRS) 5,463,300 total - mid 2019 popn estimates

nomis scaled to match nrs

2015/18 pooled scottish frs; targets vs uniform-weighted totals				

    ||target|unweighted total	diff
M- Total in employment- aged 16+||1|1,358,545|1,147,698|-16%
M- Total unemployed- aged 16+||2|61,446|55,827|-9%
F- Total in employment- aged 16+||3|1,318,657|1,138,057|-14%
F- Total unemployed- aged 16+||4|60,095|38,339|-36%
private rented||5|365,878|314,782|-14%
housing association||6|278,956|229,360|-18%
las, etc rented||7|310,508|355,811|15%
M- 0 - 4||8|139,982|150,441|7%
M- 5 - 9||9|153,297|149,992|-2%
M- 0 – 4||10|150,487|141,024|-6%
M- 15 - 19||11|144,172|113,671|-21%
M- 20 - 24||12|176,066|107,842|-39%
M- 25 - 29||13|191,145|119,725|-37%
M- 30 - 34||14|182,635|131,383|-28%
M- 35 - 39||15|172,624|147,750|-14%
M- 40 - 44||16|156,790|145,508|-7%
M- 45 - 49||17|174,812|166,359|-5%
M- 50 - 54||18|193,940|176,897|-9%
M- 55 - 59||19|190,775|178,690|-6%
M- 60 - 64||20|166,852|182,726|10%
M- 65 - 69||21|144,460|195,057|35%
M- 70 - 74||22|132,339|152,683|15%
M- 75 - 79||23|87,886|113,671|29%
M- 80’+|| 24|104,741|112,550|7%
F- 0 - 4||25|131,733|149,095|13%
F- 5 - 9||26|146,019|149,320|2%
F- 10 - 14||27|144,187|130,486|-10%
F- 15 - 19||28|137,786|116,137|-16%
F- 20 - 24||29|171,390|119,052|-31%
F- 25 - 29||30|191,110|155,597|-19%
F- 30 - 34||31|186,828|158,960|-15%
F- 35 - 39||32|179,898|165,686|-8%
F- 40 - 44||33|162,642|157,167|-3%
F- 45 - 49||34|186,646|170,843|-8%
F- 50 - 54||35|207,150|189,004|-9%
F- 55 - 59||36|202,348|206,716|2%
F- 60 - 64||37|177,841|196,626|11%
F- 65 - 69||38|154,984|206,491|33%
F- 70 - 74||39|146,517|173,085|18%
F- 75 - 79||40|108,065|120,173|11%
F- 80+||41|165,153|137,661|-17%
1 adult: male||42|439,000|391,011|-11%
1 adult: female||43|467,000|482,262|3%
2 adults||44|797,000|895,693|12%
1 adult, 1 child||45|70,000|65,467|-6%
1 adult, 2+ children||46|66,000|47,755|-28%
2+ adults, 1+ children||47|448,000|431,367|-4%
3+ adults||48|190,000|163,444|-14%
Carer’s Allowance||49|77,842|64,571|-17%
Attendance Allowance||50|127,307|82,731|-35%
PIP/DLA||51|431,461|330,476|-23%

## sources

* Households: [NRS: Estimates of Households and Dwellings in Scotland, 2019](https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/households/household-estimates/2019) file house-est-19-all-tabs.xlsx table 7
* Tenure: [Scottish Government: Housing statistics: Stock by tenure](https://www.gov.scot/publications/housing-statistics-stock-by-tenure/) file strock.xls data for March 2018
* Employment: [Nomis](https://www.nomisweb.co.uk/); file 291203550.csv
* benefits [DWP: StatExplore](https://stat-xplore.dwp.gov.uk/) files table_2020-07-17(XX).xslx
* population [NRS: Mid-Year Population Estimates](https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/population/population-estimates/mid-year-population-estimates) file mid-year-pop-est-19-data.xlsxmid-year-pop-est-19-data.xlsx table 1

All raw data retrieved 16-17 July 2020, and stored in [/data/targets/].