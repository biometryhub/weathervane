#!/usr/bin/env ruby

# wVane: A Ruby module and script for automating the process of
# downloading SILO weather/climate datasets. Easily retrieve weather
# datasets for given GPS coordinates and start/end dates. The script
# provides a complete command-line interface for easy data retrieval.
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
# Date last modified: 03/05/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# Using the built-in open-uri module for the HTTP GET, and csv for
# parsing the downloaded CSV
require 'open-uri'
require 'csv'

# Namespace for wVane data download functions and URL formatting.
# @author Russell A. Edson
# @since 1.2.0
module WVane
  PROGRAM_NAME = 'wVane'.freeze
  VERSION_NUMBER = '1.2.0'.freeze
  COPYRIGHT = 'Copyright (c) 2021 University of Adelaide Biometry Hub'.freeze

  # The base API URL for the dataset retrieval
  API_URL = 'https://www.longpaddock.qld.gov.au/cgi-bin/silo/'\
    'DataDrillDataset.php?'.freeze

  # Weather variable descriptions, codes and 'prettied' variable names
  # See also:
  #   https://www.longpaddock.qld.gov.au/silo/about/climate-variables/
  WEATHER_VARIABLES = %w[
    rainfall min_temp max_temp humidity_tmin humidity_tmax solar_exposure
    mean_sea_level_pressure vapour_pressure vapour_pressure_deficit
    evaporation evaporation_morton_lake evapotranspiration_fao56
    evapotranspiration_asce evapotranspiration_morton_areal
    evapotranspiration_morton_point evapotranspiration_morton_wet
  ].freeze

  WEATHER_PRETTY = WEATHER_VARIABLES.zip(
    ['Rainfall (mm)', 'Minimum Temperature (degC)',
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
     "Morton's Wet-environment Areal Potential Evapotranspiration (mm)"]
  ).to_h.freeze

  WEATHER_DESCRIPTION = WEATHER_VARIABLES.zip(
    ['Daily rainfall (mm)', 'Minimum temperature (degrees Celsius)',
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
     "Morton's wet-environment areal potential evapotranspiration (mm)"]
  ).to_h.freeze

  WEATHER_CODES = WEATHER_VARIABLES.zip(
    %w[R N X G H J M V D C L F T A P W]
  ).to_h.freeze

  WEATHER_SILO_NAMES = WEATHER_VARIABLES.zip(
    %w[daily_rain min_temp max_temp rh_tmin rh_tmax radiation mslp vp
       vp_deficit evap_comb evap_morton_lake et_short_crop et_tall_crop
       et_morton_actual et_morton_potential et_morton_wet]
  ).to_h.freeze

  module_function

  # Return a CSV::Table containing the weather data, with prettied
  # column names, from the given download URL (see :download_url).
  #
  # @param url [String] The parameter-formatted download URL.
  # @raise [OpenURI::HTTPError] Errors on a broken HTTP connection.
  # @raise [StandardError] Errors on server-side errors (e.g. for
  #   invalid date or latitude/longitude).
  # @return [CSV::Table] A CSV table containing the downloaded data.
  #
  # @example
  #   download_data(download_url(-34.9, 138.6, '2021-01-01'))
  def download_data(url)
    data = URI.open(url)
    data = CSV.parse(data, headers: true).by_col!

    # Test for invalid dates
    error_message = 'Invalid date'
    if data.to_s.include?(error_message)
      error_message = 'Invalid start date'
      raise StandardError, 'Server-side error: ' + error_message
    end

    # Test for invalid coordinates
    error_message = 'not in Australia'
    if data.to_s.include?(error_message)
      error_message = 'Latitude/longitude not within Australia'
      raise StandardError, 'Server-side error: ' + error_message
    end

    # Data prettying: remove superfluous 'source' columns
    source_columns = data.headers.select { |header| header[/_source/] }
    source_columns.map { |column| data.delete(column) }

    # Define a closure for changing column names in the CSV table
    # Note: This implicitly reorders the columns: columns will appear
    # from left to right in the order that they are changed.
    change_column_name = lambda do |old_name, new_name|
      if data.headers.include?(old_name)
        data[new_name] = data[old_name]
        data.delete(old_name)
      end
    end

    # The first three columns are the Date, Latitude and Longitude
    change_column_name['YYYY-MM-DD', 'Date']
    data['Date'] = data['Date'].map(&:strip)

    change_column_name['latitude', 'Latitude']
    data['Latitude'] = data['Latitude'].map(&:to_f)

    change_column_name['longitude', 'Longitude']
    data['Longitude'] = data['Longitude'].map(&:to_f)

    # Retrieve the elevation (if listed) from the metadata and add it
    # in as a new column (otherwise add a blank Elevation column).
    metadata = data['metadata'].to_a
    elevation = ''
    if metadata.any?
      elevation = metadata.select { |row| row.include?('elevation') }[0]
      elevation = elevation[/\d+[,.]\d+/].to_f
    end
    data.delete('metadata')
    data['Elevation (m)'] = elevation

    # Reorder/pretty all of the weather variable columns in turn.
    WEATHER_VARIABLES.each do |variable|
      silo_name = WEATHER_SILO_NAMES[variable]
      prettied_name = WEATHER_PRETTY[variable]
      change_column_name[silo_name, prettied_name]

      # Reformat the data as floating point values for the CSV.
      if data[prettied_name].any?
        data[prettied_name] = data[prettied_name].map do |value|
          value.to_f if value
        end
      end
    end

    data
  end

  # Return the parameter-formatted download URL, given the location
  # (in latitude/longitude coordinates), the start and finish dates of
  # interest, and the list of variables to be retrieved.
  #
  # @param latitude [Float] The latitude (in decimal degrees North).
  # @param longitude [Float] The longitude (in decimal degrees East).
  # @param start_date [String] The start date (in format YYYY-MM-DD).
  # @param finish_date [String] The finish date (in format YYYY-MM-DD).
  # @param variables [Array] The list of variables to be retrieved.
  # @return [String] The properly-formatted URL for the data download.
  #
  # @example
  #   download_url(-34.9, 138.6, '2020-01-01', '2020-12-31', ['rainfall'])
  def download_url(latitude, longitude, start_date, finish_date, variables)
    params = {
      'format' => 'csv',
      'username' => 'apirequest',
      'password' => 'apirequest',
      'lat' => latitude.to_s,
      'lon' => longitude.to_s,
      'start' => start_date.to_s.gsub('-', ''),
      'finish' => finish_date.to_s.gsub('-', ''),
      'comment' => variables.map { |var| WEATHER_CODES[var] }.join('')
    }
    API_URL + URI.encode_www_form(params)
  end

  # Return the earliest date of data available.
  # TODO: For SILO, as of my check on 10/03/2021, the earliest date
  #       of data available is 01/01/1889.
  #
  # @return [Date] The date of the earliest data observation available.
  #
  # @example
  #   earliest_dataset_date.to_s  #=> "1889-01-01"
  def earliest_dataset_date
    Date.parse('1889-01-01')
  end

  # Return true if the given latitude and longitude coordinates are
  # within the bounds of Australia. (Note: we use the same extent as
  # the rasters used by the Bureau of Meteorology in their gridded
  # datasets).
  #
  # @param latitude [Float] The latitude (in decimal degrees North).
  # @param longitude [Float] The longitude (in decimal degrees East).
  # @return [true,false] True if the coordinates are within Australia.
  #
  # @example
  #   in_australia?(-34.9285, 138.6007)  #=> true
  def in_australia?(latitude, longitude)
    (latitude >= -44.53 && latitude <= -9.98) \
      && (longitude >= 111.98 && longitude <= 156.27)
  end
end

# Run the wvane command-line program if this file was invoked as
# a script.
if $PROGRAM_NAME == __FILE__
  # Using OptionParser to process the command-line options
  require 'optparse'
  require 'optparse/date'

  # Parse command-line options
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: wvane.rb [options]'

    # The user must supply latitude and longitude coordinates
    opts.on('--lat LAT', 'Latitude (decimal degrees North)', Float)
    opts.on('--lng LNG', 'Longitude (decimal degrees East)', Float)

    # The user must specify a start date (the end date is optional)
    opts.on('--start START', 'Start date (YYYY-MM-DD or DD/MM/YYYY)', Date)
    opts.on('--finish FINISH', 'Finish date (YYYY-MM-DD or DD/MM/YYYY)', Date)

    # Optionally the user can specify variables to retrieve. By
    # default, this program returns all available variables for the
    # given date range and latitude/longitude coordinates.
    opts.on(
      '--vars VARS',
      'Weather variables to retrieve (default=all available variables)',
      Array
    )

    # Optionally the user can specify a filename for the output data
    # CSV. By default, saves to timestamped 'wVane_data_YYYYMMDD.csv',
    # appending an integer as appropriate to ensure that it saves to
    # a new file.
    opts.on(
      '-oOUT',
      '--out OUT',
      'Filename for the output data (default="wVane_data_YYYYMMDD.csv")',
      String
    )

    # Standard options for GNU-style command line programs
    opts.on('-v', '--verbose', 'Show verbose/debug output')
    opts.on('-V', '--version', 'Print version information') do
      puts WVane::PROGRAM_NAME + ' ' + WVane::VERSION_NUMBER.to_s \
        + "\n" + WVane::COPYRIGHT
      exit(0)
    end

    # List the weather variables and sensible options for the
    # parameters in the help screen, and include a usage example
    opts.on('--help', 'Prints this help information') do
      puts opts

      # List all of the weather variables and descriptions
      puts "\nWeather/climate variables available:"
      WVane::WEATHER_DESCRIPTION.map do |var, description|
        puts '  ' + var + ': ' + description
      end
      puts 'Extract as many variables as you like by separating with a comma.'

      # Usage example
      puts "\nExample: 2020 rainfall and maximum temperature in Adelaide"
      puts 'wvane.rb --lat -34.9285 --lng 138.6007 --start 2020-01-01 '\
        '--finish 2020-12-31 --vars rainfall,max_temp --out mydata.csv'
      exit(0)
    end
  end.parse!(into: options)
  verbose = options[:verbose]

  # Echo the CLI options for inspection if verbose/debug
  puts 'CLI options: ' + options.to_s if verbose

  # Latitude, longitude, and start date must be provided
  raise OptionParser::MissingArgument, 'lat' if options[:lat].nil?
  raise OptionParser::MissingArgument, 'lng' if options[:lng].nil?
  raise OptionParser::MissingArgument, 'start' if options[:start].nil?

  # Latitude and longitude should be (roughly) within Australia bounds
  latitude = options[:lat]
  longitude = options[:lng]
  unless WVane.in_australia?(latitude, longitude)
    error_message = 'Latitude and longitude coordinates must be within '\
      'Australia (roughly -44.53 < lat < -9.97, 111.98 < lng < 156.27).'
    raise StandardError, error_message
  end

  # The start date must not precede the oldest date of data available.
  start_date = options[:start]
  if start_date < WVane.earliest_dataset_date
    error_message = 'The given start date cannot precede 1889-01-01.'
    raise StandardError, error_message
  end

  # The (optional) finish date must not precede the start date. If not
  # provided, just take the current date as the finish date.
  finish_date = options[:finish]
  if finish_date
    if finish_date < start_date
      error_message = 'The given finish date cannot precede the start date.'
      raise StandardError, error_message
    end
  else
    finish_date = Date.today
    if verbose
      puts 'No finish date specified: defaulting to ' + finish_date.to_s
    end
  end

  # Make sure that the given variables each exist within the set of
  # available variables. (If no variables were specified, we grab all
  # of them.)
  variables = options[:vars]
  if variables
    valid_variables = variables.map do |var|
      WVane::WEATHER_VARIABLES.include?(var)
    end
    unless valid_variables.all?
      invalid_variable = variables[valid_variables.index(false)]
      error_message = invalid_variable + ' is not in the list of available '\
        'variables; did you misspell the variable?'
      raise StandardError, error_message
    end
  else
    variables = WVane::WEATHER_VARIABLES
    if verbose
      puts 'No variables specified: defaulting to all available variables.'
    end
  end

  # If no output file was provided, default to a timestamped label.
  output_file = options[:out]
  unless output_file
    output_file = 'wvane_data_' + Date.today.to_s + '.csv'
    if verbose
      puts 'No output file specified: downloading to ' + output_file + '.'
    end
  end

  # If the file exists, increment a suffix to ensure a new file.
  if File.exist?(output_file)
    extension = File.extname(output_file)
    prefix = File.basename(output_file, extension)
    suffix = 1
    loop do
      output_file = prefix + '_' + suffix.to_s + extension
      break unless File.exist?(output_file)

      # Keep incrementing until we get a new filename.
      suffix += 1
    end

    puts 'File ' + prefix + extension + ' already exists; downloading to ' +
         output_file + ' instead.'
  end

  # Construct the download URL. (URI.open throws an exception if there
  # are any HTTP/connection errors.)
  download_url = WVane.download_url(
    latitude,
    longitude,
    start_date,
    finish_date,
    variables
  )
  puts 'Data Download URL: ' + download_url if verbose

  # Download the data into a prettied CSV table
  puts 'Downloading...'
  data = WVane.download_data(download_url)

  # Finally, show (pretty-printed) the first N=6 rows.
  num_rows = 6
  column_sep = '  '
  column_widths = data.map do |column|
    column.flatten.map(&:to_s).map(&:strip).map(&:length).max
  end
  data.by_row!.to_a[0, num_rows + 1].each do |row|
    row_string = []
    row.each_with_index do |column, index|
      row_string << column.to_s.rjust(column_widths[index])
    end
    puts row_string.join(column_sep)
  end

  # Write the data to a nicely-formatted CSV and exit.
  File.open(output_file, 'w') { |file| file.write(data.to_csv) }
  puts 'Data successfully downloaded to ' + output_file + '.'
end
