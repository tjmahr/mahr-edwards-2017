# Predict expressive vocabulary at Time 2
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(rstanarm)
library(modelr)

source("./models/00_priors.R")
source("./R/model_utils.R")

d_evt <- read_csv("./data/03_input_vocab_eyetracking.csv") %>%
  select(ResearchID, EVT_GSV_T2, EVT_GSV_T1, ot1, AWC_Hourly)

evt_f_list <- modelr::formulas(
  .response = ~ scale(EVT_GSV_T2),
  slope         = ~ scale(ot1),
  input         = ~ scale(AWC_Hourly),
  input_slope   = ~ scale(AWC_Hourly) + scale(ot1),
  input_x_slope = ~ scale(AWC_Hourly) * scale(ot1))

evt_m_list <- modelr::fit_with(
  data = d_evt,
  .f = stan_glm,
  .formulas = evt_f_list,
  family = gaussian(),
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

evt_models <- package_models(
  label = "EVT T2 GSV on input and processing",
  data = d_evt,
  formulas = evt_f_list,
  models = evt_m_list,
  info = sessioninfo::session_info())

preview_model_list(evt_models)

write_rds_gzip(evt_models, "models/01a_evt_input_proc.rds")
