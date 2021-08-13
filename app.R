# weathervane App: This App acts as a user-friendly frontend to the
# weathervane package for downloading SILO weather/climate datasets.
# Users can specify the desired location using a clickable map view,
# specify the date range for the weather data, and toggle different
# weather variables on/off in the interactive view. A 1-click
# download saves the chosen weather variables to a convenient CSV.
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson
# Date last modified: 13/08/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# Using leaflet for the interactive map view, and ggplot2 for the
# 'first-glance' weather variable plots.
library(shiny)
library(leaflet)
library(ggplot2)


# App Meta #####################################################################
app_title <- 'weathervane'

# Default latitude/longitude coordinates (e.g. for Waite campus)
latitude_default <- -34.9681
latitude_step <- 1e-4

longitude_default <- 138.6355
longitude_step <- 1e-4

# Default map zoom level (enough to cover most of Adelaide)
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
        'Choose a latitude and longitude (either by entering in the input ',
        'boxes directly, or by clicking a location using the interactive ',
        'map), and select a start date and an end date. The weather variables ',
        'available at that location for the specified date range will then be ',
        'loaded into the viewing window. The viewing window includes time ',
        'series previews of the data for convenience, and each variable can ',
        'be toggled include/exclude for the download. When you are ready, ',
        'click the Download button to retrieve the specified weather ',
        'variables to a CSV.'
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
            'Download the selected dataset to a CSV (.csv) file.'
          )
        )
      ),
      fluidRow(
        downloadButton(
          outputId = 'btn_download',
          label = 'Download data to CSV...'
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

  # TODO: Might need to keep track of the checkboxes?
  variables <- reactiveVal()

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

    # TODO: May want a delay in here so that we don't immediately
    #       grab weather data while the user is still typing the
    #       coordinates? (Actually maybe we just want an
    #       'Update coordinates' button ala Kym's App?)
    #       If so, the below observeEvent for longitude also
    #       needs to be updated.
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
    session$sendCustomMessage('flash_latitude_longitude', 1000)
  })

  # Whenever the start/end dates or the coordinates are modified,
  # do a new data download.
  data <- reactive({
    # TODO: Error checking here.

    # TODO: Change this based on how the weathervane.R package
    #       file changes.
    get_austweather(
      lat = coordinates()$latitude,
      lng = coordinates()$longitude,
      start = input$start_date,
      finish = input$end_date
    )

    # TODO: Filter out any NaN columns here.
  })


  # Whenever the data is updated, regenerate the list of variables
  # and prepare the data download.
  observeEvent(data(), ignoreInit = FALSE, {
    # Generate the variables list and plot views/checkboxes
    var_names <- colnames(data())[
      which(!colnames(data()) %in% c('Date', 'Latitude', 'Longitude'))
    ]
    variables(
      lapply(
        var_names,
        function(var) { VariableView$new(var, data()[c('Date', var)]) }
      )
    )

    # Render the widget UIs
    output$variables_view <- renderUI(
      tagList(sapply(variables(), function(var) { tagList(var$ui()) }))
    )

    # Set the observers and draw the plots for each variable
    for (var in variables()) {
      var$observers(input)
      var$draw_plot(output)
    }
  })

  # The download button click:
  # TODO: Might need to disable/enable this button depending?
  output$btn_download <- downloadHandler(
    filename = function() { paste0('weathervane_data_', Sys.Date(), '.csv') },
    content = function(file) {
      download_data <- isolate(data())
      # Get only the selected weather variables
      non_var_names <- c('Date', 'Latitude', 'Longitude')
      var_names <- colnames(download_data)[
        which(!colnames(download_data) %in% non_var_names)
      ]
      selected <- var_names[
        which(sapply(isolate(variables()), function(var) { var$checked }))
      ]
      download_data <- download_data[
        append(
          which(colnames(download_data) %in% non_var_names),
          which(colnames(download_data) %in% selected)
        )
      ]

      write.csv(download_data, file, row.names = FALSE)
    }
  )
}


shinyApp(ui, server)
