---
layout: post
date:   2022-07-10
tag: Tax Benefit Model
tag: Scotland
tag: Programming
title: Updating Population targets 
author: graham_s
nav_exclude: true
---

Notes (rough) on updating weighting targets. It's finnicky and boring, with nothing quite adding up without some hacks. One difference this time is that I'm trying to gross to the household populations (excluding students in student residences and those in care homes). Though this produces problems of its own.

<!--more-->

It's tedious. Trawling through a [collection of spreasheets](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/tree/master/data/targets/aug-2022-updates) (sources for which below). 

The main working spreadsheet is [target_generation.ods](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/data/targets/aug-2022-updates/target-generation.ods). (Open office file).

This time I'm trying to include only hhld population. I found an [NRS table of estimates of the non household population by LA](https://github.com/grahamstark/ScottishTaxBenefitModel.jl/blob/master/data/targets/aug-2022-updates/2018-house-proj-source-data-alltabs.xlsx).

Problems: 

1. using just households will underpredict pension costs and receipts, and also e.g. UBI;
2. we target to disablement benefits but some of this will be received by those in care homes and I need to disaggregate that bit out and don't currently.

Scaling popns: why is NOMIS 16+ popn lower? 

Care Homes CPAGP 914
"You cannot get AA,DLA care, PIP daily living" .. in a care home...

There is a HUGE institutional popn in 16-19 age group esp Glasgow, Aberdeen, Dundee - students. Removing this is a big change.



Fiddly bits: 

* re-adjust popn groups so there's a break at 15 (so all 16+ are in a group). This is needed to make employment stuff add up correctly (I think) since employment is for all 16+s. 

I'm also adding Social-Economic group - maybe this will help proportion of higher earners and so slightly fix income tax


Sources:

‘Housing Statistics: Stock by Tenure’. n.d. Accessed 7 August 2022. http://www.gov.scot/publications/housing-statistics-stock-by-tenure/.

‘Labour Market Profile - Nomis - Official Census and Labour 
Market Statistics’. n.d. Accessed 8 August 2022. https://www.nomisweb.co.uk/reports/lmp/gor/2013265931/report.aspx.
‘Stat-Xplore - Table View’. n.d. Accessed 8 August 2022. https://stat-xplore.dwp.gov.uk/webapi/jsf/tableView/tableView.xhtml.

Team, National Records of Scotland Web. 2013a. ‘National Records of Scotland’. Document. National Records of Scotland. National Records of Scotland. 31 May 2013. https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/population/population-projections/population-projections-scotland/2020-based.

———. 2013b. ‘National Records of Scotland’. Document. National Records of Scotland. National Records of Scotland. 31 May 2013. https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/households/household-projections/2018-based-household-projections/list-of-data-tables.

‘Stat-Xplore - Table View’. n.d. Accessed 8 August 2022. https://stat-xplore.dwp.gov.uk/webapi/jsf/tableView/tableView.xhtml.
