# Predict receptive vocabulary at Time 2 including Time 1 scores
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(rstanarm)
library(modelr)

source("./models/00_priors.R")
source("./R/model_utils.R")

d_ppvt <- read_csv("./data/03_input_vocab_eyetracking.csv")

ppvt_f_list <- modelr::formulas(
  .response = ~ scale(PPVT_GSV_T2),
  t1               = ~ scale(PPVT_GSV_T1),
  t1_slope         = ~ scale(PPVT_GSV_T1) + scale(ot1),
  t1_input         = ~ scale(PPVT_GSV_T1) + scale(AWC_Hourly),
  t1_input_slope   = ~ scale(PPVT_GSV_T1) + scale(AWC_Hourly) + scale(ot1),
  t1_input_x_slope = ~ scale(PPVT_GSV_T1) + scale(AWC_Hourly) * scale(ot1))

ppvt_m_list <- modelr::fit_with(
  data = d_ppvt,
  .f = stan_glm,
  .formulas = ppvt_f_list,
  family = gaussian(),
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

ppvt_t2_models <- package_models(
  label = "PPVT T2 GSV on T1 GSV, input and processing",
  data = d_ppvt,
  formulas = ppvt_f_list,
  models = ppvt_m_list,
  info = sessioninfo::session_info())

preview_model_list(ppvt_t2_models)

write_rds_gzip(ppvt_t2_models, "./models/03b_ppvt_gsv_with_t1.rds")
