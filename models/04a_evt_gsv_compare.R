# Run a WAIC model comparison on the EVT GSV models
library(dplyr, warn.conflicts = FALSE)
library(rstanarm)
source("./R/utils.R")

target_csv <- "./models/04a_evt_gsv_compare.csv"

# Load the models
simple_evt <- readRDS("./models/01a_evt_input_proc.rds")
t2_evt <- readRDS("./models/03a_evt_gsv_with_t1.rds")
models <- c(simple_evt$models, t2_evt$models)

# Make a dataframe with the names and description of the models
model_set <- data_frame(
  Model = names(models),
  Predictors = models %>% get_predictors() %>% create_prose_predictors())

# Compute WAICs
waics <- Map(waic, models)
comparison <- loo::compare(x = waics)

# Compute weights and format table
comparison %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Model") %>%
  mutate(
    weight = exp(elpd_waic) / sum(exp(elpd_waic)),
    weight = round(weight, 3)) %>%
  mutate_at(vars(-Model, -weight), funs(round(., 1))) %>%
  left_join(model_set, by = "Model") %>%
  select(Model, Predictors, everything()) %>%
  readr::write_csv(target_csv)
