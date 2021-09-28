N <- 1e4

m <- word2vec::word2vec(hep_arxiv$abstract[1:N])
emb <- as.matrix(m)

d <- dist(emb)
x <- hclust(d)

clusters <- cutree(x, k = 3)

names(clusters[clusters == 3])
