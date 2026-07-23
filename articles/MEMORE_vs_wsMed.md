# MEMORE_vs_wsMed

## introduction

This document presents a comparison between the **MEMORE 3.0 (SPSS
Plugin)** and **wsMed (R Package)** outputs.

### parallel mediation

We analyze a **three-mediator parallel mediation model**, comparing the
results obtained from both methods.

#### MEMORE 3.0 Analysis Report

    ## ```
    ##  
    ## Run MATRIX procedure:
    ## 
    ## *********************** MEMORE Procedure for SPSS Version 3.0 ***********************
    ## 
    ##                            Written by Amanda Montoya
    ## 
    ##                     Documentation available at github.com/akmontoya/MEMORE
    ## 
    ## **************************** ANALYSIS NOTES AND WARNINGS ****************************
    ## 
    ## Bootstrap confidence interval method used: Percentile bootstrap.
    ## 
    ## Number of bootstrap samples for bootstrap confidence intervals:
    ##   5000
    ## 
    ## The following variables were mean centered prior to analysis:
    ##  (        A2        +       A1       )        /2
    ##  (        B2        +       B1       )        /2
    ##  (        C2        +       C1       )        /2
    ## 
    ## Level of confidence for all confidence intervals in output:
    ##       95.00
    ## 
    ## **************************************************************************************
    ## 
    ## Model:
    ##   1
    ## 
    ## Variables:
    ## Y =   D2       D1
    ## M1 =  A2       A1
    ## M2 =  B2       B1
    ## M3 =  C2       C1
    ## 
    ## Computed Variables:
    ## Ydiff =           D2        -       D1
    ## M1diff =          A2        -       A1
    ## M2diff =          B2        -       B1
    ## M3diff =          C2        -       C1
    ## M1avg  = (        A2        +       A1       )        /2                         Centered
    ## M2avg  = (        B2        +       B1       )        /2                         Centered
    ## M3avg  = (        C2        +       C1       )        /2                         Centered
    ## 
    ## Sample Size:
    ##   100
    ## 
    ## **************************************************************************************
    ## Outcome: Ydiff =  D2        -       D1
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant     -.0316      .0170    -1.8586      .0661     -.0653      .0021
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   99
    ## 
    ## **************************************************************************************
    ## Outcome: M1diff = A2        -       A1
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant     -.0271      .0176    -1.5385      .1271     -.0621      .0079
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   99
    ## 
    ## **************************************************************************************
    ## Outcome: M2diff = B2        -       B1
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant      .0145      .0181      .8024      .4243     -.0213      .0503
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   99
    ## 
    ## **************************************************************************************
    ## Outcome: M3diff = C2        -       C1
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant      .0153      .0163      .9404      .3493     -.0170      .0477
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   99
    ## 
    ## **************************************************************************************
    ## Outcome: Ydiff =  D2        -       D1
    ## 
    ## Model Summary
    ##           R       R-sq        MSE          F        df1        df2          p
    ##       .1978      .0391      .0296      .6312     6.0000    93.0000      .7049
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant     -.0315      .0176    -1.7875      .0771     -.0665      .0035
    ## M1diff       -.0501      .1009     -.4968      .6205     -.2505      .1502
    ## M2diff       -.0844      .1022     -.8252      .4114     -.2874      .1187
    ## M3diff       -.0167      .1084     -.1536      .8782     -.2320      .1987
    ## M1avg        -.0305      .1015     -.3002      .7647     -.2320      .1711
    ## M2avg        -.0060      .0945     -.0633      .9497     -.1936      .1816
    ## M3avg        -.1552      .1090    -1.4239      .1578     -.3716      .0612
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   93
    ## 
    ## ************************* TOTAL, DIRECT, AND INDIRECT EFFECTS *************************
    ## 
    ## Total effect of X on Y
    ##      Effect         SE          t         df          p       LLCI       ULCI
    ##      -.0316      .0170    -1.8586    99.0000      .0661     -.0653      .0021
    ## 
    ## Direct effect of X on Y
    ##      Effect         SE          t         df          p       LLCI       ULCI
    ##      -.0315      .0176    -1.7875    93.0000      .0771     -.0665      .0035
    ## 
    ## Indirect Effect of X on Y through M
    ##           Effect     BootSE   BootLLCI   BootULCI
    ## Ind1       .0014      .0030     -.0049      .0078
    ## Ind2      -.0012      .0029     -.0088      .0035
    ## Ind3      -.0003      .0028     -.0072      .0050
    ## Total     -.0001      .0054     -.0130      .0092
    ## 
    ## Indirect Key
    ## Ind1  'X'      ->       M1diff   ->       Ydiff
    ## Ind2  'X'      ->       M2diff   ->       Ydiff
    ## Ind3  'X'      ->       M3diff   ->       Ydiff
    ## 
    ## Pairwise Contrasts Between Specific Indirect Effects
    ##           Effect     BootSE   BootLLCI   BootULCI
    ## (C1)       .0026      .0039     -.0053      .0113
    ## (C2)       .0016      .0043     -.0067      .0114
    ## (C3)      -.0010      .0038     -.0089      .0068
    ## 
    ## Contrast Key:
    ## (C1)  Ind1      -       Ind2
    ## (C2)  Ind1      -       Ind3
    ## (C3)  Ind2      -       Ind3
    ## 
    ## ------ END MATRIX -----
    ##  
    ## ```

#### wsMed Analysis Report

    ## 
    ## 
    ## *************** VARIABLES ***************
    ## Outcome (Y):
    ##    Condition 1: D1 
    ##    Condition 2: D2 
    ## Mediators (M):
    ##   M1:
    ##     Condition 1: A1
    ##     Condition 2: A2
    ##   M2:
    ##     Condition 1: B1
    ##     Condition 2: B2
    ##   M3:
    ##     Condition 1: C1
    ##     Condition 2: C2
    ## Sample size (rows kept): 100 
    ## 
    ## 
    ## *************** MODEL FIT ***************
    ## 
    ## 
    ## |Measure   |  Value|
    ## |:---------|------:|
    ## |Chi-Sq    | 16.275|
    ## |df        | 12.000|
    ## |p         |  0.179|
    ## |CFI       |  0.000|
    ## |TLI       | -1.829|
    ## |RMSEA     |  0.060|
    ## |RMSEA Low |  0.000|
    ## |RMSEA Up  |  0.126|
    ## |SRMR      |  0.072|
    ## 
    ## 
    ## ************* TOTAL / DIRECT / TOTAL-IND (MC) *************
    ## 
    ## 
    ## |Label          | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:--------------|--------:|------:|---------:|----------:|
    ## |Total effect   |  -0.0316| 0.0170|   -0.0650|     0.0016|
    ## |Direct effect  |  -0.0315| 0.0170|   -0.0646|     0.0016|
    ## |Total indirect |  -0.0001| 0.0047|   -0.0096|     0.0095|
    ## 
    ## Indirect effects:
    ## 
    ## 
    ## |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:-----|--------:|------:|---------:|----------:|
    ## |ind_1 |   0.0014| 0.0032|   -0.0044|     0.0089|
    ## |ind_2 |  -0.0012| 0.0026|   -0.0077|     0.0031|
    ## |ind_3 |  -0.0003| 0.0023|   -0.0056|     0.0045|
    ## 
    ## Indirect-effect key:
    ## 
    ## 
    ## |Ind   |Path                 |
    ## |:-----|:--------------------|
    ## |ind_1 |X -> M1diff -> Ydiff |
    ## |ind_2 |X -> M2diff -> Ydiff |
    ## |ind_3 |X -> M3diff -> Ydiff |
    ## 
    ## 
    ## *************** MODERATION EFFECTS (d-paths, MC) ***************
    ## 
    ## 
    ## |Coefficient | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:-----------|--------:|------:|---------:|----------:|
    ## |d1          |  -0.0305| 0.0983|   -0.2234|     0.1589|
    ## |d2          |  -0.0060| 0.0887|   -0.1800|     0.1686|
    ## |d3          |  -0.1552| 0.1041|   -0.3571|     0.0493|
    ## 
    ## 
    ## *************** MODERATION KEY (d-paths) ***************
    ## 
    ## 
    ## |Coefficient |Path           |Moderated       |
    ## |:-----------|:--------------|:---------------|
    ## |d1          |M1avg -> Ydiff |M1diff -> Ydiff |
    ## |d2          |M2avg -> Ydiff |M2diff -> Ydiff |
    ## |d3          |M3avg -> Ydiff |M3diff -> Ydiff |
    ## 
    ## 
    ## *************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************
    ## 
    ## 
    ## |Contrast                  | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:-------------------------|--------:|------:|---------:|----------:|
    ## |indirect_2  -  indirect_1 |  -0.0030| 0.0040|   -0.0120|     0.0050|
    ## |indirect_3  -  indirect_1 |  -0.0020| 0.0040|   -0.0110|     0.0060|
    ## |indirect_3  -  indirect_2 |   0.0010| 0.0040|   -0.0060|     0.0090|
    ## 
    ## 
    ## *************** C1-C2 COEFFICIENTS (No Moderator) ***************
    ## 
    ## 
    ## |Coeff | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:-----|--------:|------:|---------:|----------:|
    ## |X1_b1 |  -0.0670| 0.1070|   -0.2760|     0.1420|
    ## |X0_b1 |  -0.0350| 0.1060|   -0.2420|     0.1730|
    ## |X1_b2 |  -0.0880| 0.1010|   -0.2860|     0.1120|
    ## |X0_b2 |  -0.0820| 0.1020|   -0.2800|     0.1180|
    ## |X1_b3 |  -0.0940| 0.1140|   -0.3150|     0.1300|
    ## |X0_b3 |   0.0600| 0.1150|   -0.1650|     0.2870|
    ## 
    ## 
    ## *************** REGRESSION PATHS (MC) ***************
    ## 
    ## 
    ## |Path           |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:--------------|:-----|--------:|------:|---------:|----------:|
    ## |Ydiff ~ M1diff |b1    |  -0.0501| 0.0944|   -0.2346|     0.1337|
    ## |Ydiff ~ M1avg  |d1    |  -0.0305| 0.0983|   -0.2234|     0.1589|
    ## |Ydiff ~ M2diff |b2    |  -0.0844| 0.0916|   -0.2639|     0.0969|
    ## |Ydiff ~ M2avg  |d2    |  -0.0060| 0.0887|   -0.1800|     0.1686|
    ## |Ydiff ~ M3diff |b3    |  -0.0167| 0.1021|   -0.2168|     0.1811|
    ## |Ydiff ~ M3avg  |d3    |  -0.1552| 0.1041|   -0.3571|     0.0493|
    ## 
    ## 
    ## *************** INTERCEPTS (MC) ***************
    ## 
    ## 
    ## |Intercept |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:---------|:-----|--------:|------:|---------:|----------:|
    ## |Ydiff~1   |cp    |  -0.0315| 0.0170|   -0.0646|     0.0016|
    ## |M1diff~1  |a1    |  -0.0271| 0.0177|   -0.0619|     0.0076|
    ## |M2diff~1  |a2    |   0.0145| 0.0179|   -0.0204|     0.0498|
    ## |M3diff~1  |a3    |   0.0153| 0.0162|   -0.0160|     0.0476|
    ## |M1avg~1   |      |  -0.0000| 0.0185|   -0.0365|     0.0362|
    ## |M2avg~1   |      |   0.0000| 0.0201|   -0.0396|     0.0393|
    ## |M3avg~1   |      |  -0.0000| 0.0174|   -0.0346|     0.0339|
    ## 
    ## 
    ## *************** VARIANCES (MC) ***************
    ## 
    ## 
    ## |Variance       |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:--------------|:-----|--------:|------:|---------:|----------:|
    ## |Ydiff~~Ydiff   |      |   0.0275| 0.0039|    0.0200|     0.0351|
    ## |M1diff~~M1diff |      |   0.0308| 0.0043|    0.0222|     0.0392|
    ## |M2diff~~M2diff |      |   0.0323| 0.0046|    0.0234|     0.0411|
    ## |M3diff~~M3diff |      |   0.0264| 0.0037|    0.0192|     0.0336|
    ## |M1avg~~M1avg   |      |   0.0339| 0.0048|    0.0244|     0.0433|
    ## |M2avg~~M2avg   |      |   0.0407| 0.0057|    0.0294|     0.0520|
    ## |M3avg~~M3avg   |      |   0.0306| 0.0043|    0.0223|     0.0392|
    ## 
    ## 
    ## *************** STANDARDIZED (MC) ***************
    ## 
    ## 
    ## |Parameter      | Estimate|     SE|          R|    2.5%|  97.5%|
    ## |:--------------|--------:|------:|----------:|-------:|------:|
    ## |cp             |  -0.1858| 0.0991| 20000.0000| -0.3785| 0.0090|
    ## |b1             |  -0.0519| 0.0950| 20000.0000| -0.2344| 0.1353|
    ## |d1             |  -0.0331| 0.1038| 20000.0000| -0.2375| 0.1686|
    ## |b2             |  -0.0894| 0.0942| 20000.0000| -0.2702| 0.1008|
    ## |d2             |  -0.0071| 0.1027| 20000.0000| -0.2079| 0.1937|
    ## |b3             |  -0.0160| 0.0950| 20000.0000| -0.2016| 0.1695|
    ## |d3             |  -0.1601| 0.1037| 20000.0000| -0.3569| 0.0499|
    ## |a1             |  -0.1546| 0.1024| 20000.0000| -0.3589| 0.0430|
    ## |a2             |   0.0806| 0.1012| 20000.0000| -0.1140| 0.2830|
    ## |a3             |   0.0945| 0.1009| 20000.0000| -0.0994| 0.2979|
    ## |Ydiff~~Ydiff   |   0.9578| 0.0462| 20000.0000|  0.7999| 0.9764|
    ## |M1diff~~M1diff |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M2diff~~M2diff |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M3diff~~M3diff |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M1avg~~M1avg   |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M1avg~~M2avg   |   0.2898| 0.0932| 20000.0000|  0.0974| 0.4645|
    ## |M1avg~~M3avg   |   0.3395| 0.0909| 20000.0000|  0.1494| 0.5069|
    ## |M2avg~~M2avg   |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M2avg~~M3avg   |   0.3240| 0.0917| 20000.0000|  0.1341| 0.4963|
    ## |M3avg~~M3avg   |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M1avg~1        |  -0.0000| 0.1017| 20000.0000| -0.2002| 0.1990|
    ## |M2avg~1        |   0.0000| 0.1007| 20000.0000| -0.1994| 0.1982|
    ## |M3avg~1        |  -0.0000| 0.1008| 20000.0000| -0.1991| 0.1981|
    ## |indirect_1     |   0.0080| 0.0184| 20000.0000| -0.0255| 0.0513|
    ## |indirect_2     |  -0.0072| 0.0149| 20000.0000| -0.0443| 0.0180|
    ## |indirect_3     |  -0.0015| 0.0134| 20000.0000| -0.0325| 0.0259|
    ## |total_indirect |  -0.0007| 0.0270| 20000.0000| -0.0548| 0.0543|
    ## |total_effect   |  -0.1865| 0.0993| 20000.0000| -0.3810| 0.0096|

    ## 
    ## Outcome Difference Model (Ydiff):
    ##  Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + b2*M2diff + d2*M2avg + b3*M3diff + d3*M3avg 
    ## 
    ## Mediator Difference Model (Chained Mediator - M1diff):
    ## M1diff ~ a1*1 
    ## 
    ## Mediator Difference Model (Other Mediators):
    ## M2diff ~ a2*1
    ## M3diff ~ a3*1 
    ## 
    ## Indirect Effects:
    ## indirect_1 := a1 * b1
    ## indirect_2 := a2 * b2
    ## indirect_3 := a3 * b3 
    ## 
    ## Total Indirect Effect:
    ##  total_indirect := indirect_1 + indirect_2 + indirect_3 
    ## 
    ## Total Effect:
    ##  total_effect := cp + total_indirect

### chained/serial mediation

We analyze a **Serial Mediation (`Serial = 1`)**.

#### MEMORE 3.0 Analysis Report

    ## ```
    ##  
    ## Run MATRIX procedure:
    ## 
    ## *********************** MEMORE Procedure for SPSS Version 3.0 ***********************
    ## 
    ##                            Written by Amanda Montoya
    ## 
    ##                     Documentation available at github.com/akmontoya/MEMORE
    ## 
    ## **************************** ANALYSIS NOTES AND WARNINGS ****************************
    ## 
    ## Bootstrap confidence interval method used: Percentile bootstrap.
    ## 
    ## Number of bootstrap samples for bootstrap confidence intervals:
    ##   5000
    ## 
    ## The following variables were mean centered prior to analysis:
    ##  (        A2        +       A1       )        /2
    ##  (        B2        +       B1       )        /2
    ## 
    ## Level of confidence for all confidence intervals in output:
    ##       95.00
    ## 
    ## **************************************************************************************
    ## 
    ## Model:
    ##   1
    ## 
    ## Variables:
    ## Y =   C2       C1
    ## M1 =  A2       A1
    ## M2 =  B2       B1
    ## 
    ## Computed Variables:
    ## Ydiff =           C2        -       C1
    ## M1diff =          A2        -       A1
    ## M2diff =          B2        -       B1
    ## M1avg  = (        A2        +       A1       )        /2                         Centered
    ## M2avg  = (        B2        +       B1       )        /2                         Centered
    ## 
    ## Sample Size:
    ##   100
    ## 
    ## **************************************************************************************
    ## Outcome: Ydiff =  C2        -       C1
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant      .0153      .0163      .9404      .3493     -.0170      .0477
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   99
    ## 
    ## **************************************************************************************
    ## Outcome: M1diff = A2        -       A1
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant     -.0271      .0176    -1.5385      .1271     -.0621      .0079
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   99
    ## 
    ## **************************************************************************************
    ## Outcome: M2diff = B2        -       B1
    ## 
    ## Model Summary
    ##           R       R-sq        MSE          F        df1        df2          p
    ##       .2351      .0553      .0314     2.8371     2.0000    97.0000      .0635
    ## 
    ## Model
    ##               coeff         SE          t          p       LLCI       ULCI
    ## constant      .0208      .0179     1.1603      .2488     -.0148      .0564
    ## M1diff        .2333      .1010     2.3086      .0231      .0327      .4338
    ## M1avg        -.0578      .0963     -.6002      .5498     -.2489      .1333
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   97
    ## 
    ## **************************************************************************************
    ## Outcome: Ydiff =  C2        -       C1
    ## 
    ## Model Summary
    ##           R       R-sq        MSE          F        df1        df2          p
    ##       .1720      .0296      .0269      .7238     4.0000    95.0000      .5778
    ## 
    ## Model
    ##                Coef         SE          t          p       LLCI       ULCI
    ## constant      .0160      .0167      .9563      .3413     -.0172      .0492
    ## M1diff       -.0360      .0962     -.3744      .7089     -.2270      .1549
    ## M2diff       -.1123      .0967    -1.1607      .2487     -.3043      .0798
    ## M1avg        -.0617      .0931     -.6619      .5097     -.2466      .1233
    ## M2avg        -.0733      .0875     -.8374      .4044     -.2469      .1004
    ## 
    ## Degrees of freedom for all regression coefficient estimates:
    ##   95
    ## 
    ## ************************* TOTAL, DIRECT, AND INDIRECT EFFECTS *************************
    ## 
    ## Total effect of X on Y
    ##      Effect         SE          t         df          p       LLCI       ULCI
    ##       .0153      .0163      .9404    99.0000      .3493     -.0170      .0477
    ## 
    ## Direct effect of X on Y
    ##      Effect         SE          t         df          p       LLCI       ULCI
    ##       .0160      .0167      .9563    95.0000      .3413     -.0172      .0492
    ## 
    ## Indirect Effect of X on Y through M
    ##           Effect     BootSE   BootLLCI   BootULCI
    ## Ind1       .0010      .0031     -.0045      .0084
    ## Ind2      -.0023      .0036     -.0111      .0033
    ## Ind3       .0007      .0010     -.0008      .0034
    ## Total     -.0006      .0048     -.0109      .0095
    ## 
    ## Indirect Key
    ## Ind1  'X'      ->       M1diff   ->       Ydiff
    ## Ind2  'X'      ->       M2diff   ->       Ydiff
    ## Ind3  'X'      ->       M1diff   ->       M2diff   ->       YDiff
    ## 
    ## Pairwise Contrasts Between Specific Indirect Effects
    ##           Effect     BootSE   BootLLCI   BootULCI
    ## (C1)       .0033      .0042     -.0042      .0128
    ## (C2)       .0003      .0034     -.0063      .0083
    ## (C3)      -.0030      .0041     -.0132      .0035
    ## 
    ## Contrast Key:
    ## (C1)  Ind1      -       Ind2
    ## (C2)  Ind1      -       Ind3
    ## (C3)  Ind2      -       Ind3
    ## 
    ## ------ END MATRIX -----
    ##  
    ## ```

#### wsMed Analysis Report

``` r

result2 <- wsMed(
  data = example_data, #dataset
  M_C1 = c("A1","B1"), # A1/B1 is A/B mediator variable in condition 1
  M_C2 = c("A2","B2"), # A2/B2 is A/B mediator variable in condition 2
  Y_C1 = "C1", # C1 is outcome variable in condition 1
  Y_C2 = "C2", # C2 is outcome variable in condition 2
  form = "CN", # Parallel mediation
  standardized = TRUE,
)
print(result2,digits=4)
```

    ## 
    ## 
    ## *************** VARIABLES ***************
    ## Outcome (Y):
    ##    Condition 1: C1 
    ##    Condition 2: C2 
    ## Mediators (M):
    ##   M1:
    ##     Condition 1: A1
    ##     Condition 2: A2
    ##   M2:
    ##     Condition 1: B1
    ##     Condition 2: B2
    ## Sample size (rows kept): 100 
    ## 
    ## 
    ## *************** MODEL FIT ***************
    ## 
    ## 
    ## |Measure   |  Value|
    ## |:---------|------:|
    ## |Chi-Sq    |  5.751|
    ## |df        |  3.000|
    ## |p         |  0.124|
    ## |CFI       |  0.494|
    ## |TLI       | -0.518|
    ## |RMSEA     |  0.096|
    ## |RMSEA Low |  0.000|
    ## |RMSEA Up  |  0.214|
    ## |SRMR      |  0.050|
    ## 
    ## 
    ## ************* TOTAL / DIRECT / TOTAL-IND (MC) *************
    ## 
    ## 
    ## |Label          | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:--------------|--------:|------:|---------:|----------:|
    ## |Total effect   |   0.0153| 0.0163|   -0.0170|     0.0471|
    ## |Direct effect  |   0.0160| 0.0163|   -0.0162|     0.0478|
    ## |Total indirect |  -0.0006| 0.0045|   -0.0103|     0.0082|
    ## 
    ## Indirect effects:
    ## 
    ## 
    ## |Label   | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:-------|--------:|------:|---------:|----------:|
    ## |ind_1   |   0.0010| 0.0031|   -0.0048|     0.0081|
    ## |ind_2   |  -0.0023| 0.0032|   -0.0103|     0.0024|
    ## |ind_1_2 |   0.0007| 0.0009|   -0.0005|     0.0032|
    ## 
    ## Indirect-effect key:
    ## 
    ## 
    ## |Ind     |Path                           |
    ## |:-------|:------------------------------|
    ## |ind_1   |X -> M1diff -> Ydiff           |
    ## |ind_2   |X -> M2diff -> Ydiff           |
    ## |ind_1_2 |X -> M1diff -> M2diff -> Ydiff |
    ## 
    ## 
    ## *************** MODERATION EFFECTS (d-paths, MC) ***************
    ## 
    ## 
    ## |Coefficient | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:-----------|--------:|------:|---------:|----------:|
    ## |d1          |  -0.0617| 0.0909|   -0.2401|     0.1169|
    ## |d2          |  -0.0733| 0.0823|   -0.2338|     0.0884|
    ## |d_1_2       |  -0.0578| 0.0953|   -0.2457|     0.1293|
    ## 
    ## 
    ## *************** MODERATION KEY (d-paths) ***************
    ## 
    ## 
    ## |Coefficient |Path            |Moderated        |
    ## |:-----------|:---------------|:----------------|
    ## |d1          |M1avg -> Ydiff  |M1diff -> Ydiff  |
    ## |d2          |M2avg -> Ydiff  |M2diff -> Ydiff  |
    ## |d_1_2       |M1avg -> M2diff |M1diff -> M2diff |
    ## 
    ## 
    ## *************** CONTRAST INDIRECT EFFECTS (No Moderator) ***************
    ## 
    ## 
    ## |Contrast                    | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:---------------------------|--------:|------:|---------:|----------:|
    ## |indirect_2    -  indirect_1 |  -0.0030| 0.0040|   -0.0130|     0.0040|
    ## |indirect_1_2  -  indirect_1 |  -0.0000| 0.0030|   -0.0070|     0.0070|
    ## |indirect_1_2  -  indirect_2 |   0.0030| 0.0040|   -0.0020|     0.0120|
    ## 
    ## 
    ## *************** C1-C2 COEFFICIENTS (No Moderator) ***************
    ## 
    ## 
    ## |Coeff    | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:--------|--------:|------:|---------:|----------:|
    ## |X1_b1    |  -0.0660| 0.1020|   -0.2640|     0.1350|
    ## |X0_b1    |  -0.0050| 0.1040|   -0.2080|     0.1990|
    ## |X1_b2    |  -0.1490| 0.1000|   -0.3450|     0.0480|
    ## |X0_b2    |  -0.0770| 0.1000|   -0.2750|     0.1170|
    ## |X1_b_1_2 |   0.2050| 0.1100|   -0.0080|     0.4190|
    ## |X0_b_1_2 |   0.2630| 0.1100|    0.0480|     0.4800|
    ## 
    ## 
    ## *************** REGRESSION PATHS (MC) ***************
    ## 
    ## 
    ## |Path            |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:---------------|:-----|--------:|------:|---------:|----------:|
    ## |Ydiff ~ M1diff  |b1    |  -0.0360| 0.0927|   -0.2159|     0.1467|
    ## |Ydiff ~ M1avg   |d1    |  -0.0617| 0.0909|   -0.2401|     0.1169|
    ## |Ydiff ~ M2diff  |b2    |  -0.1123| 0.0915|   -0.2917|     0.0651|
    ## |Ydiff ~ M2avg   |d2    |  -0.0733| 0.0823|   -0.2338|     0.0884|
    ## |M2diff ~ M1diff |b_1_2 |   0.2333| 0.0992|    0.0432|     0.4287|
    ## |M2diff ~ M1avg  |d_1_2 |  -0.0578| 0.0953|   -0.2457|     0.1293|
    ## 
    ## 
    ## *************** INTERCEPTS (MC) ***************
    ## 
    ## 
    ## |Intercept |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:---------|:-----|--------:|------:|---------:|----------:|
    ## |Ydiff~1   |cp    |   0.0160| 0.0163|   -0.0162|     0.0478|
    ## |M1diff~1  |a1    |  -0.0271| 0.0174|   -0.0614|     0.0069|
    ## |M2diff~1  |a2    |   0.0208| 0.0177|   -0.0134|     0.0557|
    ## |M1avg~1   |      |  -0.0000| 0.0185|   -0.0366|     0.0358|
    ## |M2avg~1   |      |   0.0000| 0.0201|   -0.0397|     0.0392|
    ## 
    ## 
    ## *************** VARIANCES (MC) ***************
    ## 
    ## 
    ## |Variance       |Label | Estimate|     SE| 2.5%CI.Lo| 97.5%CI.Up|
    ## |:--------------|:-----|--------:|------:|---------:|----------:|
    ## |Ydiff~~Ydiff   |      |   0.0256| 0.0036|    0.0186|     0.0327|
    ## |M2diff~~M2diff |      |   0.0305| 0.0043|    0.0220|     0.0389|
    ## |M1diff~~M1diff |      |   0.0308| 0.0044|    0.0222|     0.0394|
    ## |M1avg~~M1avg   |      |   0.0339| 0.0048|    0.0245|     0.0433|
    ## |M2avg~~M2avg   |      |   0.0407| 0.0058|    0.0294|     0.0521|
    ## 
    ## 
    ## *************** STANDARDIZED (MC) ***************
    ## 
    ## 
    ## |Parameter      | Estimate|     SE|          R|    2.5%|  97.5%|
    ## |:--------------|--------:|------:|----------:|-------:|------:|
    ## |cp             |   0.0983| 0.0994| 20000.0000| -0.0980| 0.2917|
    ## |b1             |  -0.0388| 0.0980| 20000.0000| -0.2288| 0.1552|
    ## |d1             |  -0.0697| 0.1007| 20000.0000| -0.2641| 0.1315|
    ## |b2             |  -0.1239| 0.0991| 20000.0000| -0.3138| 0.0713|
    ## |d2             |  -0.0908| 0.0997| 20000.0000| -0.2831| 0.1090|
    ## |a1             |  -0.1546| 0.1008| 20000.0000| -0.3563| 0.0394|
    ## |a2             |   0.1159| 0.0984| 20000.0000| -0.0756| 0.3105|
    ## |b_1_2          |   0.2278| 0.0933| 20000.0000|  0.0422| 0.4048|
    ## |d_1_2          |  -0.0592| 0.0963| 20000.0000| -0.2479| 0.1316|
    ## |Ydiff~~Ydiff   |   0.9656| 0.0416| 20000.0000|  0.8324| 0.9890|
    ## |M2diff~~M2diff |   0.9446| 0.0461| 20000.0000|  0.8187| 0.9931|
    ## |M1diff~~M1diff |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M1avg~~M1avg   |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M1avg~~M2avg   |   0.2898| 0.0936| 20000.0000|  0.0975| 0.4637|
    ## |M2avg~~M2avg   |   1.0000| 0.0000| 20000.0000|  1.0000| 1.0000|
    ## |M1avg~1        |  -0.0000| 0.1015| 20000.0000| -0.2020| 0.1980|
    ## |M2avg~1        |   0.0000| 0.1006| 20000.0000| -0.2004| 0.1964|
    ## |indirect_1     |   0.0060| 0.0185| 20000.0000| -0.0292| 0.0486|
    ## |indirect_2     |  -0.0144| 0.0191| 20000.0000| -0.0615| 0.0146|
    ## |indirect_1_2   |   0.0044| 0.0057| 20000.0000| -0.0030| 0.0189|
    ## |total_indirect |  -0.0040| 0.0269| 20000.0000| -0.0612| 0.0498|
    ## |total_effect   |   0.0943| 0.0992| 20000.0000| -0.1039| 0.2877|

``` r

printGM(result2)
```

    ## 
    ## Outcome Difference Model (Ydiff):
    ##  Ydiff ~ cp*1 + b1*M1diff + d1*M1avg + b2*M2diff + d2*M2avg 
    ## 
    ## Mediator Difference Model (Chained Mediator - M1diff):
    ## M1diff ~ a1*1 
    ## 
    ## Mediator Difference Model (Other Mediators):
    ## M2diff ~ a2*1 + b_1_2*M1diff + d_1_2*M1avg 
    ## 
    ## Indirect Effects:
    ## indirect_1 := a1 * b1
    ## indirect_2 := a2 * b2
    ## indirect_1_2 := a1 * b_1_2 * b2 
    ## 
    ## Total Indirect Effect:
    ##  total_indirect := indirect_1 + indirect_2 + indirect_1_2 
    ## 
    ## Total Effect:
    ##  total_effect := cp + total_indirect
