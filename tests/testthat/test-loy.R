context("depends_and_deploy")

test_that("identifies correct packages in project",{
  expect_equal({
    get_proj_deps(test_path('test_project'))
  },
    c('sf', 'CB', 'tidycensus', 'rize'),
  )
})


## test_that("creates correct desc file in project",{
##   expect_success({
##     dep::ends(project_root = test_path("test_project"))
##   }
##   )
## })

## test_that("installs the right packages from a desc file",{
##   expect_success(
##     dep::loy(test_path("test_project"))
##   )
## })
