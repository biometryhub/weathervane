#' Check URL for invalid response
#'
#' @param url_output The output from a URL call to check for invalid response
#'
#' @return If the response appears valid, return the original input, otherwise throw error.
#' @keywords internal
check_url_response <- function(url_output) {
  # Test for invalid dates
  if (grepl('(Sorry).+(date).+(invalid)*', url_output)) {
    stop('Server-side error: Invalid start/end date', call. = FALSE)
  }

  # Test for invalid coordinates
  if (grepl('(check).+(within Australia)', url_output)) {
    stop('Server-side error: Invalid latitude/longitude', call. = FALSE)
  }

  # Test for invalid station ID
  if (grepl('Invalid station number', url_output)) {
    stop('Server-side error: Invalid station ID provided', call. = FALSE)
  }

  # Test for invalid parameters (e.g. missing comment=)
  # if (grepl('missing essential parameters', url_output, fixed = TRUE)) {
  #   stop('Server-side error: Missing parameters/malformed URL')
  # }

  # Test for a rejected URL (which can happen e.g. if the latitude
  # or longitude is 'too long')
  # if (grepl('([R|r]ejected)', url_output)) {
  #   stop('Server-side error: URL rejected')
  # }

  # Catch-all test for some other server-side error (e.g. if the server
  # is inaccessible)
  if (grepl('(error occurred)|(error checking)|([R|r]ejected)|(missing essential parameters)', url_output)) {
    stop('Server-side error: Unspecified error or server inaccessible', call. = FALSE)
  }

  return(url_output)
}
