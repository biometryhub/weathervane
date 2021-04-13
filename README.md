# ~~AustWeather~~ wVane
<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Licence](https://img.shields.io/github/license/mashape/apistatus.svg)](http://choosealicense.com/licenses/mit/)
[![Ruby version](https://img.shields.io/badge/wvane.rb%20version-1.1.0-ef6666.svg)](/wvane.rb)
[![Ruby dependency](https://img.shields.io/badge/Ruby%3E%3D-2.6.6-ef6666.svg)](https://www.ruby-lang.org/)
[![R version](https://img.shields.io/badge/wvane.R%20version-1.1.0-80b6ff.svg)](/wvane.R)
[![Ruby dependency](https://img.shields.io/badge/R%3E%3D-4.0.0-80b6ff.svg)](https://cran.r-project.org/)
<!-- badges: end -->

The mythical 'Australia weather App' that automates retrieving weather data. Finally getting around to finishing it.

### 16/03/2021
Phase 1: getting a proof-of-concept Ruby script up to make sure the HTTP requests/responses are alright and perform diagnostics.

### 13/04/2021
Reformulated as **wVane**. The Ruby version has been refactored as a testable module and unit tests have been written. A MVP for the R package has been written (yet to be updated, using the Ruby version as a stencil), and the Shiny App is written and functional. Pending documentation, CSS-prettying and some unit/Shiny tests.
