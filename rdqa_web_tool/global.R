# ============================================================================
# RDQA Web Tool — Global Configuration
# Routine Data Quality Audit Tool for DHIS2-integrated Health Programmes
# Authors: Paul Mubiri & Raymond R. Wayesu
# ============================================================================

# --- Core Shiny packages ---
library(shiny)
library(bslib)
library(htmltools)
library(DT)

# --- Data manipulation ---
library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)
library(stringr)

# --- Visualization ---
library(ggplot2)
library(plotly)
library(scales)

# --- Reporting ---
library(rmarkdown)
library(knitr)

# --- DHIS2 packages (loaded conditionally) ---
# These are loaded with graceful fallbacks so the app works in demo mode
# even when DHIS2 packages are not installed.

dhis2r_available    <- requireNamespace("dhis2r", quietly = TRUE)
khisr_available     <- requireNamespace("khisr", quietly = TRUE)
datimutils_available <- requireNamespace("datimutils", quietly = TRUE)
datimvalidation_available <- requireNamespace("datimvalidation", quietly = TRUE)
dhisextractr_available <- requireNamespace("dhisextractr", quietly = TRUE)

pkg_status <- list(
  dhis2r          = dhis2r_available,
  khisr           = khisr_available,
  datimutils      = datimutils_available,
  datimvalidation = datimvalidation_available,
  dhisextractr    = dhisextractr_available
)

# --- App configuration ---
APP_TITLE   <- "RDQA Web Tool"
APP_VERSION <- "1.0.0"
APP_AUTHORS <- "Paul Mubiri & Raymond R. Wayesu"

# VF tolerance band
VF_LOWER <- 90
VF_UPPER <- 110

# Color palette (ColorBrewer Set2 — colorblind-safe)
COLORS <- list(
  primary    = "#1A365D",
  secondary  = "#2C5282",
  accent     = "#66C2A5",
  warning    = "#FC8D62",
  danger     = "#E63946",
  success    = "#2A9D8F",
  muted      = "#718096",
  light_bg   = "#F7FAFC",
  chart = c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3",
            "#A6D854", "#FFD92F", "#E5C494", "#B3B3B3")
)

# --- Source module files ---
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = FALSE)
}
