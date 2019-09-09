#' dep::ends()
#'
#' @details Finds and documents (in a DESCRIPTION file) all R packages required to run all R code in a project.  The version of each package is taken from versions installed in the user's library (.libPaths()) and the current used version of R is also recorded.
#'
#' @param project_root project root folder
#' @param overwrite overwrite an existing DESCRIPTION file?
#'
#' @return NULL; but side effect is the creation of a DESCRIPTION file within the project root folder
#' @export
ends <- function(project_root = getwd(), overwrite = FALSE, ...){
    desc_file <- file.path(project_root, "DESCRIPTION")
    if (file.exists(desc_file)) {
      ## warning("\nDESCRIPTION file already exists; overwriting it\n")
      stop("DESCRIPTION file already exists, rerun with `overwrite = TRUE` to force file creation")
    }
    init_desc(project_root = project_root, ...)
    get_proj_deps(root = project_root) %>%
    purrr::walk(add_dep_to_desc,
                project_root = project_root)
}

#' creates a minimal DESCRIPTION file with defaults taken from the current environment
init_desc <- function(project_root = getwd(),
                      title = basename(getwd()),
                      date = substr(Sys.time(), 1, 10),
                      r_version = getRversion(),
                      ...) {
  desc_path <- file.path(project_root, "DESCRIPTION")
    dsc <- desc::desc(text = "")
    dsc$set(Title = title, Date = date, R.version = r_version, ...)
    dsc$write(desc_path)
}

get_gh_remote <- function(pkg_name){
  dsc <- desc::desc(package = pkg_name)
  github_info <- dsc$get(c("GithubUsername", "GithubRepo"))
  if (any(is.na(github_info))) stop()
  paste(github_info, collapse = "/")
  }

add_dep_to_desc <- function(pkg_name, project_root = getwd()) {
    desc_path <- file.path(project_root, "DESCRIPTION")
    if (! file.exists(desc_path)) {
        stop("need a DESCRIPTION file to deploy, create one first with dep:::init_desc()", call. = FALSE)
    }
    if (! requireNamespace(pkg_name, quietly = TRUE)){
        stop(c(pkg_name, ' must be installed before you can take a dependency on it.'), call. = FALSE)
    }
    pkg_d <- utils::packageDescription(pkg_name)
    is.cran <- !is.null(pkg_d$Repository) && pkg_d$Repository == "CRAN"
    is.github <- !is.null(pkg_d$GithubRepo)
    is.base <- !is.null(pkg_d$Priority) && pkg_d$Priority == "base"

    if (!is.cran & !is.github & !is.base){
      stop("CRAN or GitHub info for ", pkg_name, " not found. Other repositories are currently not supported.",
           call. = FALSE)
    }

    if (is.base) {
      message("ignoring ", pkg_name, " because it will be specified using the version of R")
    }

    ver <- paste("==", packageVersion(pkg_name))
    if (is.cran) remote <- "CRAN"
    if (is.github) remote <- get_gh_remote(pkg_name)
    message("    ", "adding ", pkg_name, " (", ver, ") from ", remote)
    desc::desc_set_dep(pkg_name,
                       type = "Imports",
                       version = ver,
                       file = desc_path)
    if (! remote == "CRAN"){
      existing_remotes <- desc::desc_get_remotes(desc_path)
      remotes <- unique(c(existing_remotes, remote))
      desc::desc_set_remotes(remotes, file = desc_path)
    }
    return(invisible())
}
