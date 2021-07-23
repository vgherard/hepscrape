#---------------------------------------------------- Load dependencies and data

library(aRxiv, warn.conflicts = F, quietly = T)

if (!can_arxiv_connect()) {
	cat("Unable to establish connection with aRxiv API. Aborting.\n")
	quit(save = "no")
}

library(dplyr, warn.conflicts = F, quietly = T)
library(magrittr, warn.conflicts = F, quietly = T)
source("R/preprocess.R")

hep_arxiv <- readRDS("data/hep_arxiv.rds")



#------------------------------------ Select temporal window to look for updates

last_submitted <- as.Date(hep_arxiv$submitted[[1]])
from <- last_submitted - 7
to <- last_submitted + 7



#---------------------------------------------------------------- Form API query

arxiv_query <- function(cat = "cat:hep-ph", from, to) {
	from <- gsub("-", "", as.character(from))
	to <- gsub("-", "", as.character(to))
	paste0(
		cat,
		" AND ",
		"submittedDate:[", from, " TO ", to, "]"
	)
}



#--------------------------------------------------------------- Query arXiv API

res <- arxiv_search(arxiv_query(from = from, to = to), limit = 1000) %>%
	as_tibble() %>%
	select(id, submitted, authors, title, abstract)



#----------------------------------------------------- Discard duplicate records

res %<>%
	filter(grepl("v1", id)) %>%
	mutate(id = gsub("v1", "", id, fixed = T))

res <- anti_join(res, hep_arxiv, by = "id")

if (nrow(res) == 0) {
	cat("No new record found.\n")
	quit(save = "no")
} else {
	cat("Found", nrow(res), "new records. Merging.\n")
}



#---------------------------------------------------------- Preprocess text data

res %<>%
	mutate(title = text_preprocess(title),
	       abstract = text_preprocess(abstract)
	)

#------------------------------------------------------- Merge update to dataset

hep_arxiv <- bind_rows(hep_arxiv, res) %>% arrange(desc(submitted))

#------------------------------------------------------------------ Save to .rds

saveRDS(hep_arxiv, "data/hep_arxiv.rds")

