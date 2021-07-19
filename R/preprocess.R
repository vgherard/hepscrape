library(reticulate, warn.conflicts = F, quietly = T)
library(dplyr)
reticulate::use_condaenv()
latex2text <- reticulate::import("pylatexenc.latex2text")
decode_latex <- function(x) {
	try(x <- latex2text$latex2text(x, tolerant_parsing = T), silent = T)
	x
	}

text_preprocess <- function(x) {
	x %>%
		vapply(decode_latex, "", USE.NAMES = F) %>%
		gsub("\\n", " ", .) %>%
		# Remove punctuation
		gsub("[.,!?;:]", " ", .) %>%
		tolower
}

submitted_preprocess <- function(x) {
	x %>%
		gsub("[A-z]{3}, ", "", .) %>%
		(lubridate::dmy_hms) %>%
		as.character
}
