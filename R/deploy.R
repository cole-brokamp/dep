loy <- function(...) {
    if (! file.exists(file.path(".", "DESCRIPTION"))) {
        stop("need a DESCRIPTION file to deploy, create one first with dep::ends()", call. = FALSE)
    }
    ## init Rprofile, init private library, set lib paths
    pak:::proj_create('.')
    pak::pkg_install(pkg = 'local::.',
                     lib = './r-packages',
                     upgrade = FALSE,
                     ask = interactive(),
                     ...)
}
