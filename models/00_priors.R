# Hardcode the priors for the regression models

default_prior <- rstanarm::normal(
  location = 0,
  scale = 1,
  autoscale = FALSE)

default_intercept <- rstanarm::normal(
  location = 0,
  scale = 5,
  autoscale = FALSE)

default_error <- rstanarm::cauchy(
  location = 0,
  scale = 5,
  autoscale = FALSE)
