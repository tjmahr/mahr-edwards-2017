# Regress lexical processing on language input
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(rstanarm)
library(modelr)

source("./models/00_priors.R")
source("./R/model_utils.R")

d_ot1 <- read_csv("./data/03_input_vocab_eyetracking.csv") %>%
  select(ResearchID, ot1, AWC_Hourly)

ot1_f_list <- modelr::formulas(
  .response = ~ scale(ot1),
  slope_on_input = ~ scale(AWC_Hourly))

ot1_m_list <- modelr::fit_with(
  data = d_ot1,
  .f = stan_glm,
  .formulas = ot1_f_list,
  family = gaussian(),
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

ot1_models <- package_models(
  label = "Processing on input",
  data = d_ot1,
  formulas = ot1_f_list,
  models = ot1_m_list,
  info = sessioninfo::session_info())

preview_model_list(ot1_models)

write_rds_gzip(ot1_models, "./models/01c_slope_on_input.rds")
