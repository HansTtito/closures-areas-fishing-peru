# =============================================================================
# INTERFAZ DE USUARIO
# =============================================================================

ui <- fluidPage(
  tags$head(tags$style(HTML(css))),
  
  div(class = "main-header",
      h1("🐟 Zonas de Cierre Pesquero"),
      p("Sistema de Consulta - PRODUCE")
  ),
  
  sidebarLayout(
    sidebarPanel(
      class = "sidebar-panel",
      width = 3,
      
      h4("📅 Período de Consulta"),
      dateRangeInput(
        "fechas",
        label = NULL,
        start = Sys.Date() - 30,
        end = Sys.Date(),
        format = "dd/mm/yyyy",
        language = "es",
        separator = " hasta "
      ),
      
      actionButton("buscar", "🔍 Consultar Zonas", class = "btn-search"),
      
      uiOutput("estado"),
      
      div(class = "info-section",
          h5("ℹ️ Información", style = "margin-top: 0;"),
          textOutput("info_datos"),
          br(),
          p("Los datos se actualizan automáticamente cada día")
      )
    ),
    
    mainPanel(
      width = 9,
      div(class = "map-container",
          withSpinner(
            leafletOutput("mapa", height = "650px"),
            type = 6,
            color = "#0ea5e9"
          )
      )
    )
  )
)