# =============================================================================
# CSV MAPPING FUNCTIONS - CLEAN VERSION
# =============================================================================

#' Create popup content for CSV points
#'
#' @description
#' Generates HTML popup content for CSV points including date and
#' any additional columns found in the data.
#'
#' @param csv_data Data frame with CSV point data.
#' @param extra_cols Vector of additional column names to include.
#' @param popup_width Maximum width for popup content.
#'
#' @return Vector of HTML strings for popup content.
#'
#' @keywords internal
create_csv_popup_content <- function(csv_data, extra_cols, popup_width = 250) {
  
  popup_list <- vector("character", nrow(csv_data))
  
  for (i in 1:nrow(csv_data)) {
    row_data <- csv_data[i, ]
    
    # Start popup content
    popup_html <- paste0(
      "<div style='max-width: ", popup_width, "px; font-family: Arial, sans-serif;'>",
      "<h4 style='margin: 0 0 10px 0; color: #FF6B35; border-bottom: 2px solid #FF6B35; padding-bottom: 5px;'>",
      "📍 CSV Data Point</h4>",
      "<strong>📅 Date: </strong>", format(row_data$Date, "%d/%m/%Y"), "<br>",
      "<strong>🌐 Coordinates: </strong>", 
      round(row_data$Lat, 4), "°S, ", round(abs(row_data$Long), 4), "°W<br>"
    )
    
    # Add extra columns if available
    if (!is.null(extra_cols) && length(extra_cols) > 0) {
      popup_html <- paste0(popup_html, "<hr style='margin: 8px 0;'>")
      
      for (col in extra_cols) {
        if (col %in% colnames(csv_data) && !is.na(row_data[[col]])) {
          # Format column name for display
          display_name <- gsub("_", " ", col)
          display_name <- tools::toTitleCase(display_name)
          
          # Format value based on type
          value <- row_data[[col]]
          if (is.numeric(value)) {
            if (value == round(value)) {
              formatted_value <- format(value, big.mark = ",")
            } else {
              formatted_value <- format(round(value, 2), big.mark = ",")
            }
          } else {
            formatted_value <- as.character(value)
          }
          
          # Add emoji based on column name
          emoji <- get_column_emoji(col)
          
          popup_html <- paste0(
            popup_html,
            "<strong>", emoji, " ", display_name, ": </strong>",
            formatted_value, "<br>"
          )
        }
      }
    }
    
    popup_html <- paste0(popup_html, "</div>")
    popup_list[i] <- popup_html
  }
  
  return(popup_list)
}

#' Get appropriate emoji for column names
#'
#' @description
#' Returns appropriate emoji based on column name patterns.
#'
#' @param col_name Column name to match.
#'
#' @return Single character emoji.
#'
#' @keywords internal
get_column_emoji <- function(col_name) {
  col_lower <- tolower(col_name)
  
  if (grepl("vessel|boat|ship|embarcac", col_lower)) return("🚢")
  if (grepl("species|especie|fish|pez", col_lower)) return("🐟")
  if (grepl("catch|captura|peso|weight", col_lower)) return("⚖️")
  if (grepl("temp|temperatura", col_lower)) return("🌡️")
  if (grepl("depth|prof", col_lower)) return("📏")
  if (grepl("wind|viento", col_lower)) return("💨")
  if (grepl("current|corriente", col_lower)) return("🌊")
  if (grepl("note|observ|comment", col_lower)) return("📝")
  if (grepl("time|hora", col_lower)) return("⏰")
  if (grepl("crew|tripul", col_lower)) return("👥")
  
  return("📊") # Default emoji for data
}

#' Enhanced interactive plotting function with CSV integration
#'
#' @description
#' Creates an interactive map using leaflet, showing fishing zone polygons with popup 
#' information and optional CSV data points. This function extends the original 
#' plot_zones_interactive functionality to include CSV data visualization.
#'
#' @param polygons List of polygons. Each must have fields such as coords, announcement, dates and coordinates.
#' @param coastline Data frame with the coastline (columns Long and Lat).
#' @param title Title to display at the top of the map.
#' @param colors Vector of colors. If NULL, they are automatically assigned with RColorBrewer::brewer.pal.
#' @param show_legend Logical. If TRUE, the layers control (legend) is displayed.
#' @param labels Optional vector of names to display in the legend and map labels.
#' @param base_layers Logical. If TRUE, includes base layers such as satellite and ocean maps.
#' @param minimap Logical. If TRUE, displays a minimap in the lower right corner.
#' @param csv_data Data frame with CSV points (columns: Date, Long, Lat, and additional columns).
#' @param csv_extra_cols Vector of additional column names from CSV to show in popups.
#' @param csv_marker_color Color for CSV point markers. Default: "#FF6B35" (orange).
#' @param csv_cluster Logical. Whether to cluster CSV points when many are present.
#' @param csv_group_name Name for CSV points group in layer control.
#'
#' @return A leaflet object with the interactive map including both zones and CSV points.
#'
#' @export
#' @import leaflet
#' @importFrom RColorBrewer brewer.pal
plot_zones_with_csv <- function(polygons, 
                               title = NULL, 
                               colors = NULL, 
                               show_legend = TRUE,
                               labels = NULL, 
                               base_layers = TRUE, 
                               minimap = TRUE,
                               csv_data = NULL,
                               csv_extra_cols = NULL,
                               csv_marker_color = "#FF6B35",
                               csv_cluster = TRUE,
                               csv_group_name = "CSV Points") {

  # Generate colors for fishing zones
  if(is.null(colors)){
    colors <- RColorBrewer::brewer.pal(n = min(max(3, length(polygons)), 11), name = "Set3")
  }

  # Initialize leaflet map
  map <- leaflet::leaflet() %>%
    leaflet::addTiles(group = "OpenStreetMap")

  # Add base layers if requested
  if (base_layers) {
    map <- map %>%
      leaflet::addProviderTiles(leaflet::providers$Esri.OceanBasemap, group = "Ocean") %>%
      leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron, group = "Simple") %>%
      leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satellite")
  }

  # Add title if provided
  if (!is.null(title)) {
    map <- map %>%
      leaflet::addControl(
        html = paste0("<h4>", title, "</h4>"),
        position = "topleft"
      )
  }

  # Process fishing zone polygons
  overlay_groups <- c()

  for (i in seq_along(polygons)) {
    polygon <- polygons[[i]]
    color_idx <- (i - 1) %% length(colors) + 1

    # Determine label for this polygon
    label <- if (!is.null(labels) && length(labels) >= i) {
      labels[i]
    } else {
      polygon$announcement
    }

    overlay_groups <- c(overlay_groups, label)

    # Create popup content for fishing zones
    popup_content <- paste0(
      "<div style='max-width: 300px; font-family: Arial, sans-serif;'>",
      "<h4 style='margin: 0 0 10px 0; color: #0ea5e9; border-bottom: 2px solid #0ea5e9; padding-bottom: 5px;'>",
      "🐟 ", label, "</h4>",
      "<strong>📢 Announcement: </strong>", polygon$announcement, "<br>",
      "<strong>📅 Start date: </strong>", format(polygon$start_date, "%d/%m/%Y %H:%M"), "<br>",
      "<strong>📅 End date: </strong>", format(polygon$end_date, "%d/%m/%Y %H:%M"), "<br>",
      "<strong>🌐 Start Lat: </strong>", polygon$Start_Lat, "<br>",
      "<strong>🌐 Start Lon: </strong>", polygon$Start_Long, "<br>",
      "<strong>🌐 End Lat: </strong>", polygon$End_Lat, "<br>",
      "<strong>🌐 End Lon: </strong>", polygon$End_Long, "<br>",
      "<strong>⚓ Start Nautical Miles: </strong>", polygon$StartNauticalMiles, "<br>",
      "<strong>⚓ End Nautical Miles: </strong>", polygon$EndNauticalMiles, "<br>",
      "</div>"
    )

    # Extract coordinates for leaflet
    leaflet_coords <- list(
      lng = polygon$coords[, 1],
      lat = polygon$coords[, 2]
    )

    # Add polygon to map
    map <- map %>%
      leaflet::addPolygons(
        lng = leaflet_coords$lng,
        lat = leaflet_coords$lat,
        fillColor = colors[color_idx],
        fillOpacity = 0.7,
        color = "black",
        weight = 1,
        popup = popup_content,
        group = label,
        label = label,
        highlightOptions = leaflet::highlightOptions(
          weight = 3,
          color = "#666",
          fillOpacity = 0.8,
          bringToFront = TRUE
        )
      )
  }

  # Add CSV points if provided
  if (!is.null(csv_data) && is.data.frame(csv_data) && nrow(csv_data) > 0) {
    
    # Validate CSV data structure
    required_cols <- c("Date", "Long", "Lat")
    if (all(required_cols %in% colnames(csv_data))) {
      
      # Remove rows with missing coordinates
      valid_coords <- !is.na(csv_data$Long) & !is.na(csv_data$Lat)
      csv_clean <- csv_data[valid_coords, ]
      
      if (nrow(csv_clean) > 0) {
        
        # Add CSV group to overlay groups
        overlay_groups <- c(overlay_groups, csv_group_name)
        
        # Create popup content for CSV points
        csv_popup_content <- create_csv_popup_content(csv_clean, csv_extra_cols, 250)
        
        # Create custom icon for CSV points
        csv_icon <- leaflet::awesomeIcons(
          icon = "circle",
          iconColor = "white",
          markerColor = "orange",
          library = "fa"
        )
        
        # Add CSV points to map
        if (csv_cluster && nrow(csv_clean) > 10) {
          # Use clustering for many points
          map <- map %>%
            leaflet::addAwesomeMarkers(
              data = csv_clean,
              lng = ~Long,
              lat = ~Lat,
              icon = csv_icon,
              popup = csv_popup_content,
              label = ~paste("CSV Point -", format(Date, "%d/%m/%Y")),
              group = csv_group_name,
              clusterOptions = leaflet::markerClusterOptions(
                showCoverageOnHover = FALSE,
                zoomToBoundsOnClick = TRUE
              ),
              options = leaflet::markerOptions(riseOnHover = TRUE)
            )
        } else {
          # Regular markers for fewer points
          map <- map %>%
            leaflet::addAwesomeMarkers(
              data = csv_clean,
              lng = ~Long,
              lat = ~Lat,
              icon = csv_icon,
              popup = csv_popup_content,
              label = ~paste("CSV Point -", format(Date, "%d/%m/%Y")),
              group = csv_group_name,
              options = leaflet::markerOptions(riseOnHover = TRUE)
            )
        }
      }
    }
  }

  # Add layer control with all groups
  if (show_legend && length(overlay_groups) > 0) {
    base_groups <- if (base_layers) {
      c("OpenStreetMap", "Ocean", "Simple", "Satellite")
    } else {
      "OpenStreetMap"
    }
    
    map <- map %>%
      leaflet::addLayersControl(
        baseGroups = base_groups,
        overlayGroups = overlay_groups,
        position = "topright",
        options = leaflet::layersControlOptions(collapsed = FALSE)
      )
  }

  # Add scale bar
  map <- map %>%
    leaflet::addScaleBar(position = "bottomleft", options = leaflet::scaleBarOptions(imperial = FALSE))

  # Add minimap if requested
  if (minimap) {
    map <- map %>%
      leaflet::addMiniMap(
        tiles = leaflet::providers$CartoDB.Positron,
        toggleDisplay = TRUE,
        position = "bottomright"
      )
  }

  # Fit bounds to show all data
  all_longs <- unlist(lapply(polygons, function(p) p$coords[, 1]))
  all_lats <- unlist(lapply(polygons, function(p) p$coords[, 2]))
  
  # Include CSV bounds if available
  if (!is.null(csv_data) && nrow(csv_data) > 0 && all(c("Long", "Lat") %in% colnames(csv_data))) {
    valid_csv <- csv_data[!is.na(csv_data$Long) & !is.na(csv_data$Lat), ]
    if (nrow(valid_csv) > 0) {
      all_longs <- c(all_longs, valid_csv$Long)
      all_lats <- c(all_lats, valid_csv$Lat)
    }
  }

  map <- map %>%
    leaflet::fitBounds(
      lng1 = min(all_longs) - 0.5,
      lat1 = min(all_lats) - 0.5,
      lng2 = max(all_longs) + 0.5,
      lat2 = max(all_lats) + 0.5
    )

  return(map)
}