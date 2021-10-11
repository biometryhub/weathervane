/**
 * Ancillary JavaScript functions for the weathervane App.
 *
 * Copyright (c) 2021 University of Adelaide Biometry Hub
 * MIT Licence
 *
 * Code author: Russell A. Edson
 * Date last modified: 11/10/2021
 * Send all bug reports/questions/comments to
 *   biometryhubdev@gmail.com
 */

/**
 * Toggle colour the latitude/longitude input widgets to indicate that
 * they have been updated (true = updated, false = not updated).
 *
 * @param {boolean} updated True if updated, false if not.
 */
function colour_lat_lng(updated) {
  latitude = document.getElementById("latitude");
  longitude = document.getElementById("longitude");

  if (updated) {
    latitude.classList.add("updated");
    longitude.classList.add("updated");
  } else {
    latitude.classList.remove("updated");
    longitude.classList.remove("updated");
  }
}
Shiny.addCustomMessageHandler("colour_lat_lng", colour_lat_lng);

/**
 * Toggle colour the start date input widget to indicate that it has
 * been updated (true = updated, false = not updated).
 *
 * @param {boolean} updated True if updated, false if not.
 */
function colour_start_date(updated) {
  start_date = document.getElementById("start_date").children[1];

  if (updated) {
    start_date.classList.add("updated");
  } else {
    start_date.classList.remove("updated");
  }
}
Shiny.addCustomMessageHandler("colour_start_date", colour_start_date);

/**
 * Toggle colour the end date input widget to indicate that it has
 * been updated (true = updated, false = not updated).
 *
 * @param {boolean} updated True if updated, false if not.
 */
function colour_end_date(updated) {
  end_date = document.getElementById("end_date").children[1];

  if (updated) {
    end_date.classList.add("updated");
  } else {
    end_date.classList.remove("updated");
  }
}
Shiny.addCustomMessageHandler("colour_end_date", colour_end_date);

/**
 * Toggle bolding the 'Update' button to indicate whether an update
 * has occurred (in which case clicking the button will apply the
 * update).
 *
 * @param {boolean} updated True if updated, false if not.
 */
function bold_update_button(updated) {
  btn_update = document.getElementById("btn_update");

  if (updated) {
    btn_update.classList.add("bolded");
  } else {
    btn_update.classList.remove("bolded");
  }
}
Shiny.addCustomMessageHandler("bold_update_button", bold_update_button);
