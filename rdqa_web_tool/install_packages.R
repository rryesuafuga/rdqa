# ============================================================================
# RDQA Web Tool — Package Installation Script
#
# Run this script once before launching the app to install all dependencies.
# Usage: Rscript install_packages.R
# ============================================================================

cat("╔══════════════════════════════════════════════════════╗\n")
cat("║  RDQA Web Tool — Package Installer                  ║\n")
cat("║  Paul Mubiri & Raymond R. Wayesu                    ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

# --- Helper ---
install_if_missing <- function(pkg, repo = "CRAN") {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  Installing %s from %s...\n", pkg, repo))
    if (repo == "CRAN") {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(sprintf("  ✓ %s installed successfully.\n", pkg))
    } else {
      cat(sprintf("  ✗ %s installation failed.\n", pkg))
    }
  } else {
    cat(sprintf("  ✓ %s already installed.\n", pkg))
  }
}

install_from_github <- function(pkg, ghrepo) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  Installing %s from GitHub (%s)...\n", pkg, ghrepo))
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes", repos = "https://cloud.r-project.org")
    }
    tryCatch({
      remotes::install_github(ghrepo, upgrade = "never", quiet = TRUE)
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat(sprintf("  ✓ %s installed successfully.\n", pkg))
      } else {
        cat(sprintf("  ✗ %s installation failed.\n", pkg))
      }
    }, error = function(e) {
      cat(sprintf("  ✗ %s failed: %s\n", pkg, e$message))
      cat(sprintf("    (This is optional — the app works without it.)\n"))
    })
  } else {
    cat(sprintf("  ✓ %s already installed.\n", pkg))
  }
}

# --- 1. Core CRAN packages (required) ---
cat("── Core packages (CRAN) ─────────────────────────────\n")
core_packages <- c(
  "shiny", "bslib", "htmltools",
  "DT",
  "dplyr", "tidyr", "purrr", "lubridate", "stringr",
  "ggplot2", "plotly", "scales",
  "rmarkdown", "knitr",
  "httr", "jsonlite",
  "remotes"
)
for (pkg in core_packages) install_if_missing(pkg)

# --- 2. DHIS2 CRAN packages (optional but recommended) ---
cat("\n── DHIS2 packages (CRAN) ────────────────────────────\n")
install_if_missing("dhis2r")
install_if_missing("khisr")

# --- 3. DHIS2 GitHub packages (optional) ---
cat("\n── DHIS2 packages (GitHub) ──────────────────────────\n")
install_from_github("datimutils",      "pepfar-datim/datimutils")
install_from_github("datimvalidation", "pepfar-datim/datimvalidation")
install_from_github("dhisextractr",    "grlurton/dhisextractr")

# --- 4. Deployment helper ---
cat("\n── Deployment packages ──────────────────────────────\n")
install_if_missing("rsconnect")

# --- Summary ---
cat("\n══ Installation Summary ═════════════════════════════\n")
all_pkgs <- c(core_packages, "dhis2r", "khisr",
              "datimutils", "datimvalidation", "dhisextractr", "rsconnect")
installed <- sapply(all_pkgs, requireNamespace, quietly = TRUE)
cat(sprintf("  Installed: %d / %d packages\n", sum(installed), length(installed)))
if (any(!installed)) {
  cat("  Missing (optional): ",
      paste(names(installed[!installed]), collapse = ", "), "\n")
}
cat("\n  Run the app with: shiny::runApp('rdqa_web_tool')\n")
cat("═════════════════════════════════════════════════════\n")
