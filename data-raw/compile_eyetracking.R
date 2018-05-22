# Remove unreliable eyetracking data
library(dplyr, warn.conflicts = FALSE)
library(readr, warn.conflicts = FALSE)
library(stringr)
library(yaml)
library(lookr)

constants <- yaml.load_file("data/constants.yaml") %>%
  getElement("eyetracking")

# Stores facts about the eyetracking data
eyetracking <- list()

# Load eyetracking data.
cols_et <- cols(
  Basename = col_character(),
  TrialNo = col_integer(),
  Time = col_double(),
  XMean = col_double(),
  YMean = col_double(),
  GazeByImageAOI = col_character()
)

# Keep only data in analysis window
gazes <- bind_rows(
  read_csv("data-raw/eyetracking/gazes_pt1.csv", col_types = cols_et),
  read_csv("data-raw/eyetracking/gazes_pt2.csv", col_types = cols_et)) %>%
  select(-XMean, -YMean) %>%
  filter(min(constants$window) <= Time, Time <= max(constants$window))

# Assign frames to bins
times <- gazes %>%
  select(Time) %>%
  distinct() %>%
  mutate(TimeBin = AssignBins(Time, constants$binwidth)) %>%
  group_by(TimeBin) %>%
  mutate(BinTime = round(min(Time), -1)) %>%
  ungroup()

gazes <- gazes %>%
  left_join(times, by = "Time") %>%
  mutate(Subj = str_extract(Basename, "\\d{3}L"),
         Block = str_extract(Basename, "Block\\d"))

# Protocol check
col_times <- cols(
  .default = col_integer(),
  Basename = col_character()
)

# First protocol blocks
d1 <- "data-raw/eyetracking/trial_times_1.csv" %>%
  read_csv(col_types = col_times) %>%
  mutate(Protocol = 1)

# Second protocol blocks
d2 <- "data-raw/eyetracking/trial_times_2.csv" %>%
  read_csv(col_types = col_times) %>%
  mutate(Protocol = 2)

both_protocols <- bind_rows(d1, d2) %>%
  mutate(Subj = str_extract(Basename, "\\d{3}L"),
         Block = str_extract(Basename, "Block\\d"))

# Dates and times of each block
col_admin <- cols(
  Basename = col_character(),
  DateTime = col_datetime(format = ""),
  Subject = col_character(),
  Dialect = col_character()
)

admins <- "./data-raw/eyetracking/administration.csv" %>%
  read_csv(col_types = col_admin)

# Combine names with date-times
blocks <- both_protocols %>%
  select(Protocol, Subj, Block, Basename) %>%
  distinct() %>%
  left_join(admins, by = "Basename")

# Blocks with different protocols
cat("Blocks of each experiment version:\n")
blocks %>%
  group_by(Protocol) %>%
  summarise(n = n(),
            date_min = as.Date(min(DateTime)),
            date_max = as.Date(max(DateTime))) %>% as.data.frame

eyetracking$protocol_counts <- blocks %>%
  count(Protocol) %>%
  as.list()

blocks %>%
  select(Subj, Dialect, Protocol) %>%
  distinct() %>%
  tidyr::spread(., Protocol, Dialect) %>%
  mutate(HasProtocol1Data = !is.na(`1`),
         HasProtocol2Data = !is.na(`2`),
         HasEyetracking = TRUE) %>%
  select(Subj, HasProtocol1Data, HasProtocol2Data, HasEyetracking) %>%
  write_csv("./data/00_has_eyetracking.csv")

# blocks %>%
#   select(Subj, Block, Protocol) %>%
#   distinct() %>%
#   tidyr::spread(., Block, Protocol) %>%
#   write_csv("./data/protocol_summary.csv")

# Don't use Protocol 1 blocks
protocol2_blocks <-  both_protocols %>%
  filter(Protocol == 2) %>%
  select(Subj, Block, Basename, TrialNo) %>%
  distinct()

# Check trials per block and blocks per child
trials_per_block <- protocol2_blocks %>%
  group_by(Subj, Block) %>%
  summarise(n_trials = n())

blocks_per_child <- trials_per_block %>%
  count(Subj)

# Single blockers
single_blockers <- blocks_per_child %>%
  filter(n != 2) %>%
  getElement("Subj")

# Most kids contribute two blocks
children_per_blockcount <- blocks_per_child %>%
  rename(num_blocks = n) %>%
  count(num_blocks)

eyetracking$children_per_blockcount <- children_per_blockcount %>%
  ungroup() %>%
  as.list()

cat("Unrecorded trials:")
trials_per_block %>%
  filter(n_trials != 24) %>%
  as.data.frame() %>%
  as.list() %>%
  str()

# Remove Protocol 1 blocks from gaze dataframe
gazes <- gazes %>%
  semi_join(protocol2_blocks, by = c("Basename"))




## Missing data checks

# Compute amount of missing data per trial
trial_checks <- gazes %>%
  AggregateLooks(Subj + Basename + TrialNo ~ GazeByImageAOI) %>%
  tbl_df() %>%
  mutate(BadTrial = constants$max_prop_na < PropNA)
# trial_checks

# Compute proportion of bad trials in each block
block_check <- trial_checks %>%
  group_by(Subj, Basename) %>%
  summarise(NumTrials = n(),
            NumBadTrials = sum(BadTrial),
            PropBadTrials = mean(BadTrial),
            MeanPropNA = mean(PropNA),
            BadBlock = constants$max_prop_bad_trials < PropBadTrials) %>%
  ungroup()
# block_check

# Record how many blocks per child (and entire children) children have to be
# excluded
bad_blocks_per_child <- block_check %>%
  group_by(Subj) %>%
  summarise(NumBlocks = n_distinct(Basename),
            NumBadBlocks = sum(BadBlock),
            AllBlocksDropped = NumBlocks == NumBadBlocks)
# bad_blocks_per_child
eyetracking$blocks_dropped_per_child <- as.list(bad_blocks_per_child)

# Remove the bad blocks
bad_blocks <- block_check %>% filter(BadBlock)
gazes <- anti_join(gazes, bad_blocks, by = c("Basename", "Subj"))

# Recompute amount of missing data per trial
trial_checks <- gazes %>%
  AggregateLooks(Subj + Basename + TrialNo ~ GazeByImageAOI) %>%
  tbl_df() %>%
  mutate(BadTrial = constants$max_prop_na < PropNA)
# trial_checks

# Count the number of bad trials remaining
eyetracking$bad_trial_counts <- trial_checks %>%
  count(BadTrial) %>%
  as.list()

eyetracking$bad_trials_per_block <- trial_checks %>%
  count(Subj, Basename, BadTrial) %>%
  ungroup() %>%
  as.list()

# Remove the bad trials
bad_trials <- trial_checks %>%
  filter(BadTrial) %>%
  select(Subj, Basename, TrialNo)
gazes <- anti_join(gazes, bad_trials, by = c("TrialNo", "Basename", "Subj"))

gazes <- gazes %>%
  select(-Block) %>%
  arrange(Basename, TrialNo, Time) %>%
  write_csv("./data/01_looks.csv")


## Bundle eyetracking facts for manuscript insertions

eyetracking$ms <- list()

ms_entry <- function(value, note) {
  note <- stringr::str_replace_all(note, "\n", " ")
  note <- stringr::str_replace_all(note, "\\s{2,}", " ")
  list(value = value, note = note)
}

eyetracking$ms$cutoff <- ms_entry(
  value = constants$max_prop_na * 100,
  note = "Maximum percentage of missing data allowed in a trial. Trials with
  more than this amount are unreliable."
)

eyetracking$ms$trial_prop_cutoff <- ms_entry(
  value = constants$max_prop_bad_trials * 100,
  note = "Maximum percentage of unreliable trials allowed in a block. Blocks
  with percentages of unreliable trials larger than this amount are unreliable."
)

as.yaml(eyetracking) %>%
  writeLines("data/eyetracking_facts.yaml")
