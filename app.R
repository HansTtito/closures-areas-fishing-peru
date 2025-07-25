# =============================================================================
# APLICACIÓN PRINCIPAL - ZONAS DE CIERRE PESQUERO
# =============================================================================

# Cargar módulos
source("R/config.R")
source("R/ui.R")
source("R/server.R")

# Ejecutar aplicación
shinyApp(ui = ui, server = server)