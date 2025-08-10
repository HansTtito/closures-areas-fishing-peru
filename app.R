# =============================================================================
# APLICACIÓN PRINCIPAL - ZONAS DE CIERRE PESQUERO
# =============================================================================

library(shiny)
library(leaflet)
library(Tivy)  # Your fishing zones package
library(shinycssloaders)
library(shinyWidgets)
library(DT)  # For data tables if needed

# Source the new CSV functions
source("R/csv-helpers.R")      # The CSV validation and processing functions
source("R/csv-mapping.R")      # The mapping functions for CSV integration

# Source your existing configuration
source("R/config.R")           # Contains CSS and other configurations
source("R/server.R")
source("R/ui.R")

# =============================================================================
# RUN APPLICATION
# =============================================================================

shinyApp(ui = ui, server = server)