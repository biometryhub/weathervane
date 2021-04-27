# wVane: An R package for automating the process of downloading
# SILO weather/climate datasets. Easily retrieve weather datasets for
# given GPS coordinates and start/end dates for use in your projects.
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson
# Date last modified: 16/04/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au


#'
#'
#'
weather_variables <- function() {
  data.frame(
    check.names = FALSE,
    variable_name = c(
      'rainfall', 'min_temp', 'max_temp', 'min_humidity', 'max_humidity',
      'solar_exposure', 'mean_sea_level_pressure', 'vapour_pressure',
      'vapour_pressure_deficit', 'evaporation', 'evaporation_morton_lake',
      'evapotranspiration_fao56', 'evapotranspiration_asce',
      'evapotranspiration_morton_areal', 'evapotranspiration_morton_point',
      'evapotranspiration_morton_wet'
    ),
    pretty_name = c(
      'Rainfall (mm)', 'Minimum Temperature (degC)',
      'Maximum Temperature (degC)', 'Minimum Relative Humidity (%)',
      'Maximum Relative Humidity (%)', 'Solar Exposure (MJ/m2)',
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
    code = c(
      'R', 'N', 'X', 'G', 'H', 'J', 'M', 'V', 'D', 'C', 'L', 'F', 'T', 'A',
      'P', 'W'
    ),
    silo_name = c(
      'daily_rain', 'min_temp', 'max_temp', 'rh_tmin', 'rh_tmax', 'radiation',
      'mslp', 'vp', 'vp_deficit', 'evap_comb', 'evap_morton_lake',
      'et_short_crop', 'et_tall_crop', 'et_morton_actual',
      'et_morton_potential', 'et_morton_wet'
    )
  )
}









# The main crux of the App download/plotting/etc stuff for the
# weather variables goes here. The idea should be that a user could
# simply read in this file and automatically have access to all of
# the R functions that do the data download to a data.frame/file.

# Will also need ggplot functions for the small weather variable
# 'preview' plots.





# TODO: these need to be functions, and/or embedded in functions.

api_url <- paste0(
  'https://www.longpaddock.qld.gov.au/cgi-bin/silo/',
  'DataDrillDataset.php?'
)

# Weather data names, codes, prettied variable names and descriptions
# (codes taken from www.longpaddock.qld.gov.au/silo/about/climate-variables/)
weather_meta <- data.frame(
  name = c(
    'rainfall', 'min_temp', 'max_temp', 'min_humidity', 'max_humidity',
    'solar_exposure', 'mean_sea_level_pressure', 'vapour_pressure',
    'vapour_pressure_deficit', 'evaporation', 'evaporation_morton_lake',
    'evapotranspiration_fao56', 'evapotranspiration_asce',
    'evapotranspiration_morton_areal', 'evapotranspiration_morton_point',
    'evapotranspiration_morton_wet'
  ),
  SILO_name = c(
    'daily_rain', 'min_temp', 'max_temp', 'rh_tmin', 'rh_tmax', 'radiation',
    'mslp', 'vp', 'vp_deficit', 'evap_comb', 'evap_morton_lake',
    'et_short_crop', 'et_tall_crop', 'et_morton_actual', 'et_morton_potential',
    'et_morton_wet'
  ),
  code = c(
    'R', 'N', 'X', 'G', 'H', 'J', 'M', 'V', 'D', 'C', 'L', 'F', 'T', 'A', 'P',
    'W'
  ),
  pretty_name = c(
    'Rainfall (mm)', 'Minimum Temperature (degC)', 'Maximum Temperature (degC)',
    'Minimum Relative Humidity (%)', 'Maximum Relative Humidity (%)',
    'Solar Exposure (MJ/m2)', 'Mean Pressure at Sea Level (hPa)',
    'Vapour Pressure (hPa)', 'Vapour Pressure Deficit (hPa)',
    'Evaporation (mm)', "Morton's Shallow Lake Evaporation (mm)",
    'FAO56 Short Crop Evapotranspiration (mm)',
    'ASCE Tall Crop Evapotranspiration (mm)',
    "Morton's Areal Actual Evapotranspiration (mm)",
    "Morton's Point Potential Evapotranspiration (mm)",
    "Morton's Wet-environment Areal Potential Evapotranspiration (mm)"
  ),
  description = c(
    'Daily rainfall (mm)', 'Minimum temperature (degrees Celsius)',
    'Maximum temperature (degrees Celsius)',
    'Relative humidity at time of min temperature (%)',
    'Relative humidity at time of max temperature (%)',
    'Solar exposure (MJ/m2)', 'Mean pressure at sea level (hPa)',
    'Vapour pressure (hPa)', 'Vapour pressure deficit (hPa)',
    'Class A pan evaporation [synthetic estimate pre-1970] (mm)',
    "Morton's shallow lake evaporation (mm)",
    'FAO56 short crop evapotranspiration (mm)',
    'ASCE tall crop evapotranspiration (mm)',
    "Morton's areal actual ET (mm)",
    "Morton's point potential ET (mm)",
    "Morton's wet-env areal potential ET (mm)"
  )
)


# return weather as a data frame. TODO unit test this too.
# default parameters: end date is today's system date, and
# by sane default get all available variables (so you don't have to
# mess about remembering the names if you don't want.)
get_austweather <- function(
  lat,
  lng,
  start,
  finish = Sys.Date(),
  vars = weather_meta$name
) {
  # Latitude and longitude have to be provided and roughly within
  # Australia bounds
  if (lat < -44.53 | lat > -9.98) {
    stop('Latitude must be within -44.53 and -9.97 degrees North.')
  }
  if (lng < 111.98 | lng > 156.27) {
    stop('Longitude must be within 111.98 and 156.27 degrees East.')
  }

  # Parse the start date, and make sure that it doesn't precede the
  # oldest date of data available (01/01/1889, as of checking on the
  # 10/03/2021).
  start <- as.numeric(gsub('-', '', strftime(start, format = '%Y-%m-%d')))
  if (start < 18890101) {
    stop('The given start date cannot precede 1889-01-01.')
  }

  # Parse the end date (if provided), and make sure that it appears
  # after the start date.
  finish <- as.numeric(gsub('-', '', strftime(finish, format = '%Y-%m-%d')))
  if (finish < start) {
    stop('The given end date must not precede the start date.')
  }

  # Make sure that the given set of variables each exist in the set
  # of available variables. (If no variables were given, we grab all
  # available variables by default.)
  okay_variables <- vars %in% weather_meta$name
  if (!all(okay_variables)) {
    erroneous_variable <- vars[which(okay_variables == FALSE)[1]]
    message <- paste0(
      erroneous_variable,
      ' is not in the list of available variables (did you misspell the ',
      'variable?)\n',
      'Available variables are:\n',
      paste(weather_meta$name, collapse = '  '),
      '\n'
    )
    stop(message)
  }

  # Construct the download URL with the data parameters
  url_params <- list(
    'format' = 'csv',
    'username' = 'apirequest',
    'password' = 'apirequest',
    'lat' = lat,
    'lon' = lng,
    'start' = start,
    'finish' = finish,
    'comment' = paste(
      sapply(
        vars,
        function(var) { weather_meta[which(weather_meta$name == var), 'code'] }
      ),
      collapse = ''
    )
  )
  url <- paste0(
    api_url,
    paste(names(url_params), unlist(url_params), sep = '=', collapse = '&')
  )

  # TODO: Might need some URL sanity-checking here? Also perhaps
  #       need to check for broken collections, etc.
  #       Also sometimes certain sets of coordinates don't return
  #       anything (e.g. if they're in the middle of the ocean), so
  #       we should check for those here too.

  # Download the weather data HTML using the constructed URL
  data <- xml2::xml_text(xml2::read_html(url))
  data <- read.table(text = data, header = TRUE, sep = ',')

  # Delete 'source' columns (if any)
  source_columns <- colnames(data)[grepl('_source', colnames(data))]
  data <- data[ , !(colnames(data) %in% source_columns)]

  # Delete the 'metadata' column
  # TODO: Need to get the elevation data first!
  data <- data[ , !(colnames(data) == 'metadata')]

  # Change column names to be more reader-friendly
  silo_names <- colnames(data)
  silo_names[which(silo_names == 'latitude')] <- 'Latitude'
  silo_names[which(silo_names == 'longitude')] <- 'Longitude'
  silo_names[which(silo_names == 'YYYY.MM.DD')] <- 'Date'
  for (i in which(silo_names %in% weather_meta$SILO_name)) {
    var <- weather_meta[which(weather_meta$SILO_name == silo_names[i]), ]
    silo_names[i] <- var$pretty_name
  }
  data <- `colnames<-`(data, silo_names)

  # Sort so that the columns are in the desired order.
  var_order <- which(silo_names == 'Date')
  var_order <- c(var_order, which(silo_names == 'Latitude'))
  var_order <- c(var_order, which(silo_names == 'Longitude'))
  for (i in 1:length(weather_meta$pretty_name)) {
    var_order <- c(var_order, which(silo_names == weather_meta$pretty_name[i]))
  }
  data <- data[ , var_order]

  data
}



