`data-raw`
========================================================================

This folder contains scripts for preparing raw data. It also contains
the raw eyetracking data in the subfolder `eyetracking`.

`get_scores.R` downloads child demographics, test scores and LENA data
from our lab's internal database. It cannot be reproduced by people
outside our lab. It is included so that I can reproduce the work of
downloading the data. It also documents the data-reduction steps on the
LENA data. It produces `data/00_all_scores.csv` and `data/01_scores.csv`.

`compile_eyetracking.R` performs data screening on the eyetracking data.
The rules for data screening are stored in `data/constants.yaml`. The
script produces the following the files.

  - `data/00_has_eyetracking.csv`: One row per subject, indicating which
    versions of experiment they had.
  - `data/01_looks.csv`: final eyetracking dataset after excluding
    unreliable trials.
  - `data/eyetracking_facts.yaml`: information about the data exclusions
    it made.


