## We were asked by a reviewer why we didn't control for age. This quick script
## shows that the effects don't change when we try to control for age.

library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
library(readr)
library(rstanarm)
library(modelr)
theme_set(theme_grey())

source("./models/00_priors.R")
source("./R/model_utils.R")


# Quick helper function to fit the same kind of model
my_stan_lm <- function(...) {
  stan_glm(
    ...,
    prior = default_prior,
    prior_intercept = default_intercept,
    family = gaussian())
}

# Get a data-frame of 2 uncertainty intervals and median from a model
double_interval <- function(m) tristan::double_etdi(m, .95, .9)

# Streamlined version of above two
make_intervals <- function(data, formula) {
  data %>%
    my_stan_lm(formula, data = .) %>%
    double_interval()
}

# Read in the raw measures
d <- read_csv("./data/03_input_vocab_eyetracking.csv") %>%
  select(ResearchID, matches("GSV"), matches("Age"),
         matches("Standard"), ot1, AWC_Hourly) %>%
  mutate(Measure = "Raw")

# Control for age in each one
d_residualized <- d %>%
  residualize(EVT_GSV_T2 ~ EVT_Age_T2) %>%
  residualize(EVT_GSV_T1 ~ EVT_Age_T1) %>%
  residualize(PPVT_GSV_T2 ~ PPVT_Age_T2) %>%
  residualize(PPVT_GSV_T1 ~ PPVT_Age_T1) %>%
  residualize(PPVT_Standard_T2 ~ PPVT_Age_T2) %>%
  residualize(PPVT_Standard_T1 ~ PPVT_Age_T1) %>%
  residualize(EVT_Standard_T2 ~ EVT_Age_T2) %>%
  residualize(EVT_Standard_T1 ~ EVT_Age_T1) %>%
  residualize(AWC_Hourly ~ LENA_Age) %>%
  residualize(ot1 ~ EVT_Age_T1) %>%
  mutate(Measure = "Age Adjusted")

d2 <- bind_rows(d, d_residualized)


# Run some visual checks to verify that the transformation worked
d_visual_check <- d2 %>%
  tidyr::gather(Key, Value, -ResearchID, -Measure) %>%
  tidyr::spread(Measure, Value)

ggplot(d_visual_check) +
  aes(x = Raw, y = `Age Adjusted`) +
  geom_point() +
  facet_wrap("Key", scales = "free")

ggplot(d2) +
  aes(x = EVT_Age_T1, y = EVT_GSV_T1, color = Measure) +
  geom_point() +
  stat_smooth(method = "lm") +
  ggtitle("EVT GSV decorrelated with age")

ggplot(d2) +
  aes(x = PPVT_Age_T1, y = PPVT_GSV_T1, color = Measure) +
  geom_point() +
  stat_smooth(method = "lm") +
  ggtitle("PPVT GSV decorrelated with age")



# Fit separate models for the age controlled and raw measures
fit_model_pair <- function(model_name, formula, data = d2) {
  data %>%
    split(.$Measure) %>%
    purrr::map(. %>% make_intervals(formula)) %>%
    bind_rows(.id = "model") %>%
    mutate(Test = model_name)
}

# Fit the model for each outcome measure
evt_gsv_models <- fit_model_pair(
  "EVT GSV",
  scale(EVT_GSV_T2) ~ scale(ot1) * scale(AWC_Hourly) + scale(EVT_GSV_T1))

ppvt_gsv_models <- fit_model_pair(
  "PPVT GSV",
  scale(PPVT_GSV_T2) ~ scale(ot1) * scale(AWC_Hourly) + scale(PPVT_GSV_T1))

evt_std_models <- fit_model_pair(
  "EVT Standard",
  scale(EVT_Standard_T2) ~ scale(ot1) * scale(AWC_Hourly) + scale(EVT_Standard_T1))

ppvt_std_models <- fit_model_pair(
  "PPVT Standard",
  scale(PPVT_Standard_T2) ~ scale(ot1) * scale(AWC_Hourly) + scale(PPVT_Standard_T1))

# Helper to clean up parameter names
clean_names <- . %>%
  stringr::str_replace_all("scale", "") %>%
  stringr::str_replace_all("[()]", "") %>%
  stringr::str_replace_all("[:]", "%*%") %>%
  stringr::str_replace_all("_Hourly", "") %>%
  stringr::str_replace_all("(EVT|PPVT)_GSV_T1", "GSV (T1)") %>%
  stringr::str_replace_all("GSV_T1", "GSV (T1)") %>%
  stringr::str_replace_all("(EVT|PPVT)_Standard_T1", "Standard (T1)") %>%
  stringr::str_replace_all("Standard_T1", "Standard (T1)") %>%
  stringr::str_replace_all("(EVT|PPVT)_Age_T1", "Age (T1)") %>%
  stringr::str_replace_all("ot1", "Processing") %>%
  stringr::str_replace_all(" ", "~") %>%
  # So that sigma doesn't get parsed and converted to the Greek letter
  stringr::str_replace_all("sigma", 'paste("s", "igma")')

# Combine the GSV models
everything <- bind_rows(evt_gsv_models, ppvt_gsv_models) %>%
  mutate(term = stringr::str_replace(term, "PPVT_|EVT_", ""))

# Set the ordering for the parameter names
everything$plot_term <- everything$term %>%
  clean_names() %>%
  # Normally values go up the y axis. We want them to go down so first parameter
  # is on the top of y axis, so we reverse the factor levels.
  factor(., levels = rev(unique(.)))

ggplot(everything %>% filter(term != "(Intercept)", term != "sigma")) +
  aes(x = plot_term, y = estimate,
      color = Test, group = interaction(model, Test)) +
  geom_hline(yintercept = 0, size = 2, color = "white") +
  geom_point(aes(shape = model), position = position_dodge(width = .8), size = 3) +
  geom_linerange(aes(ymin = outer_lower, ymax = outer_upper,
                     group = interaction(model, Test)),
                 position = position_dodge(width = .8), size = .5) +
  geom_linerange(aes(ymin = inner_lower, ymax = inner_upper,
                     group = interaction(model, Test)),
                 position = position_dodge(width = .8), size = 1.5) +
  theme(legend.position = "top", legend.justification	= c(1, 0)) +
  labs(caption = "Point: Median parameter estimate.\nLines: 95% and 90% intervals\nAll measures tranformed to z-scores.",
       x = NULL, y = NULL,
       color = "Outcome", shape = "Model") +
  scale_shape_manual(
    breaks = c("Raw", "Age Adjusted"),
    labels = c("Raw", "Age Adjusted"),
    values = c("Age Adjusted" = 15, "Raw" = 19)) +
  scale_x_discrete(
    breaks = as.character(levels(everything$plot_term)),
    labels = parse(text = as.character(levels(everything$plot_term)))) +
  coord_flip()

ggsave("./models/figs-age-effect/gsv-adjusted-age.png", last_plot(), width = 6, height = 6)


# Same process but for the Standard score models
everything2 <- bind_rows(evt_std_models, ppvt_std_models) %>%
  mutate(term = stringr::str_replace(term, "PPVT_|EVT_", ""))

everything2$plot_term <- everything2$term %>%
  clean_names() %>%
  factor(., levels = rev(unique(.)))

(last_plot() %+% filter(everything2, term != "(Intercept)", term != "sigma")) +
  scale_x_discrete(
    breaks = as.character(levels(everything2$plot_term )),
    labels = parse(text = as.character(levels(everything2$plot_term ))))

ggsave("./models/figs-age-effect/std-adjusted-age.png", last_plot(), width = 6, height = 6)
