# Comparing wsMed and MEMORE

## What is compared?

These examples compare unstandardized indirect effects and their
contrasts in a parallel and a serial model. They use the package’s
simulated `example_data`, not the empirical manuscript dataset. The
MEMORE 3.0 reports are stored SPSS output; they are not rerun when this
page is built. The wsMed analyses below are executed when the tutorial
is rebuilt.

| Setting | Matched choice |
|----|----|
| Data | The same 100 complete simulated participant rows |
| Direction | Condition 2 minus condition 1 for every pair |
| Model | The same mediator ordering and directed connections |
| Covariates and moderator | None; MEMORE does not support covariates |
| Scale | Unstandardized effects |
| Indirect-effect inference | 5,000 participant bootstrap samples; 95% percentile CIs |

The default wsMed analysis uses Monte Carlo inference. Here we
explicitly request bootstrap inference and 5,000 replicates to match the
method and sample count in the stored reports. The two programs do not
use identical resamples, so matching settings does not imply identical
CI endpoints.

**Why focus on indirect effects?** In these MEMORE reports, total and
direct effects use regression-based SEs and *t* intervals. The wsMed
bootstrap report uses bootstrap SEs and percentile CIs for all effects.
Thus the indirect-effect intervals below have a common interpretation;
the total- and direct-effect intervals should not be treated as
equivalent output. Contrasts are calculated within each bootstrap
sample, retaining dependence between indirect effects.

## Parallel mediation

The three mediators are A, B and C; the outcome is D. There are no
directed connections among mediators.

``` r

result1 <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1", "C1"),
  M_C2 = c("A2", "B2", "C2"),
  Y_C1 = "D1",
  Y_C2 = "D2",
  ci_method = "bootstrap",
  bootstrap = 5000
)
print(result1)
#> wsMed analysis
#> Model: P | DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | bootstrap 
#> 95% percentile intervals; 5000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                     -0.031486   0.016692 -0.065312  0.000477
#> indirect_1: M1                         0.001360   0.003223 -0.004983  0.008751
#> indirect_2: M2                        -0.001222   0.002960 -0.008998  0.003281
#> indirect_3: M3                        -0.000256   0.002695 -0.006899  0.004957
#> total_indirect: Total indirect effect -0.000118   0.005509 -0.012749  0.009917
#> total: Total effect                   -0.031604   0.017059 -0.066636  0.000594
#> Inference draws: 5000 retained of 5000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
```

The table aligns specific pathways, their total, and the same signed
contrasts:

| Effect | MEMORE estimate | wsMed estimate | MEMORE 95% CI | wsMed 95% CI |
|:---|---:|---:|---:|---:|
| Ind1: A -\> D | 0.0014 | 0.0014 | \[-0.0049, 0.0078\] | \[-0.0050, 0.0088\] |
| Ind2: B -\> D | -0.0012 | -0.0012 | \[-0.0088, 0.0035\] | \[-0.0090, 0.0033\] |
| Ind3: C -\> D | -0.0003 | -0.0003 | \[-0.0072, 0.0050\] | \[-0.0069, 0.0050\] |
| Total indirect | -0.0001 | -0.0001 | \[-0.0130, 0.0092\] | \[-0.0127, 0.0099\] |
| Ind1 - Ind2 | 0.0026 | 0.0026 | \[-0.0053, 0.0113\] | \[-0.0052, 0.0115\] |
| Ind1 - Ind3 | 0.0016 | 0.0016 | \[-0.0067, 0.0114\] | \[-0.0063, 0.0114\] |
| Ind2 - Ind3 | -0.0010 | -0.0010 | \[-0.0089, 0.0068\] | \[-0.0090, 0.0066\] |

Full stored MEMORE 3.0 parallel-model report

``` text

Run MATRIX procedure:

*********************** MEMORE Procedure for SPSS Version 3.0 ***********************

                           Written by Amanda Montoya

                    Documentation available at github.com/akmontoya/MEMORE

**************************** ANALYSIS NOTES AND WARNINGS ****************************

Bootstrap confidence interval method used: Percentile bootstrap.

Number of bootstrap samples for bootstrap confidence intervals:
  5000

The following variables were mean centered prior to analysis:
 (        A2        +       A1       )        /2
 (        B2        +       B1       )        /2
 (        C2        +       C1       )        /2

Level of confidence for all confidence intervals in output:
      95.00

**************************************************************************************

Model:
  1

Variables:
Y =   D2       D1
M1 =  A2       A1
M2 =  B2       B1
M3 =  C2       C1

Computed Variables:
Ydiff =           D2        -       D1
M1diff =          A2        -       A1
M2diff =          B2        -       B1
M3diff =          C2        -       C1
M1avg  = (        A2        +       A1       )        /2                         Centered
M2avg  = (        B2        +       B1       )        /2                         Centered
M3avg  = (        C2        +       C1       )        /2                         Centered

Sample Size:
  100

**************************************************************************************
Outcome: Ydiff =  D2        -       D1

Model
               Coef         SE          t          p       LLCI       ULCI
constant     -.0316      .0170    -1.8586      .0661     -.0653      .0021

Degrees of freedom for all regression coefficient estimates:
  99

**************************************************************************************
Outcome: M1diff = A2        -       A1

Model
               Coef         SE          t          p       LLCI       ULCI
constant     -.0271      .0176    -1.5385      .1271     -.0621      .0079

Degrees of freedom for all regression coefficient estimates:
  99

**************************************************************************************
Outcome: M2diff = B2        -       B1

Model
               Coef         SE          t          p       LLCI       ULCI
constant      .0145      .0181      .8024      .4243     -.0213      .0503

Degrees of freedom for all regression coefficient estimates:
  99

**************************************************************************************
Outcome: M3diff = C2        -       C1

Model
               Coef         SE          t          p       LLCI       ULCI
constant      .0153      .0163      .9404      .3493     -.0170      .0477

Degrees of freedom for all regression coefficient estimates:
  99

**************************************************************************************
Outcome: Ydiff =  D2        -       D1

Model Summary
          R       R-sq        MSE          F        df1        df2          p
      .1978      .0391      .0296      .6312     6.0000    93.0000      .7049

Model
               Coef         SE          t          p       LLCI       ULCI
constant     -.0315      .0176    -1.7875      .0771     -.0665      .0035
M1diff       -.0501      .1009     -.4968      .6205     -.2505      .1502
M2diff       -.0844      .1022     -.8252      .4114     -.2874      .1187
M3diff       -.0167      .1084     -.1536      .8782     -.2320      .1987
M1avg        -.0305      .1015     -.3002      .7647     -.2320      .1711
M2avg        -.0060      .0945     -.0633      .9497     -.1936      .1816
M3avg        -.1552      .1090    -1.4239      .1578     -.3716      .0612

Degrees of freedom for all regression coefficient estimates:
  93

************************* TOTAL, DIRECT, AND INDIRECT EFFECTS *************************

Total effect of X on Y
     Effect         SE          t         df          p       LLCI       ULCI
     -.0316      .0170    -1.8586    99.0000      .0661     -.0653      .0021

Direct effect of X on Y
     Effect         SE          t         df          p       LLCI       ULCI
     -.0315      .0176    -1.7875    93.0000      .0771     -.0665      .0035

Indirect Effect of X on Y through M
          Effect     BootSE   BootLLCI   BootULCI
Ind1       .0014      .0030     -.0049      .0078
Ind2      -.0012      .0029     -.0088      .0035
Ind3      -.0003      .0028     -.0072      .0050
Total     -.0001      .0054     -.0130      .0092

Indirect Key
Ind1  'X'      ->       M1diff   ->       Ydiff
Ind2  'X'      ->       M2diff   ->       Ydiff
Ind3  'X'      ->       M3diff   ->       Ydiff

Pairwise Contrasts Between Specific Indirect Effects
          Effect     BootSE   BootLLCI   BootULCI
(C1)       .0026      .0039     -.0053      .0113
(C2)       .0016      .0043     -.0067      .0114
(C3)      -.0010      .0038     -.0089      .0068

Contrast Key:
(C1)  Ind1      -       Ind2
(C2)  Ind1      -       Ind3
(C3)  Ind2      -       Ind3

------ END MATRIX -----
```

## Serial mediation

The two mediators are A and B; the outcome is C. `form = "CN"` adds the
A-to-B connection, matching the stored MEMORE serial specification. The
third indirect effect now follows A → B → C.

``` r

result2 <- wsMed(
  data = example_data,
  M_C1 = c("A1", "B1"),
  M_C2 = c("A2", "B2"),
  Y_C1 = "C1",
  Y_C2 = "C2",
  form = "CN",
  ci_method = "bootstrap",
  bootstrap = 5000
)
print(result2)
#> wsMed analysis
#> Model: CN | DE | Observations: 100 
#> Effects:
#> wsMed all | raw scale | bootstrap 
#> 95% percentile intervals; 5000 joint draws; SE from effect draws
#> Condition contrast: C2 - C1 
#>                                        Estimate Std. Error  CI lower  CI upper
#> cp: Direct effect                      0.015995   0.016422 -0.017209  0.047258
#> indirect_1: M1                         0.000977   0.003106 -0.004617  0.008159
#> indirect_1_2: M1 -> M2                 0.000710   0.001088 -0.000763  0.003552
#> indirect_2: M2                        -0.002337   0.003775 -0.011787  0.003241
#> total_indirect: Total indirect effect -0.000650   0.005013 -0.011443  0.009266
#> total: Total effect                    0.015346   0.016257 -0.016721  0.046780
#> Inference draws: 5000 retained of 5000 ; 0 excluded before effect extraction.
#> Use as.data.frame() for the full-precision table and metadata.
#> Post-fit admissibility: 1 of 1 ; excluded rows: 0
```

| Effect | MEMORE estimate | wsMed estimate | MEMORE 95% CI | wsMed 95% CI |
|:---|---:|---:|---:|---:|
| Ind1: A -\> C | 0.0010 | 0.0010 | \[-0.0045, 0.0084\] | \[-0.0046, 0.0082\] |
| Ind2: B -\> C | -0.0023 | -0.0023 | \[-0.0111, 0.0033\] | \[-0.0118, 0.0032\] |
| Ind3: A -\> B -\> C | 0.0007 | 0.0007 | \[-0.0008, 0.0034\] | \[-0.0008, 0.0036\] |
| Total indirect | -0.0006 | -0.0006 | \[-0.0109, 0.0095\] | \[-0.0114, 0.0093\] |
| Ind1 - Ind2 | 0.0033 | 0.0033 | \[-0.0042, 0.0128\] | \[-0.0039, 0.0133\] |
| Ind1 - Ind3 | 0.0003 | 0.0003 | \[-0.0063, 0.0083\] | \[-0.0067, 0.0082\] |
| Ind2 - Ind3 | -0.0030 | -0.0030 | \[-0.0132, 0.0035\] | \[-0.0139, 0.0035\] |

Full stored MEMORE 3.0 serial-model report

``` text

Run MATRIX procedure:

*********************** MEMORE Procedure for SPSS Version 3.0 ***********************

                           Written by Amanda Montoya

                    Documentation available at github.com/akmontoya/MEMORE

**************************** ANALYSIS NOTES AND WARNINGS ****************************

Bootstrap confidence interval method used: Percentile bootstrap.

Number of bootstrap samples for bootstrap confidence intervals:
  5000

The following variables were mean centered prior to analysis:
 (        A2        +       A1       )        /2
 (        B2        +       B1       )        /2

Level of confidence for all confidence intervals in output:
      95.00

**************************************************************************************

Model:
  1

Variables:
Y =   C2       C1
M1 =  A2       A1
M2 =  B2       B1

Computed Variables:
Ydiff =           C2        -       C1
M1diff =          A2        -       A1
M2diff =          B2        -       B1
M1avg  = (        A2        +       A1       )        /2                         Centered
M2avg  = (        B2        +       B1       )        /2                         Centered

Sample Size:
  100

**************************************************************************************
Outcome: Ydiff =  C2        -       C1

Model
               Coef         SE          t          p       LLCI       ULCI
constant      .0153      .0163      .9404      .3493     -.0170      .0477

Degrees of freedom for all regression coefficient estimates:
  99

**************************************************************************************
Outcome: M1diff = A2        -       A1

Model
               Coef         SE          t          p       LLCI       ULCI
constant     -.0271      .0176    -1.5385      .1271     -.0621      .0079

Degrees of freedom for all regression coefficient estimates:
  99

**************************************************************************************
Outcome: M2diff = B2        -       B1

Model Summary
          R       R-sq        MSE          F        df1        df2          p
      .2351      .0553      .0314     2.8371     2.0000    97.0000      .0635

Model
              coeff         SE          t          p       LLCI       ULCI
constant      .0208      .0179     1.1603      .2488     -.0148      .0564
M1diff        .2333      .1010     2.3086      .0231      .0327      .4338
M1avg        -.0578      .0963     -.6002      .5498     -.2489      .1333

Degrees of freedom for all regression coefficient estimates:
  97

**************************************************************************************
Outcome: Ydiff =  C2        -       C1

Model Summary
          R       R-sq        MSE          F        df1        df2          p
      .1720      .0296      .0269      .7238     4.0000    95.0000      .5778

Model
               Coef         SE          t          p       LLCI       ULCI
constant      .0160      .0167      .9563      .3413     -.0172      .0492
M1diff       -.0360      .0962     -.3744      .7089     -.2270      .1549
M2diff       -.1123      .0967    -1.1607      .2487     -.3043      .0798
M1avg        -.0617      .0931     -.6619      .5097     -.2466      .1233
M2avg        -.0733      .0875     -.8374      .4044     -.2469      .1004

Degrees of freedom for all regression coefficient estimates:
  95

************************* TOTAL, DIRECT, AND INDIRECT EFFECTS *************************

Total effect of X on Y
     Effect         SE          t         df          p       LLCI       ULCI
      .0153      .0163      .9404    99.0000      .3493     -.0170      .0477

Direct effect of X on Y
     Effect         SE          t         df          p       LLCI       ULCI
      .0160      .0167      .9563    95.0000      .3413     -.0172      .0492

Indirect Effect of X on Y through M
          Effect     BootSE   BootLLCI   BootULCI
Ind1       .0010      .0031     -.0045      .0084
Ind2      -.0023      .0036     -.0111      .0033
Ind3       .0007      .0010     -.0008      .0034
Total     -.0006      .0048     -.0109      .0095

Indirect Key
Ind1  'X'      ->       M1diff   ->       Ydiff
Ind2  'X'      ->       M2diff   ->       Ydiff
Ind3  'X'      ->       M1diff   ->       M2diff   ->       YDiff

Pairwise Contrasts Between Specific Indirect Effects
          Effect     BootSE   BootLLCI   BootULCI
(C1)       .0033      .0042     -.0042      .0128
(C2)       .0003      .0034     -.0063      .0083
(C3)      -.0030      .0041     -.0132      .0035

Contrast Key:
(C1)  Ind1      -       Ind2
(C2)  Ind1      -       Ind3
(C3)  Ind2      -       Ind3

------ END MATRIX -----
```

## Reading the comparison

The indirect-effect and contrast point estimates agree to the four
decimal places available in the stored MEMORE reports. Percentile CI
endpoints can differ because of the bootstrap resamples and quantile
conventions.

Centering also matters in the serial example. MEMORE recenters mediator
averages in each bootstrap sample, while wsMed resamples variables
centered during data preparation. This can change downstream-mediator
intercepts and their indirect-effect draws, even with identical
resamples. Interpret the serial intervals in light of this additional
implementation difference.

Matching point estimates establishes agreement for these fitted models;
it does not by itself validate interval coverage or other model
specifications.

The comparison does not establish agreement for standardized or
moderated effects. Their definitions and scale conventions need separate
checks; see [Standardized
effects](https://yangzhen1999.github.io/wsMed/articles/StandardizedModeratedMediation.md).
For a first analysis with the default wsMed settings, use [Get
started](https://yangzhen1999.github.io/wsMed/articles/GetStarted.md).
