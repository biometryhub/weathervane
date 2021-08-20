# Scaffolding/helper functions for the unit tests for weathervane.
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson
# Date last modified: 20/08/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

#' Return a vector of the coded parameters in the given URL
#'
#' @param url The URL to parse for parameters
#' @return A named character vector containing the decoded parameters
#' @keywords internal
#' @examples
#' decode_url_parameters('https://blahblah.com/page?param1=2&param2=X')
decode_url_parameters <- function(url) {
  named_parameters <- strsplit(tail(strsplit(url, '\\?|&')[[1]], -1), '=')
  for (index in 1:length(named_parameters)) {
    pair <- named_parameters[[index]]
    if (length(pair) != 2) {
      named_parameters[[index]][2] <- ''
    }
  }
  named_parameters <- as.data.frame(named_parameters, stringsAsFactors = FALSE)

  parameters <- as.character(named_parameters[2, ])
  names(parameters) <- as.character(named_parameters[1, ])
  parameters
}
