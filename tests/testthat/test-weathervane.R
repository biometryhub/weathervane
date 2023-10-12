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
# context('Tests for weather_variables()')

test_that('weather_variables() returns a data frame', {
  expect_s3_class(weather_variables(), "data.frame")
})

test_that('weather_variables() returns the expected variables', {
  expect_equal(weather_variables()$variable_name,
               c("rainfall", "min_temp", "max_temp", "humidity_tmin",
                 "humidity_tmax", "solar_exposure", "mean_sea_level_pressure",
                 "vapour_pressure", "vapour_pressure_deficit", "evaporation",
                 "evaporation_morton_lake", "evapotranspiration_fao56",
                 "evapotranspiration_asce", "evapotranspiration_morton_areal",
                 "evapotranspiration_morton_point", "evapotranspiration_morton_wet"))

  expect_equal(weather_variables()$pretty_name,
               c('Rainfall (mm)', 'Minimum Temperature (degC)',
                 'Maximum Temperature (degC)',
                 'Relative Humidity at Minimum Temperature (%)',
                 'Relative Humidity at Maximum Temperature (%)', 'Solar Exposure (MJ/m2)',
                 'Mean Pressure at Sea Level (hPa)', 'Vapour Pressure (hPa)',
                 'Vapour Pressure Deficit (hPa)', 'Evaporation (mm)',
                 "Morton's Shallow Lake Evaporation (mm)",
                 'FAO56 Short Crop Evapotranspiration (mm)',
                 'ASCE Tall Crop Evapotranspiration (mm)',
                 "Morton's Areal Actual Evapotranspiration (mm)",
                 "Morton's Point Potential Evapotranspiration (mm)",
                 "Morton's Wet-environment Areal Potential Evapotranspiration (mm)"))

  expect_equal(weather_variables()$description,
               c('Daily rainfall (mm)', 'Minimum temperature (degrees Celsius)',
                 'Maximum temperature (degrees Celsius)',
                 'Relative humidity at time of minimum temperature (%)',
                 'Relative humidity at time of maximum temperature (%)',
                 'Solar exposure (MJ/m2)', 'Mean pressure at sea level (hPa)',
                 'Vapour pressure (hPa)', 'Vapour pressure deficit (hPa)',
                 'Class A pan evaporation [synthetic estimate for pre-1970] (mm)',
                 "Morton's shallow lake evaporation (mm)",
                 'FAO56 short crop evapotranspiration (mm)',
                 'ASCE tall crop evapotranspiration (mm)',
                 "Morton's areal actual evapotranspiration (mm)",
                 "Morton's point potential evapotranspiration (mm)",
                 "Morton's wet-environment areal potential evapotranspiration (mm)"))

  expect_equal(weather_variables()$silo_name,
               c('daily_rain', 'min_temp', 'max_temp', 'rh_tmin', 'rh_tmax', 'radiation',
                 'mslp', 'vp', 'vp_deficit', 'evap_comb', 'evap_morton_lake',
                 'et_short_crop', 'et_tall_crop', 'et_morton_actual',
                 'et_morton_potential', 'et_morton_wet'))

  expect_equal(weather_variables()$silo_code,
               c('R', 'N', 'X', 'G', 'H', 'J', 'M', 'V',
                 'D', 'C', 'L', 'F', 'T', 'A', 'P', 'W'))
})


# Test cases for the main weather retrieval interface ##########################
# context('Tests for get_weather_data()')

test_that('get_weather_data() fails if outside Australia', {
  expect_error(get_weather_data(-1, 1, Sys.Date()-1),
               "Latitude and longitude coordinates must be within Australia \\(roughly -44.53 < lat < -9.97, 111.98 < lng < 156.27\\)")
})

test_that('get_weather_data() truncates decimal places', {
  # Using minimal variables to reduce server load
  expect_identical(get_weather_data(latitude = -34.9680512, longitude = 138.6352101, start_date = Sys.Date()-1, variables = "rainfall"),
                   get_weather_data(latitude = round(-34.9680512, 4), longitude = round(138.6352101, 4), start_date = Sys.Date()-1, variables = "rainfall"))
})

test_that('get_weather_data() fails if start date is earlier than 1889-01-01', {
  expect_error(get_weather_data(-34.968, 138.635, start_date = "1700-01-01"),
               "The given start date cannot precede 1889-01-01")
})

test_that('get_weather_data() fails if finish date is earlier than start_date', {
  expect_error(get_weather_data(-34.968, 138.635, start_date = Sys.Date(), finish_date = Sys.Date() -1),
               "The given finish date cannot precede the start date")
})

test_that('get_weather_data() fails if invalid weather varibales are provided', {
  expect_error(get_weather_data(-34.968, 138.635, start_date = Sys.Date()-1, variables = "xyz"),
               "xyz is not in the list of available variables\\; did you misspell the variable\\?\nYou can use weathervane\\:\\:weather_variables\\(\\) to check the list of available variables\\. Use the entries in the variable_name column to select variables as desired\\.")
  expect_error(get_weather_data(-34.968, 138.635, start_date = Sys.Date()-1, variables = "humidity"),
               "humidity is not in the list of available variables;")
  expect_error(get_weather_data(-34.968, 138.635, start_date = Sys.Date()-1, variables = "temperature"),
               "temperature is not in the list of available variables;")
})

test_that('get_weather_data() has different column names if pretty_names = FALSE', {
  pretty_names <- get_weather_data(-34.968, 138.635, start_date = Sys.Date()-1, variables = "rainfall")
  ugly_names <- get_weather_data(-34.968, 138.635, start_date = Sys.Date()-1, variables = "rainfall", pretty_names = FALSE)
  expect_identical(colnames(pretty_names),
                   c("Date", "Latitude", "Longitude",
                     "Elevation (m)", "Rainfall (mm)"))
  expect_identical(colnames(ugly_names),
                   c("Date", "Latitude", "Longitude",
                     "Elevation..m.", "Rainfall..mm."))
  expect_false(identical(colnames(pretty_names), colnames(ugly_names)))
})

test_that('get_weather_data() returns all weather variables by default', {
  data <- get_weather_data(-34.968, 138.635, start_date = Sys.Date()-5)
  expect_identical(colnames(data),
                   c("Date", "Latitude", "Longitude", "Elevation (m)",
                     weather_variables()$pretty_name))
  expect_equal(nrow(data), 5)
})

test_that('get_weather_data() returns a single row of data with one input date', {
  data <- get_weather_data(-34.968, 138.635, start_date = Sys.Date()-1, variables = "rainfall")
  expect_equal(nrow(data), 1)
})


# Test cases for the main weather data download function #######################
# context('Tests for download_data()')

test_that('download_data() produces an error if dates are invalid', {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- 'abc'
  finish_date <- '2021-12-31'
  variables <- c('rainfall')

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  expect_error(download_data(url), 'Server-side error: Invalid start/end date')
})

test_that('download_data() produces an error if latitude and/or longitude are invalid', {
  latitude <- -3.9285
  longitude <- 18.6007
  start_date <- '2021-12-30'
  finish_date <- '2021-12-31'
  variables <- c('rainfall')

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  expect_error(download_data(url), 'Server-side error: Invalid latitude/longitude')
})

test_that('download_data() produces an error if url is invalid', {
  latitude <- -3.9285
  longitude <- 18.6007
  start_date <- '2021-12-30'
  finish_date <- '2021-12-31'
  variables <- "abc"

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  url2 <- download_url(latitude = latitude, longitude = longitude,
                       start_date = start_date, finish_date = finish_date,
                       variables = NA)
  # url3 <- download_url(NA, NA, start_date, finish_date, variables)
  # url4 <- download_url(latitude, longitude, NA, NA, variables)
  expect_error(download_data(url), 'Server-side error: Unspecified error or server inaccessible')
  expect_error(download_data(url2), 'Server-side error: Unspecified error or server inaccessible')
  # expect_error(download_data(url3), 'Server-side error: Unspecified error or server inaccessible')
  # expect_error(download_data(url4), 'Server-side error: Unspecified error or server inaccessible')
  # expect_error(download_data("https://example.com/"), 'Server-side error: Missing parameters/malformed URL')
})


# Test cases for the URL constructor ###########################################
# Note that no error checking happens during the construction of
# the download URL in this function. It is expected that the
# latitudes, longitudes, dates and variables list will all be
# sanity-checked before this function is called, and garbage in
# begets garbage out.
# context('Tests for download_url()')

test_that('download_url() constructs a working URL properly' , {
  latitude <- -34.9285
  longitude <- 138.6007
  start_date <- '2020-01-01'
  finish_date <- '2021-12-31'
  variables <- c('rainfall', 'max_temp', 'min_temp')

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

    url <- download_url(latitude = latitude, longitude = longitude,
                        start_date = start_date, finish_date = finish_date,
                        variables = variable)
    parameters <- decode_url_parameters(url)

    expect_equal(as.character(parameters['format']), 'csv')
    expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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
  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
  expect_equal(as.character(parameters['password']), 'apirequest')
  expect_equal(as.character(parameters['lat']), '-34.9285')
  expect_equal(as.character(parameters['lon']), '138.6007')
  expect_equal(as.character(parameters['start']), '20200101')
  expect_equal(as.character(parameters['finish']), '20211231')
  expect_equal(as.character(parameters['comment']), 'XN')

  # Reverse order for variables
  variables <- c('min_temp', 'max_temp')
  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  parameters <- decode_url_parameters(url)

  expect_equal(as.character(parameters['format']), 'csv')
  expect_equal(as.character(parameters['username']), 'biometryhubdev@gmail.com')
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

  url <- download_url(latitude = latitude, longitude = longitude,
                      start_date = start_date, finish_date = finish_date,
                      variables = variables)
  expect_type(url, 'character')
})


# Test cases for the earliest date of data observations ########################
# Here we mainly have a tautological test case that tests this
# earliest test data against 1889-01-01: this test is a sentinel
# that fails if we've ever updated the date in weathervane.R but
# not in these test files (and likely other places!)
# context('Tests for earliest_dataset_date()')

test_that('1889-01-01 is the earliest date of data', {
  expect_equal(earliest_dataset_date(), as.Date('1889-01-01'))
})

test_that('earliest_dataset_date() returns a Date object', {
  expect_s3_class(earliest_dataset_date(), 'Date')
})


# Test cases for the in_australia() function ###################################
# Note that our 'bounds' for what Australia is match up with
# the bounds used by SILO (and also the Bureau of Meteorology),
# and which actually include parts of Indonesia and Papua New
# Guinea. We document this here in these tests.
# context('Tests for in_australia()')

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
