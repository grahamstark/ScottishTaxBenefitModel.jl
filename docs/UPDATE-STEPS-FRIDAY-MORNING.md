# UPDATE STEPS FRIDAY MORNING 

* **TURN OFF ALL 2ndary loading** (because lcf,shs,was indexes need rebuilt )
* **TURN OFF PRECOMPUTED WEIGHTS**

1. Project.toml tag increment
2. upload `augdata`; X
3. upload `scottish-frs-data`; X
4. upload `disabilities`; X
5. julia up X
6. git commit X
7. run `shs` `lcf` `shs` mergers on new frs; X
8. fixup merged shs lcf was code;X
8a. fixup Cons/Wealth; copy to SHS X
9. run weights generation; X
10. run local weights generation; X
11. weights to  `scottish-frs-data`; rerun 2,3,4
12. git commit
13. git tag matching

**SECONDARY LOADING TURNED ON**

Write unit tests for new disabilities generosity
Write code - switch disability benefits to by age and to Scotland

14. run unit tests X
15. eyeball tests on aggregates 
16. current parameter system check the fuck out of it.
17. tax credits transition turn credits OFF
18. ct calculation from https://cpag.org.uk/welfare-rights/benefits-scotland/scottish-benefits/help-council-tax/calculating-working-age-scottish-council-tax-reduction
19. One-off shs add council healthboard into hh dataframe
20. PIP/DLA/AA/CA hand-route in NMTBenefits

```julia
using ScottishTaxBenefitModel,
    .Definitions,
    .FRSHouseholdGetter,
    .MatchingLibs,
    .ModelHousehold,
    .RunSettings,
    .SHSData,
    .Uprating,
    .Utils

using CSV,
    DataFrames,
    Revise,
    Definitions

settings = Settings()
settings.weighting_strategy = dont_use_weights

settings.indirect_method = matching

settings.wealth_method = matching
settings.do_indirect_tax_calculations = true
settings.use_shs = true
 settings.num_households, settings.num_people=FRSHouseholdGetter.initialise(settings; reset=true)


```