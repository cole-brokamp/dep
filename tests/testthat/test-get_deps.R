context("parse_packages")

test_that("parses packages from R script",{
  expect_equal(
    get_deps(test_path("r_code.R")),
    paste0('pkg', 1:11)
  )
})

test_that("parses packages from RMarkdown file",{
  expect_equal(
    get_deps(test_path("r_code.Rmd")),
    paste0('pkg', 1:11)
  )
})

test_that("parses packages from directory",{
  expect_equal(
    get_proj_deps(test_path("r_code_dir")),
    paste0('pkg', 1:11)
  )
})
