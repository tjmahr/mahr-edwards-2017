
Research compendium for our article:

Mahr, T., & Edwards, J. R. (2018). **Using language input and lexical processing
to predict vocabulary size**. *Developmental Science*.
doi:[10.1111/desc.12685](https://doi.org/10.1111/desc.12685)


## Repository overview

  - `data-raw` contains our raw eyetracking data and scripts to download
    child-level data and screen the eyetracking data.
  - `data` contains the child-level data at various stages of data
    screening and the final dataset used for the models.
  - `models` contains the scripts to fit all the models in the paper and
    the output of those models.
  - `R` contains various helper scripts.
  - `reports` contains the RMarkdown files used to produce the
    manuscript.

Dependencies among the files are documented in the `Makefile`.

## Tools

This repository works best with a current version of RStudio. Use `New Project >
Version Control > Git > ...` to clone this repository as an RStudio project.
Once it's cloned, the `packrat` bootstrapper will download the packages and
recreate the package library used for this repository. This process takes a
while. 

If you have `make` installed, then `Build > Build All` will compile the report.
Otherwise, run the script `reports/compile_report.R`.

If you have any problems, open an issue on GitHub and I'll see how I can help. 
(I have not tested these steps on a fresh installation of R, so you might 
need help.)

## License

I am not a lawyer, but I would describe the layout of ownership here as
follows: The article is copyrighted by the journal, although it does not
appear in a compiled form in this repository. The R
scripts and RMarkdown files in this repository are the same ones that I
used to produce the article. Thus, a motivated R user could reproduce
the accepted version of the article. This is a good thing because every
single result in the article is reproducible.

For the things that are *not* the article, I would say: The GPL-3
license applies to the R code I have written in the .R and .Rmd files.
The data, collected at the University of Wisconsin–Madison, still belong
to the university. The `packrat` directory contains reference versions 
of the packages I used, so they belong to their creators.

## Citation

Here is the BibTeX entry for the article:

```
@article {Mahr2018,
  title    = {Using language input and lexical processing to predict 
              vocabulary size},
  author   = {Mahr, Tristan and Edwards, Jan R.},
  year     = {2018},
  journal  = {Developmental Science},
  doi      = {10.1111/desc.12685},
  pages    = {e12685},
  url      = {http://doi.org/10.1111/desc.12685},
  abstract = {Children learn words by listening to caregivers, and the 
              quantity and quality of early language input predict later 
              language development. Recent research suggests that word 
              recognition efficiency may influence the relationship between 
              input and vocabulary growth. We asked whether language input 
              and lexical processing at 28–39 months predicted vocabulary 
              size one year later in 109 preschoolers. Input was measured 
              using adult word counts from LENA recordings. We used the 
              visual world paradigm and measured lexical processing as the 
              rate of change in proportion of looks to target. Regression 
              analysis showed that lexical processing did not constrain the 
              effect of input on vocabulary size. We also found that input 
              and processing were more reliable predictors of receptive than 
              expressive vocabulary growth.}
}
```
