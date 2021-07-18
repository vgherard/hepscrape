library(aRxiv)
library(text2vec)
#library(data.table)
library(dplyr)
library(magrittr)
#library(dtplyr)
library(ggwordcloud)

hep_arxiv <- readRDS("data/hep_arxiv.rds")

it <- itoken(hep_arxiv$abstract,
	     preprocessor = kgrams::preprocess,
	     tokenizer = word_tokenizer,
	     ids = hep_arxiv$id,
	     progressbar = TRUE
)

vocab <- create_vocabulary(it)
vectorizer <- vocab_vectorizer(vocab)
dtm <- create_dtm(it, vectorizer)
dtm_binary <- dtm > 0
tfidf <- TfIdf$new(smooth_idf = F, norm = "l1")
dtm_tfidf <- fit_transform(dtm, tfidf)
binary_tfidf <- TfIdf$new(smooth_idf = F, norm = "none")
dtm_binary_tfidf <- fit_transform(dtm_binary, binary_tfidf)

tfidf_avg <- Matrix::colMeans(dtm_tfidf[1:100, ])
tf_avg <- Matrix::colMeans(dtm[1:100, ])
binary_tfidf_avg <- Matrix::colMeans(dtm_binary_tfidf[1:100, ])
binary_tf_avg <- Matrix::colMeans(dtm_binary[1:100, ])
words <- dtm_tfidf@Dimnames[[2]]

set.seed(840)
tbl <- tibble(
	word = words,
	size = tfidf_avg,
	color = binary_tfidf_avg
	) %>%
	filter(!(word %in% stopwords::stopwords(source = "smart"))) %>%
	arrange(desc(size)) %>%
	head(100) %>%
	mutate(rand_angle = -45 + 11.25 * sample(0:8, n(), replace = T)) %>%
	#mutate(rand_angle = 90 * sample(0:1, n(), replace = T)) %>%
	{.}

plot <- ggplot(tbl,
       aes(label = word, size = size
           ,angle = rand_angle
           ,color = color
       )
) +
	geom_text_wordcloud(
		shape = "circle", eccentricity = 1, show.legend = T) +
	theme_minimal() +
	scale_color_gradient(low = "blue", high = "red", guide = "colourbar") +
	labs(color = "binary tf-idf  (avg @ last 100)",
	     size = "tf-idf (avg @ last 100)"
	     )

png("img/cloud.png", width = 640, height = 480, res = 110)
print(plot)
dev.off()
