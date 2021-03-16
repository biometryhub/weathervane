
//TODO

// Will want a JS function to perform the 'flash' when the lat/lng
// are updated



// timeout: number of milliseconds to display the flash.
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

