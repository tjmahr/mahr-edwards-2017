library(readr)
library(dplyr, warn.conflicts = FALSE)
library(yaml)

# Add random effects to test scores
d <- read_csv("./data/02_narrowed_scores.csv")
d_ranefs <- read_csv("./data/02_ranefs.csv")
d <- left_join(d, d_ranefs, by = "ResearchID")

# Check for no scores
d_no_scores <- d %>%
  filter(is.na(EVT_GSV_T1), is.na(PPVT_GSV_T1),
         is.na(PPVT_GSV_T1), is.na(PPVT_GSV_T2))

d %>%
  anti_join(d_no_scores, by = "ResearchID") %>%
  arrange(ResearchID) %>%
  write_csv("./data/03_input_vocab_eyetracking.csv")
