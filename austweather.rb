#!/usr/bin/ruby

# AustWeather Ruby script for automating the process of downloading
# SILO weather/climate datasets. This program provides a complete
# command-line interface that retrieves datasets for given GPS
# coordinates, start-end times and selected weather variables.
#
# NOTE: The retrieved datasets are curated by SILO, who make them
# available under a Creative Commons Attribution 4.0 International
# Licence, and their data is sourced from the Bureau of Meteorology
# weather stations. Don't forget to cite/reference appropriately!
#
# See for example:
# https://www.longpaddock.qld.gov.au/silo/about/data-suppliers/
# http://www.bom.gov.au/other/copyright.shtml
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
#
# Code author: Russell A. Edson
# Date last modified: 11/03/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# Program name, version number and copyright notice
PROGRAM_NAME = 'AustWeather'.freeze
VERSION_NUMBER = 0.1
COPYRIGHT = 'Copyright (c) 2021 University of Adelaide Biometry Hub'.freeze


# Using the built-in open-uri module for the HTTP GET, and OptionParser
# for parsing the CLI options
require 'open-uri'
require 'optparse'


# The base API URL for the dataset retrieval
API_URL = 'https://www.longpaddock.qld.gov.au/cgi-bin/silo/'\
  'DataDrillDataset.php?'.freeze

# Weather variable codes
# (taken from www.longpaddock.qld.gov.au/silo/about/climate-variables/)
WEATHER_CODES = {
  'rainfall' => 'R',
  'max_temp' => 'X',
  'min_temp' => 'N',
  'max_humidity' => 'H',
  'min_humidity' => 'G',
  'solar_exposure' => 'J',
  'mean_sea_level_pressure' => 'M',
  'vapour_pressure' => 'V',
  'vapour_pressure_deficit' => 'D',
  'evaporation' => 'C',
  'evaporation_morton_lake' => 'L',
  'evapotranspiration_fao56' => 'F',
  'evapotranspiration_asce' => 'T',
  'evapotranspiration_morton_areal' => 'A',
  'evapotranspiration_morton_point' => 'P',
  'evapotranspiration_morton_wet' => 'W'
}.freeze

WEATHER_DESCRIPTION = {
  'rainfall' => 'Daily rainfall (mm)',
  'max_temp' => 'Maximum temperature (degrees Celsius)',
  'min_temp' => 'Minimum temperature (degrees Celsius)',
  'max_humidity' => 'Relative humidity at time of max temperature (%)',
  'min_humidity' => 'Relative humidity at time of min temperature (%)',
  'solar_exposure' => 'Solar exposure (MJ/m2)',
  'mean_sea_level_pressure' => 'Mean pressure at sea level (hPa)',
  'vapour_pressure' => 'Vapour pressure (hPa)',
  'vapour_pressure_deficit' => 'Vapour pressure deficit (hPa)',
  'evaporation' => 'Class A pan evaporation [synthetic estimate pre-1970] (mm)',
  'evaporation_morton_lake' => "Morton's shallow lake evaporation (mm)",
  'evapotranspiration_fao56' => 'FAO56 short crop evapotranspiration (mm)',
  'evapotranspiration_asce' => 'ASCE tall crop evapotranspiration (mm)',
  'evapotranspiration_morton_areal' => "Morton's areal actual ET (mm)",
  'evapotranspiration_morton_point' => "Morton's point potential ET (mm)",
  'evapotranspiration_morton_wet' => "Morton's wet-env areal potential ET (mm)"
}.freeze

WEATHER_VARIABLES = WEATHER_DESCRIPTION.keys.freeze

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: austweather.rb <options>'

  # The user must supply latitude and longitude coordinates
  opts.on('--lat LAT', 'Latitude (decimal, in degrees North)', Float)
  opts.on('--lng LNG', 'Longitude (decimal, in degrees East)', Float)

  # The user must also supply a start date (the end date is optional)
  opts.on('--start STA', 'Start date (YYYY-MM-DD)', String)
  opts.on('--end END', 'End date (YYYY-MM-DD)', String)

  # Optionally, the user can specify a variable (by default, this
  # program returns all variables possible for the given date range
  # and latitude/longitude coordinates). Also optionally specify
  # a filename for the output dataset (by default, we just amalgamate
  # the latitude, longitude, start date and variable name).
  opts.on('--vars VARS', 'Weather variables to retrieve', Array)
  opts.on('-o', '--out OUT', 'The filename for the output dataset', String)

  # Standard options for GNU-style command line programs
  opts.on('-v', '--verbose', 'Show verbose/debug output')
  opts.on('-V', '--version', 'Print version information') do
    puts PROGRAM_NAME + ' ' + VERSION_NUMBER.to_s + "\n" + COPYRIGHT
    exit(0)
  end
  opts.on('--help', 'Prints this help information') do
    puts opts

    # List the climate variables and sensible options for the parameters
    puts "\nWeather/climate variables available:"
    WEATHER_DESCRIPTION.map do |var, description|
      puts '  ' + var + ': ' + description
    end
    puts 'Extract as many variables as you like by separating with a comma.'

    # Usage example
    puts "\nExample: 2020 rainfall and max temp data in Adelaide"
    puts 'austweather.rb --lat -34.9285 --lng 138.6007 '\
         '--start 2020-01-01 --end 2020-12-31 --vars rainfall,max_temp '\
         '--out mydata.csv'
    exit(0)
  end
end.parse!(into: options)
verbose = options[:verbose]

# If verbose output, echo the input CLI arguments for inspection.
puts 'CLI options: ' + options.to_s if verbose

# Latitude and longitude have to be provided
latitude = options[:lat]
longitude = options[:lng]
if !latitude && !longitude
  puts 'ERROR: Latitude AND longitude coordinates must be provided.'
  exit(1)
end

# Latitude and Longitude must be (roughly) within Australia bounds.
# The extent for BOM rasters is:
#   -44.525 <= latitude <= -9.975
#   111.975 <= longitude <= 156.275
if latitude < -44.53 || latitude > -9.98
  puts 'ERROR: Latitude must be within -44.53 and -9.97 degrees North.'
  exit(1)
end

if longitude < 111.98 || longitude > 156.27
  puts 'ERROR: Longitude must be within 111.98 and 156.27 degrees East.'
  exit(1)
end

# Make sure that the start date doesn't exceed the oldest date of
# data available (01/01/1889, as of checking on the 10/03/2021)
start_date = options[:start].gsub('-', '').to_i
if start_date < 18890101
  puts 'ERROR: The given start date cannot precede 1889-01-01.'
  exit(1)
end

# Make sure that the end date (if provided) appears after the
# start date. If no end date was provided, just use the current
# date as the end date.
end_date = options[:end]
if end_date
  end_date = end_date.gsub('-', '').to_i
  if end_date < start_date
    puts 'ERROR: The given end date must not precede the start date.'
    exit(1)
  end
else
  end_date = Time.now.strftime('%Y%m%d').to_i
  puts 'No end date provided: defaulting to ' + end_date.to_s if verbose
end

# Make sure that the given set of variables each exist in the
# set of available variables. If no variables were given, we grab all
# available variables by default.
variables = options[:vars]
if variables
  okay_variables = variables.map { |var| WEATHER_VARIABLES.include?(var) }

  unless okay_variables.all?
    erroneous_variable = variables[okay_variables.index(false)]
    puts 'ERROR: ' + erroneous_variable + ' is not in the list of '\
    'available variables (did you misspell the variable?)'
    exit(1)
  end
else
  variables = WEATHER_VARIABLES
  puts 'No variables specified: defaulting to retrieving all variables.'
end

# Check the output file. If the file already exists, exit. If no
# file was specified, default to a timestamped dummy label.
output_file = options[:out]
unless output_file
  output_file = 'austweather_data_' + Time.now.strftime('%Y%m%d') + '.csv'
  puts 'No output file specified: downloading to ' + output_file
end

if File.exist?(output_file)
  puts 'ERROR: The file ' + output_file + ' already exists. Exiting.'
  exit(1)
end

# Construct the download URL with the data parameters
url_params = {
  'format' => 'csv',
  'username' => 'apirequest',
  'password' => 'apirequest',
  'lat' => latitude,
  'lon' => longitude,
  'start' => start_date,
  'finish' => end_date,
  'comment' => variables.map { |var| WEATHER_CODES[var] } .join('')
}
url = API_URL + URI.encode_www_form(url_params)
puts url




# Need to check the response: certain combinations can still give
# errors, which this program should handle gracefully.

# TODO: some formatting of the CSV. change column titles, etc.

# Finally, show (pretty-formatted!) the first six rows and then exit.
