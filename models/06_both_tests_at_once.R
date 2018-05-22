# Compare the effects between the two tests
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(rstan)
library(brms)

d_all <- read_csv("./data/03_input_vocab_eyetracking.csv")

# Standardize all measures
scale_v <- function(...) as.vector(scale(...))
d_all$zEVT_GSV_T1 <- scale_v(d_all$EVT_GSV_T1)
d_all$zEVT_GSV_T2 <- scale_v(d_all$EVT_GSV_T2)

d_all$zPPVT_GSV_T1 <- scale_v(d_all$PPVT_GSV_T1)
d_all$zPPVT_GSV_T2 <- scale_v(d_all$PPVT_GSV_T2)

d_all$zot1 <- scale_v(d_all$ot1)
d_all$zAWC_Hourly <- scale_v(d_all$AWC_Hourly)

# Use the mvbf() feature of brms to combine formulas with different y's
bf_exp <- bf(zEVT_GSV_T2 ~ zEVT_GSV_T1 + zot1 * zAWC_Hourly)
bf_rec <- bf(zPPVT_GSV_T2 ~ zPPVT_GSV_T1 + zot1 * zAWC_Hourly)
bf_both <- mvbf(bf_exp, bf_rec, rescor = TRUE)

model <- brm(
  formula = bf_both,
  data = d_all,
  family = gaussian(),
  prior = c(
    prior(normal(0, 1), class = b),
    prior(normal(0, 5), class = Intercept),
    prior(cauchy(0, 5), class = sigma, resp = zEVTGSVT2),
    prior(cauchy(0, 5), class = sigma, resp = zPPVTGSVT2),
    prior(lkj(2), class = rescor))
)

write_rds(model, "./models/06_both_tests_at_once.rds")
