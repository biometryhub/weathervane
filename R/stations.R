#' Retrieve weather data for the given station ID and dates
#'
#' Return a data frame containing SILO Australian weather data
#' for the specified weather station, date range (from start_date
#' to finish_date, inclusive) and the specified variables. By default,
#' all available weather variables are returned if none are specified.
#' If no finish date is provided, the date range is taken from the
#' given start date up to today's date (i.e. so up to the most
#' recently uploaded weather information on the SILO server, which is
#' updated daily).
#'
#' @param station A numeric station ID, or else a character station name.
#' @param start_date A string or Date object for the starting date
#' @param finish_date A string or Date object for the finish date
#'   (Default: today's date, so retrieves up to most recently updated
#'   weather data available)
#' @param variables A vector containing the variable names
#'   (Default: retrieve all available weather variables)
#' @param pretty_names Whether to format the columns with prettied
#'   variable names (Default: TRUE). Set this to FALSE to format
#'   the column names as syntactically valid variable names (at the
#'   cost of some readability)
#' @return A data.frame containing the downloaded weather data
#' @examples
#' weather_data <- get_station_data(
#'   40004, '2020-01-01', '2020-03-31', c('rainfall', 'max_temp')
#' )
#' head(weather_data)
#'
#' @export
get_station_data <- function(
    station,
    start_date,
    finish_date = Sys.Date(),
    variables = weather_variables()$variable_name,
    pretty_names = TRUE) {

  station <- check_station(station)

  start_date <- as.Date(start_date)
  finish_date <- as.Date(finish_date)

  # The start date must not precede the oldest date of data available.
  if (start_date < earliest_dataset_date()) {
    stop(
      paste('The given start date cannot precede', earliest_dataset_date())
    )
  }

  # The finish date must not precede the start date.
  if (finish_date < start_date) {
    stop('The given finish date cannot precede the start date')
  }

  # If variables are specified, make sure that they each exist within
  # the set of available variables.
  valid_variables <- variables %in% weather_variables()$variable_name
  if (!all(valid_variables)) {
    first_erroneous <- variables[which(valid_variables == FALSE)[1]]
    stop(
      paste0(
        first_erroneous,
        ' is not in the list of available variables; did you misspell the ',
        'variable?\n',
        'You can use weathervane::weather_variables() to check the list of ',
        'available variables. Use the entries in the variable_name column ',
        'to select variables as desired.'
      )
    )
  }

  url <- download_url(station = station, start_date = start_date, finish_date = finish_date, variables = variables)
  data <- download_data(url)

  # 18/11/2021 Fix: Truncate empty rows if given less than 4 days worth
  # of data observations
  data <- data[which(data['Date'] != ''), ]

  if (!pretty_names) {
    colnames(data) <- make.names(colnames(data))
  }

  return(data)
}


#' Get details of an individual weather station
#'
#' @param station The station to retrieve details of. Station names will be attempted to be interpreted with an error returned.
#'
#' @return A data.frame with Station ID, Name, Latitude, Longitude, State and Elevation of the given station ID.
#' @export
#'
#' @examples
#' get_station_details(23031)
get_station_details <- function(station) {
  url <- "https://www.longpaddock.qld.gov.au/cgi-bin/silo/PatchedPointDataset.php?format=id&station="

  station <- check_station(station)

  url <- paste0(url, station)
  data <- xml2::xml_text(xml2::read_html(url))
  data <- check_url_response(data)

  data <- utils::read.table(text = data, header = FALSE, sep = '|',
                            strip.white = TRUE, quote = "")

  # There seems to be an extra column, which doesn't appear to be anything useful
  data$V7 <- NULL
  colnames(data) <- c("ID", "Name", "Latitude", "Longitude", "State", "Elevation")

  return(data)
}

#' Get list of all weather stations within specified distance
#'
#' Get a list of weather stations within a provided distance from a given weather station.
#'
#' @param station The station to retrieve details of. Station names will be attempted to be interpreted with an error returned.
#' @param distance Radius in km from provided station.
#' @param sort_by The column to sort the stations by. Valid values are "name" (the default), "distance", "id" or "state".
#'
#' @return A data.frame with all the weather stations along with their BoM station ID, Station name, Latitude, Longitude, State and Elevation.
#'
#' @export
#'
#' @examples
#' get_stations_by_dist("Waite", 5)
#' get_stations_by_dist(23031, 5)
#'
get_stations_by_dist <- function(station, distance, sort_by = "distance") {

  url <- "https://www.longpaddock.qld.gov.au/cgi-bin/silo/PatchedPointDataset.php?format=near&"

  station <- check_station(station)

  url <- paste0(url, "station=", station, "&radius=", distance)

  data <- xml2::xml_text(xml2::read_html(url))
  data <- check_url_response(data)

  data <- utils::read.table(text = data, header = TRUE, sep = '|',
                            strip.white = TRUE, quote = "")

  # No data is returned for some reason, but URL call hasn't failed.
  if(nrow(data)==0) {
    stop("No data returned, please check input.", call. = FALSE)
  }

  colnames(data) <- c("ID", "Name", "Latitude", "Longitude", "State", "Elevation", "Distance")

  if(tolower(sort_by) == "distance") {
    data <- data[order(data$Distance),]
  }
  else if(tolower(sort_by) == "id") {
    data <- data[order(data$ID),]
  }
  else if(tolower(sort_by) == "name") {
    data <- data[order(data$Name),]
  }
  else if(tolower(sort_by) == "state") {
    data <- data[order(data$State),]
  }
  else {
    stop("sort_by must be one of 'distance', 'name', 'id' or 'state'.", call. = FALSE)
  }

  rownames(data) <- 1:nrow(data)
  return(data)
}

#' Get a list of all weather stations
#'
#' Get the complete list of weather stations with data available on SILO (approximately 8000).
#'
#'
#' @param sort_by The column to sort the stations by. Valid values are "name" (the default), "distance" (from Alice Springs), "id" or "state".
#'
#' @return A data.frame with all the weather stations along with their BoM station ID, Station name, Latitude, Longitude, State and Elevation.
#'
#' @export
#'
#' @examples
#' head(get_all_stations())
#' head(get_all_stations(sort_by = "id"))
#'
get_all_stations <- function(sort_by = "name") {
  stations <- get_stations_by_dist(station = 15540, distance = 10000, sort_by)
  stations$Distance <- NULL
  return(stations)
}


#' Get station details from a provided (partial) name
#'
#' @param station A (partial) name of a station. Will be truncated to 10 characters. Wildcard searching can be performed with * or _
#'
#' @return A data frame listing all stations that matched the input text.
#' @export
#'
#' @examples
#' # Search by name
#' get_station_by_name("Brisbane")
#'
#' # Find a specific station
#' get_station_by_name("Adel (Waite)")
#'
#' # Will return any stations containing "botanic", "botanical" or "botany"
#' get_station_by_name("botan*")
get_station_by_name <- function(station) {
  # Set up the base URL
  url <- "https://www.longpaddock.qld.gov.au/cgi-bin/silo/PatchedPointDataset.php?format=name&nameFrag="

  # Change any special or space characters to underscore for wildcard searching
  # Input string is limited to 10 characters so truncate
  station <- substr(gsub("(\\*|\\s|[[:punct:]])+", "_", station), 1, 10)

  url <- paste0(url, station)

  data <- xml2::xml_text(xml2::read_html(url))
  data <- check_url_response(data)

  data <- utils::read.table(text = data, header = TRUE, sep = '|',
                            strip.white = TRUE, quote = "")

  colnames(data) <- c("ID", "Name", "Latitude", "Longitude", "State", "Elevation")

  return(data)
}
