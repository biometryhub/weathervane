
<!-- README.md is generated from README.Rmd. Please edit that file -->

# weathervane

<!-- badges: start -->

[![Project Status: WIP – Initial development is in progress, but there
has not yet been a stable, usable release suitable for the
public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Licence](https://img.shields.io/github/license/mashape/apistatus.svg)](http://choosealicense.com/licenses/mit/)
[![Package
version](https://img.shields.io/badge/Package%20version-0.1.0-80b6ff.svg)](/DESCRIPTION)
[![R
dependency](https://img.shields.io/badge/R%3E%3D-3.5.0-80b6ff.svg)](https://cran.r-project.org/)
[![R-CMD-check](https://github.com/biometryhub/weathervane/workflows/R-CMD-check/badge.svg)](https://github.com/biometryhub/weathervane/actions)
[![Codecov test
coverage](https://codecov.io/gh/biometryhub/weathervane/branch/main/graph/badge.svg)](https://codecov.io/gh/biometryhub/weathervane?branch=main)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fbiometryhub.github.io%2Fweathervane%2F&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
<!-- badges: end -->

Easily navigate and retrieve weather datasets for anywhere in Australia!

The **weathervane** package aids researchers in retrieving Australian
weather and climate data (sourced from SILO and the Bureau of
Meteorology) to incorporate into statistical analyses of agronomic
experiments and plant-breeding trials.

This R package includes a simple and user-friendly Shiny App for
retrieving weather data, complete with an interactive map, data previews
and CSV spreadsheet export.

![weathervane App](man/figures/app_usage.gif)

Alternatively, import the library and use the weather data retrieval
functions directly in your statistical analysis workflow.

![weathervane package](man/figures/package_usage.gif)

# Installation

Run the following code on your R console to install this package:

``` r
if(!require("remotes")) install.packages("remotes") 
remotes::install_github("biometryhub/weathervane", upgrade = FALSE)
```

# Using the package

Load the package and start using it with:

``` r
library(weathervane)
```

TODO more here

# Attribution to SILO/Bureau of Meteorology

The weather datasets currently retrieved by **weathervane** are curated
by [SILO](https://www.longpaddock.qld.gov.au/silo/), who make them
available under a Creative Commons Attribution 4.0 International
Licence. Their data is in turn mostly sourced from the [Australian
Bureau of Meteorology](http://www.bom.gov.au/) and their weather
stations.

Please reference them appropriately in any publications or other
research outputs that use the downloaded weather data. See for example:
- <https://www.longpaddock.qld.gov.au/silo/about/access-data/>

-   <http://www.bom.gov.au/other/copyright.shtml>

# Credits

TODO
