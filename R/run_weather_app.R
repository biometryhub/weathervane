#' Run the Shiny weathervane app
#'
#' Runs a shiny app where a user can select and download weather data.
#'
#' @return A list containing ggplot2 objects which are diagnostic plots.
#'
#' @param browser A logical flag to run app directly in the browser
#'
#' @importFrom shiny runApp
#'
#' @examples
#' \dontrun{
#' run_weather_app()
#' }
#' @export
run_weather_app <- function(browser = FALSE) {
  appDir <- system.file("weather_app", package = "weathervane")
  if (appDir == "") {
    stop("Could not find weather_app Try re-installing `weathervane`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
