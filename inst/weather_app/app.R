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
# Code authors: Russell A. Edson, Sam Rogers, Biometry Hub
# Date last modified: 22/10/2021
# Send all bug reports/questions/comments to
#   biometryhubdev@gmail.com


# Using leaflet for the interactive map view, ggplot2 for the
# 'first-glance' weather variable view plots and R6 classes for the
# VariableView class definition.
library(shiny)
library(leaflet)
library(ggplot2)
library(R6)


# App Meta #####################################################################
app_title <- 'weathervane'

# Default latitude/longitude coordinates (e.g. Waite campus)
latitude_default <- -34.9681
latitude_step <- 1e-4

longitude_default <- 138.6355
longitude_step <- 1e-4

# Default map zoom level (enough to cover most of Adelaide)
zoom_default <- 8

# Default dates: a 'year of data' up to the current date
end_date_default <- Sys.Date()
start_date_default <- end_date_default - 365

# Minimum/maximum dates for the date ranges
minimum_date <- as.Date('1889-01-01')
maximum_date <- Sys.Date()


# VariableView class definition ################################################

# We keep track of the VariableView instances created for unique IDs
instances_VariableView <- 0

#' 'VariableView' widget class
#'
#' A 'variable view' widget for the weathervane Shiny App. This widget
#' shows a preview of the weather time series for the specified date
#' range, and provides a toggle to the user as to whether this variable
#' should be included in the data download.
#'
#' @field var A character object containing the variable name
#' @field data A data.frame containing a 'Date' column and a column
#'   for the variable (which must have the same name as var)
#' @field checked TRUE if the user has specified that this variable
#'   should be included in the data download (default=TRUE)
#' @method ui Populate the Shiny App HTML with the markup that draws
#'   this VariableView
#' @method draw_plot(output) Draw the variable time series plot
#'   to the Shiny App output list
#' @method observers(input) Bind the event observers for this
#'   VariableView to the Shiny App input list
#'
#' @keywords internal
#' @examples
#' weather_data <- data.frame(
#'   Date = c('2021-01-01', '2021-01-02', '2021-01-03'),
#'   Rainfall = c(0, 1.1, 0.5),
#'   Temperature = c(14.8, 22.1, 16.7)
#' )
#' VariableView$new('Rainfall', weather_data[c('Date', 'Rainfall')])
VariableView <- R6::R6Class(
  classname = 'VariableView',
  public = list(
    var = NULL,
    data = NULL,

    # IDs for the UI elements (when ui() draws the widgets)
    checkbox_id = NULL,
    label_id = NULL,
    plot_id = NULL,

    # Checked = TRUE by default (i.e. variable included in download)
    checked = TRUE,

    # We colour every second VariableView row light-grey to enhance
    # readability.
    light_grey = FALSE,

    # VariableView constructor: instantiates a new VariableView
    # with the given variable name (as a string in var) and data
    # (as a data frame containing Date and variable values).
    initialize = function(var, data) {
      self$var <- var
      self$data <- data

      # Keep track of the number of instances so that we can
      # generate unique IDs successively
      instances_VariableView <<- instances_VariableView + 1

      # Generate a unique ID
      id <- paste0('x', instances_VariableView)
      self$checkbox_id <- paste0(id, '_checkbox')
      self$label_id <- paste0(id, '_label')
      self$plot_id <- paste0(id, '_plot')

      # Every second VariableView is coloured light-grey
      if (instances_VariableView %% 2 == 0) {
        self$light_grey <- TRUE
      }
    },

    # UI render method: returns the list of HTML elements that
    # draw this VariableView to the Shiny App screen.
    ui = function() {
      fluidRow(
        style = paste0(
          'height: 32px; line-height: 32px; width: 100%; margin: 0px;',
          ifelse(self$light_grey, 'background-color: #efefef', '')
        ),
        # We have a simple stylish toggle switch for the variable
        # checkboxes.
        column(
          style = 'height: inherit; padding: 0px;',
          width = 2,
          tags$label(
            class = 'toggle-switch',
            style = paste0(
              'position: relative; display: inline-block; width: 50px;',
              'height: 25px; margin-bottom: 0px; vertical-align: sub;',
              'margin-left: 4px;'
            ),
            tags$input(
              id = self$checkbox_id,
              type = 'checkbox',
              checked = ifelse(self$checked, 'checked', '')
            ),
            span(class = 'slider')
          )
        ),
        column(
          style = 'height: inherit; padding-right: 0px; padding-left: 8px;',
          width = 6,
          # TODO: Do we want hover tooltips or something here, too?
          p(id = self$label_id, class = 'truncate', self$var)
        ),
        column(
          style = 'height: inherit; padding-left: 0px;',
          width = 4,
          plotOutput(outputId = self$plot_id, height = 'inherit')
        )
      )
    },

    # Draw the small plot for the variable on the right-hand side.
    draw_plot = function(output) {
      plot_data <- data.frame(
        x = as.Date(self$data$Date),
        y = self$data[[self$var]]
      )

      output[[self$plot_id]] <- renderPlot(
        {
          ggplot2::ggplot(plot_data) +
            ggplot2::geom_line(
              ggplot2::aes(x = x, y = y),
              linewidth = 0.2,
              colour = 'blue'
            ) +
            ggplot2::theme_bw() +
            ggplot2::theme(
              axis.line = ggplot2::element_blank(),
              axis.ticks = ggplot2::element_blank(),
              axis.text.x = ggplot2::element_blank(),
              axis.title.x = ggplot2::element_blank(),
              axis.text.y = ggplot2::element_blank(),
              axis.title.y = ggplot2::element_blank(),
              legend.position = 'none',
              panel.background = ggplot2::element_blank(),
              plot.background = ggplot2::element_blank(),
              panel.grid.major = ggplot2::element_blank(),
              panel.grid.minor = ggplot2::element_blank()
            )
        },
        bg = 'transparent'
      )
    },

    # Observers
    observers = function(input) {
      observeEvent(input[[self$checkbox_id]], ignoreInit = FALSE, {
        self$checked <- input[[self$checkbox_id]]
      })
    }
  )
)


# User Interface code for the App ##############################################
ui <- fluidPage(
  tags$head(
    tags$link(rel = 'stylesheet', type = 'text/css', href = 'www/style.css'),
    tags$title(app_title),
    tags$script(src = 'www/app_ancillary.js')
  ),
  fluidRow(
    id = 'row_titlebar',
    tags$img(src = 'www/biometry_hub_bg.png', id = 'title_bg'),
    column(
      width = 10,
      id = 'col_title',
      div(
        id = 'apptitle_container',
        h1(id = 'apptitle_text', app_title)
      )
    ),
    column(
      width = 2,
      id = 'col_credits',
      div(
        id = 'credits_container',
        actionButton(inputId = 'btn_credits', label = 'Credits')
      )
    )
  ),
  fluidRow(
    id = 'row_help',
    column(
      width = 12,
      shiny::includeHTML(
        system.file('www/intro_text.html', package = 'weathervane')
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
            value = start_date_default,
            min = minimum_date,
            max = maximum_date
          )
        ),
        column(
          width = 6,
          dateInput(
            width = '100%',
            inputId = 'end_date',
            label = 'End Date',
            value = end_date_default,
            min = minimum_date,
            max = maximum_date
          )
        )
      ),
      fluidRow(
        column(width = 12,
          h5(strong("Or select last:"))
        )
      ),
      fluidRow(
        div(
          column(
            width = 3,
            actionButton(width = "100%",
                         inputId = 'btn_6mo',
                         label = '6 Months'
            )
          ),
          column(
            width = 3,
            actionButton(width = "100%",
                         inputId = 'btn_1yr',
                         label = '1 Year'
            )
          ),
          column(
            width = 3,
            actionButton(width = "100%",
                         inputId = 'btn_3yrs',
                         label = '3 years'
            )
          ),
          column(
            width = 3,
            actionButton(width = "100%",
                         inputId = 'btn_5yrs',
                         label = '5 years'
            )
          )
        )
      ),
      br(),
      fluidRow(
        column(
          width = 12,
          actionButton(
            inputId = 'btn_update',
            class = "btn-success",
            label = 'Update Coordinates/Date Range'
          ), align = "center"
        )
      ),
      fluidRow(
        column(
          width = 12,
          tags$label(
            class = 'control-label',
            'for' = 'variables_view',
            'Variables'
          ),
          div(
            id = 'row_variables',
            style = paste0(
              'overflow: scroll; height: 240px; width: inherit; ',
              'border: 1px solid #ccc;'
            ),
            uiOutput(outputId = 'variables_view')
          )
        )
      ),
      fluidRow(
        id = 'row_downloadtext',
        column(
          width = 12,
          p(
            id = 'downloadtext',
            style = 'padding-top: 8px; margin-bottom: 4px;',
            paste0(
              'Download the selected dataset to a CSV (.csv) file.'
            )
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          downloadButton(
            outputId = 'btn_download',
            label = 'Download data to CSV...'
          )
        )
      )
    ),
    column(
      width = 7,
      div(
        id = 'col_map',
        tags$canvas(id = 'map_canvas', style = 'position: absolute;'),
        leafletOutput(outputId = 'map_view', width = '100%', height = '530px')
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

  # Keep track of the toggled variables
  variables <- reactiveVal()

  # Credits: modal, appears when the 'Credits' button is clicked
  observeEvent(input$btn_credits, ignoreInit = TRUE, {
    showModal(
      modalDialog(
        easyClose = TRUE,
        title = NULL,
        shiny::includeHTML(
          system.file('www/credits.html', package = 'weathervane')
        ),
        footer = modalButton('OK')
      )
    )
  })

  # Initialise the data download
  # TODO: Error-checking?
  data <- reactiveVal(
    value = get_weather_data(
      latitude = latitude_default,
      longitude = longitude_default,
      start_date = start_date_default,
      finish_date = end_date_default
    )
  )

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
  # (And colour the latitude/longitude numeric inputs to signify
  # that they have changed)
  observeEvent(input$map_view_click, ignoreInit = TRUE, {
    click <- input$map_view_click
    coordinates(
      list(
        latitude = round(click$lat, digits = 4),
        longitude = round(click$lng, digits = 4)
      )
    )

    session$sendCustomMessage('colour_lat_lng', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  # Also update the latitude/longitude coordinates when the user
  # changes their values in the input controls (and colour the
  # widgets to reflect the change)
  observeEvent(input$latitude, ignoreInit = TRUE, {
    session$sendCustomMessage('colour_lat_lng', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)

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
    session$sendCustomMessage('colour_lat_lng', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)

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

  # Enable the shortcut buttons to update date ranges
  # 6 months
  observeEvent(input$btn_6mo, ignoreInit = TRUE, {
    updateDateInput(session, 'start_date', value = seq(as.Date(Sys.Date()), length = 2, by = "-6 months")[2])
    updateDateInput(session, 'end_date', value = Sys.Date())
    session$sendCustomMessage('colour_start_date', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  # Date range 1 year
  observeEvent(input$btn_1yr, ignoreInit = TRUE, {
    updateDateInput(session, 'start_date', value = seq(as.Date(Sys.Date()), length = 2, by = "-1 year")[2])
    updateDateInput(session, 'end_date', value = Sys.Date())
    session$sendCustomMessage('colour_start_date', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  # Date range 3 years
  observeEvent(input$btn_3yrs, ignoreInit = TRUE, {
    updateDateInput(session, 'start_date', value = seq(as.Date(Sys.Date()), length = 2, by = "-3 years")[2])
    updateDateInput(session, 'end_date', value = Sys.Date())
    session$sendCustomMessage('colour_start_date', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  # Date range 5 years
  observeEvent(input$btn_5yrs, ignoreInit = TRUE, {
    updateDateInput(session, 'start_date', value = seq(as.Date(Sys.Date()), length = 2, by = "-5 years")[2])
    updateDateInput(session, 'end_date', value = Sys.Date())
    session$sendCustomMessage('colour_start_date', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  # Whenever the dates have been changed, we highlight the date
  # range view to reflect the change.
  observeEvent(input$start_date, ignoreInit = TRUE, {
    session$sendCustomMessage('colour_start_date', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  observeEvent(input$end_date, ignoreInit = TRUE, {
    session$sendCustomMessage('colour_end_date', TRUE)
    session$sendCustomMessage('bold_update_button', TRUE)
  })

  # Whenever the latitude/longitude is successfully updated, update
  # the map with a marker.
  observeEvent(coordinates(), ignoreInit = TRUE, {
    # Refresh marker
    addMarkers(
      clearMarkers(leafletProxy('map_view')),
      lat = coordinates()$latitude,
      lng = coordinates()$longitude
    )

    # Update latitude/longitude controls
    updateNumericInput(session, 'latitude', value = coordinates()$latitude)
    updateNumericInput(session, 'longitude', value = coordinates()$longitude)
  })

  # Whenever the 'Update' button is clicked, we do a new data download
  observeEvent(input$btn_update, ignoreInit = TRUE, {
    weather_data <- get_weather_data(
      latitude = isolate(coordinates()$latitude),
      longitude = isolate(coordinates()$longitude),
      start_date = isolate(input$start_date),
      finish_date = isolate(input$end_date)
    )
    data(weather_data)

    # And reset all of the highlighted input widgets.
    session$sendCustomMessage('colour_lat_lng', FALSE)
    session$sendCustomMessage('colour_start_date', FALSE)
    session$sendCustomMessage('colour_end_date', FALSE)
    session$sendCustomMessage('bold_update_button', FALSE)
  })

  # Whenever the data is updated, regenerate the list of variables
  # and prepare the data download.
  observeEvent(data(), ignoreInit = FALSE, {
    non_weather_vars <- c('Date', 'Latitude', 'Longitude', 'Elevation (m)')

    # Generate the variables list and plot views/checkboxes
    var_names <- colnames(data())[
      which(!colnames(data()) %in% non_weather_vars)
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
  output$btn_download <- downloadHandler(
    filename = function() { paste0('weathervane_data_', Sys.Date(), '.csv') },
    content = function(file) {
      download_data <- isolate(data())
      # Get only the selected weather variables
      non_weather_vars <- c('Date', 'Latitude', 'Longitude', 'Elevation (m)')
      var_names <- colnames(download_data)[
        which(!colnames(download_data) %in% non_weather_vars)
      ]
      selected <- var_names[
        which(sapply(isolate(variables()), function(var) { var$checked }))
      ]
      download_data <- download_data[
        append(
          which(colnames(download_data) %in% non_weather_vars),
          which(colnames(download_data) %in% selected)
        )
      ]

      write.csv(download_data, file, row.names = FALSE)
    }
  )

  session$onSessionEnded(function() {
    stopApp()
  })
}

shinyApp(ui, server)
