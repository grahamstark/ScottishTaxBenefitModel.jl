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

This time I'm trying to include only hhld population. 

Problems: 

1. underpredict pensions, UBI if only using hhld popn
2. disablement benefit stuff should exclude care homes

Scaling popns: why is NOMIS 16+ popn lower? 

Care Homes CPAGP 914
"You cannot get AA,DLA care, PIP daily living" .. in a care home...

AA in payment Nov 2021 123,909
*
*
*

1st time doing this.

HUGE institutional popn 16-19 esp Glasgow, Aberdeen, Dundee - students.

Possible problem with benefit receipt adjustment for elderly

Fiddly: re-adjust popn groups 15-16 

Add Social-Economic group - maybe this will help proportion of higher earners.


Sources:

‘Housing Statistics: Stock by Tenure’. n.d. Accessed 7 August 2022. http://www.gov.scot/publications/housing-statistics-stock-by-tenure/.

‘Labour Market Profile - Nomis - Official Census and Labour 
Market Statistics’. n.d. Accessed 8 August 2022. https://www.nomisweb.co.uk/reports/lmp/gor/2013265931/report.aspx.
‘Stat-Xplore - Table View’. n.d. Accessed 8 August 2022. https://stat-xplore.dwp.gov.uk/webapi/jsf/tableView/tableView.xhtml.

Team, National Records of Scotland Web. 2013a. ‘National Records of Scotland’. Document. National Records of Scotland. National Records of Scotland. 31 May 2013. https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/population/population-projections/population-projections-scotland/2020-based.

———. 2013b. ‘National Records of Scotland’. Document. National Records of Scotland. National Records of Scotland. 31 May 2013. https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/households/household-projections/2018-based-household-projections/list-of-data-tables.

‘Stat-Xplore - Table View’. n.d. Accessed 8 August 2022. https://stat-xplore.dwp.gov.uk/webapi/jsf/tableView/tableView.xhtml.
