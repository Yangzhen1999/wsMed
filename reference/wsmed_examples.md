# Data for the manuscript examples

The prepared analysis data used in the three wsMed manuscript examples,
derived from the iWeek study deposited by Sagaribay (2025). Each row is
one participant; T1 and T2 denote measurements before and after the
study period. The examples use T2 minus T1 as the within-person
contrast.

## Usage

``` r
wsmed_examples
```

## Format

A data frame with 123 rows and 14 numeric columns:

- TSRQ_T1, TSRQ_T2:

  Autonomous motivation scores at T1 and T2.

- WEMBS_T1, WEMBS_T2:

  Subjective well-being scores at T1 and T2.

- SMUF_T1, SMUF_T2:

  Daily social media use scores at T1 and T2.

- ISI_T1, ISI_T2:

  Insomnia severity scores at T1 and T2.

- DASSS_T1, DASSS_T2:

  DASS stress-subscale scores at T1 and T2, each calculated as the sum
  of the seven stress items.

- HES_T1, HES_T2:

  Healthy eating scores at T1 and T2.

- Age:

  Age in years.

- BMI:

  Body mass index, recalculated from weight in pounds and height in
  inches using `703 * weight / height^2`.

## Source

Sagaribay, R. (2025). *iWeek: A Week-Long Social Media Abstinence
Intervention and its Impact on Well-Being, Mental Health, Body Image,
and Sleep in Latina College Students*. Mendeley Data, version 1.
[doi:10.17632/fn9n95bsh5.1](https://doi.org/10.17632/fn9n95bsh5.1) .
License: <https://creativecommons.org/licenses/by/4.0/>.

## Details

Score columns retain their prepared source values without rescaling or
standardization. The original dataset contains 221 participants: 123 in
the iWeek intervention group and 98 in the control group. This prepared
dataset retains the 123 intervention-group participants. The wsMed
examples illustrate within-person mediation using their paired T1/T2
measurements; they do not reproduce the original study's group
comparison.

The manuscript authors retained the 14 analysis columns and recalculated
BMI. Height values outside the preparation rule of 48–84 inches,
including ambiguous units, were not converted by guesswork. BMI remains
missing for 13 such records. No further participants were removed, no
values were imputed, and no additional cleaning is performed when
creating this package dataset. SPSS storage attributes are omitted;
numerical values, row order, and missing positions match the prepared
`wsMed_examples.sav` replication file.

Across these 14 columns, 55 participants (44.7 percent) have at least
one missing value, with 146 missing cells in total. Missing counts for
paired T1/T2 columns are TSRQ: 1/22; WEMBS: 0/22; SMUF: 8/18; ISI: 0/19;
DASSS: 0/23; HES: 0/20. Age is complete and BMI has 13 missing values.
Counts for an individual analysis depend on the variables it selects.

In Examples 1 and 3, TSRQ, WEMBS, and SMUF are mediators; in Example 2,
WEMBS and ISI precede TSRQ. DASSS is the outcome, HES is a
within-subject covariate, and BMI is a between-subject covariate. Age is
a covariate in Examples 1 and 2 and the moderator in Example 3.

The source data and this prepared derivative are distributed under CC BY
4.0, separately from the package code's GPL license. Attribution and
modification information are also installed in `COPYRIGHTS`.

## See also

[`example_data()`](https://yangzhen1999.github.io/wsMed/reference/example_data.md),
[`wsMed()`](https://yangzhen1999.github.io/wsMed/reference/wsMed.md),
[`wsmed_fit()`](https://yangzhen1999.github.io/wsMed/reference/wsmed_fit.md)

## Examples

``` r
data(wsmed_examples)
dim(wsmed_examples)
#> [1] 123  14
colSums(is.na(wsmed_examples))
#>  TSRQ_T1  TSRQ_T2 WEMBS_T1 WEMBS_T2  SMUF_T1  SMUF_T2   ISI_T1   ISI_T2 
#>        1       22        0       22        8       18        0       19 
#> DASSS_T1 DASSS_T2   HES_T1   HES_T2      Age      BMI 
#>        0       23        0       20        0       13 
sum(!complete.cases(wsmed_examples))
#> [1] 55
```
