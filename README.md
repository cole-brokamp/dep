# dep

> Find, document, and deploy packages that an R project depends on

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental) [![CRAN status](https://www.r-pkg.org/badges/version/dep)](https://cran.r-project.org/package=dep)

`dep` aims to simplify the process of transferring an R project from one computing environment to another by automatically documenting the project's package dependencies in a standard `DESCRIPTION` file and then installing them to a project-specific private library. Some examples of transferring an R project include:

- moving a local R project to a high performance computer
- sending a project to a collaborator
- deploying a Shiny application
- deploying R code to a continuous integration server
- creating a research compendium to ensure the reproducibility of your project
- putting a project into a Docker or Singularity container
- running an R project that contains a data analysis that was originally written three years ago using an older version of R

## Using

From within the project root folder, run:

```r
dep::ends()
```

to search R code within the project to automatically find all R packages that are used, including their repositories and versions, and to store this information in a standard `DESCRIPTION` file. Additionally, the following information is automatically stored in the `DESCRIPTION` file:
    - title as the basename of the working directory
    - current date
    - current version of `R`

After transferring the R project, from within the project root folder, run:

```r
dep::loy()
```

to install packages based on the names, repositories, and versions listed in the `DESCRIPTION` file to a project-specific library in `./r-packages/`. A project-specific `.Rprofile` is also added to make sure that the project-specific library is on the `.libPaths()` each time R is started within the project root directory.

## Installation

`dep` is currently not on CRAN; install the latest version from GitHub with

```r

remotes::install_github('cole-brokamp/dep')
# or equivalently:
# source("https://install-github.me/cole-brokamp/dep")
```

`dep` is currently undergoing development and the API is subject to change. If you are using `dep` for critical projects, you may want to specify a specific version with, e.g. `source("https://install-github.me/cole-brokamp/dep@0.1.1")`.

## An Opinionated Workflow / How This Differs from Similar Packages

- all package dependencies should be evident within the code
- use version numbers and/or GH sha1 strings to specify versions (you *don't* need all packages that you rely on to be available on CRAN *on the same date*)
- uses `DESCRIPTION` files; these are already implemented for R packages, but here we use a lightweight version for R *projects* (already in wide use within R ecosystem, but uses `debian control file` standards)
- `DESCRIPTION` file is calculated from code and not manually edited
- supports CRAN *and* GitHub packages
- each time you run `dep::ends()`, the `DESCRIPTION` file will be overwritten completely (well, at least when `overwrite = TRUE` is supplied)
- keep your DESCRIPTION file under version control! this will allow for quick reverting of the file and easier sharing of projects with colleagues
- all package versions and R version are taken from the current session (package must be installed to take a dependency on it)
- use a global library on your local machine and then use a private library only when deploying
