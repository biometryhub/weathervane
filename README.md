
<!-- README.md is generated from README.Rmd. Please edit that file -->

# weathervane

<!-- badges: start -->

[![Project Status: WIP – Initial development is in progress, but there
has not yet been a stable, usable release suitable for the
public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Licence](https://img.shields.io/github/license/mashape/apistatus.svg)](http://choosealicense.com/licenses/mit/)
[![R
version](https://img.shields.io/badge/weathervane.R%20version-0.1.0-80b6ff.svg)](/weathervane.R)
[![R
dependency](https://img.shields.io/badge/R%3E%3D-3.5.0-80b6ff.svg)](https://cran.r-project.org/)
[![R-CMD-check](https://github.com/biometryhub/weathervane/workflows/R-CMD-check/badge.svg)](https://github.com/biometryhub/weathervane/actions)
<!-- badges: end -->

The mythical ‘Australia weather App’ that automates retrieving weather
data. Finally getting around to finishing it.

### 13/08/2021

Update/finalising. At some point document here the three ways to use
weathervane (e.g. the R package, the Shiny App or the ruby CLI
interface). Alternatively perhaps remove the Ruby version later?
(e.g. if we’re preparing for CRAN or something?)

# Installation

Run the following code on your R console to install this package:

``` r
if(!require("remotes")) install.packages("remotes") 
remotes::install_github("biometryhub/BiometryTraining", upgrade = FALSE)
```

# Using the package

Load the package and start using it with:

``` r
library(BiometryTraining)
```

# Citation

If you find this pacakge useful, please cite it! Type
`citation("BiometryTraining")` on the R console to find out how.
