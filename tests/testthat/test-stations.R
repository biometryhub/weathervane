# Tests for get_station_by_name
test_that("Stations can be found by name", {
  stations <- get_station_by_name("Brisbane")
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 7L)
  expect_identical(ncol(stations), 6L)
  expect_identical(colnames(stations), c("ID", "Name", "Latitude", "Longitude", "State", "Elevation"))
  expect_identical(unique(stations$State), "QLD")
  expect_contains(stations$ID, c(40140, 40214, 40215, 40216, 40223, 40842, 40913))
})

test_that("Stations with special characters can be found", {
  stations <- get_station_by_name("Adel (Waite)")
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 1L)
  expect_identical(ncol(stations), 6L)
  expect_identical(colnames(stations), c("ID", "Name", "Latitude", "Longitude", "State", "Elevation"))
  expect_identical(stations$State, "SA")
  expect_equal(stations,
               data.frame(ID = 23031, Name = "ADELAIDE (WAITE INSTITUTE)",
                          Latitude = -34.97, Longitude = 138.633,
                          State = "SA", Elevation = 115))
})

test_that("Wildcard searching for stations works", {
  stations <- get_station_by_name("botan*")
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 10L)
  expect_contains(stations$ID, c(14163, 40215, 66006, 66007, 70247, 86232, 86375, 89001, 90023, 94030))
})

test_that("Invalid names will produce an error or no output", {
  stations_numbers <- get_station_by_name("123")
  expect_s3_class(stations_numbers, "data.frame")
  expect_identical(nrow(stations_numbers), 0L)
  expect_error(get_station_by_name(letters), "`x` must be a string of length 1")
  expect_error(get_station_by_name(iris), "`x` must be a string of length 1")
  expect_identical(nrow(get_station_by_name('1; phpinfo()')), 0L)
})


# Tests for get_all_stations
test_that("All stations are returned", {
  stations <- get_all_stations()
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 7995L)
  expect_identical(ncol(stations), 6L)
  expect_identical(colnames(stations), c("ID", "Name", "Latitude", "Longitude", "State", "Elevation"))
  expect_false("Distance" %in% colnames(stations))
  expect_contains(stations$ID[1:6], c(41497, 40000, 39000, 63000, 61000, 61065))
})

test_that("All stations are returned sorting by ID", {
  stations <- get_all_stations(sort_by = "id")
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 7995L)
  expect_equal(stations$ID[1:6], c(1001, 1005, 1006, 1009, 1010, 1012))
  expect_equal(sum(stations$ID), sum(get_all_stations(sort = "name")$ID))
})

test_that("All stations are returned sorting by state", {
  stations <- get_all_stations(sort_by = "state")
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 7995L)
  expect_equal(stations$ID[1:6], c(46006, 46028, 46049, 46085, 46029, 46037))
  expect_equal(sum(stations$ID), sum(get_all_stations(sort = "name")$ID))
})

test_that("All stations are returned sorting by distance", {
  stations <- get_all_stations(sort_by = "distance")
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 7995L)
  expect_equal(stations$ID[1:6], c(15540, 15590, 15623, 15631, 15564, 15501))
  expect_equal(sum(stations$ID), sum(get_all_stations(sort = "name")$ID))
})

test_that("Invalid sorting option returns an error", {
  expect_error(get_all_stations(sort_by = "abc"), "sort_by must be one of 'distance', 'name', 'id' or 'state'")
})


# Tests for get_stations_by_distance
test_that("Station distances can be found by name", {
  stations <- get_stations_by_dist("Waite", 5)
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 12L)
  expect_identical(ncol(stations), 7L)
  expect_identical(sum(stations$Distance), 44.5)
})

test_that("Station distances can be found by ID", {
  stations <- get_stations_by_dist(23031, 5)
  expect_identical(stations, get_stations_by_dist("Waite", 5))
})

test_that("Station distances can be sorted by ID", {
  stations <- get_stations_by_dist(23031, 5, sort_by = "id")
  expect_identical(nrow(stations), 12L)
  expect_identical(ncol(stations), 7L)
  expect_equal(stations$ID, c(23000, 23005, 23010, 23014, 23029, 23031,
                              23075, 23090, 23703, 23704, 23706, 23746))
})

test_that("Station distances can be sorted by Name", {
  stations <- get_stations_by_dist(23031, 5, sort_by = "name")
  expect_equal(stations$ID, c(23075, 23005, 23014, 23090, 23029, 23031,
                              23000, 23703, 23704, 23706, 23010, 23746))
})

test_that("Station distances can be sorted by State", {
  stations <- get_stations_by_dist(23031, 5, sort_by = "state")
  expect_equal(stations$ID, c(23031, 23010, 23014, 23005, 23029, 23703,
                              23075, 23704, 23746, 23706, 23090, 23000))
})

test_that("Station distances can be sorted by Distance", {
  stations <- get_stations_by_dist(23031, 5, sort_by = "distance")
  expect_equal(stations$ID, c(23031, 23010, 23014, 23005, 23029, 23703,
                              23075, 23704, 23746, 23706, 23090, 23000))
  expect_identical(stations, get_stations_by_dist(23031, 5))
})

test_that("Invalid sort options return an error", {
  expect_error(get_stations_by_dist(23031, 5, sort_by = "abc"),
               "sort_by must be one of 'distance', 'name', 'id' or 'state'")
})

test_that("Non unique station name returns an error", {
  expect_error(get_stations_by_dist("ADEL", 5),
               "Provided station matched multiple locations\\. Please provide unique station name or station ID\\.")
})

test_that("Invalid station ID returns an error", {
  expect_error(get_stations_by_dist(123, 5),
               "No data returned, please check input")
})

test_that("Invalid station name returns an error", {
  expect_error(get_stations_by_dist("XYZ", 5),
               "Unknown station provided\\. Please provide unique station name or station ID\\.")
})

# Tests for get_station_details
test_that("Station details are returned", {
  stations <- get_station_details(23031)
  expect_s3_class(stations, "data.frame")
  expect_identical(nrow(stations), 1L)
  expect_identical(ncol(stations), 6L)
  expect_identical(stations$Name, "ADELAIDE (WAITE INSTITUTE)")
  expect_identical(stations$Latitude, -34.97)
  expect_identical(stations$Longitude, 138.633)
  expect_identical(stations$State, "SA")
  expect_identical(stations$Elevation, 115)
})

test_that("Station details are returned when given name", {
  stations <- get_station_details("Waite")
  expect_identical(stations, get_station_details(23031))
})

test_that("Error produced with invalid station name", {
  expect_error(get_station_details("abc"),
               "Unknown station provided\\. Please provide unique station name or station ID\\.")
})

test_that("Non unique station name returns an error", {
  expect_error(get_station_details("ADEL"),
               "Provided station matched multiple locations\\. Please provide unique station name or station ID\\.")
})



# Tests for get_station_data
test_that("Station weather data can be downloaded by station ID", {
  weather_data <- get_station_data(23031, '2020-01-01', '2020-01-31', c('rainfall', 'max_temp'))
  expect_s3_class(weather_data, "data.frame")
  expect_identical(nrow(weather_data), 31L)
  expect_identical(ncol(weather_data), 4L)
})

test_that("Station weather data can be downloaded by station name", {
  weather_data <- get_station_data("Waite", '2020-01-01', '2020-01-31', c('rainfall', 'max_temp'))
  expect_s3_class(weather_data, "data.frame")
  expect_identical(nrow(weather_data), 31L)
  expect_identical(ncol(weather_data), 4L)
  expect_identical(weather_data, get_station_data(23031, '2020-01-01', '2020-01-31', c('rainfall', 'max_temp')))
})

test_that("Download all variables", {
  weather_data <- get_station_data(23031, '2020-01-01', '2020-01-02')
  expect_s3_class(weather_data, "data.frame")
  expect_identical(nrow(weather_data), 2L)
  expect_identical(ncol(weather_data), 18L)
})

test_that("Download all variables", {
  weather_data <- get_station_data("Waite", '2020-01-01', '2020-01-02')
  expect_s3_class(weather_data, "data.frame")
  expect_identical(nrow(weather_data), 2L)
  expect_identical(ncol(weather_data), 18L)
  expect_identical(colnames(weather_data), c("Date", "Elevation (m)",
                                             weather_variables()$pretty_name))
})

test_that("Get data without pretty names", {
  weather_data <- get_station_data("Waite", '2020-01-01', '2020-01-02', pretty_names = FALSE)
  expect_s3_class(weather_data, "data.frame")
  expect_identical(nrow(weather_data), 2L)
  expect_identical(ncol(weather_data), 18L)
  expect_identical(colnames(weather_data), make.names(c("Date", "Elevation (m)",
                                             weather_variables()$pretty_name)))
})

test_that("Error produced with invalid station name", {
  expect_error(get_station_data("abc", '2020-01-01', '2020-01-02'),
               "Unknown station provided\\. Please provide unique station name or station ID\\.")
})

test_that("Error produced with invalid station ID", {
  expect_error(get_station_data(123, '2020-01-01', '2020-01-02'),
               "Server-side error: Invalid station ID provided")
})

test_that("Errors produced with invalid dates", {
  expect_error(get_station_data(23031, start_date = '2020-01-02', finish_date = '2020-01-01'),
               "The given finish date cannot precede the start date")
  expect_error(get_station_data(23031, start_date = '1620-01-02', finish_date = '2020-01-01'),
               "The given start date cannot precede 1889-01-01")
  expect_error(get_station_data(23031, start_date = '2050-01-01', finish_date = '2050-01-02'),
               "Server-side error: Invalid start/end date")
})

test_that("Errors produced with invalid variables", {
  expect_error(get_station_data(23031, '2020-01-01', '2020-01-02', variables = "abc"),
               "abc is not in the list of available variables; did you misspell the variable?")
})

