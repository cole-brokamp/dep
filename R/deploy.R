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
    stop("no DESCRIPTION file in ", project_root , " to deploy", call. = FALSE)
  }

  ## init Rprofile, init private library, set lib paths
  message("deploying project to:\n", project_root)
  dir.create(file.path(project_root, 'r-packages'), recursive = TRUE, showWarnings = FALSE)

  writeLines(deploy_rprofile(),
             con = file.path(project_root, ".Rprofile"))

  .libPaths(normalizePath(file.path(project_root, 'r-packages'), mustWork = TRUE))
  ## dep:::set_lib_paths(file.path(project_root, "r-packages"))
  message(paste(c('libpaths set to:', .libPaths()), collapse = '\n'))

  ## pak will not install specific versions of packages??
  ## it will also not install a package to the project library if it is already installed in the global library
  ## pak::local_install_deps(root = project_root,
  ##                         upgrade = FALSE,
  ##                         ask = interactive())

  install_package_versions_from_desc(project_root = project_root)

}

#' explicitly set lib path rather than adding to it
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
    "message(paste(c('libpaths set to:', .libPaths()), collapse = '\\n'))")
}

install_package_versions_from_desc <- function(project_root){

  desc_path <- file.path(project_root, "DESCRIPTION")
  pkgs <- desc::desc_get_deps(desc_path)

  pkgs$version <-
    stringr::str_extract(pkgs$version,
                         "([[:digit:]]+[.-]){1,}[[:digit:]]+")
    ## regex taken from `.standard_regexps()$valid_package_version`

  rmts <- desc::desc_get_remotes(desc_path)
  rmts_pieces <- strsplit(rmts, "[/@]")
  rmts_tbl <- tibble(gh_user = map_chr(rmts_pieces, 1),
                     package = map_chr(rmts_pieces, 2),
                     sha1 = map_chr(rmts_pieces, 3))

  pkgs <- left_join(pkgs, rmts_tbl, by = 'package')

  cran_pkgs <- filter(pkgs, is.na(gh_user))
  gh_pkgs <- filter(pkgs, !is.na(gh_user))

  ## cran always gets installed, even if in "base" library
  ## TODO add catch that doesn't install CRAN package if version already exists in "base" library
  ## github will refuse to install if not a newer that what is in "base" library
  install_try_cran <- purrr::safely(.f = remotes::install_version)
  install_try_github <- purrr::safely(.f = remotes::install_github)

  walk2(.x = cran_pkgs$package, .y = cran_pkgs$version,
        ~ {
          message("    **** installing ", .x, " (", .y, ") ****")
          install_try_cran(package = .x,
                           version = .y,
                           upgrade = 'never',
                           repos = getOption('repos'),
                           quiet = FALSE)
        }
        )

  with(gh_pkgs, paste0(gh_user, '/', package, '@', sha1)) %>%
    walk(~ {
            message("    **** installing ", ., " ****")
            install_try_github(., upgrade = 'never', quiet = FALSE)
          }
         )

}

nuke <- function(project_root = getwd()){
  unlink(file.path(project_root, ".Rprofile"))
  unlink(file.path(project_root, "r-packages"), recursive = TRUE)
  unlink(file.path(project_root, "DESCRIPTION"))
}
