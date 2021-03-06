#' Compare the communities in a scimeetr object
#'
#' @param sl A list of scimeet object
#' @return A plot, generated from the sankeyNetwork function in the package networkD3
#' @importFrom dplyr %>%
#' @export
#' 
compare_scimap <- function(sl) {
  sli <- NULL
  counter <- 1
  for(i in sl) {
    # Find the dfsci data frame of the lowest coms because the dfsci of the main community would not have the smallest communitiy membership
    com_depth <- stringr::str_count(names(i), '_')
    max_cd <- max(com_depth)
    tmp <- purrr::keep(i, com_depth == max_cd)
    # Bind all the rows of these dfsci together to get a vecteur for recid and for comid
    utv <- purrr::map_df(tmp, 'dfsci') %>%
      dplyr::select(UT)
    dfscisize <- purrr::map(tmp, 'dfsci') %>%
      purrr::map_int(nrow)
    comid <- paste0('l', counter, '__', names(dfscisize))
    comidv <- rep(comid, dfscisize)
    tag <- purrr::map(tmp, 'tag') %>%
      purrr::map_chr(~paste0(.x[1:3], collapse = '_'))
    tagv <- rep(tag, dfscisize)
    dfi <- data.frame(ut = utv$UT,
                      comid = comidv,
                      tag = tagv,
                      stringsAsFactors = F)
    dfi <- list(dfi)
    names(dfi) <- paste0('l', counter)
    sli <- c(sli, dfi)
    counter <- counter + 1
  }
  tmp <- dplyr::full_join(sli$l1, sli$l2, by = 'ut') %>%
    group_by(comid.x, comid.y) %>%
    summarise(value = n(),
              tag.x = unique(tag.x),
              tag.y = unique(tag.y))
  nodes <- data.frame(names = as.character(na.omit(unique(c(tmp$comid.x, tmp$comid.y)))),
                       index = 0:(length(as.character(na.omit(unique(c(tmp$comid.x, tmp$comid.y)))))-1),
                       tags = as.character(na.omit(c(unique(tmp$tag.x), unique(tmp$tag.y)))),
                       stringsAsFactors = F)
  #nodes <- rbind(nodes, c('NA', max(nodes$index)+1, 'NA'))
  tmp <-  dplyr::left_join(tmp, nodes[,1:2], by = c('comid.x' = 'names'))
  tmp <-  dplyr::left_join(tmp, nodes[,1:2], by = c('comid.y' = 'names')) %>%
    dplyr::ungroup()
  links <- na.omit(dplyr::select(tmp, 'source' = index.x, 'target' = index.y,'value' = value))
  #links$source[is.na(links$source)] <- max(nodes$index)
  #links$target[is.na(links$target)] <- max(nodes$index)
  #links$source <- as.integer(links$source)
  #links$target <- as.integer(links$target)
  p <- networkD3::sankeyNetwork(Links = links, Nodes = as.data.frame(nodes),
                     Source = "source", Target = "target",
                     Value = "value", NodeID = "tags",
                     fontSize= 12, nodeWidth = 30)
  return(p)
}
