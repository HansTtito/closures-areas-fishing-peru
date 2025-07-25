# 🐟 Sistema de Zonas de Cierre Pesquero

## Automatización
- **Datos históricos**: `descarga_datos_inicial.R`
- **Actualización diaria**: `actualizacion_diaria.R` (automática vía GitHub Actions)
- **Aplicación**: `app.R`

## Uso Local
1. `source('descarga_datos_inicial.R')` - Una sola vez
2. `shiny::runApp()` - Para usar la app
3. `source('actualizacion_diaria.R')` - Para actualizar manualmente

## Despliegue
- Los datos se actualizan automáticamente cada día
- La app en shinyapps.io usa los datos pre-procesados

