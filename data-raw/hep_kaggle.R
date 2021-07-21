library(dplyr)
library(magrittr)
library(jsonlite)
source("R/preprocess.R")

#-------------------------------------------------- Download dataset from Kaggle

# Download to temporary file
temp <- tempfile()

# Get Kaggle credentials from environment variable or from kaggle.json
if ((kgl_env_var <- Sys.getenv("KAGGLE_API_AUTH")) != "") {
	ll <- strspit(kgl_env_var, ":")
	kgl_creds <- list(user = ll[[1]][[1]], key = ll[[1]][[2]])
} else {
	kgl_creds <- fromJSON("~/.kaggle/kaggle.json", flatten = TRUE)
}

# Download zip as binary (in memory)
base_url <- "https://www.kaggle.com/api/v1"
owner_dataset <- "Cornell-University/arxiv"
file <- "arxiv-metadata-oai-snapshot.json"
url <- paste0(base_url, "/datasets/download/", owner_dataset, "/", file)
response <- httr::GET(url,
	  httr::authenticate(kgl_creds$username, kgl_creds$key, type = "basic")
	  )

# Write binary to zip file
writeBin(httr::content(response, "raw"), temp)
rm(response)

#--------------------------------------------------- Stream arXiv data from JSON

# Read hep-ph entries from JSON stream and store in temporary environment
arxiv_data <- new.env()

tryCatch(
# TODO:
# The tryCatch() here is a temporary fix to deal with corrupt json towards
# the very end of file. Find better solution.
jsonlite::stream_in(
	unz(temp, "arxiv-metadata-oai-snapshot.json"),
	handler = function(df) {
		# Store hep-ph batches in environment
		page_id <- as.character(length(arxiv_data) + 1)
		hep_entries <- grepl(
			pattern = "hep-ph", x = df$categories, fixed = T
			)
		arxiv_data[[page_id]] <- df[hep_entries, ]
		}
	),
error = function(cnd)
	cat("Found corrupt JSON. Some arXiv entries could have been removed.")
)

# Delete temporary file
unlink(temp)

# Convert to list
arxiv_data %<>% as.list()



#--------------------------------------------- Merge data from different batches

# Number of records
n <- sum(sapply(arxiv_data, nrow))

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

tib %<>%
	mutate(title = text_preprocess(title),
	       abstract = text_preprocess(abstract),
	       submitted = submitted_preprocess(submitted)
	       )



#------------------------------------------------------------------ Arrange data

tib %<>%
	arrange(desc(submitted))



#------------------------------------------------------------------- Export data

saveRDS(tib, "data/hep_arxiv.rds")
