# =============================================================================
# CONFIGURACIÓN Y DEPENDENCIAS
# =============================================================================

# Librerías
library(shiny)
library(leaflet)
library(Tivy)
library(shinycssloaders)
library(shinyWidgets)

# CSS personalizado
# =============================================================================
# CSS WITH CSV SECTION STYLING
# =============================================================================

# CSS with CSV upload styling
css <- "
  body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background-color: #f8fafc;
  }
  
  .main-header {
    background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
    color: white;
    padding: 25px;
    margin-bottom: 25px;
    border-radius: 12px;
    box-shadow: 0 8px 30px rgba(14, 165, 233, 0.3);
  }
  
  .main-header h1 {
    margin: 0;
    font-size: 28px;
    font-weight: 700;
  }
  
  .sidebar-panel {
    background: white;
    border-radius: 12px;
    padding: 25px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    border: 1px solid #e2e8f0;
  }
  
  .btn-search {
    background: linear-gradient(135deg, #0ea5e9, #0284c7);
    border: none;
    color: white;
    font-weight: 600;
    padding: 12px 24px;
    border-radius: 10px;
    width: 100%;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(14, 165, 233, 0.3);
  }
  
  .btn-search:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(14, 165, 233, 0.4);
    color: white;
  }
  
  /* CSV Upload Styling */
  .form-group {
    margin-bottom: 15px;
  }
  
  .form-control-file {
    border: 2px dashed #cbd5e1;
    border-radius: 8px;
    padding: 15px;
    background: #f8fafc;
    transition: all 0.3s ease;
  }
  
  .form-control-file:hover {
    border-color: #0ea5e9;
    background: #f0f9ff;
  }
  
  .btn-outline-secondary {
    border: 1px solid #64748b;
    color: #64748b;
    background: transparent;
    transition: all 0.3s ease;
  }
  
  .btn-outline-secondary:hover {
    background: #64748b;
    color: white;
    border-color: #64748b;
  }
  
  /* Status Boxes */
  .status-box {
    padding: 15px;
    border-radius: 8px;
    font-weight: 500;
    margin-top: 15px;
    border-left: 4px solid;
  }
  
  .status-waiting {
    background: #e3f2fd;
    color: #1565c0;
    border-color: #2196f3;
  }
  
  .status-success {
    background: #e8f5e8;
    color: #2e7d32;
    border-color: #4caf50;
  }
  
  .status-error {
    background: #ffebee;
    color: #c62828;
    border-color: #f44336;
  }
  
  .status-empty {
    background: #fff8e1;
    color: #f57f17;
    border-color: #ffeb3b;
  }
  
  /* Map Container */
  .map-container {
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    border: 1px solid #e2e8f0;
  }
  
  /* Info Sections */
  .info-section {
    background: #f1f5f9;
    padding: 15px;
    border-radius: 8px;
    margin-top: 20px;
    font-size: 12px;
    color: #64748b;
    border-left: 3px solid #0ea5e9;
  }
  
  .info-section h5 {
    color: #334155;
    font-size: 13px;
    margin-bottom: 8px;
  }
  
  .info-section ul {
    margin: 8px 0;
    padding-left: 15px;
  }
  
  .info-section li {
    margin: 3px 0;
    font-size: 11px;
  }
  
  /* Leaflet Popup Customization */
  .leaflet-popup-content {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }
  
  .leaflet-popup-content h4 {
    margin-top: 0;
    font-size: 16px;
  }
  
  /* Date Input Styling */
  .form-control {
    border-radius: 8px;
    border: 1px solid #d1d5db;
    transition: border-color 0.3s ease;
  }
  
  .form-control:focus {
    border-color: #0ea5e9;
    box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
  }
  
  /* Section Dividers */
  .section-divider {
    border-top: 2px solid #e2e8f0;
    margin: 20px 0;
    padding-top: 20px;
  }
  
  /* Responsive Adjustments */
  @media (max-width: 768px) {
    .sidebar-panel {
      margin-bottom: 20px;
    }
    
    .main-header h1 {
      font-size: 24px;
    }
    
    .btn-search {
      padding: 10px 20px;
    }
  }
"