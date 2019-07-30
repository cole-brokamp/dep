#' dep::loy()
#'
#' @details Reads package requirements (including package versions) from a DESCRIPTION file and installs to a project-specific library, `./r-packages/`
#'
#' @param project_root project root folder
#'
#' @return NULL
#' @export
loy <- function(project_root = getwd()) {

  desc_path <- file.path(project_root, "DESCRIPTION")

  if (! file.exists(desc_path)) {
    stop("need a DESCRIPTION file to deploy, create one first with dep::ends()", call. = FALSE)
  }

  ## init Rprofile, init private library, set lib paths
  message("deploying project to\n  ", project_root)
  dir.create(file.path(project_root, "r-packages"),
             recursive = TRUE, showWarnings = FALSE)
  writeLines(deploy_rprofile(),
             con = file.path(project_root, ".Rprofile"))
  source(file.path(project_root, ".Rprofile"))

  ## the below will not install specific versions of packages
  ## it will also not install a package to the project library if it is already installed in the global library
  ## see install_package_versions() below for an alternative approach

  pak::local_install_deps(root = project_root,
                          upgrade = FALSE,
                          lib = .libPaths()[1],
                          ask = interactive())

}

deploy_rprofile <- function(){
  c("# this file was created by `dep::loy()`; please do not edit by hand",
    ".libPaths(unique(c('r-packages', .libPaths())))",
    "if (file.exists('~/.Rprofile')) source('~/.Rprofile')",
    "message('using ./r-packages/ as first package search path')")
}

install_package_versions <- function(deps){

  pkgs <- desc::desc_get_deps('DESCRIPTION')
  pkgs$version <-
    stringr::str_extract(pkgs$version,
                         "([[:digit:]]+[.-]){1,}[[:digit:]]+")
    ## regex taken from `.standard_regexps()$valid_package_version`

  rmts <- desc::desc_get_remotes('DESCRIPTION')

  ## now match remotes to matching packages and make a new column

  ## then, feed this into the appropriate install functions below

  ## all of these takes vector names of packages
  ## what happens when one of them fails?
  remotes::install_version(package, version, upgrade = 'never', quiet = FALSE) # for cran
  remotes::install_github(repo, upgrade = 'never', quiet = FALSE) # username/repo[/subdir][@ref|#pull]
}

nuke <- function(project_root = getwd()){
  unlink(file.path(project_root, ".Rprofile"))
  unlink(file.path(project_root, "r-packages"), recursive = TRUE)
}
