`data`
========================================================================

The number at the beginning indicates roughly the stage of
data-screening, so `00_all_scores.csv` precedes `01_scores.csv`. 

The most important file is `03_input_vocab_eyetracking.csv`, so the data
files are described backwards from that final file.



`03_input_vocab_eyetracking.csv`
------------------------------------------------------------------------

This is *the* dataset used in the regression models reported in the
manuscript. It is the combination of the child-level measures in
`02_narrowed_scores.csv` and growth curve estimates in `02_ranefs.csv`.



`00_all_scores.csv`, `01_scores.csv`, `02_narrowed_scores.csv`
------------------------------------------------------------------------

These files contain child-level measures.

* `01_scores.csv` is a subset of `00_all_scores.csv` with just participants who
have both receptive and expressive vocabulary scores at time 1.

* `02_narrowed_scores.csv` is a subset of `01_scores.csv` with only
typically developing participants who have eyetracking data and LENA
data.

|Field                     |Description                                                                                           |
|:-------------------------|:-----------------------------------------------------------------------------------------------------|
|*Child information*       |                                                                                                      |
|ResearchID                |Four character form of the participant's Research ID                                                  |
|Female                    |Gender: 0=Male, 1=Female                                                                              |
|AAE                       |Native dialect: 0=SAE, 1=AAE                                                                          |
|LateTalker                |Parent-reported late-talker status: 0=Not IDed as a late talker; 1=Parent IDed child as a late talker |
|CImplant                  |Cochlear implant status. 0=Child does not use CI; 1=Child uses a CI                                   |
|*Expressive vocabulary*   |                                                                                                      |
|EVT_Age_T1                |Age in months (rounded down) when Expressive Vocabulary Test 2 (EVT) was completed at time 1          |
|EVT_Age_T2                |Age in months (rounded down) when Expressive Vocabulary Test 2 (EVT) was completed at time 2          |
|EVT_Form_T1               |EVT test form used at time 1. A, B or NA (if unknown)                                                 |
|EVT_Form_T2               |EVT test form used at time 2. A, B or NA (if unknown)                                                 |
|EVT_GSV_T1                |Growth scale value at time 1. These scores scale linearly with age.                                   |
|EVT_GSV_T2                |Growth scale value at time 2. These scores scale linearly with age.                                   |
|EVT_Raw_T1                |Raw score (number of words) at time 1                                                                 |
|EVT_Raw_T2                |Raw score (number of words) at time 2                                                                 |
|EVT_Standard_T1           |Standard score at time 1. These are age-based norm-referenced scores. They have mean 100 and SD 15.   |
|EVT_Standard_T2           |Standard score at time 2. These are age-based norm-referenced scores. They have mean 100 and SD 15.   |
|*Receptive vocabulary*    |                                                                                                      |
|PPVT_Age_T1               |Age in months (rounded down) when Peabody Picture Vocabulary Test 4 (PPVT) was completed at time 1    |
|PPVT_Age_T2               |Age in months (rounded down) when Peabody Picture Vocabulary Test 4 (PPVT) was completed at time 1    |
|PPVT_Form_T1              |PPVT test form used at time 1. A, B or NA (if unknown)                                                |
|PPVT_Form_T2              |PPVT test form used at time 2. A, B or NA (if unknown)                                                |
|PPVT_GSV_T1               |Growth scale value at time 1. These scores scale linearly with age.                                   |
|PPVT_GSV_T2               |Growth scale value at time 2. These scores scale linearly with age.                                   |
|PPVT_Raw_T1               |Raw score (number of words) at time 1                                                                 |
|PPVT_Raw_T2               |Raw score (number of words) at time 2                                                                 |
|PPVT_Standard_T1          |Standard score at time 1. These are age-based norm-referenced scores. They have mean 100 and SD 15.   |
|PPVT_Standard_T2          |Standard score at time 2. These are age-based norm-referenced scores. They have mean 100 and SD 15.   |
|*Time 1 LENA data*        |                                                                                                      |
|LENA_Hours                |Duration of the LENA recording in hours                                                               |
|Prop_Meaningful           |Proportion of recording that was meaningful/close speech                                              |
|Prop_Distant              |Proportion of recording that was distant/overheard speech                                             |
|Prop_TV                   |Proportion of recording that was television or electronic noise                                       |
|Prop_Noise                |Proportion of recording that was noise                                                                |
|Prop_Silence              |Proportion of recording that was silence                                                              |
|AWC_Hourly                |Average hourly adult word count                                                                       |
|CTC_Hourly                |Average hourly caregiver-child conversational turn count                                              |
|CVC_Hourly                |Average hourly child vocalization count                                                               |
|LENA_Age                  |Age in months (rounded down) when LENA was completed                                                  |
|*Maternal education*      |                                                                                                      |
|MatEduCode                |Maternal education code. Ranges from 1 to 7. Used to order the categories                             |
|MatEdu                    |Maternal education level                                                                              |



`02_ranefs.csv`
------------------------------------------------------------------------

`02_ranefs.csv` contains each child's effect estimates from the growth
curve analysis model (`models/00_gca.RData`). These measures are
produced by `coef()` so they are the sum of the model's fixed effects
and the by-child random effects. `ot1` is the paper's measure of lexical
processing ability.

|Field                     |Description                                                                                           |
|:-------------------------|:-----------------------------------------------------------------------------------------------------|
|ResearchID                |Four character form of the participant's Research ID                                                  |
|Intercept                 |Child's intercept estimate from the model                                                             |
|ot1                       |Child's linear time slope estimate from the model                                                     |
|ot2                       |Child's quadratic time slope estimate from the model                                                  |
|ot3                       |Child's cubic time slope estimate from the model                                                      |



`01_looks.csv`
------------------------------------------------------------------------

`01_looks.csv` contains frame-by-frame eyetracking data following data
screening. This file is used to fit the growth curve model.

As noted in the manuscript, I binned data into three-frame 50-ms bins.
The binning scheme in included in this file. `Time` is the original
timestamp for a frame, `BinTime` is the new timestamp for the bin, and
`TimeBin` says which bin a frame belongs to.

For `GazeByImageAOI`, the follow values are used:

  - Image type: `Target`, `PhonologicalFoil`, `SemanticFoil`,
    `Unrelated`
  - Offscreen: `NA`
  - Onscreen but not on one of these images: `tracked`

|Field                     |Description                                                                                           |
|:-------------------------|:-----------------------------------------------------------------------------------------------------|
|Basename                  |Basename of the output files created from the eyetracking experiment                                  |
|TrialNo                   |Trial number within the block                                                                         |
|Time                      |Time (in ms after target onset) of the gaze measurement                                               |
|GazeByImageAOI            |Location of the gaze onscreen, expressed as the type of image.                                        |
|TimeBin                   |Number of the time bin within the trial                                                               |
|BinTime                   |Starting time (in ms after target onset) of the bin                                                   |
|Subj                      |Research ID for the child                                                                             |



`00_has_eyetracking_data.csv`
------------------------------------------------------------------------

I report that some child received a version of the experiment with a
timing error when we first getting the study off the ground.
`00_has_eyetracking_data.csv` records which version of the experiment
each child received.

|Field                     |Description                                                                                           |
|:-------------------------|:-----------------------------------------------------------------------------------------------------|
|Subj                      |Research ID for the child                                                                             |
|HasProtocol1Data          |Whether they have a block with (buggy, excluded) version of the experiment                            |
|HasProtocol2Data          |Whether they have a block with (fixed, included) version of the experiment                            |
|HasEyetracking            |Whether they have any eyetracking data                                                                |



Helper yaml files
------------------------------------------------------------------------

For this manuscript, I used a convention of bundling little
data-processing facts or hard-coded values into yaml files.

  - `constants.yaml` contains the data screening rules and random bits
    of information, like which participants refused their LENA devices
    or our maternal education coding scheme.

  - `eyetracking_facts.yaml` contains various bits of information about
    the eyetracking data-screening results.

  - `screening_facts.yaml` contains various bits of information about
    the test score data-screening results.


R Scripts
------------------------------------------------------------------------

  - `data_screening.R` reduces `01_scores.csv` into
    `02_narrowed_scores.csv`.

  - `prep_model_data.R` combines `02_narrowed_scores.csv` and
    `02_ranefs.csv` into `03_input_vocab_eyetracking.csv`
