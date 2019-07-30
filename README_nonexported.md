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

