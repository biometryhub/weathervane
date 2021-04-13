# Unit testing for the WVane functions.
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson, Biometry Hub
# Date last modified: 13/04/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

require 'test/unit'
require 'open-uri'
require_relative '../wvane'

# Unit testing for the WVane module functions/methods.
# @author Russell A. Edson
# @since 1.1.0
class WVaneTest < Test::Unit::TestCase
  # Setup and instantiate some dummy variables for the module tests.
  def setup
    super

    # Set up dummy latitude/longitude pairs
    @lat1 = -34.9285
    @lng1 = 138.6007
    @lat2 = 52.9548
    @lng2 = -1.1581

    # Set up dummy start and finish dates (in different formats)
    @date1 = '2020-01-01'
    @date2 = '2021-12-31'
    @date3 = '1987-11-23'
    @date4 = '14/07/2008'
    @date5 = '20160411'

    # Set up erroneous dates
    @date_err1 = '1742-03-22'
    @date_err2 = '13/17/2020'
    @date_err3 = '06/18/2009'
    @date_err4 = '2021-14-02'
    @date_err5 = '20151423'

    # Set up some dummy variable lists
    @vars1 = %w[rainfall]
    @vars2 = %w[rainfall max_temp min_temp]
    @vars3 = %w[max_temp max_humidity vapour_pressure_deficit]
    @all_vars = WVane::WEATHER_VARIABLES

    # Set up erroneous variable lists.
    @vars_err1 = %w[rainball]
    @vars_err2 = %w[wind_speed max_temp solar_exposure]
    @vars_err3 = %w[max_humidity min_humidity max_humidity]

    # Set up a dummy URL creator function for the data download.
    #TODO
  end

  # Teardown/clean up for the module tests.
  def teardown
    super
  end

  # Test cases for the :download_data method.
  def test_download_data
    #TODO
    # Test raises error on bad connection/URL

    # Test raises error on bad dates

    # Test raises error on bad coordinates

    # Test that we always get the Date, Latitude and Longitude columns

    # Test that the other columns appear only when there is data and
    # in the expected order.
  end

  # Test cases for the :download_url method. In particular, no error
  # checking takes place in the method: it is expected that the
  # latitude/longitude/dates/variables will all be sanity-checked
  # before this method is called.
  def test_download_url
    # Test that it construct a working URL properly
    url = WVane.download_url(@lat1, @lng1, @date1, @date2, @vars2)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '-34.9285')
    assert_equal(params['lon'], '138.6007')
    assert_equal(params['start'], '20200101')
    assert_equal(params['finish'], '20211231')
    assert_equal(params['comment'], 'RXN')

    # Works when requesting all variables
    url = WVane.download_url(@lat1, @lng1, @date1, @date2, @all_vars)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '-34.9285')
    assert_equal(params['lon'], '138.6007')
    assert_equal(params['start'], '20200101')
    assert_equal(params['finish'], '20211231')
    assert_equal(params['comment'], 'RNXGHJMVDCLFTAPW')


    # NOTE: No error checking takes place in this :download_url method.
    # We can happily pass blank parameters with no error
    url = WVane.download_url(nil, nil, '', '', [])
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '')
    assert_equal(params['lon'], '')
    assert_equal(params['start'], '')
    assert_equal(params['finish'], '')
    assert_equal(params['comment'], '')

    # We can pass latitudes/longitudes outside of Aust. with no error
    url = WVane.download_url(@lat2, @lng2, @date3, @date1, @vars1)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '52.9548')
    assert_equal(params['lon'], '-1.1581')
    assert_equal(params['start'], '19871123')
    assert_equal(params['finish'], '20200101')
    assert_equal(params['comment'], 'R')

    # We can pass erroneous dates with different formats and no error
    url = WVane.download_url(@lat1, @lng1, @date_err2, @date_err3, @vars1)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '-34.9285')
    assert_equal(params['lon'], '138.6007')
    assert_equal(params['start'], '13/17/2020')
    assert_equal(params['finish'], '06/18/2009')
    assert_equal(params['comment'], 'R')

    # We can pass dates outside of the SILO date range with no error
    url = WVane.download_url(@lat1, @lng2, @date_err1, @date_err1, [])
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '-34.9285')
    assert_equal(params['lon'], '-1.1581')
    assert_equal(params['start'], '17420322')
    assert_equal(params['finish'], '17420322')
    assert_equal(params['comment'], '')

    # We can pass misspelled variables in the list with no error
    url = WVane.download_url(@lat1, nil, @date4, @date5, @vars_err1)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '-34.9285')
    assert_equal(params['lon'], '')
    assert_equal(params['start'], '14/07/2008')
    assert_equal(params['finish'], '20160411')
    assert_equal(params['comment'], '')

    # We can pass variables that don't exist with no error
    url = WVane.download_url(nil, @lat1, '', @date_err4, @vars_err2)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '')
    assert_equal(params['lon'], '-34.9285')
    assert_equal(params['start'], '')
    assert_equal(params['finish'], '20211402')
    assert_equal(params['comment'], 'XJ')

    # We can pass duplicate variables in the list with no error
    url = WVane.download_url(@lat2, @lng1, '', @date1, @vars_err3)
    params = URI.decode_www_form(url).slice(1..-1).to_h
    assert_equal(params['username'], 'apirequest')
    assert_equal(params['password'], 'apirequest')
    assert_equal(params['lat'], '52.9548')
    assert_equal(params['lon'], '138.6007')
    assert_equal(params['start'], '')
    assert_equal(params['finish'], '20200101')
    assert_equal(params['comment'], 'HGH')
  end

  # Test cases for the earliest date of dataset observations.
  # Here we also have a tautological test case that tests this earliest
  # date against 01/01/1889: this test is a sentinel that fails if the
  # date is ever updated in the code but not in these test files.
  def test_earliest_dataset_date
    # Sentinel test case
    assert_equal(WVane.earliest_dataset_date.to_s, '1889-01-01')

    # We return a Date object (i.e. not a string or integer).
    assert_kind_of(Date, WVane.earliest_dataset_date)
  end

  # Test cases for the :in_australia? function.
  def test_in_australia?
    assert_true(WVane.in_australia?(@lat1, @lng1))
    assert_true(WVane.in_australia?(-43.5844, 146.7362))
    assert_true(WVane.in_australia?(-28.1999, 153.5669))
    assert_true(WVane.in_australia?(-10.6872, 142.5315))
    assert_true(WVane.in_australia?(-10.0858, 142.1679))
    assert_true(WVane.in_australia?(-25.5647, 112.9601))
    assert_true(WVane.in_australia?(-20.7844, 115.4005))
    assert_true(WVane.in_australia?(-33.5370, 115.0140))
    assert_true(WVane.in_australia?(-35.1302, 117.6227))
    assert_true(WVane.in_australia?(-36.0499, 136.7118))
    assert_true(WVane.in_australia?(-43.4933, 147.3027))
    assert_true(WVane.in_australia?(-39.0992, 146.3834))
    assert_true(WVane.in_australia?(-37.5051, 149.9658))

    assert_false(WVane.in_australia?(-45.8989, 166.7404))
    assert_false(WVane.in_australia?(-40.6563, 172.5851))
    assert_false(WVane.in_australia?(-34.4431, 172.6840))
    assert_false(WVane.in_australia?(-20.2617, 164.1146))
    assert_false(WVane.in_australia?(-8.9443, 141.0763))
    assert_false(WVane.in_australia?(-8.6502, 120.9603))
    assert_false(WVane.in_australia?(-8.5625, 114.0499))

    # FIXME: These coordinates are in Papua New Guinea/Indonesia and
    #        so should return false ideally, but they get included in
    #        the 'box' about Australia defined by the :in_australia?
    #        method. Maybe make the method more sophisticated?
    #assert_false(WVane.in_australia?(-10.5513, 150.2279))
    #assert_false(WVane.in_australia?(-9.0564, 142.1969))
    #assert_false(WVane.in_australia?(-10.7159, 123.1466))
    #assert_false(WVane.in_australia?(-10.1469, 120.4550))
  end
end