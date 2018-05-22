# Perform data-screening, keeping note of how many children are excluded at
# each stage.
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(yaml)

constants <- yaml.load_file("./data/constants.yaml")

# LENAs that had long pauses in the middle of the recording
paused_lena <- constants$lena$exclude$timepoint1 %>%
  bind_rows() %>%
  filter(code == "Pause")

# Child refused to wear LENA device
refused_lena <- constants$lena$exclude$timepoint1 %>%
  bind_rows() %>%
  filter(code == "Refuse")

# Children with eyetracking data at year one
with_et <- read_csv("./data/00_has_eyetracking.csv") %>%
  rename(ResearchID = Subj)

# Start with kids with a PPVT and an EVT score at year one
all_scores <- read_csv("./data/01_scores.csv") %>%
  # Keep kids with eyetracking and LENAs
  semi_join(with_et, by = "ResearchID") %>%
  # Keep kids with LENAs
  filter(!is.na(LENA_Hours))

# Exclude kids who are not typically developing
cis <- all_scores %>% filter(CImplant == 1)
lts <- all_scores %>% filter(LateTalker == 1)

td_scores <- all_scores %>%
  anti_join(cis, by = "ResearchID") %>%
  anti_join(lts, by = "ResearchID")

# Kids who have scores at Time 2
returned <- td_scores %>%
  filter(!is.na(PPVT_GSV_T2), !is.na(EVT_GSV_T2))

# Kids with unreliable LENAs
lena_less_than_10_hours <- returned %>%
  filter(LENA_Hours < 10)

lena_refused <- returned %>%
  anti_join(lena_less_than_10_hours, by = "ResearchID") %>%
  filter(ResearchID %in% refused_lena$id)

with_adequate_lenas <- returned %>%
  anti_join(lena_less_than_10_hours, by = "ResearchID") %>%
  anti_join(lena_refused, by = "ResearchID")

# Check that the paused LENAs were excluded by the 10 hour rule
other_excludes <- with_adequate_lenas %>%
  filter(ResearchID %in% paused_lena$id) %>%
  nrow()
stopifnot(other_excludes == 0)

# Number of kids with otherwise complete data but the wrong version of
# eyetracking experiment
num_kids_in_eyetracking_pool <- nrow(td_scores)

# Kids excluded for wrong version
bad_version_of_experiment <- with_et %>%
  semi_join(td_scores, by = "ResearchID") %>%
  filter(HasProtocol1Data, !HasProtocol2Data)

with_correct_version <- td_scores %>%
  anti_join(bad_version_of_experiment, by = "ResearchID")

# Kids with good eyetracking data
good_et <- read_csv("data/01_looks.csv") %>%
  select(ResearchID = Subj) %>%
  distinct()

with_good_et <- with_correct_version %>%
  semi_join(good_et,  by = "ResearchID")

# Kids with only good lenas and good eyetracking
with_reliable_et <- with_adequate_lenas %>%
  semi_join(with_good_et, by = "ResearchID")

# Disclose kids in other paper
in_other_paper <- with_reliable_et %>%
  filter(ResearchID %in% constants$kids_in_other_paper)

# Other bookkeeping about eyetracking
et <- yaml.load_file("data/eyetracking_facts.yaml")

# Blocks dropped, in kids with correct version
blocks_dropped <- et$blocks_dropped_per_child %>%
  as_data_frame() %>%
  rename(ResearchID = Subj) %>%
  semi_join(with_correct_version, by = "ResearchID")

# Who had all their blocks dropped
kids_with_all_blocks_dropped <- blocks_dropped %>%
  filter(AllBlocksDropped)

total_blocks_dropped <- sum(blocks_dropped$NumBadBlocks)
remaining_blocks <- sum(blocks_dropped$NumBlocks) - total_blocks_dropped

# Counts of trials kept vs dropped
trial_exclusions <- et$bad_trials_per_block %>%
  as_data_frame() %>%
  rename(ResearchID = Subj) %>%
  semi_join(with_good_et, by = "ResearchID") %>%
  group_by(BadTrial) %>%
  summarise(Count = sum(n))

trials_left <- trial_exclusions %>%
  filter(!BadTrial) %>%
  getElement("Count")

trials_dropped <- trial_exclusions %>%
  filter(BadTrial) %>%
  getElement("Count")

# One child never had their 24th written to the text file, so we treat it as
# dropped. Assert that this correction is valid. All trials are accounted for.
trials_dropped <- trials_dropped + 1
stopifnot((trials_left + trials_dropped) %% 24 == 0)

# Count the dialects of participants
dialect_count <- with_reliable_et %>% count(AAE)
aae_count <- dialect_count %>% filter(AAE == 1) %>% getElement("n")
mae_count <- dialect_count %>% filter(AAE == 0) %>% getElement("n")

# Count maternal education levels
medu_counts <- with_reliable_et %>%
  count(MatEduCode, MatEdu) %>%
  ungroup()

# Recode 7-point scale to LMH, including less than two years college as "low"
medu_counts$MatEduLMH <- case_when(
  is.na(medu_counts$MatEduCode) ~ "missing",
  medu_counts$MatEduCode < 5  ~ "low",
  medu_counts$MatEduCode == 5 ~ "mid",
  5 < medu_counts$MatEduCode  ~ "high"
)

medu_counts <- medu_counts %>%
  select(MatEduLMH, everything())
medu_counts

# Counts at each of the three levels
medu_lmh_counts <- medu_counts %>%
  group_by(MatEduLMH) %>%
  summarise(n = sum(n))

medu_lmh_counts <- structure(
  .Data = as.list(medu_lmh_counts$n),
  names = medu_lmh_counts$MatEduLMH)

screening_factoids <- list(
  starting = nrow(all_scores),
  cis = nrow(cis),
  lts = nrow(lts),
  returned_to_t2 = nrow(returned),
  inadequate_lenas = nrow(lena_less_than_10_hours),
  refused_lena = nrow(lena_refused),
  with_adequate_lenas = nrow(with_adequate_lenas),
  with_reliable_et = nrow(with_reliable_et),
  n_aae_with_reliable_et = aae_count,
  n_mae_with_reliable_et = mae_count,
  medu_counts_with_reliable_et = medu_lmh_counts,
  unreliable_et = nrow(with_adequate_lenas) - nrow(with_reliable_et),
  in_other_paper = nrow(in_other_paper),
  eyetracking = list(
    n_td_with_lenas_eyetracking = num_kids_in_eyetracking_pool,
    n_with_wrong_eyetracking_exp = nrow(bad_version_of_experiment),
    total_blocks_dropped = total_blocks_dropped,
    n_with_reliable_eyetracking = nrow(with_good_et),
    n_with_unreliable_eyetracking =
      nrow(with_correct_version) - nrow(with_good_et),
    n_addtl_unreliable_trials_dropped = trials_dropped,
    n_remaining_trials = trials_left,
    model_eligible = with_good_et$ResearchID,
    max_missing_data_percent = et$ms$cutoff$value,
    max_unreliable_trial_proportion = et$ms$trial_prop_cutoff$value
  )
)

writeLines(as.yaml(screening_factoids), "data/screening_facts.yaml")
write_csv(with_reliable_et, "data/02_narrowed_scores.csv")
