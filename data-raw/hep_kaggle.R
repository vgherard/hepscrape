library(dplyr)
library(magrittr)
if (!require(kaggler)) {
	devtools::install_github("ldurazo/kaggler")
	library(kaggler)
}

#-------------------------------------------------- Download dataset from Kaggle

# Download to temporary file
temp <- tempfile()

kgl_auth(username = "valeriogherardi", key = Sys.getenv("KAGGLE_API_AUTH"))

# Get Goggle Cloud storage URL
response <- kgl_datasets_download_all(owner_dataset = "Cornell-University/arxiv")

# Set timeout to 600 second for large file
options(timeout = max(600, getOption("timeout")))

# Download to temp
download.file(response[["url"]], temp)

#--------------------------------------------------- Stream arXiv data from JSON

# Read hep-ph entries from JSON stream and store in temporary environment
arxiv_data <- new.env()
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

tryCatch(
	source("R/preprocess.R"),
	error = function(cnd) {
		cat("Unable to load 'preprocess.R'. Aborting.")
		quit(save = "no")
	})
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
