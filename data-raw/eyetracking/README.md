Eyetracking data codebook
========================================================================

Brief recap of how the data were created
------------------------------------------------------------------------

We administered our eyetracking experiments using E-Prime, which handled
stimulus presentation and interfaced with the Tobii eyetracker. Each
session of the experiment generates a text file with event timing and
trial information from Eprime and also generates a tab-separated data
file with frame-by-frame measures emitted by the eyetracking. I used my
lookr R package to combine the information from these two files and to
perform all of the data reduction steps, like deblinking or mapping gaze
x-y coordinates to images/areas of interest. The files in this directory
contain tables of the data after those data reduction steps.

I think of eyetracking data hierarchically: eyetracking frames nested in
experiment trials nested in a block of trials. The files here provide
information on those three levels:

1. `administration.csv`: block/administration-level data.
1. `trials.csv`: trial-level data.
1. `gazes_pt1.csv`, `gazes_pt2.csv`: eyetracking frame-level data.


`administration.csv`
------------------------------------------------------------------------

`administration.csv` contains information about the blocks of the
experiment.

|Field                     |Description                                                                                           |
|:-------------------------|:-----------------------------------------------------------------------------------------------------|
|Basename                  |Basename of the output files created from the eyetracking experiment                                  |
|DateTime                  |Date and time of the eyetracking experiment                                                           |
|Subject                   |Nine character form of the participant's Research ID                                                  |
|Dialect                   |Dialect version of the experiment used                                                                |


`trials.csv`
------------------------------------------------------------------------

`trials.csv` contains all the trial-level information, although our
analyses don't use any trial level information. (We aggragated the 
trials together within each subject to get the probability of fixating 
on the target over time.)

It's easier to think about the trial-level data if we think about a
single trial looked like. We have some events.

1.  Images appear onscreen (`ImageOnset`). Brief pause.
2.  Eyetracker verifies that the child is looking onscreen by waiting
    for the child's fixation (`FixationOnset`, `FixationDur`).
3.  Carrier phrase like *find the* plays. (`CarrierOnset`, `CarrierEnd`)
4.  Target noun plays *shirt* (`Audio`, `TargetOnset`, `TargetEnd`).
5.  Brief pause.
6.  Attention getter phrase like *check it out* (`Attention`,
    `AttentionOnset`, `AttentionEnd`).
    
The images are arranged in a 2-by-2 grid. Each image plays a different
kind of a role: one is the target, one is a phonologically similar word,
one is a semantically similar word, and one is unrelated. Describing
images, image roles, role locations takes up many columns:

  - What word served each role: `Target` (e.g., `"flag"`),
    `PhonologicalFoil`, `SemanticFoil`, `Unrelated`
  - Where onscreen to find each role: `TargetImage` (e.g.,
    `"UpperRightImage"`), `PhonologicalFoilImage`, `SemanticFoilImage`,
    `UnrelatedImage`
  - What image file appeared in each location: `UpperLeftImage` (e.g.,
    `"pear1"`), `UpperRightImage`, `LowerLeftImage`, `LowerRightImage`
  - What role appeared in each location: `UpperLeftImageStimulus` (e.g.,
    `"Unrelated"`), `UpperRightImageStimulus`, `LowerLeftImageStimulus`,
    `LowerRightImageStimulus`


|Field                     |Description                                                                                           |
|:-------------------------|:-----------------------------------------------------------------------------------------------------|
|Basename                  |Basename of the output files created from the eyetracking experiment                                  |
|TrialNo                   |Trial number within the block                                                                         |
|Attention                 |Filename of the attention getter that played after the target prompt                                  |
|AttentionEnd              |Time (in ms after target onset) when attention getter ended                                           |
|AttentionOnset            |Time (in ms after target onset) when attention getter played                                          |
|Audio                     |Filename of the target prompt                                                                         |
|Bias_FrameCount           |Number of frames spent on the image during the bias window                                            |
|Bias_ImageAOI             |Name of the image fixated on during the bias window. I.e., where child was looking at target onset    |
|Bias_WindowEnd            |Time (in ms after target onset) when the bias window ended                                            |
|Bias_WindowStart          |Time (in ms after target onset) when the bias window start                                            |
|CarrierEnd                |Time (in ms after target onset) when the carrier phrase (e.g., "find the") ended                      |
|CarrierOnset              |Time (in ms after target onset) when the carrier phrase (e.g., "find the") started                    |
|FixationDur               |Time spent during the fixation verification procedure                                                 |
|FixationOnset             |Time (in ms after target onset) when the fixation procedure started                                   |
|ImageOnset                |Time (in ms after target onset) when the images appeared onscreen                                     |
|InterpolationWindow       |Max amount of time that could be filled with deblinking/interpolation                                 |
|LowerLeftImage            |Filename of the image in the lower left part of the screen                                            |
|LowerLeftImageStimulus    |Type of word (target or foil type) in the lower left part of the screen                               |
|LowerRightImage           |Filename of the image in the lower right part of the screen                                           |
|LowerRightImageStimulus   |Type of word (target or foil type) in the lower right part of the screen                              |
|PhonologicalFoil          |Word that acted as the phonological foil                                                              |
|PhonologicalFoilImage     |Location of the phonological foil                                                                     |
|SemanticFoil              |Word that acted as the semantic foil                                                                  |
|SemanticFoilImage         |Location of the semantic foil                                                                         |
|Target                    |Word that acted as the target noun                                                                    |
|TargetEnd                 |Time (in ms after target onset) when the target ended                                                 |
|TargetImage               |Location of the target noun                                                                           |
|TargetOnset               |Time (in ms after target onset) when the target noun started                                          |
|Unrelated                 |Word that acted as the unrelated word foil                                                            |
|UnrelatedImage            |Location of the unrelated word foil                                                                   |
|UpperLeftImage            |Filename of the image in the upper left part of the screen                                            |
|UpperLeftImageStimulus    |Type of word (target or foil type) in the upper left part of the screen                               |
|UpperRightImage           |Filename of the image in the upper right part of the screen                                           |
|UpperRightImageStimulus   |Type of word (target or foil type) in the upper right part of the screen                              |

The `Bias` columns refers to a procedure I perform during data reduction
to figure out where the child is look during the onset of the target
noun. I count the number of frames spent on each image during the first
part of the word and figure out which image was fixated most/earliest on
by counting the frames. I didn't use this bias information in this
article.


`gazes_pt1.csv`, `gazes_pt2.csv`
------------------------------------------------------------------------

`gazes_pt1.csv` and `gazes_pt2.csv` contain frame-by-frame output of the
eyetracker. 

Gaze locations are the average of the left and right eyes. The
measurements are in pixels with coordinate (0,0) being the lower-left
corner of the screen.

For file size reasons:

  - Just these few columns are included.
  - Only the frames from -500 to 2500 ms after target onset are
    included.
  - The data is split over two files to avoid GitHub's maximum file
    size.

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
|XMean                     |Pixel location of the gaze's _x_ coordinate.                                                          |
|XMean                     |Pixel location of the gaze's _y_ coordinate.                                                          |
|GazeByImageAOI            |Location of the gaze onscreen, expressed as the type of image.                                        |




`trial_times_1.csv`, `trial_times_2.csv`
------------------------------------------------------------------------

In the manuscript, I report that we had to discard trials from an early
version of the experiment. `trial_times_1.csv` contains event timings
for each trial from the first version, and `trial_times_2.csv` contains
the event times from the revised version of the experiment. These two
files are only used to count the numbers of blocks and trials that had
to be excluded because of the timing error so they do not merit a
codebook. The events names generally map onto columns in `trials.csv`
except that the event times `.OnsetTime` and `.StartTime` are relative
to the start of the experiment.
