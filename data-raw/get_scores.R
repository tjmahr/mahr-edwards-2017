# Download LENA data and vocabulary scores from our lab's database
library(methods)
library(L2TDatabase)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(stringr)
library(readr)
library(lubridate)

# Connect to database
cnf_file <- file.path("~/l2t_db.cnf")

if (!file.exists(cnf_file)) {
  stop("This script requires access to the L2T database")
}

# Download maternal educations
l2t_frontend <- l2t_connect(cnf_file, "l2t")

medu <- suppressWarnings(
  tbl(l2t_frontend, "Scores_TimePoint1") %>%
    select(
      Study, ResearchID, HouseholdID, Maternal_Caregiver,
      Education = Maternal_Education,
      Education_Level = Maternal_Education_Level) %>%
    collect()
)

# Check levels
medu %>%
  count(Education, Education_Level) %>%
  arrange(Education_Level)

medu <- medu %>%
  select(ResearchID, MatEduCode = Education_Level, MatEdu = Education) %>%
  arrange(ResearchID)

# Download test scores
l2t <- l2t_connect(cnf_file, "backend")

# Get kids from the first two study timepoints
tbl_cds <- tbl(l2t, "Child") %>%
  left_join("ChildStudy" %from% l2t, by = "ChildID") %>%
  left_join("Study" %from% l2t, by = "StudyID") %>%
  filter(Study %in% c("TimePoint1", "TimePoint2")) %>%
  rename(ResearchID = ShortResearchID)

# Research IDs
tbl_kids <- tbl_cds %>%
  select(Study, ChildID, ChildStudyID, ResearchID)

# Child demographics
d_demos <- tbl_cds %>%
  select(ResearchID, Female, AAE, LateTalker, CImplant) %>%
  collect() %>%
  distinct()

# Get vocab scores
tbl_evt <- tbl(l2t, "EVT") %>%
  select(ChildStudyID, EVT_Form, EVT_Raw, EVT_Standard, EVT_GSV, EVT_Age)

tbl_ppvt <- tbl(l2t, "PPVT") %>%
  select(ChildStudyID, PPVT_Form, PPVT_Raw, PPVT_Standard, PPVT_GSV, PPVT_Age)

d_scores <- tbl_kids %>%
  left_join(tbl_evt, by = "ChildStudyID") %>%
  left_join(tbl_ppvt, by = "ChildStudyID") %>%
  collect()

# Convert from long to wide format
d_scores <- d_scores %>%
  select(-ChildStudyID, -ChildID) %>%
  gather(Variable, Value, -Study, -ResearchID) %>%
  mutate(Study = str_replace(Study, "TimePoint", "T")) %>%
  unite(Variable_Study, Variable, Study, sep = "_") %>%
  spread(Variable_Study, Value)

# Get LENA data
d_lenas <- tbl(l2t, "LENA_Admin") %>%
  left_join(tbl_kids, by = "ChildStudyID") %>%
  select(ResearchID, LENAID, LENA_Age) %>%
  collect()

# Combine lena tables (hourly data with administration info)
tbl_lena_data <- tbl(l2t, "LENA_Admin") %>%
  left_join("LENA_Hours" %from% l2t, by = "LENAID")

# Keep just hours for timepoint 1 kids and download from db
d_all <- tbl_kids %>%
  inner_join(tbl_lena_data, by = "ChildStudyID") %>%
  filter(Study == "TimePoint1") %>%
  collect()

# Identify recordings that involve more than one date, find hours from second
# date. These are overnight hours (after midnight).
d_hours <- d_all %>%
  select(ResearchID, LENAID, LENAHourID, Hour) %>%
  group_by(LENAID) %>%
  mutate(Date = as.Date(Hour),
         LastDay = max(Date),
         NumDays = length(unique(Date))) %>%
  filter(NumDays != 1, Date == LastDay) %>%
  ungroup() %>%
  arrange(ResearchID, LENAID, Hour)

cat("Hours after midnight: \n")
d_hours %>%
  count(LENAID, ResearchID) %>%
  as.data.frame()

# Exclude the overnight hours
d_all <- d_all %>%
  anti_join(d_hours, by = "LENAHourID")

# View administration notes
d_notes <- d_all %>%
  select(LENAID, LENA_Notes) %>%
  distinct() %>%
  filter(!is.na(LENA_Notes))
# d_notes$LENA_Notes

# Collapse across hours
d_sum <- d_all %>%
  group_by(Study, ResearchID, LENAID) %>%
  summarise_at(vars(Duration:CVC_Actual), funs(sum)) %>%
  ungroup() %>%
  # Create helpful measures
  mutate(Hours = Duration / 3600,
         Prop_Meaningful = Meaningful / Duration,
         Prop_Distant = Distant / Duration,
         Prop_TV = TV / Duration,
         Prop_Noise = Noise / Duration,
         Prop_Silence = Silence / Duration,
         AWC_Hourly = AWC_Actual / Hours,
         CTC_Hourly = CTC_Actual / Hours,
         CVC_Hourly = CVC_Actual / Hours) %>%
  select(-(Duration:CVC_Actual))

cat("Too few hours: \n")
d_sum %>%
  filter(Hours < 10) %>%
  select(Study:Hours) %>%
  as.data.frame()

d_final <- d_sum %>%
  left_join(d_lenas, by = c("ResearchID", "LENAID")) %>%
  select(-LENAID, -Study)

d_export <- d_demos %>%
  left_join(d_scores, by = "ResearchID") %>%
  left_join(d_final, by = "ResearchID") %>%
  rename(LENA_Hours = Hours)

# Attach maternal educations
d_export <- d_export %>%
  left_join(medu) %>%
  type_convert() %>%
  arrange(ResearchID)

# Save entire dataset
d_export %>%
  write_csv("./data/00_all_scores.csv")

# Save scores from participants with EVT or PPVT scores at T1
d_no_scores <- d_export %>%
  filter(is.na(EVT_GSV_T1) | is.na(PPVT_GSV_T1))

cat("No PPVT or no EVT at Time 1: \n")
cat(d_no_scores$ResearchID, fill = TRUE)

d_study_export <- d_export %>%
  anti_join(d_no_scores, by = "ResearchID") %>%
  arrange(ResearchID)

write_csv(d_study_export, "./data/01_scores.csv")
