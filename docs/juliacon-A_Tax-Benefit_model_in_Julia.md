# A Tax-Benefit model in Julia

A tax benefit model is a computer program that calculates the effects of possible changes to the fiscal system on a sample of households. We take each of the households in a household survey dataset, calculate how much tax the household members are liable for under some proposed tax and benefit regime, and how much benefits they are entitled to, and add add up the results. If the sample is representative of the population, and the modelling sufficiently accurate, the model can then tell you, for example, the net costs of the proposals, the numbers who are made better or worse off, the effective tax rates faced by individuals, the numbers taken in and out of poverty by some change, and much else.

I want to discuss a new Tax-Benefit model for Scotland written Julia (https://github.com/grahamstark/ScottishTaxBenefitModel.jl). 

There are currently three web interfaces you can play with:

* https://ubi.virtual-worlds.scot/ (Models a Universal Basic Income)
* https://stb.virtual-worlds.scot/scotbud (construct a national budget)
* https://stb.virtual-worlds.scot/bcd/ (explores the incentive effects of the fiscal system)
