if(!dir.exists(".github/workflows")) {
  dir.create(".github/workflows", recursive = TRUE)
}

github_action_yml <- '
name: Actualización Diaria de Datos

on:
  schedule:
    - cron: "0 6 * * *"
  workflow_dispatch:

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

    - name: Instalar dependencias del sistema
      run: |
        sudo apt-get update
        sudo apt-get install -y \
          libcurl4-openssl-dev \
          libssl-dev \
          libxml2-dev \
          libpoppler-cpp-dev \
          libpng-dev \
          libjpeg-dev \
          libtiff5-dev \
          libgdal-dev \
          libproj-dev \
          libgeos-dev \
          libfontconfig1-dev \
          libfreetype6-dev \
          libudunits2-dev

    - name: Instalar dependencias de R
      run: |
        R -e "install.packages(c(\'Tivy\', \'dplyr\', \'leaflet\', \'pdftools\', \'png\', \'raster\'))"

    - name: Ejecutar actualización diaria
      run: |
        if ! Rscript actualizacion_diaria.R; then
          echo "❌ Error en actualización de datos"
          exit 1
        fi

    - name: Commit y push de cambios (si los hay)
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add data/
        if git diff --staged --quiet; then
          echo "📍 No hay cambios en los datos"
        else
          git commit -m "📊 Actualización automática de datos - $(date +%Y-%m-%d\\ %H:%M)"
          git push
          echo "✅ Datos actualizados y subidos"
        fi
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
'


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
data/*.temp

# IDE
.vscode/
  .idea/
  "
 
 writeLines(gitignore_content, ".gitignore")
 cat("✅ Archivo .gitignore creado\n")
}

# Crear README mejorado
readme_content <- "# 🐟 Sistema de Zonas de Cierre Pesquero - Perú

Visualización interactiva de las zonas de cierre preventivo para anchoveta en Perú.

## 🚀 Características

- **Automatización completa**: Actualización diaria de datos vía GitHub Actions
- **Visualización interactiva**: Mapas con Leaflet y filtros dinámicos
- **Datos oficiales**: Integra resoluciones de PRODUCE
- **Open Source**: Código y datos disponibles públicamente

## 📊 Aplicaciones

- 🌐 **App Web**: [https://kevin-ttito.shinyapps.io/fishing-closures-areas-peru/](https://kevin-ttito.shinyapps.io/fishing-closures-areas-peru/)
- 📝 **Blog**: [Detalles técnicos](https://hansttito.github.io/mi-blog/projects/fishing-closures-areas-peru/)
- 💻 **Código**: Este repositorio

## 🔧 Uso Local

### Primera vez:
\`\`\`r
# 1. Descargar datos históricos
source('descarga_datos_inicial.R')

# 2. Ejecutar la aplicación
shiny::runApp()
\`\`\`

### Actualizar datos manualmente:
\`\`\`r
source('actualizacion_diaria.R')
\`\`\`

## 🤖 Automatización

- **Frecuencia**: Diaria (6:00 AM UTC)
- **Tecnología**: GitHub Actions
- **Datos**: Se actualizan automáticamente en \`data/\`
- **Deploy**: La app en shinyapps.io usa datos pre-procesados

## 📁 Estructura

\`\`\`
├── app.R                    # Aplicación Shiny
├── descarga_datos_inicial.R # Setup inicial de datos
├── actualizacion_diaria.R   # Script de actualización
├── data/                    # Datos procesados
  └── .github/workflows/       # Automatización
  \`\`\`

## 🛠️ Tecnologías

- **R**: Shiny, Leaflet, dplyr
- **Tivy**: Paquete personalizado para datos pesqueros
- **GitHub Actions**: Automatización
- **shinyapps.io**: Hosting

## 📈 Próximos pasos

1. Ejecutar: \`source('descarga_datos_inicial.R')\`
2. Subir todo a GitHub
3. Configurar GitHub Actions (automático)
4. Desplegar \`app.R\` a shinyapps.io

---
  
  Desarrollado con ❤️ para la comunidad científica pesquera del Perú.
"

writeLines(readme_content, "README.md")
cat("✅ README.md mejorado creado\n")

# Crear archivo de configuración adicional
config_content <- "# Configuración del proyecto
# Este archivo contiene variables globales

# URLs base
PRODUCE_BASE_URL <- 'https://www.produce.gob.pe'

# Configuración de la app
APP_TITLE <- 'Zonas de Cierre Pesquero - Perú'
APP_VERSION <- '1.0.0'

# Configuración de datos
DATA_UPDATE_INTERVAL <- 'daily'
MAX_RETRIES <- 3

cat('📋 Configuración cargada\\n')
"

writeLines(config_content, "config.R")
cat("✅ Archivo config.R creado\n")

cat("\n🎉 Configuración de automatización completada\n")
cat("\n📝 Archivos creados:\n")
cat("   ├── .github/workflows/update-data.yml\n")
cat("   ├── .gitignore\n") 
cat("   ├── README.md\n")
cat("   └── config.R\n")
cat("\n🚀 Próximos pasos:\n")
cat("1. Ejecutar: source('descarga_datos_inicial.R')\n")
cat("2. Subir todo a GitHub\n")
cat("3. Verificar que GitHub Actions se active automáticamente\n")
cat("4. Desplegar app.R a shinyapps.io\n")
cat("5. ¡Tu app estará siempre actualizada! 🐟\n")