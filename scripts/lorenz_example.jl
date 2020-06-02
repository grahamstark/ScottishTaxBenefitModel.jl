using DataFrames
using TBComponents

lorenz=DataFrame( pop=ones(10),inc=[10,11,12,13,14,15,16,17,30,50])
lorenz[!,:cumpop] = cumsum(lorenz.pop)
lorenz[!,:cuminc] = cumsum(lorenz.inc)

iq = makeinequality(lorenz,:pop,:inc)
