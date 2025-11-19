# 

[Paper](https://fiscalcommission.scot/wp-content/uploads/2019/11/How-we-forecast-behavioural-responses-to-income-tax-policy-March-2018.pdf)

Discussion paras 3.5-12 a bit weird and ignore income effects.

Taxable Income? After allowance?
What's the basic rate? 20? 

Can we reproduce table 5.2? 

Spreadsheet: 

https://fiscalcommission.scot/wp-content/uploads/2019/11/How-we-forecast-behavioural-responses-to-income-tax-policy-March-2018-Calculation-workbook.xlsx

add MRs IT, NI to incomes

?? what about CB/Allowance withdrawal

https://fiscalcommission.scot/wp-content/uploads/2019/11/How-we-forecast-behavioural-responses-to-income-tax-policy-March-2018-Charts-and-Tables.xlsx

## STEPS

Does JP have a GitHub account



1. Create a module

```julia 
module TaxCorrections

end

```

2. Create a test 
   - in tests

2. Add module to ScottishTaxBenefitModel.jl

3. Collect marginal income tax/NI rates
    - add to `incomes` dataframe
    - fields are in `Results` `ITResult` - non_savings_band 
    - we need to add fields to `NIResult` first



4. Parameters (TIE_RATES and BANDS) are run settings (apply to all run systems in the same way):
    - declare fields from workbook in `RunSettings.jl`;
    - should be variables rather than constants (change run settings assumptions).

5. Tax Corrections called during output step

6. Interface is something like:

```julia
    create_tax_corrections(
        systems :: Vector{ParameterSystem},
        settings :: RunSettings )::DataFrame
```

output and calculations can then be taken straight from workbook




Qs: 

* what about allowance and CB withdrawal - should it be METRs rather than IT rates?
* self employment income?
