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
  
  .map-container {
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    border: 1px solid #e2e8f0;
  }
  
  .info-section {
    background: #f1f5f9;
    padding: 15px;
    border-radius: 8px;
    margin-top: 20px;
    font-size: 12px;
    color: #64748b;
    border-left: 3px solid #0ea5e9;
  }
"