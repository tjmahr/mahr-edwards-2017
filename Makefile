.PHONY: clean clean-local-data

# Use this as the command for running R scripts
rscriptv := Rscript --vanilla

# You can write multiple items over multiple lines if you put a \ at the end
chapters = \
	reports/01_abstract.Rmd \
	reports/01_highlights.Rmd \
	reports/02_intro.Rmd \
	reports/03_methods.Rmd \
	reports/04_looks.Rmd \
	reports/05_regressions.Rmd \
	reports/06_prediction.Rmd \
	reports/07_discussion.Rmd \
	reports/08_appendix.Rmd \
	reports/08_acknowledgements.Rmd

report-helpers = R/utils.R reports/_config_plots.yaml $(pandoc-helpers)

pandoc-helpers = \
	reports/assets/strict_tnr_style.docx \
	reports/assets/apa.csl \
	reports/assets/refs.bib \
	reports/assets/github.css

# Define variables using wildcard patterns
waic-results = models/04*.csv

simple-gsv-models = models/01*.rds
t1-gsv-models = models/03*.rds

models-all = $(t1-gsv-models) $(simple-gsv-models)





reports/00_report.md: reports/compile_report.R reports/00_report.Rmd R/clean_md.R
	$(rscriptv) $<

# touch a report file so that it is newer than its requirements
reports/00_report.Rmd: $(chapters) $(report-helpers)
	touch $@

reports/02_intro.Rmd: $(report-helpers)
	touch $@

reports/03_methods.Rmd: data/screening_facts.yaml $(report-helpers)
	touch $@

reports/04_looks.Rmd: data/02_narrowed_scores.csv models/00_gca.RData data/screening_facts.yaml $(report-helpers)
	touch $@

reports/05_regressions.Rmd: data/03_input_vocab_eyetracking.csv data/screening_facts.yaml R/model_utils.R $(simple-gsv-models) $(report-helpers)
	touch $@

reports/06_prediction.Rmd: $(t1-gsv-models) waic both_tests_at_once $(report-helpers)
	touch $@

reports/07_discussion.Rmd: data/screening_facts.yaml $(report-helpers)
	touch $@

reports/08_appendix.Rmd: models/00_gca.RData R/utils.R models_all $(report-helpers)
	touch $@


models_all: $(models-all)
waic: $(waic-results)
both_tests_at_once: models/06_both_tests_at_once.rds



# Create each 04*.csv file by running the corresponding 04*.R file
models/04%.csv: models/04%.R R/utils.R $(models-all)
	$(rscriptv) $<

# Create each 0*.rds file by running the corresponding 0*.R file
models/01%.rds: models/01%.R models/00_priors.R R/model_utils.R data/03_input_vocab_eyetracking.csv
	$(rscriptv) $<

# Create each 0*.rds file by running the corresponding 0*.R file
models/03%.rds: models/03%.R models/00_priors.R R/model_utils.R data/03_input_vocab_eyetracking.csv
	$(rscriptv) $<

models/06_both_tests_at_once.rds: models/06_both_tests_at_once.R data/03_input_vocab_eyetracking.csv
	$(rscriptv) $<



data/03_input_vocab_eyetracking.csv: data/prep_model_data.R data/02_ranefs.csv data/02_narrowed_scores.csv data/constants.yaml
	$(rscriptv) $<

models/00_gca.RData data/02_ranefs.csv: models/00_eyetracking_gca.R data/01_looks.csv data/screening_facts.yaml
	$(rscriptv) $<

data/02_narrowed_scores.csv data/screening_facts.yaml: data/data_screening.R data/constants.yaml data/01_scores.csv data/00_has_eyetracking.csv data/01_looks.csv data/eyetracking_facts.yaml
	$(rscriptv) $<

data/01_looks.csv data/00_has_eyetracking.csv data/eyetracking_facts.yaml: data-raw/compile_eyetracking.R data/constants.yaml data-raw/eyetracking/gazes_pt1.csv data-raw/eyetracking/gazes_pt2.csv data-raw/eyetracking/trial_times_1.csv data-raw/eyetracking/trial_times_2.csv data-raw/eyetracking/administration.csv
	$(rscriptv) $<

data/01_scores.csv: data-raw/get_scores.R
	$(rscriptv) $<

clean:
	rm -f reports/*.html
	rm -f reports/01_*.md
	rm -f reports/02_*.md
	rm -f reports/03_*.md
	rm -f reports/04_*.md
	rm -f reports/05_*.md
	rm -f reports/06_*.md
	rm -f reports/07_*.md
	rm -f reports/08_*.md
	rm -f reports/09_*.md
	rm -f -r reports/0*_files/
	rm -f Rplots.pdf

clean-local-data:
	rm -f data/00_has_eyetracking.csv
	rm -f data/01_looks.csv
	rm -f data/02_*.csv
	rm -f data/03_*.csv
	rm -f data/eyetracking_facts.yaml
	rm -f data/screening_facts.yaml
