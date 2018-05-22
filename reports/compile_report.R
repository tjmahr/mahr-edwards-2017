library(rmarkdown)
source("./R/clean_md.R")

undo_html_sub <- function(xs) {
  str_replace_all(xs, "</?sub>", "~")
}

undo_html_sup <- function(xs) {
  str_replace_all(xs, "</?sup>", "\\^")
}


# Compile the main report into Github-flavored markdown
withr::with_dir("./reports/", {
  render(
    input = "00_report.Rmd",
    output_file = "00_report.md",
    output_format = github_document(
      md_extensions = "-tex_math_single_backslash-hard_line_breaks-autolink_bare_uris",
      pandoc_args = c("--smart")),
    encoding = "utf8"
  )

  # Fix "word- learning" and APA citations
  "00_report.md" %>%
    clean_md_file() %>%
    stringi::stri_write_lines("00_report.md")

})

# Compile the main report into Github-flavored markdown
withr::with_dir("./reports/", {
  render(
    input = "00_report.md",
    output_file = "00_report.html",
    output_format = html_document(
      css = "assets/github.css",
      mathjax = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-MML-AM_CHTML",
      md_extensions = "-tex_math_single_backslash-hard_line_breaks-autolink_bare_uris"
    ),
    encoding = "utf8")
})

# Create the Word version
withr::with_dir("./reports/", {
  # Revert HTML superscript and subscripts back to Pandoc-flavored markdown, so
  # Word conversion goes more smoothly
  "00_report.md" %>%
    readr::read_lines() %>%
    undo_html_sub() %>%
    undo_html_sup() %>%
    stringi::stri_write_lines("00_word_report.md")

  # Need to disable autolink_bare_uris so that
  # "doi:[10.3390/brainsci4040532](https://doi.org/10.3390/brainsci4040532)"
  # and others won't get parsed into URLs.
  render(
    input = "00_word_report.md",
    output_format = word_document(
      reference_docx = "./assets/strict_tnr_style.docx",
      md_extensions = "-tex_math_single_backslash+pipe_tables+hard_line_breaks-autolink_bare_uris"),
    encoding = "utf8"
  )

  file.rename("00_word_report.docx", "00_report.docx")
  file.remove("00_word_report.md")
})


