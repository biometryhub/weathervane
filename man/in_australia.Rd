% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/weathervane.R
\name{in_australia}
\alias{in_australia}
\title{True if the given coordinates are in Australia}
\usage{
in_australia(latitude, longitude)
}
\arguments{
\item{latitude}{The latitude (in decimal degrees North)}

\item{longitude}{The longitude (in decimal degrees East)}
}
\value{
TRUE if the coordinates are within Australia, FALSE if not
}
\description{
Return TRUE if the given latitude and longitude are within the
'bounds' of Australia, where we define those bounds to be the
spatial extent of the rasters used by SILO (and also the Bureau
of Meteorology) for their gridded datasets. NOTE: These bounds
include some parts of Indonesia and Papua New Guinea, but the
SILO server processes such coordinates just fine so we don't worry
about that here in this interface.
}
\examples{
weathervane:::in_australia(-34.9285, 138.6007)
}
\keyword{internal}
