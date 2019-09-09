#' dep::loy()
#'
#' @details Reads package requirements (including package versions) from a DESCRIPTION file and installs to a project-specific library, `./r-packages/`
#'
#' @param project_root project root folder
#'
#' @return NULL
#' @export
loy <- function(project_root = getwd()) {

  project_root <- normalizePath(project_root, mustWork = TRUE)

  desc_path <- file.path(project_root, "DESCRIPTION")

  if (! file.exists(desc_path)) {
    stop("cannot find a DESCRIPTION file to deploy", call. = FALSE)
  }

  ## init Rprofile, init private library, set lib paths
  message("deploying project to\n  ", project_root)
  dir.create(file.path(project_root, 'r-packages'), recursive = TRUE, showWarnings = FALSE)

  writeLines(deploy_rprofile(),
             con = file.path(project_root, ".Rprofile"))

  .libPaths(normalizePath(file.path(project_root, 'r-packages'), mustWork = TRUE))
  ## dep:::set_lib_paths(file.path(project_root, "r-packages"))

  ## the below will not install specific versions of packages
  ## it will also not install a package to the project library if it is already installed in the global library
  ## see install_package_versions() below for an alternative approach

  pak::local_install_deps(root = project_root,
                          upgrade = FALSE,
                          lib = .libPaths()[1],
                          ask = interactive())

}

set_lib_paths <- function(lib_vec) {
  lib_vec <- normalizePath(lib_vec, mustWork = TRUE)
  shim_fun <- .libPaths
  shim_env <- new.env(parent = environment(shim_fun))
  shim_env$.Library <- character()
  shim_env$.Library.site <- character()
  environment(shim_fun) <- shim_env
  shim_fun(lib_vec)
  message(".libPaths now set to ", .libPaths())
}

deploy_rprofile <- function(){
  c("# this file was created by `dep::loy()`; please do not edit by hand",
    "## dep:::set_lib_paths('r-packages')",
    ".libPaths(normalizePath('r-packages', mustWork = TRUE))",
    "if (file.exists('~/.Rprofile')) source('~/.Rprofile')",
    "message(paste('libpaths set to: ', .libPaths(), sep = '\n'))")
}

install_package_versions_from_desc <- function(project_root){

  desc_path <- file.path(project_root, "DESCRIPTION")
  pkgs <- desc::desc_get_deps(desc_path)

  pkgs$version <-
    stringr::str_extract(pkgs$version,
                         "([[:digit:]]+[.-]){1,}[[:digit:]]+")
    ## regex taken from `.standard_regexps()$valid_package_version`

  rmts <- desc::desc_get_remotes(desc_path)
  rmts_pieces <- strsplit(rmts, "/", fixed = TRUE)
  rmts_tbl <- tibble(gh_user = map_chr(rmts_pieces, 1),
                     package = map_chr(rmts_pieces, 2))

  pkgs <- left_join(pkgs, rmts_tbl, by = 'package')

  cran_pkgs <- filter(pkgs, is.na(gh_user))
  gh_pkgs <- filter(pkgs, !is.na(gh_user))

  walk2(.x = cran_pkgs$package, .y = cran_pkgs$version,
        ~ remotes::install_version(package = .x,
                                   version = .y,
                                   upgrade = 'never',
                                   quiet = FALSE))

  remotes::install_version('sf', '0.7-3', type = 'source', upgrade = 'never', quiet = TRUE)
  remotes::install_version('tidycensus', '0.9.2', type = 'source', upgrade = 'never')


  devtools:::package_find_repo('sf', 'https://cran.rstudio.com') %>%
    as_tibble() %>%
    select(path) %>%
    tail()




  ## all of these takes vector names of packages
  ## what happens when one of them fails?
  remotes::install_version(package, version, upgrade = 'never', quiet = FALSE) # for cran
  remotes::install_github(repo, upgrade = 'never', quiet = FALSE) # username/repo[/subdir][@ref|#pull]
}

nuke <- function(project_root = getwd()){
  unlink(file.path(project_root, ".Rprofile"))
  unlink(file.path(project_root, "r-packages"), recursive = TRUE)
  unlink(file.path(project_root, "DESCRIPTION"))
}
