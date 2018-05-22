# Predict expressive vocabulary at Time 2 including Time 1 scores
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(rstanarm)
library(modelr)

source("./models/00_priors.R")
source("./R/model_utils.R")

d_evt <- read_csv("./data/03_input_vocab_eyetracking.csv")

evt_f_list <- modelr::formulas(
  .response = ~ scale(EVT_GSV_T2),
  t1               = ~ scale(EVT_GSV_T1),
  t1_slope         = ~ scale(EVT_GSV_T1) + scale(ot1),
  t1_input         = ~ scale(EVT_GSV_T1) + scale(AWC_Hourly),
  t1_input_slope   = ~ scale(EVT_GSV_T1) + scale(AWC_Hourly) + scale(ot1),
  t1_input_x_slope = ~ scale(EVT_GSV_T1) + scale(AWC_Hourly) * scale(ot1))

evt_m_list <- modelr::fit_with(
  data = d_evt,
  .f = stan_glm,
  .formulas = evt_f_list,
  family = gaussian(),
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

evt_t2_models <- package_models(
  label = "EVT T2 GSV on T1 GSV, input and processing",
  data = d_evt,
  formulas = evt_f_list,
  models = evt_m_list,
  info = sessioninfo::session_info())

preview_model_list(evt_t2_models)

write_rds_gzip(evt_t2_models, "./models/03a_evt_gsv_with_t1.rds")
