# =============================================================================
# CSV DATA PROCESSING HELPER FUNCTIONS
# =============================================================================

#' Validate CSV data structure
#'
#' @description
#' Validates that uploaded CSV has required columns and proper data types.
#' Checks for minimum required columns: Date, Long, Lat.
#'
#' @param data Data frame from uploaded CSV file.
#' @param required_cols Vector of required column names. Default: c("Date", "Long", "Lat").
#' @param date_col_patterns Vector of patterns to match date columns if "Date" not found.
#' @param lon_col_patterns Vector of patterns to match longitude columns if "Long" not found.
#' @param lat_col_patterns Vector of patterns to match latitude columns if "Lat" not found.
#'
#' @return List with validation results:
#'   - valid: Boolean indicating if validation passed
#'   - message: Character string with validation message
#'   - detected_cols: Named vector with detected column names
#'   - extra_cols: Vector of additional columns found
#'
#' @examples
#' \dontrun{
#' result <- validate_csv_data(uploaded_data)
#' if(result$valid) {
#'   # Process data
#' } else {
#'   # Show error message
#'   print(result$message)
#' }
#' }
#'
#' @export
validate_csv_data <- function(data, 
                              required_cols = c("Date", "Long", "Lat"),
                              date_col_patterns = c("date", "fecha", "day", "dia"),
                              lon_col_patterns = c("lon", "long", "longitude", "longitud"),
                              lat_col_patterns = c("lat", "latitude", "latitud")) {
  
  if (!is.data.frame(data)) {
    return(list(
      valid = FALSE,
      message = "❌ Invalid file format. Please upload a CSV file.",
      detected_cols = NULL,
      extra_cols = NULL
    ))
  }
  
  if (nrow(data) == 0) {
    return(list(
      valid = FALSE,
      message = "❌ CSV file is empty.",
      detected_cols = NULL,
      extra_cols = NULL
    ))
  }
  
  # Get column names (case insensitive)
  col_names <- colnames(data)
  col_names_lower <- tolower(col_names)
  
  # Try to detect required columns
  detected_cols <- character(3)
  names(detected_cols) <- c("date", "longitude", "latitude")
  
  # Detect date column
  date_idx <- NULL
  for (pattern in date_col_patterns) {
    matches <- grep(pattern, col_names_lower, ignore.case = TRUE)
    if (length(matches) > 0) {
      date_idx <- matches[1]
      break
    }
  }
  
  # Detect longitude column  
  lon_idx <- NULL
  for (pattern in lon_col_patterns) {
    matches <- grep(pattern, col_names_lower, ignore.case = TRUE)
    if (length(matches) > 0) {
      lon_idx <- matches[1]
      break
    }
  }
  
  # Detect latitude column
  lat_idx <- NULL
  for (pattern in lat_col_patterns) {
    matches <- grep(pattern, col_names_lower, ignore.case = TRUE)
    if (length(matches) > 0) {
      lat_idx <- matches[1]
      break
    }
  }
  
  # Check if all required columns were found
  missing_cols <- character(0)
  
  if (is.null(date_idx)) {
    missing_cols <- c(missing_cols, "Date")
  } else {
    detected_cols["date"] <- col_names[date_idx]
  }
  
  if (is.null(lon_idx)) {
    missing_cols <- c(missing_cols, "Longitude")
  } else {
    detected_cols["longitude"] <- col_names[lon_idx]
  }
  
  if (is.null(lat_idx)) {
    missing_cols <- c(missing_cols, "Latitude")
  } else {
    detected_cols["latitude"] <- col_names[lat_idx]
  }
  
  if (length(missing_cols) > 0) {
    return(list(
      valid = FALSE,
      message = paste0("❌ Missing required columns: ", paste(missing_cols, collapse = ", "), 
                      ". Available columns: ", paste(col_names, collapse = ", ")),
      detected_cols = detected_cols,
      extra_cols = NULL
    ))
  }
  
  # Validate data types and ranges
  date_col <- data[[detected_cols["date"]]]
  lon_col <- data[[detected_cols["longitude"]]]
  lat_col <- data[[detected_cols["latitude"]]]
  
  # Check longitude range
  if (!is.numeric(lon_col) || any(lon_col < -180 | lon_col > 180, na.rm = TRUE)) {
    return(list(
      valid = FALSE,
      message = "❌ Invalid longitude values. Must be numeric between -180 and 180.",
      detected_cols = detected_cols,
      extra_cols = NULL
    ))
  }
  
  # Check latitude range
  if (!is.numeric(lat_col) || any(lat_col < -90 | lat_col > 90, na.rm = TRUE)) {
    return(list(
      valid = FALSE,
      message = "❌ Invalid latitude values. Must be numeric between -90 and 90.",
      detected_cols = detected_cols,
      extra_cols = NULL
    ))
  }
  
  # Identify extra columns for popup information
  used_indices <- c(date_idx, lon_idx, lat_idx)
  extra_indices <- setdiff(1:length(col_names), used_indices)
  extra_cols <- col_names[extra_indices]
  
  return(list(
    valid = TRUE,
    message = paste0("✅ CSV validated successfully. ", nrow(data), " rows found."),
    detected_cols = detected_cols,
    extra_cols = extra_cols
  ))
}

#' Process CSV data for mapping
#'
#' @description
#' Processes validated CSV data, converts dates, filters by date range,
#' and prepares data for mapping visualization.
#'
#' @param data Data frame with CSV data.
#' @param detected_cols Named vector with detected column names from validate_csv_data().
#' @param extra_cols Vector of additional column names for popup information.
#' @param date_start Start date for filtering (Date object).
#' @param date_end End date for filtering (Date object).
#'
#' @return List with processed data:
#'   - data: Processed and filtered data frame
#'   - message: Processing status message
#'   - n_total: Total number of rows before filtering
#'   - n_filtered: Number of rows after filtering
#'
#' @examples
#' \dontrun{
#' validation <- validate_csv_data(csv_data)
#' if(validation$valid) {
#'   processed <- process_csv_data(
#'     csv_data, 
#'     validation$detected_cols,
#'     validation$extra_cols,
#'     as.Date("2024-01-01"),
#'     as.Date("2024-12-31")
#'   )
#' }
#' }
#'
#' @export
process_csv_data <- function(data, detected_cols, extra_cols, date_start, date_end) {
  
  tryCatch({
    n_total <- nrow(data)
    
    # Rename columns to standard names
    processed_data <- data
    colnames(processed_data)[colnames(processed_data) == detected_cols["date"]] <- "Date"
    colnames(processed_data)[colnames(processed_data) == detected_cols["longitude"]] <- "Long"
    colnames(processed_data)[colnames(processed_data) == detected_cols["latitude"]] <- "Lat"
    
    # Convert date column to proper Date format
    date_converted <- convert_to_date(processed_data$Date, output_type = "date")
    
    if (is.null(date_converted)) {
      return(list(
        data = data.frame(),
        message = "❌ Could not parse date format. Please use DD/MM/YYYY, YYYY-MM-DD, or similar formats.",
        n_total = n_total,
        n_filtered = 0
      ))
    }
    
    processed_data$Date <- date_converted
    
    # Filter by date range
    if (!is.null(date_start) && !is.null(date_end)) {
      date_filter <- processed_data$Date >= date_start & processed_data$Date <= date_end
      processed_data <- processed_data[date_filter, ]
    }
    
    # Remove rows with missing coordinates
    complete_coords <- complete.cases(processed_data[, c("Long", "Lat")])
    processed_data <- processed_data[complete_coords, ]
    
    n_filtered <- nrow(processed_data)
    
    if (n_filtered == 0) {
      return(list(
        data = data.frame(),
        message = paste0("📋 No CSV points found in the selected date range (", 
                        format(date_start, "%d/%m/%Y"), " to ", 
                        format(date_end, "%d/%m/%Y"), ")"),
        n_total = n_total,
        n_filtered = 0
      ))
    }
    
    return(list(
      data = processed_data,
      message = paste0("✅ ", n_filtered, " CSV points processed successfully"),
      n_total = n_total,
      n_filtered = n_filtered
    ))
    
  }, error = function(e) {
    return(list(
      data = data.frame(),
      message = paste0("❌ Error processing CSV data: ", substr(as.character(e), 1, 50)),
      n_total = nrow(data),
      n_filtered = 0
    ))
  })
}

#' Generate mock CSV data for testing (Ocean points only)
#'
#' @description
#' Creates sample CSV data with random coordinates in ocean waters around Peru coast,
#' random dates, and additional sample columns for testing purposes.
#' All coordinates are validated using Tivy::land_points() to ensure they are in ocean areas only.
#'
#' @param n_points Number of sample points to generate. Default: 50.
#' @param date_start Start date for random date generation.
#' @param date_end End date for random date generation.
#' @param lat_range Latitude range (vector of min, max). Default: c(-18, -4).
#' @param lon_range Longitude range (vector of min, max). Default: c(-82, -75).
#' @param additional_cols List of additional columns to include.
#' @param max_attempts Maximum attempts to generate valid ocean coordinates per point. Default: 100.
#'
#' @return Data frame with mock CSV data ready for download.
#'
#' @examples
#' \dontrun{
#' mock_data <- generate_mock_csv_data(
#'   n_points = 100,
#'   date_start = as.Date("2024-01-01"),
#'   date_end = as.Date("2024-12-31")
#' )
#' write.csv(mock_data, "sample_data.csv", row.names = FALSE)
#' }
#'
#' @export
generate_mock_csv_data <- function(n_points = 50,
                                  date_start = Sys.Date() - 90,
                                  date_end = Sys.Date(),
                                  lat_range = c(-18, -4),
                                  lon_range = c(-82, -75),
                                  additional_cols = list(
                                    "Vessel" = c("Boat_A", "Boat_B", "Boat_C", "Boat_D"),
                                    "Species" = c("Anchovy", "Sardine", "Mackerel", "Tuna"),
                                    "Catch_kg" = NULL,
                                    "Temperature" = NULL,
                                    "Depth_m" = NULL,
                                    "Notes" = c("Good conditions", "Rough seas", "Clear water", "Strong wind")
                                  ),
                                  max_attempts = 100) {
  
  # set.seed(123) # For reproducible results
  
  # Generate random dates
  date_seq <- seq(from = date_start, to = date_end, by = "day")
  random_dates <- sample(date_seq, n_points, replace = TRUE)
  
  # Ocean-based fishing zones clusters (known fishing areas offshore)
  cluster_centers <- list(
    c(-12.5, -77.8), # West of Lima (offshore)
    c(-8.3, -79.5),  # West of Trujillo (offshore)
    c(-14.2, -76.8), # West of Ica (offshore)
    c(-16.1, -74.5), # West of Arequipa (offshore)
    c(-6.0, -81.0),  # North Peru offshore
    c(-10.5, -78.5), # Central Peru offshore
    c(-15.8, -75.2)  # South Peru offshore
  )
  
  lats <- numeric(n_points)
  lons <- numeric(n_points)
  
  # Generate ocean coordinates with Tivy validation
  for (i in 1:n_points) {
    attempts <- 0
    valid_point <- FALSE
    
    while (!valid_point && attempts < max_attempts) {
      attempts <- attempts + 1
      
      # Generate coordinate based on clustering strategy
      if (runif(1) < 0.8 && length(cluster_centers) > 0) {
        # 80% clustered around known fishing areas
        center <- cluster_centers[[sample(length(cluster_centers), 1)]]
        candidate_lat <- center[1] + rnorm(1, 0, 0.4)
        candidate_lon <- center[2] + rnorm(1, 0, 0.3)
      } else {
        # 20% random ocean points
        candidate_lat <- runif(1, lat_range[1], lat_range[2])
        candidate_lon <- runif(1, lon_range[1], lon_range[2])
      }
      
      # Ensure coordinates are within bounds
      candidate_lat <- max(lat_range[1], min(lat_range[2], candidate_lat))
      candidate_lon <- max(lon_range[1], min(lon_range[2], candidate_lon))
      
      # Validate with Tivy::land_points()
      tryCatch({
        land_status <- Tivy::land_points(x_point = candidate_lon, y_point = candidate_lat)
        
        if (land_status == "sea") {
          lats[i] <- candidate_lat
          lons[i] <- candidate_lon
          valid_point <- TRUE
        }
        
      }, error = function(e) {
        # If Tivy function fails, skip this coordinate and try again
        warning(paste("Tivy::land_points() failed for coordinates:", 
                     candidate_lon, candidate_lat, "- trying again"))
      })
    }
    
    # If we couldn't find a valid ocean point after max_attempts, 
    # use a fallback known ocean coordinate
    if (!valid_point) {
      warning(paste("Could not generate valid ocean point after", max_attempts, 
                   "attempts for point", i, ". Using fallback coordinates."))
      
      # Use a known ocean coordinate as fallback (west of Lima)
      fallback_centers <- list(
        c(-12.0, -78.5),
        c(-10.0, -78.8),
        c(-14.0, -77.5),
        c(-16.0, -75.0),
        c(-8.0, -80.0)
      )
      
      fallback <- fallback_centers[[((i-1) %% length(fallback_centers)) + 1]]
      lats[i] <- fallback[1] + runif(1, -0.2, 0.2)
      lons[i] <- fallback[2] + runif(1, -0.2, 0.2)
    }
  }
  
  # Create base data frame
  mock_data <- data.frame(
    Date = format(random_dates, "%d/%m/%Y"),
    Long = round(lons, 4),
    Lat = round(lats, 4),
    stringsAsFactors = FALSE
  )
  
  # Add additional columns
  for (col_name in names(additional_cols)) {
    col_values <- additional_cols[[col_name]]
    
    if (is.null(col_values)) {
      # Generate numeric data based on column name
      if (grepl("catch|peso", tolower(col_name))) {
        mock_data[[col_name]] <- round(runif(n_points, 50, 500), 1)
      } else if (grepl("temp", tolower(col_name))) {
        mock_data[[col_name]] <- round(runif(n_points, 15, 25), 1)
      } else if (grepl("depth|prof", tolower(col_name))) {
        # Ocean depths - should be realistic for fishing areas
        mock_data[[col_name]] <- round(runif(n_points, 20, 300), 0)
      } else {
        mock_data[[col_name]] <- round(runif(n_points, 1, 100), 2)
      }
    } else {
      # Sample from provided values
      mock_data[[col_name]] <- sample(col_values, n_points, replace = TRUE)
    }
  }
  
  # Sort by date
  mock_data <- mock_data[order(as.Date(mock_data$Date, format = "%d/%m/%Y")), ]
  rownames(mock_data) <- NULL
  
  return(mock_data)
}