# A 'variable view' widget for the weathervane Shiny App. Shows
# a preview of the weather time series and provides a toggle for
# whether to include that variable in the data download.
#
# Copyright (c) 2021 University of Adelaide Biometry Hub
# MIT Licence
#
# Code author: Russell A. Edson
# Date last modified: 13/08/2021
# Send all bug reports/questions/comments to
#   russell.edson@adelaide.edu.au

# Using ggplot2 to draw the preview weather time series plots
library(ggplot2)
library(R6)

# Make a variable view widget, complete with the checkbox, label
# and plot for the data.

#' TODO: Making this as an R6 object, so document accordingly.
#'
#'
VariableView <- R6Class(
  classname = 'VariableView',
  public = list(
    #TODO document these object attributes
    var = NULL,
    data = NULL,

    # IDs for the UI elements (when ui() draws the widgets)
    checkbox_id = NULL,
    label_id = NULL,
    plot_id = NULL,

    # Checked = TRUE by default (i.e. variable included in download)
    checked = TRUE,

    # Constructor
    initialize = function(var, data) {
      self$var <- var
      self$data <- data

      # Generate an 'almost-surely unique' ID
      id <- paste0('x', as.integer(runif(1, 1, 1e8)))

      # IDs for the UI elements (when ui() draws the widgets)
      self$checkbox_id <- paste0(id, '_checkbox')
      self$label_id <- paste0(id, '_label')
      self$plot_id <- paste0(id, '_plot')
    },

    # UI render
    ui = function() {
      fluidRow(
        style = 'height: 32px; width: 100%;',
        column(
          style = 'height: inherit;',
          width = 1,
          checkboxInput(
            inputId = self$checkbox_id,
            label = NULL,
            value = self$checked
          )
        ),
        column(
          style = 'height: inherit;',
          width = 7,
          p(id = self$label_id, self$var)
        ),
        column(
          style = 'height: inherit;',
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

      output[[self$plot_id]] <- renderPlot({
        ggplot(plot_data) +
          geom_line(aes(x = x, y = y), size = 0.2, colour = 'blue') +
          theme_bw() +
          theme(
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            axis.text.x = element_blank(),
            axis.title.x = element_blank(),
            axis.text.y = element_blank(),
            axis.title.y = element_blank(),
            legend.position = 'none',
            panel.background = element_blank(),
            plot.background = element_blank(),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank()
          )
      })
    },

    # Observers
    observers = function(input) {
      observeEvent(input[[self$checkbox_id]], ignoreInit = FALSE, {
        self$checked <- input[[self$checkbox_id]]
      })
    }
  )
)
