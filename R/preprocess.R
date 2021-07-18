text_preprocess <- function(x) {
	x %>%
		gsub("\\n", " ", .) %>%
		kgrams::preprocess(
			# Remove characters not matched by the regex
			erase = "[^-.?!:;()'[:alnum:][:space:]]",
			# Put everything to lower case
			lower_case = TRUE
		)
}

submitted_preprocess <- function(x) {
	x %>%
		gsub("[A-z]{3}, ", "", .) %>%
		(lubridate::dmy_hms) %>%
		as.character
}
