# dep

> Find, document, and deploy packages that an R project depends on

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental) [![CRAN status](https://www.r-pkg.org/badges/version/dep)](https://cran.r-project.org/package=dep)

`dep` aims to simplify the process of transferring an R project from one computing environment to another by automatically documenting the project's package dependencies in a standard `DESCRIPTION` file and then installing them to a project-specific private library. Some examples of "transferring" an R project include:

- moving a local R project to a compute server
- sending a project to a collaborator
- deploying a Shiny application to a Shiny server
- deploying R code to a continuous integration server
- creating a research compendium to ensure the reproducibility of your project
- putting a project into a Docker or Singularity container
- running an R project that contains a data analysis that was originally written three years ago using an older version of R

## Using

From within the project root folder, run:

```r
dep::ends()
```

to search R code within the project to automatically find all R packages that are used, including their repositories and versions, and to store this information in a standard `DESCRIPTION` file.

After "transferring" the R project, from within the project root folder, run:

```r
dep::loy()
```

to install packages based on the names, repositories, and versions listed in the `DESCRIPTION` file to a project-specific library in `./r-packages/` using the `pak` package. A project-specific `.Rprofile` is also added to make sure that the project-specific library is on the `.libPaths()` each time R is started within the project root directory.

## Installation

`dep` is currently not on CRAN; install the latest version from GitHub with

```r

remotes::install_github('cole-brokamp/dep')
# or equivalently:
# source("https://install-github.me/cole-brokamp/dep")
```
## Non-Exported Functions

### *Find* packages that a project depends on

- `dep:::get_deps()` to get dependencies from a file
- `dep:::get_proj_deps()` to get dependencies from a project
    - recursively search all files in project
    - deduplicate deps

These can be used if you wish to exclude certain packages from the `DESCRIPTION` file because, for instance, they are expensive to install and can be maintained in the "global" R library, or they might already be included in your base Docker image:

```r
dep:::get_proj_deps() %>%
  filter(...) %>%
  purrr::walk(dep:::add_deps_to_desc)
```

Similarly, you can create a `DESCRIPTION` file for just one file instead of the entire project:

```r
dep:::get_deps('my_code.R') %>%
  dep:::add_deps_to_desc()
```

### *Document* packages that a project depends on

- `dep:::init_desc()` to create a minimal `DESCRIPTION` file
    - default title to the basename of the working directory
    - add current date
    - add version of `R`
    - look for existing `DESCRIPTION` file first and refuse to overwrite (unless `force = TRUE`)
- `dep:::add_deps_to_desc()` to write tibble of package dependencies returned by `dep:::get_deps()` or `dep:::get_proj_deps()` into an existing desc files
    - refuse to do this if the desc file already has deps???

### *Deploy* packages that a project depends on

- `dep:::init_project_library()` to initialize project-specific library
  - ensure `pak` has its library available
  - create `./r-packages/` folder
  - add `/.Rprofile` to ensure its is in `.libPaths()` (and source any superior `.Rprofile files)
  - source `/.Rprofile` to make sure it is usable right away

## Pros

- uses `DESCRIPTION` files; these are already implemented for R packages, but here we will use a lightweight version for R *projects* (already in wide use within R ecosystem, but uses `debian control file` standards)
- relies on `pak` package for fast, cheap package installation
- supports CRAN and GitHub packages

## Cons

- `dep` will not install system dependencies that are required for R packages

## Details

### Package/Project file/folder structure:

```{sh}
DESCRIPTION   # describe project and its dependencies
.Rprofile     # library path setup
r-packages/   # private package library
...           # all other files, e.g. data/, figs/, R/packages
```

### project specific `.Rprofile`:

```{r}
if (file.exists('~/.Rprofile')) source('~/.Rprofile')
dir.create('r-packages', showWarnings = FALSE, recursive = TRUE)
.libPaths(unique(c('r-packages', .libPaths())))
## should there be a message that we are using r-packages within our library paths?
```

### manually editing desc file

- file can always be edited manually and using other R packages for manipulating desc files (`usethis`, `devtools`, etc)
- R still falls back to the "global" library, so some packages that we depend on can be omitted if there are expensive to install and/or do not need to be maintained in a private library
- docker / singularity (can go in and edit out deps that are included in your base image)
- should always specify a package greater than or equal to a version (unless you know better, specify with `exact_version = TRUE`

### tips

- keep your DESCRIPTION file under version control! this will allow for quick reverting of the file and easier sharing of projects with colleagues
- it isn't necessary to use project versions in the `DESCRIPTION` file; you can use Git tags/releases because the project can be under version control (but should we really do this automatically? or how can this field by automatically updated after a new tag is created?)

## More Information

- https://github.com/r-lib/desc
- https://github.com/benmarwick/rrtools
- https://github.com/karthik/holepunch
- https://github.com/hadley/requirements
- https://github.com/karthik/rstudio2019
- https://github.com/cole-brokamp/CB/blob/master/DESCRIPTION
- http://r-pkgs.had.co.nz/description.html
- https://www.rdocumentation.org/packages/usethis/versions/1.4.0/topics/use_description
- https://install-github.me/r-lib/pkg
- https://resources.rstudio.com/rstudio-conf-2019/it-depends-a-dialog-about-dependencies
