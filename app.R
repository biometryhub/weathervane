# TODO: Brief App overview to go here.
# Working name: AustWeather (but come up with something better)
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
#
# Code author: Russell A. Edson
# Date last modified: 16/03/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# TODO: document libraries used.
library(shiny)
library(leaflet)


# App Meta #####################################################################
app_title <- 'AustWeather'

# Default latitude/longitude coordinates (for Waite campus, e.g.)
latitude_default <- -34.9681
latitude_step <- 1e-4

longitude_default <- 138.6355
longitude_step <- 1e-4

# Default map zoom level (enough to cover most of SA)
zoom_default <- 8

# Default dates: a 'year of data' up to the current date
end_date = Sys.Date()
start_date = end_date - 365

# TODO: Implement the min/max dates?


# User Interface code for the App ##############################################
ui <- fluidPage(
  tags$head(
    tags$link(rel = 'stylesheet', type = 'text/css', href = 'style.css'),
    tags$title(app_title),
    tags$script(src = 'app_ancillary.js')
  ),
  fluidRow(
    id = 'row_titlebar',
    column(
      width = 10, 
      id = 'col_title',
      h2(id = 'apptitle', app_title)
    ),
    column(
      width = 2, 
      id = 'col_credits',
      actionButton(inputId = 'btn_credits', label = 'Credits')
    )
  ),
  fluidRow(
    id = 'row_helptext',
    p(
      id = 'helptext',
      paste0(
        'Some helpful text about how to use the app here. Choose a latitude ',
        'and longitude (by entering in the input boxes, or alternatively by ',
        'choosing a location using the map on the right), and select a start ',
        'date and end date. The variables available at the location are ',
        'loaded into the viewing window, where you can select the ones you ',
        'want and even preview the time series data. When your are ready, ',
        'press the Download to file... button to download the data.'
      )
    )
  ),
  fluidRow(
    column(
      width = 5,
      id = 'col_controls',
      fluidRow(
        id = 'row_latlng',
        column(
          width = 6, 
          numericInput(
            width = '100%',
            inputId = 'latitude',
            label = 'Latitude (°N)',
            value = latitude_default,
            step = latitude_step
          )
        ),
        column(
          width = 6, 
          numericInput(
            width = '100%',
            inputId = 'longitude',
            label = 'Longitude (°E)',
            value = longitude_default,
            step = longitude_step
          )
        )
      ),
      fluidRow(
        id = 'row_dates',
        column(
          width = 6,
          dateInput(
            width = '100%',
            inputId = 'start_date',
            label = 'Start Date',
            value = start_date
          )
        ),
        column(
          width = 6,
          dateInput(
            width = '100%',
            inputId = 'end_date',
            label = 'End Date',
            value = end_date
          )
        )
      ),
      fluidRow(
        tags$label(
          class = 'control-label', 
          'for' = 'variables_view',
          'Variables'
        ),
        div(
          id = 'row_variables',
          style = 'overflow: scroll; height: 240px; width: inherit;',
          uiOutput(outputId = 'variables_view')
        )
      ),
      fluidRow(
        id = 'row_downloadtext',
        p(
          id = 'downloadtext',
          paste0(
            'Download the selected dataset to a file (.csv/.xls/.xlsx/.rds).'
          )
        )
      ),
      fluidRow(
        downloadButton(
          outputId = 'btn_download',
          label = 'Download data to file...'
        )
      )
    ),
    column(
      width = 7,
      div(
        id = 'col_map',
        tags$canvas(id = 'map_canvas', style = 'position: absolute;'),
        leafletOutput(outputId = 'map_view', width = '100%', height = '480px')
      )
    )
  )
)


# Server code for the App functionality ########################################
server <- function(input, output, session) {
  # Keep track of the latitude and longitude coordinates
  coordinates <- reactiveVal(
    value = list(
      latitude = latitude_default,
      longitude = longitude_default
    )
  )
  
  # Credits: modal, appears when the 'Credits' button is clicked
  observeEvent(input$btn_credits, ignoreInit = TRUE, {
    showModal(
      modalDialog(
        easyClose = TRUE,
        title = NULL,
        includeHTML(file.path('www', 'credits.html')),
        footer = modalButton('OK')
      )
    )
  })
  
  # Initialise the leaflet map
  output$map_view <- renderLeaflet({
    setView(
      addMarkers(
        addProviderTiles(
          leaflet(),
          providers$OpenStreetMap,
          options = providerTileOptions(noWrap = TRUE)
        ),
        lat = latitude_default,
        lng = longitude_default
      ),
      lat = latitude_default,
      lng = longitude_default,
      zoom = zoom_default
    )
  })
  
  # Update the latitude/longitude when the user clicks on the map
  observeEvent(input$map_view_click, ignoreInit = TRUE, {
    click <- input$map_view_click
    coordinates(
      list(
        latitude = round(click$lat, digits = 4),
        longitude = round(click$lng, digits = 4)
      )
    )
  })
  
  # Also update the latitude/longitude coordinates when the user
  # changes their values in the input controls
  observeEvent(input$latitude, ignoreInit = TRUE, {
    # Error-checking: If we cannot parse the entered value, don't do
    # anything (yet).
    latitude_value <- as.numeric(input$latitude)
    if (!is.na(latitude_value)) {
      coordinates(
        list(
          latitude = latitude_value,
          longitude = as.numeric(isolate(coordinates()['longitude']))
        )
      )
    }
  })
  
  observeEvent(input$longitude, ignoreInit = TRUE, {
    # Error-checking: If we cannot parse the entered value, don't do
    # anything (yet).
    longitude_value <- as.numeric(input$longitude)
    if (!is.na(longitude_value)) {
      coordinates(
        list(
          latitude = as.numeric(isolate(coordinates()['latitude'])),
          longitude = longitude_value
        )
      )
    }
  })
  
  # Whenever the latitude/longitude is updated, update the map with
  # a marker and flash the latitude/longitude coordinates to indicate
  # that they've changed.
  observeEvent(coordinates(), ignoreInit = TRUE, {
    # Refresh marker
    addMarkers(
      clearMarkers(leafletProxy('map_view')),
      lat = coordinates()$latitude,
      lng = coordinates()$longitude
    )
    
    # Update and flash latitude/longitude controls
    updateNumericInput(session, 'latitude', value = coordinates()$latitude)
    updateNumericInput(session, 'longitude', value = coordinates()$longitude)
    session$sendCustomMessage('flash_latitude_longitude', 500)
  })
  
}


shinyApp(ui, server)
