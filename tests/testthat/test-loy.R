context("depends_and_deploy")

test_that("identifies correct packages in project",{
  expect_equal({
    get_proj_deps(test_path('test_project'))
  },
    c('sf', 'CB', 'tidycensus', 'rize'),
  )
})


test_that("creates correct desc file in project",{
  expect_success({
    setwd(test_path('test_project'))
    ends()
  }
  )
})

test_that("installs the right packages from a desc file",{
  expect_success(
    setwd(test_path('test_project'))
    loy()
    packageVersion('CB')
    packageVersion('tidycensus')
  )
})

nuke(test_path("test_project"))
