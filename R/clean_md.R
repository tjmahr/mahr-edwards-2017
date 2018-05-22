## Helper script that fixes APA citations and
## fixes things like "word- learning"

library(stringr)

clean_md_file <- function(file_path) {
  # report
  report <- readr::read_lines(file_path)

  # Ignore the bibliography
  line_references_start <-  report %>%
    str_detect("^References$") %>%
    which()

  # Say the bibliography is last line if it's missing
  if (length(line_references_start) == 0) {
    line_references_start <- length(report)
  }

  main_lines <- report[seq_len(line_references_start)]

  # Ignore lines that aren't prose
  table_lines <- main_lines %>% str_detect("^[|]")
  img_lines <- main_lines %>% str_detect("^[<img]")
  header_lines <- main_lines %>% str_detect("^[-][-]|^[#]")

  do_not_touch <- table_lines | img_lines | header_lines
  lines_to_check <- main_lines[!do_not_touch]

  main_lines[!do_not_touch] <- lines_to_check %>%
    replace_inline_amper() %>%
    replace_hyphen_space()

  report[seq_len(line_references_start)] <- main_lines
  report
}



replace_inline_amper <- function(text) {
  # Assume that an inline citation consists of an author's last name followed by a
  # parenthesized year. If we find those, we fix the inline citations with
  # ampersands.

  # Last names are letters and hyphens and spaces.
  re_author <- "[[:alpha:]- ]+"
  re_inline_year <- "[(]\\d{4}[)]"
  re_author_year <- sprintf("(%s %s)", re_author, re_inline_year)

  # Allow a comma for when 3 or more authors
  re_maybe_comma <- "(,?)"
  re_amper <- "( & )"

  re_ampersand_author_year <- sprintf("%s(?=%s)", re_amper, re_author_year)
  str_replace_all(text, re_ampersand_author_year, " and ")
  # c("Maggie & Lisa (2005) found...",
  #   "...have been found (Maggie & Lisa, 2005)",
  #   "Jones & Hyphen-Name (2005) found...",
  #   "...have been found (Jones & Hyphen-Name, 2005)",
  #   "Marge, Maggie, & Lisa (2005) found...",
  #   "...have been found (Marge, Maggie, & Lisa, 2005)",
  #   "Jones & Space Name (2005) found...",
  #   "...have been found (Jones & Space Name, 2005)") %>%
  #   replace_inline_amper() -> text
}



replace_hyphen_space <- function(text) {
  # text <- c("word- learning", "x- and y- centered", "five- andersons")

  # Use a negative look-ahead to skip "x- and y-examples"
  re_hypen_space <- "(\\w+)- (?!and )(\\w+)"

  text %>%
    str_replace_all(re_hypen_space, "\\1-\\2") %>%
    str_replace_all("\\d- SD", "\\1-SD")
}

# file_path <- "./reports/09_appendix.md"
# stringi::stri_write_lines(clean_md_file(file_path), file_path)
