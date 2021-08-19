#' Run the Shiny weathervane app
#'
#' Runs a shiny app where a user can select and download weather data.
#'
#' @examples
#' \dontrun{
#' run_weather_app()
#' }
#' @export
run_weather_app <- function() {
  appDir <- system.file("weather_app", package = "weathervane")
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package \"shiny\" is needed for this function to work. Please install it.",
         call. = FALSE)
  }
  else if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package \"ggplot2\" is needed for this function to work. Please install it.",
         call. = FALSE)
  }
  else if(!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Package \"leaflet\" is needed for this function to work. Please install it.",
         call. = FALSE)
  }
  else if (appDir == "") {
    stop("Could not find weather_app. Try re-installing `weathervane`.", call. = FALSE)
  }
  else {
    shiny::runApp(appDir, display.mode = "normal")
  }
}
