# weathervane: An R package for automating the process of downloading
# SILO weather/climate datasets. Easily retrieve weather datasets for
# given GPS coordinates and date ranges for use in your projects.
#
# NOTE: The weather datasets are curated by SILO, who make them
#       available under a Creative Commons Attribution 4.0
#       International Licence; and their data is sourced from the
#       Australian Bureau of Meteorology weather stations.
#       Please cite/reference them appropriately!
#       See for example:
#       https://www.longpaddock.qld.gov.au/silo/about/data-suppliers/
#       http://www.bom.gov.au/other/copyright.shtml
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson, Biometry Hub
# Date last modified: 18/08/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au


#' Weather variables, including ID codes and descriptions
#'
#' Return a data frame mapping the available weather variables to
#' their 'pretty' names, their descriptions, and their SILO
#' codes and identifier names.
#' (See also
#'  https://www.longpaddock.qld.gov.au/silo/about/climate-variables/)
#'
#' @return A data.frame containing the weather variables and codes
#' @examples
#' weather_variables()
#' @export
weather_variables <- function() {
  data.frame(
    variable_name = c(
      'rainfall', 'min_temp', 'max_temp', 'humidity_tmin', 'humidity_tmax',
      'solar_exposure', 'mean_sea_level_pressure', 'vapour_pressure',
      'vapour_pressure_deficit', 'evaporation', 'evaporation_morton_lake',
      'evapotranspiration_fao56', 'evapotranspiration_asce',
      'evapotranspiration_morton_areal', 'evapotranspiration_morton_point',
      'evapotranspiration_morton_wet'
    ),
    pretty_name = c(
      'Rainfall (mm)', 'Minimum Temperature (degC)',
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
      "Morton's Wet-environment Areal Potential Evapotranspiration (mm)"
    ),
    description = c(
      'Daily rainfall (mm)', 'Minimum temperature (degrees Celsius)',
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
      "Morton's wet-environment areal potential evapotranspiration (mm)"
    ),
    silo_name = c(
      'daily_rain', 'min_temp', 'max_temp', 'rh_tmin', 'rh_tmax', 'radiation',
      'mslp', 'vp', 'vp_deficit', 'evap_comb', 'evap_morton_lake',
      'et_short_crop', 'et_tall_crop', 'et_morton_actual',
      'et_morton_potential', 'et_morton_wet'
    ),
    silo_code = c(
      'R', 'N', 'X', 'G', 'H', 'J', 'M', 'V', 'D', 'C', 'L', 'F', 'T', 'A',
      'P', 'W'
    )
  )
}

#' Retrieve weather data for the given location and dates
#'
#' Return a data frame containing SILO Australian weather data
#' for the specified latitude/longitude, date range (from start_date
#' to finish_date, inclusive) and the specified variables. By default,
#' all available weather variables are returned if none are specified.
#' If no finish date is provided, the date range is taken from the
#' given start date up to today's date (i.e. so up to the most
#' recently uploaded weather information on the SILO server, which is
#' updated daily).
#'
#' @param latitude The latitude (in decimal degrees North)
#' @param longitude The longitude (in decimal degrees East)
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
#' get_weather_data(-34.9, 138.6, '2021-01-01', pretty_names = FALSE)
#' get_weather_data(
#'   -34.18, 139.98, '2020-01-01', '2020-03-31', c('rainfall', 'max_temp')
#' )
#' @export
get_weather_data <- function(
  latitude,
  longitude,
  start_date,
  finish_date = Sys.Date(),
  variables = weather_variables()$variable_name,
  pretty_names = TRUE
) {
  # Given latitude and longitude should be (roughly) within
  # Australia bounds
  if (!in_australia(latitude, longitude)) {
    stop(
      paste(
        'Latitude and longitude coordinates must be within Australia',
        '(roughly -44.53 < lat < -9.97, 111.98 < lng < 156.27)'
      )
    )
  }

  # Since latitudes/longitudes that are 'too long' are rejected by the
  # server, we truncate the latitude and longitude to 4 decimal points
  # (which is still higher resolution than the SILO grid resolution)
  max_decimal_points <- 4
  latitude <- round(latitude, digits = max_decimal_points)
  longitude <- round(longitude, digits = max_decimal_points)

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

  data <- download_data(
    download_url(latitude, longitude, start_date, finish_date, variables)
  )

  if (!pretty_names) {
    colnames(data) <- make.names(colnames(data))
  }

  data
}


#' Download the weather data from the constructed URL
#'
#' Return a data frame containing the SILO weather dataset,
#' complete with prettied column names, from the given download
#' URL.
#'
#' @param url A character string containing the download URL
#' @return A data.frame containing the specified weather data
#' @seealso [download_url()] to generate the requisite URLs.
#'
#' @importFrom xml2 read_html xml_text
#' @importFrom utils read.table
#'
#' @keywords internal
#'
#' @examples
#' weathervane:::download_data(
#'   weathervane:::download_url(-34.9, 138.6, '2020-01-01', '2020-12-31', c('rainfall'))
#' )
#' @keywords internal
download_data <- function(url) {
  data <- xml2::xml_text(xml2::read_html(url))

  # Test for invalid dates
  if (grepl('(Sorry).+(date).+(invalid)*', data)) {
    stop('Server-side error: Invalid start/end date')
  }

  # Test for invalid coordinates
  if (grepl('(check).+(within Australia)', data)) {
    stop('Server-side error: Invalid latitude/longitude')
  }

  # Test for invalid parameters (e.g. missing comment=)
  if (grepl('missing essential parameters', data, fixed = TRUE)) {
    stop('Server-side error: Missing parameters/malformed URL')
  }

  # Test for a rejected URL (which can happen e.g. if the latitude
  # or longitude is 'too long')
  if (grepl('([R|r]ejected)', data)) {
    stop('Server-side error: URL rejected')
  }

  # Catch-all test for some other server-side error (e.g. if the server
  # is inaccessible)
  if (grepl('(error occurred)|(error checking)', data)) {
    stop('Server-side error: Unspecified error or server inaccessible')
  }

  # Convert to table and remove source columns if any
  data <- utils::read.table(text = data, header = TRUE, sep = ',')
  source_columns <- colnames(data)[grepl('_source', colnames(data))]
  data <- data[ , !(colnames(data) %in% source_columns)]

  # Retrieve the elevation (if listed) from the metadata and add it
  # in as a new column (otherwise add a blank Elevation column).
  metadata <- paste(unlist(data['metadata']), collapse = ',')
  elevation <- ''
  if (grepl('elevation= ', metadata, fixed = TRUE)) {
    elevation <- regmatches(
      metadata,
      regexpr('(?<=elevation=)\\s*\\d+[.,]\\d+', metadata, perl = TRUE)
    )
  }
  data['Elevation (m)'] <- trimws(elevation)
  data['metadata'] <- NULL

  # Pretty each of the column names
  column_names <- colnames(data)
  column_names[which(column_names == 'YYYY.MM.DD')] <- 'Date'
  column_names[which(column_names == 'latitude')] <- 'Latitude'
  column_names[which(column_names == 'longitude')] <- 'Longitude'

  silo_names <- weather_variables()$silo_name
  pretty_names <- weather_variables()$pretty_name
  for (index in which(column_names %in% silo_names)) {
    old_name <- column_names[index]
    column_names[index] <- pretty_names[which(silo_names == old_name)]
  }
  data <- `colnames<-`(data, column_names)

  # Reorder columns
  var_order <- append(
    c(
      which(column_names == 'Date'),
      which(column_names == 'Latitude'),
      which(column_names == 'Longitude'),
      which(column_names == 'Elevation (m)')
    ),
    unlist(
      lapply(
        1:length(pretty_names),
        function(index) {
          which(column_names == pretty_names[index])
        }
      )
    )
  )
  data <- data[ , var_order]

  data
}

#' The download URL for the SILO weather data download
#'
#' Return a character string containing the parameter-formatted
#' download URL for the SILO data, given the latitude/longitude
#' coordinates, the start and finish dates of interest, and a list
#' of variables to be retrieved.
#'
#' @param latitude The latitude (in decimal degrees North)
#' @param longitude The longitude (in decimal degrees East)
#' @param start_date A string or Date object for the starting date
#' @param finish_date A string or Date object for the finish date
#' @param variables A vector containing the variable names
#' @return The parameter-formatted URL for the data download
#' @keywords internal
#' @examples
#' weathervane:::download_url(-34.9, 138.6, '2020-01-01', '2020-12-31', c('rainfall'))
download_url <- function(
  latitude,
  longitude,
  start_date,
  finish_date,
  variables
) {
  # Base API URL and parameter format specifiers.
  # NOTE: If SILO updates their server/API, these are the things
  #       most likely to need changing in weathervane, so check
  #       here first.
  api_url <- paste0(
    'https://www.longpaddock.qld.gov.au/cgi-bin/silo/',
    'DataDrillDataset.php?'
  )
  weather_vars <- weather_variables()
  params <- list(
    'format' = 'csv',
    'username' = 'apirequest',
    'password' = 'apirequest',
    'lat' = latitude,
    'lon' = longitude,
    'start' = gsub('-', '', as.character(start_date)),
    'finish' = gsub('-', '', as.character(finish_date)),
    'comment' = paste(
      sapply(
        variables,
        function(var) {
          weather_vars[which(weather_vars$variable_name == var), 'silo_code']
        }
      ),
      collapse = ''
    )
  )

  paste0(
    api_url,
    paste(names(params), unlist(params), sep = '=', collapse = '&')
  )
}

#' The earliest date of data available
#'
#' Return a Date object containing the earliest date of data
#' available from the SILO server. (As of checking on 10/03/2021,
#' the earliest date is 01/01/1889, although this may change.)
#'
#' @return A Date object representing the earliest date
#' @keyworks internal
#' @examples
#' weathervane:::earliest_dataset_date()
earliest_dataset_date <- function() {
  as.Date('1889-01-01')
}

#' True if the given coordinates are in Australia
#'
#' Return TRUE if the given latitude and longitude are within the
#' 'bounds' of Australia, where we define those bounds to be the
#' spatial extent of the rasters used by SILO (and also the Bureau
#' of Meteorology) for their gridded datasets. NOTE: These bounds
#' include some parts of Indonesia and Papua New Guinea, but the
#' SILO server processes such coordinates just fine so we don't worry
#' about that here in this interface.
#'
#' @param latitude The latitude (in decimal degrees North)
#' @param longitude The longitude (in decimal degrees East)
#' @return TRUE if the coordinates are within Australia, FALSE if not
#' @keywords internal
#' @examples
#' weathervane:::in_australia(-34.9285, 138.6007)
in_australia <- function(latitude, longitude) {
  (latitude >= -44.53 & latitude <= -9.98) &
    (longitude >= 111.98 & longitude <= 156.27)
}
