/**
 * Ancillary JavaScript functions for the weathervane App.
 *
 * Copyright (c) 2021 University of Adelaide Biometry Hub
 * MIT Licence
 *
 * Code author: Russell A. Edson
 * Date last modified: 13/08/2021
 * Send all bug reports/questions/comments to
 *   russell.edson@adelaide.edu.au
 */

/**
 * Flash the latitude/longitude input widgets to indicate that they
 * have been updated.
 *
 * @param {number[]} timeout Time (in milliseconds) to show the flash.
 */
function flash_latitude_longitude(timeout) {
  latitude = document.getElementById("latitude");
  longitude = document.getElementById("longitude");
  latitude.classList.add("flash");
  longitude.classList.add("flash");

  setTimeout(
    function() {
      latitude.classList.remove("flash");
      longitude.classList.remove("flash");
    },
    timeout
  );
}

Shiny.addCustomMessageHandler(
  "flash_latitude_longitude",
  flash_latitude_longitude
);

