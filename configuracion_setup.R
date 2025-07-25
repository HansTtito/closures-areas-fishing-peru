# =============================================================================
# CONFIGURACIÓN PARA AUTOMATIZACIÓN
# =============================================================================

# Crear estructura de directorios
if(!dir.exists(".github/workflows")) {
  dir.create(".github/workflows", recursive = TRUE)
}

# Crear archivo de GitHub Actions para automatización diaria
github_action_yml <- '
name: Actualización Diaria de Datos

on:
  schedule:
    - cron: "0 6 * * *"  # Ejecutar todos los días a las 6:00 AM UTC
  workflow_dispatch:      # Permitir ejecución manual

jobs:
  update-data:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v3
      
    - name: Setup R
      uses: r-lib/actions/setup-r@v2
      with:
        r-version: "4.3.0"
        
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev libpoppler-cpp-dev
        
    - name: Install R dependencies
      run: |
        R -e "install.packages(c(\'remotes\', \'dplyr\'))"
        R -e "remotes::install_github(\'your-username/Tivy\')"  # Ajustar según corresponda
        
    - name: Run daily update
      run: Rscript 2_actualizacion_diaria.R
      
    - name: Commit and push changes
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add data/
        git diff --staged --quiet || git commit -m "Actualización automática de datos - $(date)"
        git push
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
'

# Guardar archivo de GitHub Actions
writeLines(github_action_yml, ".github/workflows/update-data.yml")

cat("✅ Archivo de GitHub Actions creado: .github/workflows/update-data.yml\n")

# Crear .gitignore si no existe
if(!file.exists(".gitignore")) {
  gitignore_content <- "
# R files
.Rhistory
.RData
.Ruserdata

# Shiny
rsconnect/

# OS
.DS_Store
Thumbs.db

# Mantener datos pero ignorar archivos temporales
data/*.tmp
data/*.log
"
  
  writeLines(gitignore_content, ".gitignore")
  cat("✅ Archivo .gitignore creado\n")
}

# Crear README
readme_content <- "# 🐟 Sistema de Zonas de Cierre Pesquero

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
"

writeLines(readme_content, "README.md")

cat("✅ README.md creado\n")
cat("🎉 Configuración de automatización completada\n")
cat("\n📝 Próximos pasos:\n")
cat("1. Ejecutar: source('descarga_datos_inicial.R')\n")
cat("2. Subir todo a GitHub\n")
cat("3. Configurar GitHub Actions\n")
cat("4. Desplegar app.R a shinyapps.io\n")