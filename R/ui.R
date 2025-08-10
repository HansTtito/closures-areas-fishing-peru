# =============================================================================
# USER INTERFACE WITH CSV UPLOAD
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
      
      # Date Range Section
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
      
      # CSV Upload Section
      div(style = "margin-top: 20px; padding-top: 20px; border-top: 2px solid #e2e8f0;",
          h4("📂 Datos Adicionales (CSV)"),
          fileInput(
            "csv_file",
            label = "Subir archivo CSV",
            accept = c(".csv", ".txt"),
            buttonLabel = "Seleccionar...",
            placeholder = "Ningún archivo seleccionado"
          ),
          
          # CSV validation status
          uiOutput("csv_status"),
          
          # Sample data download
          div(style = "margin-top: 10px;",
              downloadButton(
                "download_sample",
                "📥 Descargar datos de prueba",
                class = "btn btn-outline-secondary btn-sm",
                style = "width: 100%; font-size: 12px;"
              )
          ),
          
          # CSV info section
          div(class = "info-section", style = "margin-top: 15px; font-size: 11px;",
              h5("💡 Formato requerido:", style = "margin-top: 0; font-size: 12px;"),
              tags$ul(
                tags$li("Columnas mínimas: Date, Long, Lat"),
                tags$li("Formato fecha: DD/MM/YYYY o YYYY-MM-DD"),
                tags$li("Coordenadas en grados decimales"),
                tags$li("Máximo 1000 filas recomendado")
              )
          )
      ),
      
      # Search Button
      actionButton("buscar", "🔍 Consultar Zonas", class = "btn-search", style = "margin-top: 20px;"),
      
      # Status Section
      uiOutput("estado"),
      
      # Data Info Section
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
            leafletOutput("mapa", height = "750px"),
            type = 6,
            color = "#0ea5e9"
          )
      )
    )
  )
)