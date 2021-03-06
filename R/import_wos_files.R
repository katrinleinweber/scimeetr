#' Import and Merge Web of Science Files into a Data Frame
#' 
#' This function imports and if there is more than one file in the user selected
#' directory automatically merges Web of Science files. This is all put into a 
#' data frame. Moreover, all duplicated records are automatically removed.
#' 
#' @usage import_wos_files(files_directory)
#' @param files_directory a character vector giving the \bold{folder} path in 
#'   which all the Web of Science files to be imported into a data frame can be 
#'   found. This folder should contain \bold{only} the files to be imported.
#' @details No details for now.
#' @return data frame of 62 columns and a number of row equal to the number of 
#'   unique records.
#' @author Maxime Rivest
#' @examples 
#' \dontrun{Since this example shows how to load WOS from your system we need to run the following line to find the path to the exemple file} 
#' fpath <- system.file("extdata", package="scimeetr") 
#' fpath <- paste(fpath, "/wos_folder/", sep = "") 
#' \dontrun{Then we can run the actual example} 
#' wos_df <- import_wos_files(files_directory = fpath)
#' @seealso \code{\link{scimeetr}} and \code{\link{import_scopus_files}}.
#' @keywords manip
#' @export
#' @import dplyr stringr
import_wos_files <-
function (files_directory) 
{
  dfsci_temp <- NULL
  folder_content <- list.files(files_directory)
  files_quantity <- length(folder_content)
  for (files in 1:files_quantity) {
    full_file_path <- paste(files_directory, folder_content[files], 
                            sep = "")
    if (files == 1) {
      fileName <- full_file_path
      v_char <- suppressWarnings(readLines(full_file_path, encoding = "UTF-8"))
      v_char <- iconv(v_char, from = "UTF-8", to = "ASCII", 
                      sub = "")
      tab_count <- stringr::str_count(v_char[], '\t')
      good_lines <- c(1, which(tab_count == max(tab_count)))
      dfsci <-read.table(text = v_char ,header = T, quote = "",
                         fileEncoding = 'ASCII',
                         row.names = NULL,
                         comment.char = "",
                         stringsAsFactors = F,
                         sep = "\t")
    }
    else {
      fileName <- full_file_path
      v_char <- suppressWarnings(readLines(full_file_path, encoding = "UTF-8"))
      v_char <- iconv(v_char, from = "UTF-8", to = "ASCII", 
                      sub = "")
      tab_count <- stringr::str_count(v_char[], '\t')
      good_lines <- c(1, which(tab_count == max(tab_count)))
      dfsci_temp <-read.table(text = v_char[good_lines] ,header = T, quote = "",
                              fileEncoding = 'ASCII',
                              row.names = NULL,
                              comment.char = "",
                              stringsAsFactors = F,
                              sep = "\t")
      dfsci <- rbind(dfsci, dfsci_temp)
    }
  }
  column_names <- names(dfsci)[-1]
  dfsci <- dfsci[, 1:(ncol(dfsci) - 1)]
  names(dfsci) <- column_names
  dfsci$RECID <- make_recid(dfsci)
  lsci <- list("com1" = list("dfsci" = dfsci[!duplicated(dfsci), ]))
  class(lsci) <- c('scimeetr', class(lsci))
  lsci <- add_table_freq(lsci)
  return(lsci)
}
