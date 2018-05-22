## A reviewer asked why we adult word counts. This quick script shows how adult
## word count is the most reliable of all the LENA predictors.

library(readr)
library(rstanarm)
library(ggplot2)
library(dplyr)
library(bayesplot)

source("./models/00_priors.R")

d_all <- read_csv("./data/03_input_vocab_eyetracking.csv")

library(recipes)

# When only predictors and outcomes, a simplified formula can be used.
rec <- recipe(d_all) %>%
  add_role(EVT_GSV_T2, PPVT_GSV_T2, new_role = "outcome") %>%
  add_role(contains("Prop_"), new_role = "predictor") %>%
  add_role(CTC_Hourly, AWC_Hourly, new_role = "predictor") %>%
  step_center(all_predictors(), all_outcomes()) %>%
  step_scale(all_predictors(), all_outcomes())
prepped <- prep(rec)

d_model <- bake(prepped, PPVT_GSV_T2, all_predictors(), newdata = d_all)
d2_model <- bake(prepped, EVT_GSV_T2, all_predictors(), newdata = d_all)


library(rstanarm)
m <- stan_glm(
  PPVT_GSV_T2 ~ .,
  family = gaussian(),
  data = d_model,
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

m2 <- stan_glm(
  EVT_GSV_T2 ~ .,
  family = gaussian(),
  data = d2_model,
  prior = default_prior,
  prior_intercept = default_intercept,
  prior_aux = default_error)

prep_fit <- function(m) {
  dfm <- as.data.frame(m) %>%
    select(starts_with("Prop"), ends_with("Hourly")) %>%
    select(one_of(sort(names(.))))

  names(dfm)  <- names(dfm) %>%
    tolower() %>%
    stringr::str_replace("_hourly", "") %>%
    stringr::str_replace("prop_", "Prop. ") %>%
    stringr::str_replace("tv", "TV") %>%
    stringr::str_replace("awc", "Adult word count") %>%
    stringr::str_replace("ctc", "Conv. turn count")
  dfm
}

m_ppvt <- prep_fit(m)
m_evt <- prep_fit(m2)

theme_set(theme_default(base_size = 10))
mcmc_intervals(m_ppvt, prob = .5, prob_outer = .9) +
  labs(caption = "Intervals: Thick 50%, Thin 90%",
       title = "Year 2 PPVT GSV scores regressed on all LENA measures")

mcmc_intervals(m_evt, prob = .5, prob_outer = .9) +
  labs(caption = "Intervals: Thick 50%, Thin 90%",
       title = "Year 2 EVT GSV scores regressed on all LENA measures")

