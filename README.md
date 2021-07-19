
<!-- README.md is generated from README.Rmd. Please edit that file -->

# hepscrape

<!-- badges: start -->
<!-- badges: end -->

This repository automatically scrapes [arXiv](https://arxiv.org/) on a
daily basis, for new articles in the hep-ph category (also crossposted).

The resulting dataset is stored in R serialized data format (.rds) in
`data/hep_arxiv.rds`, and is a dataframe with the following fields:

    - id: arXiv unique identifier
    - submitted: date of submission
    - authors
    - title
    - abstract

This dataset is kept up-to-date with the full [arXiv Metadata OAI
Snapshot](https://www.kaggle.com/Cornell-University/arxiv), and it
contains all arXiv:hep-ph records over the last 30 years.

More info coming soon.

![hep-ph word
cloud](https://raw.githubusercontent.com/vgherard/hepscrape/master/img/cloud.png)

Figure: Word cloud from hep-ph abstracts. Words’ character sizes are
proportional to their Term-Frequency - Inverse-Document-Frequency,
whereas color gradients are proportional to Term-Presence -
Inverse-Document-Frequency (a.k.a. binary tf-idf). The `idf` weight is
given by `w = ln (1 / df) ^ 1.5`. Term-frequencies are averaged over the
last 100 arXiv submissions, while Inverse Document Frequencies are
computed from the whole arXiv Metadata OAI Snapshot corpus.
