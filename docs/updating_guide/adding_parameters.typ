=== STBParameters

Parameters are organised into `structs`, recursively, finally into `TaxBenefitSystem` 



Uses #link("https://mauro3.github.io/Parameters.jl/stable/")[Parameters.jl] to initialise fields.

==== Example 

```julia



@with_kw mutable struct WinterFuelPayment{T<:Real}
    income_limit=T(999_999_999)
    amounts = T[0.0,200, 300] #203.40,305.10]
    upper_age = 80
end


```

Most systems

Always add weeklyise!:

```julia


function weeklyise!( wfp :: WinterFuelPayment; 
  wpm=WEEKS_PER_MONTH, 
  wpy=WEEKS_PER_YEAR )
    if wpf.income_limit < 999_999_999 # don't mess with some default upper limit
        wfp.income_limit /= wpy
    end
    wfp.amounts ./= wpy
end

```

The values for this are usually expressed annually, so `/= WEEKS_PER_YEAR` converts to weekly. 

The `wpy=WEEKS_PER_YEAR .../MONTH` are there because sometimes you need different definitions - the UC tests need 

==== Adding to loaded parameters

Check whether it's meaningful to add entries into 