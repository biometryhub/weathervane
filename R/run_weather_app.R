#' Run the Shiny weathervane app
#'
#' Runs a shiny app where a user can select and download weather data.
#'
#' @importFrom utils installed.packages
#'
#' @examples
#' \dontrun{
#' run_weather_app()
#' }
#' @export
run_weather_app <- function() {
  appDir <- system.file("weather_app", package = "weathervane")

  installed_pkgs <- rownames(installed.packages())
  not_found <- setdiff(c("ggplot2", "leaflet", "shiny"), grep("(^ggplot2$)|(^shiny$)|(^leaflet$)", installed_pkgs, value = TRUE))
  if (length(not_found) > 0) {
    stop("Package ", not_found[1], " is needed for this function to work. Please install it.", call. = FALSE)
  }

  if (appDir == "") {
    stop("Could not find weather_app. Try re-installing `weathervane`.", call. = FALSE)
  }
  else {
    shiny::addResourcePath('www', system.file('www', package = 'weathervane'))
    if(interactive()) {
      shiny::runApp(appDir)
    }
    else(return(FALSE))
  }
}
