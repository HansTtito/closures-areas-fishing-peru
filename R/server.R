server <- function(input, output, session) {
  
  # Cargar datos al inicio
  datos_completos <- reactive({
    if(file.exists("data/zonas_pesqueras.rds")) {
      readRDS("data/zonas_pesqueras.rds")
    } else {
      data.frame()  # Datos vacíos si no existe el archivo
    }
  })
  
  metadatos <- reactive({
    if(file.exists("data/metadatos.rds")) {
      readRDS("data/metadatos.rds")
    } else {
      list(total_registros = 0, ultima_actualizacion = Sys.time())
    }
  })
  
  # Estado reactivo
  estado <- reactiveValues(
    status = "inicial",
    mensaje = "",
    zonas = 0
  )
  
  # Información de datos
  output$info_datos <- renderText({
    meta <- metadatos()
    if(meta$total_registros > 0) {
      paste0("📊 ", meta$total_registros, " registros disponibles\n",
             "🔄 Última actualización: ", format(meta$ultima_actualizacion, "%d/%m/%Y %H:%M"))
    } else {
      "⚠️ No hay datos disponibles"
    }
  })
  
  # Mapa inicial
  output$mapa <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -77.0428, lat = -12.0464, zoom = 6) %>%
      addProviderTiles("CartoDB.Positron")
  })
  
  # Estado dinámico
  output$estado <- renderUI({
    if(estado$status == "inicial") {
      div(class = "status-box status-waiting",
          p("ℹ️ Listo para consultar", style = "margin: 0;"),
          p("Selecciona fechas y presiona consultar", style = "margin: 5px 0 0 0; font-size: 12px; opacity: 0.8;")
      )
    } else {
      div(class = paste0("status-box status-", estado$status),
          p(estado$mensaje, style = "margin: 0;")
      )
    }
  })
  
  # Procesamiento principal
  observeEvent(input$buscar, {
    
    # Validaciones
    if(is.null(input$fechas[1]) || is.null(input$fechas[2])) {
      estado$status <- "error"
      estado$mensaje <- "❌ Selecciona un rango de fechas válido"
      return()
    }
    
    if(input$fechas[1] > input$fechas[2]) {
      estado$status <- "error"
      estado$mensaje <- "❌ La fecha inicial debe ser anterior a la final"
      return()
    }
    
    # Verificar que hay datos
    datos <- datos_completos()
    if(nrow(datos) == 0) {
      estado$status <- "error"
      estado$mensaje <- "❌ No hay datos disponibles. Contacta al administrador."
      return()
    }
    
    # Filtrar datos por fechas
    fecha_inicio <- as.POSIXct(paste(input$fechas[1], "00:00:00"))
    fecha_fin <- as.POSIXct(paste(input$fechas[2], "23:59:59"))
    
    datos_filtrados <- datos %>%
      filter(
        StartDateTime >= fecha_inicio & StartDateTime <= fecha_fin |
          EndDateTime >= fecha_inicio & EndDateTime <= fecha_fin |
          (StartDateTime <= fecha_inicio & EndDateTime >= fecha_fin)
      )
    
    if(nrow(datos_filtrados) == 0) {
      estado$status <- "empty"
      estado$mensaje <- paste0("📋 No hay zonas activas entre ", 
                               format(input$fechas[1], "%d/%m/%Y"), " y ", 
                               format(input$fechas[2], "%d/%m/%Y"))
      
      # Limpiar mapa
      leafletProxy("mapa") %>%
        clearShapes() %>%
        clearMarkers()
      
      return()
    }
    
    # Crear mapa con datos filtrados
    tryCatch({
      
      mapa_nuevo <- plot_fishing_zones(
        data = datos_filtrados,
        type = "interactive",
        show_legend = TRUE,
        base_layers = TRUE,
        minimap = TRUE
      )
      
      output$mapa <- renderLeaflet({ mapa_nuevo })
      
      # Estado exitoso
      estado$status <- "success"
      estado$zonas <- nrow(datos_filtrados)
      estado$mensaje <- paste0("✅ ", estado$zonas, " zona(s) encontrada(s) para el período seleccionado")
      
    }, error = function(e) {
      estado$status <- "error"
      estado$mensaje <- "❌ Error al generar el mapa"
    })
  })
}
