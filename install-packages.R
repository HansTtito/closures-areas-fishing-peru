packages <- c(
  "rsconnect",
  "Tivy",
  "dplyr",
  "leaflet",
  "pdftools",
  "png",
  "raster",
  "shinycssloaders"
)

new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if (length(new_packages)) {
  install.packages(new_packages, dependencies = TRUE)
  cat("✅ Paquetes instalados:", paste(new_packages, collapse = ", "), "\n")
} else {
  cat("✅ Todos los paquetes ya están instalados\n")
}
