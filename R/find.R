#' Get packages required to run all R code in a project
#'
#' @details Finds all R and Rmd files in a project and uses \code{\link{get_deps}}
#'     to find all R packages required for the code to run
#'
#' @param root project root folder to recursively search for R and Rmd files
#'
#' @return a vector of package names
#' @export
get_proj_deps <- function(root = '.') {
    fls <- list.files(path = root,
                      pattern='^.*\\.R$|^.*\\.Rmd$',
                      full.names=TRUE,
                      recursive=TRUE)
    pkg_names <- unlist(purrr::map(fls, get_deps))
    pkg_names <- unique(pkg_names)
    if (length(pkg_names) == 0) {
        warning('no packages found in project')
        return(invisible(NULL))
    }
    return(unname(pkg_names))
}

#' Get packages required to run all R code in a file
#'
#' Parses an R or R Markdown file for the package names that would be required to run the code.
#'
#' @param fl file to parse for required package names
#'
#' @return a vector of package names as character strings
#' @export
#'
#' @details This function uses regular expressions to search through a file
#'   containing R code to find required package names.  It extracts not only
#'   package names denoted by \code{\link[base]{library}} and \code{\link[base]{require}}, but also
#'   packages not attached to the global namespace, but are still called with
#'   \code{\link[base]{::}} or \code{\link[base]{:::}}.
#'
#'   Because it relies on regular expressions, it assumes all packages adhere to
#'   the valid CRAN package name rules (contain only ASCII letters, numbers, and
#'   dot; have at least two characters and start with a letter and not end it a
#'   dot). Code is also tidying internally, making the code more predictable and
#'   easier to parse (removes comments, adds whitespace around operators, etc).
#'   R Markdown files are also supported by extracting only R code using
#'   \code{\link[knitr]{purl}}.
#'
#' @examples \dontrun{
#' cat('library(ggplot2)\n # library(curl)\n require(leaflet)\n CB::date_print()\n',file='temp.R')
#' get_deps('temp.R')
#' unlink('temp.R')
#' }

get_deps <- function(fl){
    lns <- get_lines(fl)
    rgxs <- list(library = '(?<=(library\\()|(library\\(["\']{1}))[[:alnum:]|.]+',
                 require = '(?<=(require\\()|(require\\(["\']{1}))[[:alnum:]|.]+',
                 colon = "[[:alnum:]|.]*(?=:{2,3})")

    found_pkgs <- purrr::map(rgxs, finder, lns = lns)
    found_pkgs <- unique(unlist(found_pkgs))
    found_pkgs <- found_pkgs[! found_pkgs %in% c('', ' ')]
    return(found_pkgs)
}

finder <- function(rgx, lns) unlist(regmatches(lns, gregexpr(rgx, lns, perl = TRUE)))

get_lines <- function(file_name) {
    if (tools::file_ext(file_name) == 'Rmd') {
      rmd_lns <- readLines(file_name)
      tmp.file <- tempfile()
      cat(rmd_chunks(rmd_lns), file = tmp.file)
      file_name <- tmp.file
    }
    lns <- tryCatch(formatR::tidy_source(file_name,
                                         comment = FALSE,
                                         blank = FALSE,
                                         arrow = TRUE,
                                         brace.newline = TRUE,
                                         output = FALSE)$text.mask,
                    error = function(e) {
                        message(paste('Could not parse R code in:', file_name))
                        message('   Make sure you are specifying the right file')
                        message('   and check for syntax errors')
                        stop("", call. = FALSE)
                    })
    if (is.null(lns)) stop('No parsed text available', call. = FALSE)
    return(lns)
}

rmd_chunks <- function(lines) {
  ## From https://github.com/rstudio/rstudio/blob/0edb05f67b4f2eea25b8cfb15f7c64ec9b27b288/src/gwt/acesupport/acemode/rmarkdown_highlight_rules.js#L181-L184
  chunk_start_re <- "^(?:[ ]{4})?`{3,}\\s*\\{[Rr]\\b(?:.*)engine\\s*\\=\\s*['\"][rR]['\"](?:.*)\\}\\s*$|^(?:[ ]{4})?`{3,}\\s*\\{[rR]\\b(?:.*)\\}\\s*$";
  chunk_end_re <- "^(?:[ ]{4})?`{3,}\\s*$"
  chunk_start <- grepl(chunk_start_re, lines, perl = TRUE)
  chunk_end <- grepl(chunk_end_re, lines, perl = TRUE)
  chunk_num <- cumsum(chunk_start)
  in_chunk <- (chunk_num - cumsum(chunk_end)) != 0
  chunks <- split(lines[in_chunk], chunk_num[in_chunk])
  names(chunks) <- NULL
  chunks <- lapply(chunks, function(x) x[-1])
  chunks <- lapply(chunks, paste, collapse = "\n")
  sapply(chunks, function(x) paste0(x, "\n"))
}
