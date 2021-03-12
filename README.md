# AustWeather
<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Licence](https://img.shields.io/github/license/mashape/apistatus.svg)](http://choosealicense.com/licenses/mit/)
<!-- badges: end -->

The mythical 'Australia weather App' that automates retrieving weather data. Finally getting around to making it.

### 12/03/2021
Phase 1: getting a proof-of-concept Ruby script up to make sure the HTTP requests/responses are alright and perform diagnostics.

(**Phase 1 Complete**: however, should check that the SILO interpolations from the web API/HTTP calls match up with the values in the NetCDFs previously downloaded, to be safe.)

Phase 2: porting the Ruby script logic to a standalone R function that can be used to retrieve the weather data (using the API/HTTP calls) and store it in a data frame.

Phase 3: construction of the Shiny App according to the plan (see uploaded PDF).
