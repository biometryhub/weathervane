# TODO: Brief App overview to go here.
# Working name: AustWeather (but come up with something better)
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
#
# Code author: Russell A. Edson
# Date last modified: 12/03/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# TODO: document libraries used.
library(shiny)


# App Meta #####################################################################
app_title <- 'AustWeather'


# User Interface code for the App ##############################################
ui <- fluidPage(
  tags$head(
    tags$link(rel = 'stylesheet', type = 'text/css', href = 'style.css'),
    tags$title(app_title),
    tags$script(src = 'app_ancillary.js')
  ),
  fluidRow(
    id = 'titlebar',
    column(width = 10, h2(id = 'apptitle', app_title)),
    column(width = 2, actionButton(inputId = 'btn_credits', label = 'Credits'))
  )
)

# Server code for the App functionality ########################################
server <- function(input, output, session) {
  
  # Credits: modal
  observeEvent(input$btn_credits, {
    showModal(
      modalDialog(
        easyClose = TRUE,
        title = NULL,
        includeHTML(file.path('www', 'credits.html')),
        footer = modalButton('OK')
      )
    )
  })
  
}


shinyApp(ui, server)
