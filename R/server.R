# =============================================================================
# SERVIDOR
# =============================================================================
server <- function(input, output, session) {
  
  datos_completos <- reactive({
    if(file.exists("data/zonas_pesqueras.rds")) {
      tryCatch({
        readRDS("data/zonas_pesqueras.rds")
      }, error = function(e) {
        data.frame()
      })
    } else {
      data.frame()
    }
  })
  
  metadatos <- reactive({
    if(file.exists("data/metadatos.rds")) {
      tryCatch({
        readRDS("data/metadatos.rds")
      }, error = function(e) {
        list(total_registros = 0, ultima_actualizacion = Sys.time())
      })
    } else {
      list(total_registros = 0, ultima_actualizacion = Sys.time())
    }
  })
  
  estado <- reactiveValues(
    status = "inicial",
    mensaje = "",
    zonas = 0
  )
  
  output$info_datos <- renderText({
    meta <- metadatos()
    datos <- datos_completos()
    
    if(nrow(datos) > 0) {
      paste0("📊 ", nrow(datos), " registros disponibles\n",
             "🔄 Última actualización: ", format(meta$ultima_actualizacion, "%d/%m/%Y %H:%M"))
    } else {
      "⚠️ No hay datos disponibles. Ejecuta el script de datos iniciales."
    }
  })
  
  output$mapa <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -77.0428, lat = -12.0464, zoom = 6) %>%
      addProviderTiles("CartoDB.Positron")
  })
  
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
  
  observeEvent(input$buscar, {
    
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
    
    datos <- datos_completos()
    
    if(nrow(datos) == 0) {
      estado$status <- "error"
      estado$mensaje <- "❌ No hay datos disponibles. Ejecuta: source('descarga_datos_inicial.R')"
      return()
    }
    
    tryCatch({
      
      fecha_inicio <- as.POSIXct(paste(input$fechas[1], "00:00:00"))
      fecha_fin <- as.POSIXct(paste(input$fechas[2], "23:59:59"))
      
      valid_rows <- !is.na(datos$StartDateTime) & !is.na(datos$EndDateTime)
      
      date_filter <- (
        (datos$StartDateTime >= fecha_inicio & datos$StartDateTime <= fecha_fin) |
          (datos$EndDateTime >= fecha_inicio & datos$EndDateTime <= fecha_fin) |
          (datos$StartDateTime <= fecha_inicio & datos$EndDateTime >= fecha_fin)
      )
      
      final_filter <- valid_rows & date_filter
      datos_filtrados <- datos[final_filter, ]
      
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
      
      mapa_nuevo <- plot_fishing_zones(
        data = datos_filtrados,
        type = "interactive",
        show_legend = TRUE,
        base_layers = TRUE,
        minimap = TRUE
      )
      
      output$mapa <- renderLeaflet({ mapa_nuevo })
      
      estado$status <- "success"
      estado$zonas <- nrow(datos_filtrados)
      estado$mensaje <- paste0("✅ ", estado$zonas, " zona(0s) encontrada(s) para el período seleccionado")
      
    }, error = function(e) {
      estado$status <- "error"
      estado$mensaje <- paste0("❌ Error al procesar datos: ", substr(as.character(e), 1, 50))
      
      # Log para debugging
      cat("Error en filtrado:", as.character(e), "\n")
    })
  })
}