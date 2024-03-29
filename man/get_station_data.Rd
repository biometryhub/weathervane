% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/stations.R
\name{get_station_data}
\alias{get_station_data}
\title{Retrieve weather data for the given station ID and dates}
\usage{
get_station_data(
  station,
  start_date,
  finish_date = Sys.Date(),
  variables = weather_variables()$variable_name,
  pretty_names = TRUE
)
}
\arguments{
\item{station}{A numeric station ID, or else a character station name.}

\item{start_date}{A string or Date object for the starting date}

\item{finish_date}{A string or Date object for the finish date
(Default: today's date, so retrieves up to most recently updated
weather data available)}

\item{variables}{A vector containing the variable names
(Default: retrieve all available weather variables)}

\item{pretty_names}{Whether to format the columns with prettied
variable names (Default: TRUE). Set this to FALSE to format
the column names as syntactically valid variable names (at the
cost of some readability)}
}
\value{
A data.frame containing the downloaded weather data
}
\description{
Return a data frame containing SILO Australian weather data
for the specified weather station, date range (from start_date
to finish_date, inclusive) and the specified variables. By default,
all available weather variables are returned if none are specified.
If no finish date is provided, the date range is taken from the
given start date up to today's date (i.e. so up to the most
recently uploaded weather information on the SILO server, which is
updated daily).
}
\examples{
weather_data <- get_station_data(
  23031, '2020-01-01', '2020-03-31', c('rainfall', 'max_temp')
)
head(weather_data)

}
