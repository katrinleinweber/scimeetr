#' Make graph based on coupling
#' 
#' @param biblio_df A data.frame of class scimeetr created from importing files
#' with import_bib_file or a list of class scimeetr created from the 
#' function scimap.
#' @param coupling_by A vector of length one. Equal to either: 
#' 'bc'/'bibliographic coupling', 'kc'/'keyword coupling', 'tc'/'title coupling', 
#' 'ac'/'abstract coupling', 'jc'/'journal coupling', 'ac'/'author coupling'.
#' @return graph object
#' @export
#' @import dplyr 

coupling <- function(dfsci = dfsci, coupling_by = 'bic'){
  # Change factors to characters to allow text manipulation
  for(i in 1:ncol(dfsci)){
    if(is.factor(dfsci[,i])){
      dfsci[,i] <- as.character(dfsci[,i])
    }
  }
  # Switch for coupling options
  if(coupling_by == 'bic'){
    cr_list <- strsplit(dfsci$CR, split="; ")
    names(cr_list) <- dfsci$UT
    crutdf <- data.frame('UT'= rep(names(cr_list), sapply(cr_list, length)), 
                         'CR' = unlist(cr_list),
                         stringsAsFactors=F)
    couple_df <- inner_join(crutdf, crutdf, by = 'CR') %>%
      filter(UT.x > UT.y) %>%
      group_by(UT.x, UT.y) %>%
      summarise(count = n()) %>%
      left_join(dfsci[,c('UT', 'CR')], by = c('UT.x' = 'UT'))%>%
      left_join(dfsci[,c('UT', 'CR')], by = c('UT.y' = 'UT'))%>%
      mutate(NR.x = stringr::str_count(CR.x, "; "),
             NR.y = stringr::str_count(CR.y, "; "),
             w_ij = count/sqrt(NR.x * NR.y)) %>%
      select(UT.x, UT.y, w_ij)
    couple_df$w_ij[couple_df$w_ij == Inf] <- 0
    couple_df <- filter(couple_df, w_ij != 0)
    names(couple_df) <- c("rec1", 
                          "rec2",
                          "weight"
    )
    couple_df <- ungroup(couple_df)
    #missing_df <- data.frame('rec1' = biblio_df$UT[which(!(biblio_df$UT %in% unique(c(couple_df$rec2, couple_df$rec1))))],
     #                        'rec2' = biblio_df$UT[1],
      #                       'weight' = 0,
       #                      stringsAsFactors = F)
    #couple_df <- rbind(couple_df, missing_df)
    graph <- igraph::graph_from_data_frame(d=couple_df, directed= F)
    
  } else if(coupling_by == 'kec'){

    DE_list <- strsplit(dfsci$DE, "[;][ ]")
    names(DE_list) <- dfsci$UT
    deutdf <- data.frame('UT'= rep(names(DE_list), sapply(DE_list, length)), 
                         'KW' =  tolower(unlist(DE_list)),
                         stringsAsFactors=F)

    ID_list <- strsplit(dfsci$ID, "[;][ ]")
    names(ID_list) <- dfsci$UT
    idutdf <- data.frame('UT'= rep(names(ID_list), sapply(ID_list, length)), 
                         'KW' =  tolower(unlist(ID_list)),
                         stringsAsFactors=F)
    
    kwutdf <- rbind(idutdf, deutdf)
    kw_length <- group_by(kwutdf, UT) %>%
      summarize(NK = n())
    couple_df <- inner_join(kwutdf, kwutdf, by = 'KW') %>%
      filter(UT.x > UT.y) %>%
      group_by(UT.x, UT.y) %>%
      summarise(count = n()) %>%
      left_join(kw_length, by = c('UT.x' = 'UT'))%>%
      left_join(kw_length, by = c('UT.y' = 'UT'))%>%
      mutate(w_ij = count/sqrt(NK.x * NK.y)) %>%
      select(UT.x, UT.y, w_ij)
    couple_df$w_ij[couple_df$w_ij == Inf] <- 0
    couple_df <- filter(couple_df, w_ij != 0)
    names(couple_df) <- c("rec1", 
                          "rec2",
                          "weight"
    )
    couple_df <- ungroup(couple_df)
   # missing_df <- data.frame('rec1' = biblio_df$UT[which(!(biblio_df$UT %in% unique(c(couple_df$rec2, couple_df$rec1))))],
    #                         'rec2' = biblio_df$UT[1],
     #                        'weight' = 0,
      #                       stringsAsFactors = F)
   # couple_df <- rbind(couple_df, missing_df)
    graph <- igraph::graph_from_data_frame(d=couple_df, directed= F)
  } else if(coupling_by == 'tic'){
    documents <- tolower(dfsci$TI)
    documents <- tm::Corpus(tm::VectorSource(documents))
    documents <- tm::tm_map(documents, tm::removePunctuation)
    documents <- tm::tm_map(documents, tm::removeNumbers)
    meaningless_word <- c(tm::stopwords("english"), 'use', 'used', 'using', 'uses',
                          'new', 'effect', 'effects', 'affect', 'affects', 'impact',
                          'impacts', 'implication', 'implications', 'potential',
                          'influence', 'influences', 'influenced', 'study', '-',
                          'data', 'can', 'results', 'different', 'similar', 'also',
                          'c', 'may', 'based', 'important', 'within','however',
                          'found', 'analysis', 'changes', 'among', 'large',
                          'number', 'higher', 'well', 'studies', 'total',
                          'increased', 'increases', 'elsevier', 'level', 'many',
                          'rights', 'present', 'will', 'low', 'across', 'showed',
                          'associated', 'approach', 'related', 'provide', 'including',
                          'increase')
    documents <- tm::tm_map(documents, tm::removeWords, meaningless_word)
    myTdm <- tm::DocumentTermMatrix(documents)
    myTdm2 <- tm::removeSparseTerms(myTdm, sparse = 0.99)
    dtm2list <- apply(myTdm2, 1, function(x) {
      paste(rep(names(x), x), collapse=" ")
    })
    TI_list <- strsplit(dtm2list, "[ ]")
    names(TI_list) <- dfsci$UT
    tiutdf <- data.frame('UT'= rep(names(TI_list), sapply(TI_list, length)), 
                         'TI' =  unlist(TI_list),
                         stringsAsFactors=F)
    couple_df <- inner_join(tiutdf, tiutdf, by = 'TI') %>%
      filter(UT.x > UT.y) %>%
      group_by(UT.x, UT.y) %>%
      summarise(count = n()) %>%
      left_join(dfsci[,c('UT', 'TI')], by = c('UT.x' = 'UT'))%>%
      left_join(dfsci[,c('UT', 'TI')], by = c('UT.y' = 'UT'))%>%
      mutate(NR.x = stringr::str_count(TI.x, " "),
             NR.y = stringr::str_count(TI.y, " "),
             w_ij = count/sqrt(NR.x * NR.y)) %>%
      select(UT.x, UT.y, w_ij)
    couple_df$w_ij[couple_df$w_ij == Inf] <- 0
    couple_df <- filter(couple_df, w_ij != 0)
    names(couple_df) <- c("rec1", 
                          "rec2",
                          "weight"
    )
    graph <- igraph::graph_from_data_frame(d=couple_df, directed= F)
    
  } else if(coupling_by == 'abc'){
    documents <- tolower(dfsci$AB)
    documents <- tm::Corpus(tm::VectorSource(documents))
    documents <- tm::tm_map(documents, tm::removePunctuation)
    documents <- tm::tm_map(documents, tm::removeNumbers)
    meaningless_word <- c(tm::stopwords("english"), 'use', 'used', 'using', 'uses',
                          'new', 'effect', 'effects', 'affect', 'affects', 'impact',
                          'impacts', 'implication', 'implications', 'potential',
                          'influence', 'influences', 'influenced', 'study', '-',
                          'data', 'can', 'results', 'different', 'similar', 'also',
                          'c', 'may', 'based', 'important', 'within','however',
                          'found', 'analysis', 'changes', 'among', 'large',
                          'number', 'higher', 'well', 'studies', 'total',
                          'increased', 'increases', 'elsevier', 'level', 'many',
                          'rights', 'present', 'will', 'low', 'across', 'showed',
                          'associated', 'approach', 'related', 'provide', 'including',
                          'increase')
    documents <- tm::tm_map(documents, tm::removeWords, meaningless_word)
    myTdm <- tm::DocumentTermMatrix(documents)
    myTdm2 <- tm::removeSparseTerms(myTdm, sparse = 0.99)
    dtm2list <- apply(myTdm2, 1, function(x) {
      paste(rep(names(x), x), collapse=" ")
    })
    AB_list <- strsplit(dtm2list, "[ ]")
    names(AB_list) <- dfsci$UT
    abutdf <- data.frame('UT'= rep(names(AB_list), sapply(AB_list, length)), 
                         'AB' =  tolower(unlist(AB_list)),
                         stringsAsFactors=F)
    abutdf <- abutdf %>% group_by(UT, AB) %>% summarise()
    couple_df <- inner_join(abutdf, abutdf, by = 'AB') %>%
      filter(UT.x > UT.y) %>%
      group_by(UT.x, UT.y) %>%
      summarise(count = n()) %>%
      left_join(dfsci[,c('UT', 'AB')], by = c('UT.x' = 'UT'))%>%
      left_join(dfsci[,c('UT', 'AB')], by = c('UT.y' = 'UT'))%>%
      mutate(NR.x = stringr::str_count(AB.x, " "),
             NR.y = stringr::str_count(AB.y, " "),
             w_ij = count/sqrt(NR.x * NR.y)) %>%
      select(UT.x, UT.y, w_ij)
    couple_df$w_ij[couple_df$w_ij == Inf] <- 0
    couple_df <- filter(couple_df, w_ij != 0)
    names(couple_df) <- c("rec1", 
                          "rec2",
                          "weight"
    )
    graph <- igraph::graph_from_data_frame(d=couple_df, directed= F)
  } else if(coupling_by == 'joc'){
    
  } else if(coupling_by == 'auc'){
    
  } else if(coupling_by == 'woc'){
    couple_df <- wcoupling()
    graph <- igraph::graph_from_data_frame(d=couple_df, directed= F)
  }
  return(graph)
}