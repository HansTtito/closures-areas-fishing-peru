library(Tivy)
# =============================================================================
# SERVER WITH CSV PROCESSING FUNCTIONALITY
# =============================================================================

server <- function(input, output, session) {
  
  # Original fishing zones data
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
  
  # Original metadata
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
  
  # Reactive values for application state
  estado <- reactiveValues(
    status = "inicial",
    mensaje = "",
    zonas = 0,
    csv_points = 0
  )
  
  # Reactive values for CSV data
  csv_data <- reactiveValues(
    raw = NULL,
    processed = NULL,
    validation = NULL,
    extra_cols = NULL
  )
  
  # =============================================================================
  # CSV FILE HANDLING
  # =============================================================================
  
  # Process uploaded CSV file
  observeEvent(input$csv_file, {
    req(input$csv_file)
    
    tryCatch({
      # Read CSV file
      file_path <- input$csv_file$datapath
      raw_data <- read.csv(file_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
      
      # Validate CSV structure
      validation_result <- validate_csv_data(raw_data)
      
      # Store results
      csv_data$raw <- raw_data
      csv_data$validation <- validation_result
      
      if (validation_result$valid) {
        csv_data$extra_cols <- validation_result$extra_cols
        # Initial processing will happen when search button is clicked
      }
      
    }, error = function(e) {
      csv_data$validation <- list(
        valid = FALSE,
        message = paste0("❌ Error reading CSV file: ", substr(as.character(e), 1, 50)),
        detected_cols = NULL,
        extra_cols = NULL
      )
    })
  })
  
  # Reset CSV data when file is removed
  observeEvent(input$csv_file, {
    if (is.null(input$csv_file)) {
      csv_data$raw <- NULL
      csv_data$processed <- NULL
      csv_data$validation <- NULL
      csv_data$extra_cols <- NULL
    }
  })
  
  # =============================================================================
  # OUTPUT RENDERING
  # =============================================================================
  
  # CSV validation status
  output$csv_status <- renderUI({
    if (is.null(csv_data$validation)) {
      return(NULL)
    }
    
    validation <- csv_data$validation
    
    if (validation$valid) {
      div(class = "status-box status-success",
          p(validation$message, style = "margin: 0; font-size: 12px;"),
          if (!is.null(validation$extra_cols) && length(validation$extra_cols) > 0) {
            p(paste("Columnas adicionales:", paste(validation$extra_cols, collapse = ", ")), 
              style = "margin: 5px 0 0 0; font-size: 10px; opacity: 0.8;")
          }
      )
    } else {
      div(class = "status-box status-error",
          p(validation$message, style = "margin: 0; font-size: 12px;")
      )
    }
  })
  
  # Data information display
  output$info_datos <- renderText({
    meta <- metadatos()
    datos <- datos_completos()
    
    base_info <- if(nrow(datos) > 0) {
      paste0("📊 ", nrow(datos), " registros de zonas disponibles\n",
             "🔄 Última actualización: ", format(meta$ultima_actualizacion, "%d/%m/%Y %H:%M"))
    } else {
      "⚠️ No hay datos de zonas disponibles. Ejecuta el script de datos iniciales."
    }
    
    # Add CSV info if available
    if (!is.null(csv_data$validation) && csv_data$validation$valid) {
      csv_info <- paste0("\n📂 CSV cargado: ", nrow(csv_data$raw), " puntos")
      base_info <- paste0(base_info, csv_info)
    }
    
    return(base_info)
  })
  
  # Initialize map
  output$mapa <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -77.0428, lat = -12.0464, zoom = 6) %>%
      addProviderTiles("CartoDB.Positron")
  })
  
  # Status display
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
  
  # =============================================================================
  # MAIN SEARCH FUNCTIONALITY
  # =============================================================================
  
  observeEvent(input$buscar, {
    
    # Validate date inputs
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
    
    tryCatch({
      # Process fishing zones data
      datos <- datos_completos()
      fecha_inicio <- as.POSIXct(paste(input$fechas[1], "00:00:00"))
      fecha_fin <- as.POSIXct(paste(input$fechas[2], "23:59:59"))
      
      # Filter fishing zones
      datos_filtrados <- data.frame()
      if (nrow(datos) > 0) {
        valid_rows <- !is.na(datos$StartDateTime) & !is.na(datos$EndDateTime)
        date_filter <- (
          (datos$StartDateTime >= fecha_inicio & datos$StartDateTime <= fecha_fin) |
            (datos$EndDateTime >= fecha_inicio & datos$EndDateTime <= fecha_fin) |
            (datos$StartDateTime <= fecha_inicio & datos$EndDateTime >= fecha_fin)
        )
        final_filter <- valid_rows & date_filter
        datos_filtrados <- datos[final_filter, ]
      }
      
      # Process CSV data if available
      csv_processed <- NULL
      if (!is.null(csv_data$validation) && csv_data$validation$valid) {
        csv_result <- process_csv_data(
          data = csv_data$raw,
          detected_cols = csv_data$validation$detected_cols,
          extra_cols = csv_data$extra_cols,
          date_start = input$fechas[1],
          date_end = input$fechas[2]
        )
        
        if (nrow(csv_result$data) > 0) {
          csv_processed <- csv_result$data
          csv_data$processed <- csv_processed
        }
      }
      
      # Check if any data was found
      zones_found <- nrow(datos_filtrados)
      csv_points_found <- if(is.null(csv_processed)) 0 else nrow(csv_processed)
      
      if (zones_found == 0 && csv_points_found == 0) {
        estado$status <- "empty"
        estado$mensaje <- paste0("📋 No hay datos para el período ", 
                                 format(input$fechas[1], "%d/%m/%Y"), " - ", 
                                 format(input$fechas[2], "%d/%m/%Y"))
        
        # Clear map
        leafletProxy("mapa") %>%
          clearShapes() %>%
          clearMarkers() %>%
          clearMarkerClusters()
        
        return()
      }
      
      # AGREGAR ESTA LÍNEA:
      polygons <- Tivy:::prepare_polygons(data = datos_filtrados, coastline = Tivy::peru_coastline, coast_parallels = Tivy::peru_coast_parallels)

      # Create combined map
      mapa_nuevo <- plot_zones_with_csv(
        polygons = polygons,  # del prepare_polygons()
        csv_data = csv_processed,
        csv_extra_cols = csv_data$extra_cols,
        show_legend = TRUE,
        base_layers = TRUE,
        minimap = TRUE
      )
      
      # Update map
      output$mapa <- renderLeaflet({ mapa_nuevo })
      
      # Update status
      estado$status <- "success"
      estado$zonas <- zones_found
      estado$csv_points <- csv_points_found
      
      # Create status message
      result_parts <- character(0)
      if (zones_found > 0) {
        result_parts <- c(result_parts, paste(zones_found, "zona(s) pesquera(s)"))
      }
      if (csv_points_found > 0) {
        result_parts <- c(result_parts, paste(csv_points_found, "punto(s) CSV"))
      }
      
      estado$mensaje <- paste0("✅ Encontrado(s): ", paste(result_parts, collapse = " + "))
      
    }, error = function(e) {
      estado$status <- "error"
      estado$mensaje <- paste0("❌ Error al procesar datos: ", substr(as.character(e), 1, 50))
      
      # Log for debugging
      cat("Error en filtrado:", as.character(e), "\n")
    })
  })
  
  # =============================================================================
  # DOWNLOAD SAMPLE DATA
  # =============================================================================
  
  output$download_sample <- downloadHandler(
    filename = function() {
      paste0("datos_muestra_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      # Generate mock data
      sample_data <- generate_mock_csv_data(
        n_points = 20,
        date_start = Sys.Date() - 60,
        date_end = Sys.Date(),
        additional_cols = list(
          "Vessel" = c("Pesquero_A", "Pesquero_B", "Pesquero_C"),
          "Species" = c("Anchoveta", "Sardina", "Jurel", "Caballa"),
          "Catch_kg" = NULL,
          "Temperature_C" = NULL,
          "Depth_m" = NULL,
          "Notes" = c("Condiciones buenas", "Mar agitado", "Agua clara", "Viento fuerte")
        )
      )
      
      # Write CSV with UTF-8 encoding
      write.csv(sample_data, file, row.names = FALSE, fileEncoding = "UTF-8")
    },
    contentType = "text/csv"
  )
}