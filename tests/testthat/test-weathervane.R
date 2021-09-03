# Unit tests for the weathervane package functions (not including
# the accompanying Shiny app).
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson
# Date last modified: 20/08/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au


# Test cases for the weather variables list function ###########################
context('Tests for weather_variables()')

test_that('blah', {
  expect_equal(2, 2)
})

# Test cases for the main weather retrieval interface ##########################
context('Tests for get_weather_data()')

test_that('blah', {
  expect_equal(2, 2)
})

# Test cases for the main weather data download function #######################
context('Tests for download_data()')

test_that('blah', {
  expect_equal(2, 2)
})


# Test cases for the URL constructor ###########################################
# Note that no error checking happens during the construction of
# the download URL in this function. It is expected that the
# latitudes, longitudes, dates and variables list will all be
# sanity-checked before this function is called, and garbage in
# begets garbage out.
context('Tests for download_url()')

test_that('download_url() constructs a working URL properly' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2021-12-31'
  variables <- c('rainfall', 'max_temp', 'min_temp')

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20200101')
  expect_equal(as.character(parameters['finish']), '20211231')
  expect_equal(as.character(parameters['comment']), 'RXN')
})

test_that('download_url() works when requesting all variables' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2021-12-31'
  variables <- weather_variables()$variable_name

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20200101')
  expect_equal(as.character(parameters['finish']), '20211231')
  expect_equal(as.character(parameters['comment']), 'RNXGHJMVDCLFTAPW')
})

test_that('download_url() works when requesting each specific variable' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2021-12-31'

  variables <- weather_variables()$variable_name
  codes <- weather_variables()$silo_code

  for (index in 1:length(variables)) {
    variable <- variables[index]
    code <- codes[index]

    url <- download_url(latitude, longitude, start_date, finish_date, variable)
    parameters <- decode_url_parameters(url)

    expect_equal(as.character(parameters['format']), 'csv')
    expect_equal(as.character(parameters['username']), 'apirequest')
    expect_equal(as.character(parameters['password']), 'apirequest')
    expect_equal(as.character(parameters['lat']), '-34.9285')
    expect_equal(as.character(parameters['lon']), '138.6007')
    expect_equal(as.character(parameters['start']), '20200101')
    expect_equal(as.character(parameters['finish']), '20211231')
    expect_equal(as.character(parameters['comment']), code)
  }
})

test_that('download_url() lists variables in exactly the given order' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2021-12-31'

  variables <- c('max_temp', 'min_temp')
  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20200101')
  expect_equal(as.character(parameters['finish']), '20211231')
  expect_equal(as.character(parameters['comment']), 'XN')

  # Reverse order for variables
  variables <- c('min_temp', 'max_temp')
  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20200101')
  expect_equal(as.character(parameters['finish']), '20211231')
  expect_equal(as.character(parameters['comment']), 'NX')
})

test_that('(GIGO) there are no errors thrown for blank parameters' , {
  latitude <- ''
  longitude <- ''
  start_date <- ''
  finish_date <- ''
  variables <- ''

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '')
  expect_equal(as.character(parameters['lon']), '')
  expect_equal(as.character(parameters['start']), '')
  expect_equal(as.character(parameters['finish']), '')
  expect_equal(as.character(parameters['comment']), 'character(0)')
})

test_that('(GIGO) there are no errors thrown for non-Australia coordinates' , {
  latitude <- 52.9548
  longitude <- -1.1581
  start_date <- '1987-11-23'
  finish_date <- '2020-01-01'
  variables <- 'rainfall'

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '52.9548')
  expect_equal(as.character(parameters['lon']), '-1.1581')
  expect_equal(as.character(parameters['start']), '19871123')
  expect_equal(as.character(parameters['finish']), '20200101')
  expect_equal(as.character(parameters['comment']), 'R')
})

test_that('(GIGO) there are no errors thrown for bad/ill-formatted dates' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '13/17/2020'
  finish_date <- '06/18/2009'
  variables <- 'rainfall'

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '13/17/2020')
  expect_equal(as.character(parameters['finish']), '06/18/2009')
  expect_equal(as.character(parameters['comment']), 'R')
})

test_that('(GIGO) there are no errors thrown for dates outside of range' , {
  latitude <- -34.9285
  longitude <- -1.1581
  start_date <- '1742-03-22'
  finish_date <- '1781-12-20'
  variables <- c('rainfall', 'evaporation')

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '-1.1581')
  expect_equal(as.character(parameters['start']), '17420322')
  expect_equal(as.character(parameters['finish']), '17811220')
  expect_equal(as.character(parameters['comment']), 'RC')
})

test_that('(GIGO) there are no errors thrown for mispelled variables' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2020-01-01'
  variables <- c('rainball', 'min_temp', 'max_temperature')

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20200101')
  expect_equal(as.character(parameters['finish']), '20200101')
  expect_equal(as.character(parameters['comment']), 'character(0)Ncharacter(0)')
})

test_that('(GIGO) there are no errors thrown for nonexistent variables' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2021-02-03'
  finish_date <- '2021-04-05'
  variables <- c('max_temp', 'wind_speed', 'solar_exposure')

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20210203')
  expect_equal(as.character(parameters['finish']), '20210405')
  expect_equal(as.character(parameters['comment']), 'Xcharacter(0)J')
})

test_that('(GIGO) there are no errors thrown for duplicate variables' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '1987-06-05'
  finish_date <- '1981-01-01'
  variables <- c('humidity_tmax', 'humidity_tmin', 'humidity_tmax')

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'apirequest')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '19870605')
  expect_equal(as.character(parameters['finish']), '19810101')
  expect_equal(as.character(parameters['comment']), 'HGH')
})

test_that('download_url() returns a character object', {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2021-12-31'
  variables <- c('rainfall', 'max_temp', 'evaporation')

  url <- download_url(latitude, longitude, start_date, finish_date, variables)
  expect_is(url, 'character')
})


# Test cases for the earliest date of data observations ########################
# Here we mainly have a tautological test case that tests this
# earliest test data against 1889-01-01: this test is a sentinel
# that fails if we've ever updated the date in weathervane.R but
# not in these test files (and likely other places!)
context('Tests for earliest_dataset_date()')

test_that('1889-01-01 is the earliest date of data', {
  expect_equal(earliest_dataset_date(), as.Date('1889-01-01'))
})

test_that('earliest_dataset_date() returns a Date object', {
  expect_is(earliest_dataset_date(), 'Date')
})


# Test cases for the in_australia() function ###################################
# Note that our 'bounds' for what Australia is match up with
# the bounds used by SILO (and also the Bureau of Meteorology),
# and which actually include parts of Indonesia and Papua New
# Guinea. We document this here in these tests.
context('Tests for in_australia()')

test_that('lat/lng in Australia correctly return TRUE', {
  expect_true(in_australia(-34.9285, 138.6007))
  expect_true(in_australia(-43.5844, 146.7362))
  expect_true(in_australia(-28.1999, 153.5669))
  expect_true(in_australia(-10.6872, 142.5315))
  expect_true(in_australia(-10.0858, 142.1679))
  expect_true(in_australia(-25.5647, 112.9601))
  expect_true(in_australia(-20.7844, 115.4005))
  expect_true(in_australia(-33.5370, 115.0140))
  expect_true(in_australia(-35.1302, 117.6227))
  expect_true(in_australia(-36.0499, 136.7118))
  expect_true(in_australia(-43.4933, 147.3027))
  expect_true(in_australia(-39.0992, 146.3834))
  expect_true(in_australia(-37.5051, 149.9658))
})

test_that('some lat/lng in Indonesia/Papua New Guinea return TRUE too', {
  # TODO: But maybe they shouldn't and we should make this
  #       function more sophisticated? Possible improvement here?
  expect_true(in_australia(-10.5513, 150.2279))
  expect_true(in_australia(-10.7159, 123.1466))
  expect_true(in_australia(-10.1469, 120.4550))
})

test_that('most lat/lng outside of Australia correctly return FALSE', {
  expect_false(in_australia(-45.8989, 166.7404))
  expect_false(in_australia(-40.6563, 172.5851))
  expect_false(in_australia(-34.4431, 172.6840))
  expect_false(in_australia(-20.2617, 164.1146))
  expect_false(in_australia(-8.9443, 141.0763))
  expect_false(in_australia(-8.6502, 120.9603))
  expect_false(in_australia(-8.5625, 114.0499))
  expect_false(in_australia(-9.0564, 142.1969))
})