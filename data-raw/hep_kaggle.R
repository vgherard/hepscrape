library(dplyr)
library(magrittr)

# TODO:
# Replace local stored data with download from
# https://www.kaggle.com/Cornell-University/arxiv


#--------------------------------------------------- Stream arXiv data from JSON
arxiv_data <- new.env()
x <- jsonlite::stream_in(
	file("data-raw/arxiv-metadata-oai-snapshot.json"),
	handler = function(df) {
		page_id <- as.character(length(arxiv_data) + 1)
		hep_entries <- grepl(
			pattern = "hep-ph", x = df$categories, fixed = T
			)
		arxiv_data[[page_id]] <- df[hep_entries, ]
		}
	)
arxiv_data %<>% as.list()

# Number of records
n <- sum(sapply(arxiv_data, nrow))



#--------------------------------------------- Merge data from different batches

tib <- lapply(arxiv_data, function(df) {
	df %<>%
		as_tibble %>%
		mutate(
			submitted = vapply(versions, function(x){
				res <- x[["created"]][[1]]
				}, FUN.VALUE = "")
			) %>%
		select(id, submitted, authors, title, abstract)
	}) %>%
	bind_rows()



#---------------------------------------------------------------- Transform data

source("R/preprocess.R")
tib %<>%
	mutate(title = text_preprocess(title),
	       abstract = text_preprocess(abstract),
	       submitted = submitted_preprocess(submitted)
	       )



#------------------------------------------------------------------ Arrange data

tib %<>%
	arrange(desc(submitted))



#------------------------------------------------------------------- Export data

saveRDS(tib, "data/hep-arxiv.rds")
