#!/usr/bin/ruby

# Copyright (c) 2021 University of Adelaide Biometry Hub
#
# Code author: Russell A. Edson
# Date last modified: 09/03/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# Using the built-in open-uri module for the HTTP GET, and OptionParser
# for parsing the CLI options
require 'open-uri'
require 'optparse'


# Program name, version number and copyright notice
PROGRAM_NAME = 'AustWeather'.freeze
VERSION_NUMBER = 0.1
COPYRIGHT = 'Copyright (c) 2021 University of Adelaide Biometry Hub'.freeze

# The base API URL for the dataset retrieval
API_URL = 'https://www.longpaddock.qld.gov.au/cgi-bin/silo/'.freeze

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
# TODO: WEATHER_DESCRIPTION to describe these, plus units.


# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: austweather.rb <options>'


  # The user must supply latitude and longitude coordinates
  opts.on('--latitude LAT', 'Latitude (decimal, in degrees North)', Float)
  opts.on('--longitude LNG', 'Longitude (decimal, in degrees East)', Float)

  # The user must also supply a start date and end date
  opts.on('--start STA', 'Start date (YYYY-MM-DD)', String)
  opts.on('--end END', 'End date (YYYY-MM-DD)', String)

  # Optionally, the user can specify a variable (by default, this
  # program returns all variables possible for the given date range
  # and latitude/longitude coordinates). Also optionally specify
  # a filename for the output dataset (by default, we just amalgamate
  # the latitude, longitude, start date and variable name).
  opts.on('--variables VARS', 'Weather variables to retrieve', Array)
  opts.on('--output OUT', 'The filename for the output dataset', String)

  # Standard options for GNU-style command line programs
  opts.on('-v', '--verbose', 'Show verbose/debug output')
  opts.on('-V', '--version', 'Print version information') do
    puts PROGRAM_NAME + ' ' + VERSION_NUMBER.to_s + "\n" + COPYRIGHT
    exit
  end
  opts.on('--help', 'Prints this help information') do
    puts opts
    # TODO: An example query/download command here. List the variables
    #       available too?
    exit
  end
end.parse!(into: options)
verbose = options[:verbose]

# If verbose output, echo the input CLI arguments for inspection.
puts 'CLI options: ' + options.to_s if verbose


