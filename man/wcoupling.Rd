% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/word_coupling.R
\name{wcoupling}
\alias{wcoupling}
\title{Word coupling}
\usage{
wcoupling(dfsci, kw = 5, ti = 3, ab = 2)
}
\arguments{
\item{dfsci}{a dataframe that resides within a community within a scimeetr object}
}
\value{
data frame of 62 columns and a number of row equal to the number of 
  unique records.
}
\description{
This function make an adjencency table that is a combination of kw, ti ,ab words.
}
\details{
No details for now.
}
\examples{
wcoupling(scimeetr_list$com1$dfsci, kw = 2, ti = 1 ab = 1)
}
\author{
Maxime Rivest
}
