
# library(Tivy)
# library(dplyr)

# actualizar_datos_diarios <- function() {
  
#   cat("🔄 Iniciando actualización diaria -", Sys.time(), "\n")
  
#   tryCatch({
    
#     if(!file.exists("data/zonas_pesqueras.rds")) {
#       cat("❌ No se encontró archivo de datos base\n")
#       cat("💡 Ejecuta primero: source('1_crear_datos_iniciales.R')\n")
#       return(FALSE)
#     }
    
#     datos_existentes <- readRDS("data/zonas_pesqueras.rds")
#     metadatos <- readRDS("data/metadatos.rds")
    
#     cat("📂 Datos existentes:", nrow(datos_existentes), "registros\n")
    
#     fecha_desde <- format(Sys.Date() - 10, "%d/%m/%Y")
#     fecha_hasta <- format(Sys.Date(), "%d/%m/%Y")
    
#     cat("🔍 Buscando datos desde", fecha_desde, "hasta", fecha_hasta, "\n")
    
#     anuncios_nuevos <- fetch_fishing_announcements(
#       start_date = fecha_desde,
#       end_date = fecha_hasta,
#       download = FALSE,
#       verbose = FALSE
#     )
    
#     if(nrow(anuncios_nuevos) == 0) {
#       cat("ℹ️ No hay nuevos anuncios\n")
      
#       # Actualizar solo metadatos
#       metadatos$ultima_actualizacion <- Sys.time()
#       saveRDS(metadatos, "data/metadatos.rds")
      
#       return(TRUE)
#     }
    
#     cat("📥 Procesando", nrow(anuncios_nuevos), "anuncios nuevos...\n")
    
#     datos_nuevos <- tryCatch({
      
#       resultados <- list()
      
#       for(i in 1:min(5, nrow(anuncios_nuevos))) {  # Máximo 5 por día
        
#         cat("📄 Procesando documento", i, "de", nrow(anuncios_nuevos), "\n")
        
#         resultado <- tryCatch({
#           extract_pdf_data(pdf_sources = anuncios_nuevos$DownloadURL[i], verbose = FALSE)
#         }, error = function(e) {
#           cat("⚠️ Error en documento", i, "\n")
#           return(NULL)
#         })
        
#         if(!is.null(resultado) && nrow(resultado) > 0) {
#           resultados[[length(resultados) + 1]] <- resultado
#         }
        
#         Sys.sleep(1) 
#       }
      
#       if(length(resultados) > 0) {
#         do.call(rbind, resultados)
#       } else {
#         NULL
#       }
      
#     }, error = function(e) {
#       cat("❌ Error procesando datos nuevos:", as.character(e), "\n")
#       return(NULL)
#     })
    
#     if(!is.null(datos_nuevos) && nrow(datos_nuevos) > 0) {
      
#       datos_nuevos_formateados <- format_extracted_data(
#         data = datos_nuevos,
#         convert_coordinates = TRUE
#       )
      
#       datos_nuevos_formateados$fecha_procesamiento <- Sys.time()
#       datos_nuevos_formateados$version_datos <- "1.0"
      
#       if("file_name" %in% names(datos_existentes) && "file_name" %in% names(datos_nuevos_formateados)) {
#         archivos_existentes <- unique(datos_existentes$file_name)
#         datos_nuevos_formateados <- datos_nuevos_formateados[
#           !datos_nuevos_formateados$file_name %in% archivos_existentes, 
#         ]
#       }
      
#       if(nrow(datos_nuevos_formateados) > 0) {
        
#         datos_actualizados <- rbind(datos_existentes, datos_nuevos_formateados)
        
#         saveRDS(datos_actualizados, "data/zonas_pesqueras.rds")
        
#         metadatos$ultima_actualizacion <- Sys.time()
#         metadatos$total_registros <- nrow(datos_actualizados)
#         metadatos$registros_agregados_hoy <- nrow(datos_nuevos_formateados)
        
#         saveRDS(metadatos, "data/metadatos.rds")
        
#         cat("✅ Actualización completada\n")
#         cat("📊 Nuevos registros agregados:", nrow(datos_nuevos_formateados), "\n")
#         cat("📊 Total de registros:", nrow(datos_actualizados), "\n")
        
#       } else {
#         cat("ℹ️ No hay datos nuevos únicos para agregar\n")
        
#         # Actualizar solo timestamp
#         metadatos$ultima_actualizacion <- Sys.time()
#         metadatos$registros_agregados_hoy <- 0
#         saveRDS(metadatos, "data/metadatos.rds")
#       }
      
#     } else {
#       cat("ℹ️ No se obtuvieron datos nuevos válidos\n")
      
#       # Actualizar solo timestamp
#       metadatos$ultima_actualizacion <- Sys.time()
#       metadatos$registros_agregados_hoy <- 0
#       saveRDS(metadatos, "data/metadatos.rds")
#     }
    
#     return(TRUE)
    
#   }, error = function(e) {
#     cat("❌ Error en actualización diaria:", as.character(e), "\n")
#     return(FALSE)
#   })
# }

# resultado <- actualizar_datos_diarios()

# if(resultado) {
#   cat("🎉 Actualización diaria completada exitosamente\n")
# } else {
#   cat("❌ Error en la actualización diaria\n")
# }