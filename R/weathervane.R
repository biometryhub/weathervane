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
# Date last modified: 17/08/2021
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

##TODO: A public-facing wrapper for download_data(download_url),
##      complete with error checking. What's a good name for this?


#' (Private) Download the weather data from the constructed URL
#'
#' Return a data frame containing the SILO weather dataset,
#' complete with prettied column names, from the given download
#' URL.
#'
#' @param url A character string containing the download URL
#' @return A data.frame containing the specified weather data
#' @seealso [download_url()] to generate the requisite URLs.
#' @examples
#' download_data(
#'   download_url(-34.9, 138.6, '2020-01-01', '2020-12-31', c('rainfall'))
#' )
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

  # TODO (finish this)


}

#' (Private) The download URL for the SILO weather data download
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
#' @examples
#' download_url(-34.9, 138.6, '2020-01-01', '2020-12-31', c('rainfall'))
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

#' (Private) The earliest date of data available
#'
#' Return a Date object containing the earliest date of data
#' available from the SILO server. (As of checking on 10/03/2021,
#' the earliest date is 01/01/1889, although this may change.)
#'
#' @return A Date object representing the earliest date
#' @examples
#' earliest_dataset_date()
earliest_dataset_date <- function() {
  as.Date('1889-01-01')
}

#' (Private) True if the given coordinates are in Australia
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
#' @examples
#' in_australia(-34.9285, 138.6007)
in_australia <- function(latitude, longitude) {
  (latitude >= -44.53 & latitude <= -9.98) &
    (longitude >= 111.98 & longitude <= 156.27)
}











# TODO: Scaffolding below: mid-refactoring this into the above functions.

#
#
# # return weather as a data frame. TODO unit test this too.
# # default parameters: end date is today's system date, and
# # by sane default get all available variables (so you don't have to
# # mess about remembering the names if you don't want.)
# # TODO: Change name.
# get_austweather <- function(
#   lat,
#   lng,
#   start,
#   finish = Sys.Date(),
#   vars = weather_meta$name
# ) {
#   # Latitude and longitude have to be provided and roughly within
#   # Australia bounds
#   if (lat < -44.53 | lat > -9.98) {
#     stop('Latitude must be within -44.53 and -9.97 degrees North.')
#   }
#   if (lng < 111.98 | lng > 156.27) {
#     stop('Longitude must be within 111.98 and 156.27 degrees East.')
#   }
#
#   # Parse the start date, and make sure that it doesn't precede the
#   # oldest date of data available (01/01/1889, as of checking on the
#   # 10/03/2021).
#   start <- as.numeric(gsub('-', '', strftime(start, format = '%Y-%m-%d')))
#   if (start < 18890101) {
#     stop('The given start date cannot precede 1889-01-01.')
#   }
#
#   # Parse the end date (if provided), and make sure that it appears
#   # after the start date.
#   finish <- as.numeric(gsub('-', '', strftime(finish, format = '%Y-%m-%d')))
#   if (finish < start) {
#     stop('The given end date must not precede the start date.')
#   }
#
#   # Make sure that the given set of variables each exist in the set
#   # of available variables. (If no variables were given, we grab all
#   # available variables by default.)
#   okay_variables <- vars %in% weather_meta$name
#   if (!all(okay_variables)) {
#     erroneous_variable <- vars[which(okay_variables == FALSE)[1]]
#     message <- paste0(
#       erroneous_variable,
#       ' is not in the list of available variables (did you misspell the ',
#       'variable?)\n',
#       'Available variables are:\n',
#       paste(weather_meta$name, collapse = '  '),
#       '\n'
#     )
#     stop(message)
#   }
#
#   # Construct the download URL with the data parameters
#   url_params <- list(
#     'format' = 'csv',
#     'username' = 'apirequest',
#     'password' = 'apirequest',
#     'lat' = lat,
#     'lon' = lng,
#     'start' = start,
#     'finish' = finish,
#     'comment' = paste(
#       sapply(
#         vars,
#         function(var) { weather_meta[which(weather_meta$name == var), 'code'] }
#       ),
#       collapse = ''
#     )
#   )
#   url <- paste0(
#     api_url,
#     paste(names(url_params), unlist(url_params), sep = '=', collapse = '&')
#   )
#
#   # Download the weather data HTML using the constructed URL
#   data <- xml2::xml_text(xml2::read_html(url))
#   data <- read.table(text = data, header = TRUE, sep = ',')
#
#   # Delete 'source' columns (if any)
#   source_columns <- colnames(data)[grepl('_source', colnames(data))]
#   data <- data[ , !(colnames(data) %in% source_columns)]
#
#   # Delete the 'metadata' column
#   # TODO: Need to get the elevation data first!
#   data <- data[ , !(colnames(data) == 'metadata')]
#
#   # Change column names to be more reader-friendly
#   silo_names <- colnames(data)
#   silo_names[which(silo_names == 'latitude')] <- 'Latitude'
#   silo_names[which(silo_names == 'longitude')] <- 'Longitude'
#   silo_names[which(silo_names == 'YYYY.MM.DD')] <- 'Date'
#   for (i in which(silo_names %in% weather_meta$SILO_name)) {
#     var <- weather_meta[which(weather_meta$SILO_name == silo_names[i]), ]
#     silo_names[i] <- var$pretty_name
#   }
#   data <- `colnames<-`(data, silo_names)
#
#   # Sort so that the columns are in the desired order.
#   var_order <- which(silo_names == 'Date')
#   var_order <- c(var_order, which(silo_names == 'Latitude'))
#   var_order <- c(var_order, which(silo_names == 'Longitude'))
#   for (i in 1:length(weather_meta$pretty_name)) {
#     var_order <- c(var_order, which(silo_names == weather_meta$pretty_name[i]))
#   }
#   data <- data[ , var_order]
#
#   data
# }
#


