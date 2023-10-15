test_that("App scaffolding works", {
  expect_equal(run_weather_app(), FALSE)
})

test_that('Stub out shiny being installed', {
  mockery::stub(run_weather_app, 'installed.packages', installed.packages()[rownames(installed.packages())!="shiny",])
  expect_error(run_weather_app(), "Package shiny is needed for this function to work\\. Please install it\\.")
})

test_that('Stub out system.file', {
  mockery::stub(run_weather_app, 'system.file', "")
  expect_error(run_weather_app(), "Could not find weather_app\\. Try re-installing `weathervane`.")
})

