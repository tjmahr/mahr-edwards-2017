## Helper functions for formatting/printing values




## Formatting Helpers ---------------------------------------------------------

divide_by <- magrittr::divide_by
round2 <- function(xs) round(xs, 2)
fixed2 <- function(xs) printy::fmt_fix_digits(xs, 2)

mean_center <- function(x) scale(x, center = TRUE, scale = FALSE)

# Format cells in a correlation matrix
format_cor <- . %>%
  printy::fmt_leading_zero() %>%
  printy::fmt_minus_sign() %>%
  printy::fmt_replace_na(replacement = "&nbsp;")

round2_leading_minus <- . %>%
  round2() %>%
  printy::fmt_minus_sign()

fixed2_leading_minus <- . %>%
  printy::fmt_fix_digits(2) %>%
  printy::fmt_minus_sign()


# Combine two numbers to make a confidence interval c(0, 1) -> "0, 1"
ci_string <- function(xs, fun_format = fixed2_leading_minus) {
  stopifnot(length(xs) == 2)
  xs <- fun_format(sort(xs)) %>% printy::fmt_minus_sign()
  sprintf("%s, %s", xs[1], xs[2])
}

map_ci_string <- function(xs, ys, ...) {
  Map(function(xs, ys) ci_string(c(xs, ys), ...), xs, ys) %>% unlist()
}


# Is x[n] the same as x[n-1]
is_same_as_last <- function(xs) {
  same_as_last <- xs == lag(xs)
  # Overwrite NA (first lag) from lag(xs)
  same_as_last[1] <- FALSE
  same_as_last
}

replace_same_as_last <- function(xs, replacement = "") {
  xs[is_same_as_last(xs)] <- replacement
  xs
}

pretty_eq <- function(lhs, rhs, html = TRUE) {
  eq <- ifelse(html, "&nbsp;= ", " = ")
  paste0(lhs, eq, rhs)
}

# general subscript
x_sub <- function(x, sub) {
  sprintf("%s~%s~", x, sub)
}

# coefficient subscript
b_sub <- function(sub) {
  x_sub("*&beta;*", sub)
}

r2 <- function(x) {
  pretty_eq("*R*^2^", printy::fmt_leading_zero(x))
}




## lme4 Helpers ---------------------------------------------------------------

tidy_lme4_variances <- . %>%
  VarCorr() %>%
  as.data.frame() %>%
  filter(is.na(var2)) %>%
  select(-var2)

tidy_lme4_covariances <- . %>%
  VarCorr() %>%
  as.data.frame() %>%
  filter(!is.na(var2))

# Create a data-frame with random effect variances and correlations
tidy_ranef_summary <- function(model) {
  vars <- tidy_lme4_variances(model)
  cors <- tidy_lme4_covariances(model) %>% select(-vcov)

  # Create some 1s for the diagonal of the correlation matrix
  self_cor <- vars %>%
    select(-vcov) %>%
    mutate(var2 = var1, sdcor = 1.0) %>%
    na.omit()

  # Spread out long-from correlations into a matrix
  cor_matrix <- bind_rows(cors, self_cor) %>%
    mutate(sdcor = printy::fmt_fix_digits(sdcor, 2)) %>%
    tidyr::spread(var1, sdcor) %>%
    rename(var1 = var2)

  left_join(vars, cor_matrix, by = c("grp", "var1"))
}

# Sort random effects groups, and make sure residual comes last
sort_ranef_grps <- function(df) {
  residual <- filter(df, grp == "Residual")
  df %>%
    filter(grp != "Residual") %>%
    arrange(grp) %>%
    bind_rows(residual)
}

format_fixef_num <- . %>%
  printy::fmt_fix_digits(2) %>%
  printy::fmt_minus_sign()




## Stan Helpers ---------------------------------------------------------------

# Create a function to unscale a variable
make_rescaler <- function(xs) {
  mean_xs <- mean(xs)
  sd_xs <- sd(xs)
  function(x, add_mean = FALSE) {
    unscaled <- x * sd_xs
    unscaled <- if (add_mean) unscaled + mean_xs else unscaled
    round(unscaled, 2)
  }
}

get_intervals <- function(model, parameters = NULL, prob = .95,
                          fun_format = printy::fmt_fix_digits) {
  interval <- posterior_interval(model, prob, pars = parameters)
  as.list(apply(interval, 1, ci_string, fun_format))
}

get_coefs <- function(model, parameter, fun_format = round2) {
  as.list(fun_format(coef(model)[parameter]))
}

get_coefs_raw <- function(...) {
  get_coefs(..., fun_format = I)
}

fast_r2 <- function(model) {
  ssr <- var(residuals(model))
  sst <- var(model$y)
  r2 <- 1 - (ssr / sst)
  printy::fmt_fix_digits(r2, 3)
}

tidy_hpdi <- function(xs, prob = .95) {
  xs %>%
    coda::as.mcmc() %>%
    coda::HPDinterval(prob) %>%
    as.data.frame %>%
    tibble::rownames_to_column("Variable") %>%
    tibble::as_tibble() %>%
    mutate(Level = prob) %>%
    select(Level, Variable, lower, upper)
}

estimate_interval <- function(xs, interval_width = .95) {
  alpha <- (1 - interval_width) / 2
  probs <- c(alpha, 1 - alpha)
  quantile(xs, probs = probs)
}

# Get proportion of posterior samples satisfying some inequality
posterior_proportion <- function(model, inequality) {
  draws <- as.data.frame(model)
  mean(lazyeval::f_eval(inequality, draws))
}

# Get the predictors from each model
get_predictors <- . %>%
  Map(formula, .) %>%
  Map(function(x) x[[3]], .) %>%
  as.character()




## Manuscript Helpers ---------------------------------------------------------

# Create a prose version of each formula
create_prose_predictors <- . %>%
  stringr::str_replace_all("(\\S+) [*] (\\S+)", "\\1 + \\2 + (\\1 x \\2)") %>%
  stringr::str_replace_all("scale[(]\\w+_GSV_T1[)]", "T1") %>%
  stringr::str_replace_all("scale[(]ot1[)]", "Processing") %>%
  stringr::str_replace_all("scale[(]AWC_Hourly[)]", "Input")

# Create a math-prose version of each formula
create_math_predictors <- function(xs, vocab_type = "expressive",
                                   exp_t1 = "ExpTime1", rec_t1 = "RecTime1") {
  t1 <- ifelse(vocab_type == "expressive", exp_t1, rec_t1)
  emph_t1 <- paste0("_", t1, "_")

  xs %>%
    create_prose_predictors() %>%
    stringr::str_replace_all("sigma", "_&sigma;_") %>%
    stringr::str_replace_all(".Intercept.", "_&alpha;_") %>%
    stringr::str_replace_all("^T1$", x_sub("_&beta;_", emph_t1)) %>%
    stringr::str_replace_all("Input", x_sub("_&beta;_", "_Input_")) %>%
    stringr::str_replace_all("Processing", x_sub("_&beta;_", "_Processing_"))
}

infer_prior_class <- function(x) {
  if ("prior_scale_for_dispersion" %in% names(x)) {
    class(x) <- c("halfcauchy", class(x))
  }

  if ("dist" %in% names(x)) {
    class(x) <- c(x$dist, class(x))
  }

  x
}

express_prior <- function(x) {
  UseMethod("express_prior")
}

express_prior.default <- function(x) {
  NA_character_
}

express_prior.normal <- function(x) {
  scale <- if (is.null(x$scale)) "default" else x$scale
  sprintf("Normal(%s, %s)", x$location, x$scale)
}

express_prior.halfcauchy <- function(x) {
  scale <- if (is.null(x$scale)) "default" else x$scale
  sprintf("HalfCauchy(%s, %s)", 0, x$prior_scale_for_dispersion)
}
