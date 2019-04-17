loy <- function(project_root = getwd()) {

  desc_path <- file.path(project_root, "DESCRIPTION")

  if (! file.exists(desc_path)) {
    stop("need a DESCRIPTION file to deploy, create one first with dep::ends()", call. = FALSE)
  }

  ## init Rprofile, init private library, set lib paths
  ## pak:::proj_create(project_root)
  message("deploying project to\n  ", project_root)
  dir.create(file.path(project_root, "r-packages"),
             recursive = TRUE, showWarnings = FALSE)
  writeLines(pak:::proj_rprofile(),
             con = file.path(project_root, ".Rprofile"))
  ## pak::pak_setup(mode = "auto", quiet = FALSE)
  ## .libPaths()
  .libPaths(unique(c(file.path(project_root, "r-packages"), .libPaths())))
  ## pak::pak_sitrep()
  pak::local_install_deps(project_root,
                          upgrade = FALSE,
                          ask = interactive())
  ## add option to check if all required libraries are avail?
  ## and then error if they are not?
}

nuke <- function(project_root = getwd()){
  unlink(file.path(project_root, ".Rprofile"))
  unlink(file.path(project_root, "r-packages"), recursive = TRUE)
}
