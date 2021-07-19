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

lnorm <- Matrix::Diagonal(x = 1 / Matrix::rowSums(dtm))
tf <- lnorm %*% dtm
tf_avg_at_n <- Matrix::colMeans(tf[1:100, ])
btf_avg_at_n <- Matrix::colMeans(dtm_binary[1:100, ])

idf <- log(1 / Matrix::colMeans(dtm_binary))


size <- tf_avg_at_n * idf ^ 1.5
color <- btf_avg_at_n * idf ^ 1.5


words <- names(size)
set.seed(840)
tbl <- tibble(
	word = words,
	size = size,
	color = color
	) %>%
	arrange(desc(size)) %>%
	head(100) %>%
	mutate(rand_angle = -45 + 11.25 * sample(0:8, n(), replace = T)) %>%
	{.}

plot <- ggplot(tbl,
       aes(label = word, size = size
           ,color = color
           ,angle = rand_angle
       )
) +
	geom_text_wordcloud(
		shape = "circle", eccentricity = 1, show.legend = T) +
	theme_minimal() +
	scale_color_gradient(low = "blue", high = "red", guide = "colourbar") +
	labs(size = "tf-idf (avg @ last 100)",
	     color = "tp-idf  (avg @ last 100)",
	     title = "Trending words in hep-ph abstracts",
	     subtitle = paste("Last update:", Sys.Date())
	     )

png("img/cloud.png", width = 680, height = 480, res = 110)
print(plot)
dev.off()
