# Predict receptive vocabulary at Time 2
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(rstanarm)
library(modelr)

source("./models/00_priors.R")
source("./R/model_utils.R")

d_ppvt <- read_csv("./data/03_input_vocab_eyetracking.csv") %>%
  select(ResearchID, PPVT_GSV_T2, PPVT_GSV_T1, ot1, AWC_Hourly)

ppvt_f_list <- modelr::formulas(
  .response = ~ scale(PPVT_GSV_T2),
  slope         = ~ scale(ot1),
  input         = ~ scale(AWC_Hourly),
  input_slope   = ~ scale(AWC_Hourly) + scale(ot1),
  input_x_slope = ~ scale(AWC_Hourly) * scale(ot1))

ppvt_m_list <- modelr::fit_with(
  data = d_ppvt,
  .f = stan_glm,
  .formulas = ppvt_f_list,
  family = gaussian(),
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

ppvt_models <- package_models(
  label = "PPVT T2 GSV on input and processing",
  data = d_ppvt,
  formulas = ppvt_f_list,
  models = ppvt_m_list,
  info = sessioninfo::session_info())

preview_model_list(ppvt_models)

write_rds_gzip(ppvt_models, "./models/01b_ppvt_input_proc.rds")
