[^FN_MS_EXAMPLES]: Recent examples of  such reports are @de_agostini_child_2019, @callan_profile_2015, and @reed_tackling_2018
[^FN_SCOTTISH_CHILD]: [@scottish_government_statement_2019]
[^FN_SCOT_INCOME_TAX_1]: [@macdonell_scotland_2017], [@scottish_fiscal_commission_how_2018]
[^FN_JAVED]: [@woodcock_conservative_2019]
[^FN_FUEL]: [@politics_home_boris_2019], [@eglot_theresa_2018]
[^FN_FINANCIAL_YEAR]: Much economic data is reported for "Financial Years" (sometimes called "Tax Years" or "Fiscal Years"); in the UK the Tax Year runs from April 6th to April 5th the next year (but 1st April-31st March for Government Accounting).
[^FN_POVOLD]: Poverty and Inequality are also discussed in the DD209 course, chapter 4, though at a more theoretical level than the practical approach I take here.
[^FN_FRS]: See: [@dwp_family_2019]
[^FN_SPI]: See: [@burkhauser_survey_2017]
[^FN_HBAI]: [@department_for_work_and_pensions_households_2019]
[^FNPCT]: Sometimes as a proportion, so 0.2 instead of 20%.
[^FN_INCOME_HHLD]: we're talking about people's income rather loosely here - obviously there are many millions of people (children, stay-at-home carers and so on) who have no income of their own at all. What we mean instead is something like the averaged income of the household to which they belong.
[^FN_HOUSEHOLDS]: A household is defined in our surveys as a group of people at the same address with shared living arrangements; see [@dwp_family_2019]
[^FN_EQUIVALENCE]: See [@chanfreau_scottish_2008]
[^FN_ENGEL]: See [@chai_retrospectives:_2010] and [@banks_children_1993]
[^FN_BANKS_2]: See [@banks_children_1993]
[^FN_LCF]: See [@office_for_national_statistics_living_2019]
[^FN_EQUIV_IFS]: [@banks_children_1993]
[^FN_WOMEN_TRANSFERS]: [@schady_are_2007]
[^FN_SAMPLE_SURVEYS]: [@haughton_handbook_2009], ¶2 is a very good introduction to the ideas behind large sample survey datasets.
[^FN_JULIA]: [@bezanson_julia_2017]
[^FN_GIT]: [@stark_grahamstark/stb.jl_2019]
[^FN_WEIGHTS]: see [@creedy_survey_2003] for a discussion of the techniques needed to find these weights.
[^FN_POOL]: we acually pool together three years of data so we have a reasonably large sample from our Northern country, so much of our data is actually older than a year.
[^FN_STRESS]: [@haughton_handbook_2009], ¶ 6 and [@wilkinson_spirit_2009].
[^FN_HBAI_2]:  We've covered median [^xx], equivalised [^yy] and household [^zz] earlier.
[^FN_FOWLER]: Stark and Dilnot
[^FN_DALTON]: - [Hugh Dalton](https://en.wikipedia.org/wiki/Hugh_Dalton).
[^FN_REL_POV]: Since our standard HBAI relative poverty line is defined against median income, this is of course not strictly true, but it is true of absolute poverty, and true of any poverty measure once the poverty line is defined.
[^FN_HIGH_INCOME]: the merits of using income, wealth or consumption are somewhat different for the very rich than the very poor,  measuring very high incomes or wealth using survey data  poses special problems; see: [@burkhauser_survey_2017]
[^FN_WORLD_BANK_GINI]: Source: [@world_bank_world_2019] Data from 2015 except Australia (2014), USA (2016)
[^FN_INDEXES]: see [@haughton_handbook_2009], ¶6 for a discussion of these indexes and several more.
[^FN_PALMA]: See: [@cobham_alex_is_2014]
[^FN_GE_MODEL]: See: [@debreu_theory_1959] and [@arrow_general_1971].
[^FN_SCHUMPETER]: Joseph Schumpeter wrote: "[The] system of economic equilibrium, uniting, as it does, the quality of 'revolutionary' creativeness with the quality of classic synthesis, is the only work by an economist that will stand comparison with the achievements of theoretical physics." [@schumpeter_history_1954], Part IV, p827
[^FN_STIGLITZ]: See: [@stiglitz_revolution_2016]
[^FN_WAS]: [@office_for_national_statistics_wealth_2018]
[^FN_US]: [@institute_for_social_and_economic_research_understanding_2019]
[^FN_ELSA]: [@elsa_english_2019]
[^FN_PANEL]: especially in economics, Longitudinal surveys are often referred to as *panel data*.
[^FNWALES]: see [This Social Care Simulation](https://virtual-worlds-research.com/demos/wsc/) for example.
[^FN_RANDOM]: we discuss to exceptions to this below.
[^FN_SAMPLE_SIZE]: the FRS is the largest of these datasets; in 2017/9 it contained data on 33,289 adults and 9,558 ¶ldren living in 19,105 households.
[^FN_ELSA_REP]: ELSA is, as its name suggests, covers England only.
[^FN_PARTIC]: See [@meyer_household_2015] for a discussion of this and other problems with household datasets.
[^FN_INTERVIEW]: the LCF also leaves diaries with people in which they can record their spending; other surveys use diaries to record, for example trips to work or school.
[^FN_BOOTSTRAP]: see, [@department_for_work_and_pensions_uncertainty_2014], p10- for an illustration of bootstrapping the FRS.
[^FN_CREEDY]: see [@creedy_survey_2003] for a discussion; for those with some programming experience,  [the source code for the model weighting routine is available](https://github.com/grahamstark/TBComponents.jl).
[^FN_SMOKING]: find IFS (Panos?) paper
[^FN_JENKINS]: see [@burkhauser_survey_2017-1].
[^FN_SMITH]: [@smith_inquiry_1776] ¶ 2
[^FN_KAY]: [@kay_john_fewer_2012]
[^FN_UNCERTAINTY]: see [@department_for_work_and_pensions_uncertainty_2014] for a discussion of these issues.
[^FN_HH_DEF]: see: [@horsfield_living_2016], section 8.
[^FN_BANKS]: Formally, the curve is a linear regression of the share of food against the *logarithm* of total spending (you also met logarithms in the macroeconomics week). See [@banks_children_1993] and [@deaton_analysis_2019] for a discussion of why this is the standard form used for Engel curves.
[^FN_TOTAL_EXP]: there are technical reasons for preferring total expenditure over total income here, discussed in [@blundell_consumption_1998]
[^FN_EQ_CALC]: the calculation goes as follows: let `Y` be total expenditure, and the share of food be `sf`. Then, for households with ¶ldren: `sf = (44.5+0.0434×Y)/Y`. We need to find `Y` that gives `sf=0.11`. Manipulating the equation a little, this is 44.5/(0.11-0.043) ≈ 664.18.
[^FN_DEATON_CASE]: see [@case_consumption_2003] for a discussion.
[^FN_MIXED]: for summaries of the relevant evidence, see [@case_consumption_2003] [FIXME need something more recent] on health outcomes, [@deaton_analysis_2019] on consumption.
[^FN_MEADE]: for a very clear discussion of this and related matters, see the Meade Report from the Institute for Fiscal Studies (IFS) [@meade_structure_1978], ¶pters 2 and 3.
[^FN_KAY_KEEN]: see [@kay_estimating_1984].
[^FN_BLUNDELL]: see, for example [@blundell_consumption_1998]
[^FN_SEN]: [@sen_commodities_1999]
[^FN_UN_MULTI]: [@united_nations_development_programme_2019_2019]
[^FN_SOCIAL_METRICS]: [@social_metrics_commission_social_2019]
[^FN_MEADE_2]: [@meade_structure_1978], ¶2 has an excellent discussion of these issues.
[^FN_PERIODS]: [@bbc_scotlands_2019]
[^FN_FOOD]: [@nhs_scotland_food_2019]
[^FN_FUEL-POV]: [@department_for_business_energy_&_industrial_strategy_fuel_2019]
[^FN_DEMAND]:  We had a glimpse of how you might estimate such a model earlier, in the section on equivalence scales. See [@deaton_analysis_2019] for full details on how this is done in practice.
[^FN_KAY_INCIDENCE]: see [@kay_talk_2005] good general discussion of the notion of tax incidence.
[^FN_US_CORP]: [@saez_triumph_2019]; see also [@clausing_who_2012] for a discussion of the evidence on corporation tax
[^FN_OECD_1]: see [@oecd_what_1995]. OECD is the "Organisation of Economic Cooperation and Development". HBAI actually uses a slightly different scale for its "after housing costs" series.
[^FN_OECD_2]: [@hagenaars_poverty_1994] FIXME get this from OU Library!!!
[^FN_HBAI_METHODS]: see [@dwp_hbai_2015] for a discussion of equivalisation in the HBAI.
[^FN_RENT]: see see [@dwp_hbai_2015], p 266- for a discussion.
[^FN_HILLS]: see [@hills_inequality_2004], ¶ 8, for a good discussion of this and related points.
[^FN_OPEN_SOURCE]: [@open_source_initiative_open_2019]
[^FN_FRY_STARK]: see (e.g.) [@fry_take-up_1993]
[^FN_DUCLOS]: see [@duclos_take-up_1991]
[^FN_MOND]: see (e.g.) [@monbiot_cleansing_2014]
[^FN_TOLLEY]: [@redson_tolleys_2019];
[^FN_MELVILLE]: admittedly, you don't actually need to read the entire stack of Tolley's guides; the 600-odd pages of [@melville_melvilles_2019] is enough for most of our purposes.
[^FN_TEST_FIRST]: see [Wikipedia](https://en.wikipedia.org/wiki/Test-driven_development)
[^FN_TEST_2]: you can see the model tests suites [on the GitHib file sharing site]().
[^FN_SOCIAL_METRICS_2]: interestingly, a recent re-examination of poverty statistics by the Social Metrics Commission uses benefit units - which it calls "Sharing Units" - as its main unit of analysis. We'll discuss this study presently.
[^FN_UNIT_TESTS]: [https://docs.julialang.org/en/v1/stdlib/Test/index.html](https://docs.julialang.org/en/v1/stdlib/Test/index.html)
[^FN_CPAG]: [@child_poverty_action_group_welfare_2019]
[^FN_LABOUR]: see [@blundell_labour_1992] for a survey.
[^FN_MALCHUP]: it's natural to think 'dynamic' trumps 'static', but see [@machlup_statics_1959] for a rightly sceptical view of this.
[^FN_BUDGET_CONSTRAINT]: the alogrithm needed to create a complete set see [@duncan_recursive_2000].
[^FN_SFC_2]: see [@scottish_fiscal_commission_how_2018] for a discussion.
[^FN_ESRI]: see [@callan_profile_2015] for an application of these ideas to Ireland, and [@adam_financial_2006] for the UK.
[^FN_IFS_BENEFITS]: see [@norris_keiller_survey_2016] for a recent survey of the UK benefits system.
[^FN_JSA]: [@dwp_jobseekers_2019]
[^FN_STARK_DILNOT]: see [@dilnot_poverty_1986] for a discussion.
[^FN_MIG]: Minimum Income Guarantee
[^FN_WTC]: [@dwp_working_2019]
[^FN_UC]: [@dwp_universal_2019]
[^FN_BASIC]: see, for example: [@basic_income_earth_network_basic_2019] and [@basic_income_scotland_basic_2019] for Basic Income advocacy, and [@house_of_commons_work_and_pensions_committee_citizens_2017] for a sceptical view.:
[^FN_STARK_DILNOT-2]: see [@dilnot_poverty_1986] for a discussion.
[^FN_SLOMAN]: [@sloman_pragmatists_2015]
[^FN_RP]: example!!
[^FN_ENGEL-2]: sometimes the Engel curve is considered to be the relation between the *share* of spending on a good and total spending, not the *level* of spending, as here.
[^FN_FULL-FACT]: [@full_fact_full_2019]
[^FN_FERRET]: [@the_ferret_ferret_2019]
[^FN_LIE]: [@johnson_assessing_1993]
[^FN_GOVT]: [@stanley_understanding_2019] is a terrific resource on the role of senior civil servants.
[^FN_LANDMAN]: [http://www.landman-economics.co.uk/about.php](http://www.landman-economics.co.uk/about.php)
[^FN_PRS]: [@national_records_of_scotland_web_national_2019]
[^FN_SFC]: [@scottish_fisc_scotlands_2019]
[^FN_REED_STARK]: [@reed_tackling_2018]
[^FN_DIMMSIM]:[https://adrs-global.com](https://adrs-global.com) FIXME
[^FN_MEMSA]: [https://adrs-global.com](https://adrs-global.com)
[^FN_SATTSIM]: [https://adrs-global.com](https://adrs-global.com)
[^FN_ADRS]: see [https://adrs-global.com](https://adrs-global.com)
[^FN_FGT]: see [@haughton_handbook_2009], ¶ 2 for a discussion
[^FN_SEN_POV]: [@haughton_handbook_2009], ¶ 2
[^FN_WREN_LEWIS]: see [@wren-lewis_but_2017] for a discussion in the context of the UK's austerity programme.
[^FN_POLL_TAX]: see [@bbc_radio_4_our_2006] for a discussion of the original English Poll Tax and the "Peasant's Revolt", and [@besley_fiscal_1997] for a discussion of the Community Charge, the ill-fated local tax introduced in 1987.
[^FN_VAT]: see [@commission_questions_2011] for European Commission advocacy for the extension of VAT, and also [@kay_john_fewer_2012].
[^FN_SPREADSHEETS]: see [@panko_what_2008] for a review of evidence on spreadsheet errors, and [@eurosprig_spreadsheet_2019] for a compendium of major known mistakes.
[^FN_IGOTM]: [@brice_using_2015].
[^FN_SFC_FORE][@scottish_fiscal_commission_how_2018]
[^FN-BLOG] https://stb-blog.virtual-worlds.scot
[^FN-TEST-FIRST][@google_inc_introducing_nodate]
[^FN_BCS] https://stb.virtual-worlds.scot/bcd/
[^FN_UBI] https://stb.virtual-worlds.scot/ubi/
[^FN_SCOTBUDG] https://stb.virtual-worlds.scot/scotbudg/
[^FN_TRIPLEPC] https://triplepc.northumbria.ac.uk; a paper on TriplePC is forthcoming in the International Journal of Microsimulation [@stark_public_2024]
