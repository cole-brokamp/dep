ends <- function(root = ".", force = FALSE, ...){
    descfile <- file.path(root, "DESCRIPTION")
    if (! file.exists(descfile)) {
        init_desc(root = root, ..., force = force)
    }
    ## should there be a message for what deps were found and where they will be added to? (use the rcli package already needed for pak)
    purrr::walk(get_proj_deps(), add_deps_to_desc)
}

#' creates a minimal DESCRIPTION file with defaults taken from the current environment
init_desc <- function(root = ".",
                      force = FALSE,
                      title = basename(getwd()),
                      date = substr(Sys.time(), 1, 10),
                      r_version = with(R.version, paste(major, minor, sep = '.')),
                      ...) {
  if (file.exists(file.path(root, "DESCRIPTION"))) {
    stop("DESCRIPTION file already exists; will not overwrite unless force = TRUE", call. = FALSE)
    }
    dsc <- desc::desc(text = "")
    dsc$set(Title = title, Date = date, R.version = r_version, ...)
    tryCatch(dsc$add_me(role = c("cre", "aut")),
             error = function(e) invisible(NULL))
    descfile <- file.path(root, "DESCRIPTION")
    dsc$write(descfile)
}


## takes version number and remote info from library
## but won't this be a problem if trying to force a re- dep::ends() ??
## should FORCE = TRUE, unset .libPaths()?, we always want to check on package version info from the current library
## BUT, this could be okay because making a desc file after a deploy would be equivalent to relying on a private library (the error that a package must be installed before you can take a dependency on it would be good, because it would force you to install to the private library first).
add_dep_to_desc <- function(pkg_name, root = '.') {
    desc_path <- file.path(root, "DESCRIPTION")
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
    if (!is.cran & !is.github & !is.base)
        stop("CRAN or GitHub info for ", pkg_name, " not found. Other repositories are currently not supported.",
             call. = FALSE)
    ver <- as.character(utils::packageVersion(pkg_name))
    ## will is.base cause problems if I need to specify stats::filter in my code? (for masking reasons)
    if (is.base) stop('Do not specify base packages in your code; specify R version instead', call. = FALSE)
        desc::desc_set_dep(pkg_name,
                           type = "Imports",
                           version = ver,
                           file = root)
    return(invisible())
}

## add_package_to_desc('sf')
## add_package_to_desc('tidyverse')
## add_package_to_desc('CB')
## add_package_to_desc('packageNotHere')

