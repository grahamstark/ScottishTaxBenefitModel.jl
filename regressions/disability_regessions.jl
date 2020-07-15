m1=glm(@formula(rec_dla ~ sex+age+age^2+has_long_standing_illness), frsad, Binomial(), ProbitLink(), contrasts=Dict( :sex=>DummyCoding(),region=>DummyCoding() ))
ERROR: UndefVarError: region not defined
Stacktrace:
 [1] top-level scope at REPL[41]:1

julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness), frsad, Binomial(), ProbitLink())
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness

Coefficients:
───────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%    Upper 95%
───────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -3.24777      0.211192    -15.3783     <1e-52  -3.6617       -2.83384
male                       -0.0544373    0.0416767    -1.30618    0.1915  -0.136122      0.0272475
age                         0.0241171    0.0080333     3.00214    0.0027   0.00837213    0.0398621
age ^ 2                    -0.000220768  7.42807e-5   -2.97208    0.0030  -0.000366356  -7.51809e-5
has_long_standing_illness   1.41559      0.0674057    21.001      <1e-97   1.28348       1.5477
───────────────────────────────────────────────────────────────────────────────────────────────────

julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_are_reduced), frsad, Binomial(), ProbitLink() )
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness + adls_are_reduced

Coefficients:
────────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%     Upper 95%
────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -4.1575       0.230665    -18.024      <1e-71  -4.60959      -3.7054
male                       -0.0455679    0.0453536    -1.00473    0.3150  -0.134459      0.0433234
age                         0.0312366    0.00864961    3.61133    0.0003   0.0142837     0.0481896
age ^ 2                    -0.000309058  7.99093e-5   -3.86761    0.0001  -0.000465677  -0.000152439
has_long_standing_illness   3.57689      0.115243     31.0379     <1e-99   3.35102       3.80276
adls_are_reduced           -0.788239     0.0364389   -21.6318     <1e-99  -0.859658     -0.71682
────────────────────────────────────────────────────────────────────────────────────────────────────

julia> sum
sum          sum!          summary       summarystats
julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind), frsad, Binomial(), ProbitLink() )
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness + adls_are_reduced + registered_blind

Coefficients:
────────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%     Upper 95%
────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -4.17346      0.231674    -18.0144     <1e-71  -4.62753      -3.71939
male                       -0.0461626    0.0454249    -1.01624    0.3095  -0.135194      0.0428685
age                         0.0322653    0.00868381    3.71558    0.0002   0.0152454     0.0492853
age ^ 2                    -0.000318686  8.02143e-5   -3.97294    <1e-4   -0.000475904  -0.000161469
has_long_standing_illness   3.54727      0.115463     30.7222     <1e-99   3.32097       3.77357
adls_are_reduced           -0.779472     0.036456    -21.3812     <1e-99  -0.850925     -0.70802
registered_blind            1.19454      0.308298      3.87463    0.0001   0.590287      1.79879
────────────────────────────────────────────────────────────────────────────────────────────────────

julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_are_reduced+registered_blind+registered_deaf), frsad, Binomial(), ProbitLink() )
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness + adls_are_reduced + registered_blind + registered_deaf

Coefficients:
────────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%     Upper 95%
────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -4.17529      0.231739    -18.0172     <1e-71  -4.62949      -3.72109
male                       -0.0478031    0.0454648    -1.05143    0.2931  -0.136912      0.0413062
age                         0.032694     0.00869122    3.76172    0.0002   0.0156595     0.0497285
age ^ 2                    -0.000324531  8.03315e-5   -4.03991    <1e-4   -0.000481978  -0.000167085
has_long_standing_illness   3.53704      0.115617     30.5928     <1e-99   3.31043       3.76364
adls_are_reduced           -0.776163     0.0364875   -21.272      <1e-99  -0.847677     -0.704649
registered_blind            1.17059      0.310078      3.77513    0.0002   0.562844      1.77833
registered_deaf             0.758412     0.313767      2.41712    0.0156   0.143441      1.37338
────────────────────────────────────────────────────────────────────────────────────────────────────

julia> frsad.adls_are_reduced
17244-element Array{Int64,1}:
 -1
 -1
  2
 -1
 -1
 -1
 -1
 -1
 -1
 -1
 -1
 -1
 -1
 -1
 -1
 -1
  ⋮
 -1
  1
 -1
 -1
  3
 -1
  1
 -1
 -1
 -1
 -1
 -1
 -1
  2
  3

julia> frsad.adls_bad=frsad.adls_are_reduced.==2
julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_bad+registered_blind+registered_deaf), frsad, Binomial(), ProbitLink() )
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness + adls_bad + registered_blind + registered_deaf

Coefficients:
───────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%    Upper 95%
───────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -3.18773      0.213601    -14.9238     <1e-49  -3.60638      -2.76908
male                       -0.073906     0.0423648    -1.74451    0.0811  -0.15694       0.0091275
age                         0.0223198    0.00816007    2.73525    0.0062   0.00632638    0.0383133
age ^ 2                    -0.000207203  7.55268e-5   -2.74344    0.0061  -0.000355233  -5.91734e-5
has_long_standing_illness   1.52929      0.0688263    22.2196     <1e-99   1.39439       1.66419
adls_bad                   -0.451632     0.0526255    -8.58199    <1e-17  -0.554776     -0.348487
registered_blind            1.56686      0.310211      5.05096    <1e-6    0.958861      2.17486
registered_deaf             1.0943       0.312947      3.49677    0.0005   0.480939      1.70767
───────────────────────────────────────────────────────────────────────────────────────────────────

julia> frsad.adls_bad=frsad.adls_are_reduced.==1

julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_bad+registered_blind+registered_deaf), frsad, Binomial(), ProbitLink() )
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness + adls_bad + registered_blind + registered_deaf

Coefficients:
────────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%     Upper 95%
────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -3.29658      0.225642    -14.6098     <1e-47  -3.73883      -2.85433
male                       -0.0644818    0.045123     -1.42903    0.1530  -0.152921      0.0239575
age                         0.0285674    0.00864389    3.30492    0.0010   0.0116257     0.0455091
age ^ 2                    -0.000284036  7.99551e-5   -3.55244    0.0004  -0.000440745  -0.000127327
has_long_standing_illness   0.893089     0.0739754    12.0728     <1e-32   0.7481        1.03808
adls_bad                    1.11412      0.049044     22.7168     <1e-99   1.018         1.21025
registered_blind            1.13783      0.309969      3.6708     0.0002   0.530305      1.74536
registered_deaf             0.765249     0.316436      2.41833    0.0156   0.145045      1.38545
────────────────────────────────────────────────────────────────────────────────────────────────────

julia> frsad.adls_mid=frsad.adls_are_reduced.==2
julia> m1=glm(@formula(rec_dla ~ male+age+age^2+has_long_standing_illness+adls_bad+adls_mid+registered_blind+registered_deaf), frsad, Binomial(), ProbitLink() )
StatsModels.TableRegressionModel{GeneralizedLinearModel{GLM.GlmResp{Array{Float64,1},Binomial{Float64},ProbitLink},GLM.DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

rec_dla ~ 1 + male + age + :(age ^ 2) + has_long_standing_illness + adls_bad + adls_mid + registered_blind + registered_deaf

Coefficients:
────────────────────────────────────────────────────────────────────────────────────────────────────
                               Estimate  Std. Error    z value  Pr(>|z|)     Lower 95%     Upper 95%
────────────────────────────────────────────────────────────────────────────────────────────────────
(Intercept)                -3.37067      0.227936    -14.7878     <1e-48  -3.81742      -2.92392
male                       -0.0530578    0.0455421    -1.16503    0.2440  -0.142319      0.0362029
age                         0.0316339    0.00871238    3.63091    0.0003   0.0145579     0.0487098
age ^ 2                    -0.000314796  8.0546e-5    -3.90827    <1e-4   -0.000472663  -0.000156928
has_long_standing_illness   0.566277     0.0935136     6.05556    <1e-8    0.382993      0.74956
adls_bad                    1.44442      0.0756717    19.0879     <1e-80   1.2961        1.59273
adls_mid                    0.538657     0.0825454     6.52558    <1e-10   0.376871      0.700443
registered_blind            1.14345      0.310092      3.68744    0.0002   0.535677      1.75122
registered_deaf             0.747574     0.314667      2.37576    0.0175   0.130837      1.36431
────────────────────────────────────────────────────────────────────────────────────────────────────


disability_dexterity
disability_hearing
disability_learning
disability_memory
disability_mental_health
disability_mobility
disability_other_difficulty
disability_socially
disability_stamina
disability_vision

m1=glm(
  @formula(
    rec_dla ~
      data_year+
      male+
      age+
      age^2+
      has_long_standing_illness+
      adls_bad+
      adls_mid+
      registered_blind+
      registered_partially_sighted+
      registered_deaf+
      disability_dexterity+
      disability_learning+
      disability_memory+
      disability_mental_health+
      disability_mobility+
      disability_socially+
      disability_stamina),
  frsad,
  Binomial(),
  ProbitLink(),
  contrasts=Dict( :data_year=>DummyCoding()
  )
)
