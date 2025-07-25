# =============================================================================
# SCRIPT PARA CREAR DATOS HISTÓRICOS INICIALES
# Ejecutar UNA VEZ para generar el archivo base
# =============================================================================

library(Tivy)
library(dplyr)

# Configuración
fecha_inicio <- "01/01/2023"  # Ajustar según necesites
fecha_fin <- format(Sys.Date(), "%d/%m/%Y")

cat("🔄 Creando datos históricos desde", fecha_inicio, "hasta", fecha_fin, "\n")

# Función para procesar datos de manera robusta
procesar_datos_historicos <- function(start_date, end_date) {
  
  tryCatch({
    
    # Obtener anuncios
    cat("📡 Obteniendo lista de anuncios...\n")
    anuncios <- fetch_fishing_announcements(
      start_date = start_date,
      end_date = end_date,
      download = FALSE,
      verbose = TRUE
    )
    
    if(nrow(anuncios) == 0) {
      cat("⚠️ No se encontraron anuncios\n")
      return(data.frame())
    }
    
    cat("📥 Procesando", nrow(anuncios), "documentos...\n")
    
    # Procesar en lotes para evitar problemas de memoria
    todos_los_datos <- list()
    batch_size <- 5  # Procesar de a 5 PDFs
    
    for(i in seq(1, nrow(anuncios), by = batch_size)) {
      
      end_idx <- min(i + batch_size - 1, nrow(anuncios))
      cat("📄 Procesando lote", ceiling(i/batch_size), "- PDFs", i, "a", end_idx, "\n")
      
      batch_urls <- anuncios$DownloadURL[i:end_idx]
      
      batch_data <- tryCatch({
        extract_pdf_data(pdf_sources = batch_urls, verbose = FALSE)
      }, error = function(e) {
        cat("❌ Error en lote", ceiling(i/batch_size), ":", as.character(e), "\n")
        return(NULL)
      })
      
      if(!is.null(batch_data) && nrow(batch_data) > 0) {
        todos_los_datos[[length(todos_los_datos) + 1]] <- batch_data
      }
      
      # Pausa entre lotes
      Sys.sleep(2)
    }
    
    # Combinar todos los datos
    if(length(todos_los_datos) > 0) {
      datos_combinados <- do.call(rbind, todos_los_datos)
      
      # Formatear datos
      cat("🔄 Formateando datos...\n")
      datos_formateados <- format_extracted_data(
        data = datos_combinados,
        convert_coordinates = TRUE
      )
      
      # Agregar metadatos
      datos_formateados$fecha_procesamiento <- Sys.time()
      datos_formateados$version_datos <- "1.0"
      
      return(datos_formateados)
      
    } else {
      cat("⚠️ No se pudieron procesar datos\n")
      return(data.frame())
    }
    
  }, error = function(e) {
    cat("❌ Error general:", as.character(e), "\n")
    return(data.frame())
  })
}

# Procesar datos históricos
datos_historicos <- procesar_datos_historicos(fecha_inicio, fecha_fin)

if(nrow(datos_historicos) > 0) {
  
  # Crear directorio de datos si no existe
  if(!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  # Guardar datos
  saveRDS(datos_historicos, "data/zonas_pesqueras.rds")
  
  # Guardar metadatos
  metadatos <- list(
    fecha_creacion = Sys.time(),
    periodo_cobertura = paste(fecha_inicio, "a", fecha_fin),
    total_registros = nrow(datos_historicos),
    ultima_actualizacion = Sys.time()
  )
  
  saveRDS(metadatos, "data/metadatos.rds")
  
  cat("✅ Datos históricos creados exitosamente\n")
  cat("📊 Total de registros:", nrow(datos_historicos), "\n")
  cat("📁 Archivos guardados en: data/zonas_pesqueras.rds\n")
  
} else {
  cat("❌ No se pudieron crear los datos históricos\n")
}

cat("🎉 Proceso completado\n")