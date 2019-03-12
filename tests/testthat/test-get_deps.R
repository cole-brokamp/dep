context("parse_packages")

test_that("parses packages from R code",{
  expect_equal(
    get_deps("r_code.R"),
    paste0('pkg', 1:11)
  )
})
