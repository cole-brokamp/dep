#' dep::ends()
#'
#' @details Finds and documents (in a DESCRIPTION file) all R packages required to run all R code in a project.  The version of each package is taken from versions installed in the user's library (.libPaths()) and the current used version of R is also recorded.
#'
#' @param project_root project root folder
#' @param overwrite overwrite an existing DESCRIPTION file?
#' @param ... further arguments passed to \code{dsc$set}
#'
#' @return NULL; but side effect is the creation of a DESCRIPTION file within the project root folder
#' @export
ends <- function(project_root = getwd(), overwrite = FALSE, ...){
  project_root <- normalizePath(project_root, mustWork = TRUE)
  desc_file <- file.path(project_root, "DESCRIPTION")
  if (file.exists(desc_file)) {
    stop("DESCRIPTION file already exists, rerun with `overwrite = TRUE` to force file creation")
  }
  init_desc(project_root = project_root, ...)
  proj_deps <- get_proj_deps(root = project_root)
  purrr::walk(proj_deps, add, project_root = project_root)
}

#' creates a minimal DESCRIPTION file with defaults taken from the current environment
init_desc <- function(project_root = getwd(),
                      title = basename(project_root),
                      date = substr(Sys.time(), 1, 10),
                      r_version = paste(getRversion(), sep = '.'),
                      ...) {
  desc_path <- file.path(project_root, "DESCRIPTION")
    dsc <- desc::desc(text = "")
    dsc$set(Title = title, Date = date, R.version = r_version, ...)
    dsc$write(desc_path)
}

#' add a dependency
add <- function(pkg_name, project_root = getwd()) {
  project_root <- normalizePath(project_root, mustWork = TRUE)
  desc_path <- file.path(project_root, "DESCRIPTION")

  if (! file.exists(desc_path)) {
    stop("no DESCRIPTION file in ", project_root, call. = FALSE)
  }
  if (! requireNamespace(pkg_name, quietly = TRUE)){
    stop(c(pkg_name, ' must be installed before you can take a dependency on it'), call. = FALSE)
  }

  pkg_d <- utils::packageDescription(pkg_name)
  is_cran <- !is.null(pkg_d$Repository) && pkg_d$Repository == "CRAN"
  is_github <- !is.null(pkg_d$GithubRepo)
  is_base <- !is.null(pkg_d$Priority) && pkg_d$Priority == "base"

  if (!is_cran & !is_github & !is_base){
    stop("CRAN or GitHub info for ", pkg_name, " not found. Other repositories are currently not supported.",
         call. = FALSE)
  }

  if (is_base) {
    message("ignoring ", pkg_name, " because it will be specified using the version of R")
    return(invisible())
  }

  ver <- paste("==", utils::packageDescription(pkg_name)$Version)
  if (is_cran) remote <- get_cran_remote(pkg_name)
  if (is_github) remote <- get_gh_remote(pkg_name)
  message("    ", "adding ", pkg_name, " (", ver, ") from ", remote)

  # add package to desc
  desc::desc_set_dep(pkg_name,
                     type = "Imports",
                     version = ver,
                     file = desc_path)

  # add remote to desc if github
  if (is_github){
    existing_remotes <- desc::desc_get_remotes(desc_path)
    remotes <- unique(c(existing_remotes, remote))
    desc::desc_set_remotes(remotes, file = desc_path)
  }

  return(invisible())
}

#' get remote from package desc file
get_gh_remote <- function(pkg_name){
  dsc <- desc::desc(package = pkg_name)
  paste0(
    dsc$get('GithubUsername'),
    '/',
    dsc$get('GithubRepo'),
    '@',
    dsc$get('GithubSHA1')
  )
}

get_cran_remote <- function(pkg_name){
  dsc <- desc::desc(package = pkg_name)
  cran_info <- dsc$get("RemoteRepos")
  if (any(is.na(cran_info))) cran_info <- "https://cran.rstudio.com"
  paste(cran_info)
}
