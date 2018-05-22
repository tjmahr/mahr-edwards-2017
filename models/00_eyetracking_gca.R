# Fit the model for the eyetracking data
library(methods)
library(readr)
library(dplyr, warn.conflicts = FALSE)
library(lookr)
library(lme4)
library(ggplot2)
library(yaml)
library(polypoly)
library(sessioninfo)

# Load the list of participants that we can include in the model
screening <- yaml.load_file("./data/screening_facts.yaml")
model_eligible <- screening$eyetracking$model_eligible

looks <- read_csv("./data/01_looks.csv", col_types = "cidcidc") %>%
  rename(ResearchID = Subj) %>%
  filter(ResearchID %in% model_eligible) %>%
  rename(Subj = ResearchID)

list(UniqueValuesInModelData = lapply(looks, n_distinct)) %>% str()

binned <- looks %>%
  AggregateLooks(Subj + BinTime ~ GazeByImageAOI) %>%
  tbl_df()

ggplot(binned) +
  aes(x = BinTime, y = Proportion) +
  geom_line(aes(group = Subj), alpha = .2) +
  stat_summary(fun.data = "mean_se", geom = "pointrange")

# Add orthogonal polynomials of time
binned <- binned %>%
  poly_add_columns(BinTime, degree = 3, prefix = "ot", scale_width = 1)

# Fit the model
display <- arm::display
inv_logit <- arm::invlogit

m_ot3 <- glmer(
  cbind(Target, Others) ~ ot1 + ot2 + ot3 + (ot1 + ot2 + ot3 | Subj),
  data = binned,
  family = binomial)
display(m_ot3)

# Save each participant's growth curve values
d_ranefs <- coef(m_ot3) %>%
  getElement("Subj") %>%
  tibble::rownames_to_column("Subj") %>%
  setNames(c("Subj", "Intercept", "ot1", "ot2", "ot3")) %>%
  rename(ResearchID = Subj) %>%
  write_csv("./data/02_ranefs.csv")

gca <- list(
  model = m_ot3,
  data = binned,
  session_info = sessioninfo::session_info())

save(gca, file = "./models/00_gca.RData")
