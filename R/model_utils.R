## Helper functions for the modeling stage of the analysis

# Residualize a variable y with a linear model y ~ x. Returns an updated copy of
# data where y is overwritten with the residuals from lm(y ~ x).
residualize <- function(data, f) {
  # Capture y variable as a valid column name.

  # Not using as.character() because it returns a vector for more complex y's
  #   as.character(rlang::f_rhs(~ scale(y)))
  #   #> [1] "scale" "y"
  y_name <- rlang::expr_text(rlang::f_lhs(f))

  modelr::add_residuals(data, lm(f, data), y_name)
}

# Save an R object to a compressed RDS file. (Open with readRDS() or
# readr::read_rds())
write_rds_gzip <- function(x, path) {
  saveRDS(x, file = path, compress = "gzip")
  invisible(x)
}

# Package a list of models built from a shared data-set together
package_models <- function(data, models, formulas, label, info = NULL) {
  # Rough check that all models have same number of observations
  nobs_data <- nrow(data)
  nobs_models <- vapply(models, stats::nobs, 1)
  stopifnot(all(nobs_models == nobs_data))

  list(
    data = data,
    models = models,
    formulas = formulas,
    label = label,
    info = info)
}

# Print out a glance-view of the objects in a packaged model list
preview_model_list <- function(x, ...) {
  to_char <- function(f) {
    sprintf(
      "%s %s %s", as.character(f)[2], as.character(f)[1], as.character(f)[3])
  }

  # Print the description
  l1 <- sprintf("Model set: %s\n", x$label)

  # Add padding to make formulas line up
  lengths <- nchar(names(x$formulas))
  padding <- Map(function(x) rep(" ", x), max(lengths) - lengths) %>%
    lapply(paste0, collapse = "") %>%
    unlist()

  l_rest <- Map(
    function(x, s, y) sprintf("%s%s: %s\n", s, x, to_char(y)),
    names(x$formulas), padding, x$formulas) %>%
    unlist()
  cat(l1, l_rest)
  invisible(x)
}
