# ============================================================================
# RDQA Web Tool — Deployment Script
#
# Three free hosting options:
#
#   1. shinyapps.io  — 25 active hours/month free tier
#   2. Posit Cloud   — Free shared project with Shiny support
#   3. Hugging Face Spaces — Free Docker-based hosting
#
# Usage: Rscript deploy.R [target]
#        target = "shinyapps" | "posit" | "info"
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
target <- if (length(args) > 0) args[1] else "info"

# ──────────────────────────────────────────────────────────────────────────
# Option 1: shinyapps.io (Recommended)
# ──────────────────────────────────────────────────────────────────────────
deploy_shinyapps <- function() {
  cat("── Deploying to shinyapps.io ─────────────────────\n")
  cat("Make sure you have set your credentials first:\n")
  cat("  rsconnect::setAccountInfo(\n")
  cat("    name   = 'YOUR_ACCOUNT',\n")
  cat("    token  = 'YOUR_TOKEN',\n")
  cat("    secret = 'YOUR_SECRET'\n")
  cat("  )\n\n")

  library(rsconnect)

  deployApp(
    appDir   = ".",
    appName  = "rdqa-web-tool",
    appTitle = "RDQA Web Tool",
    account  = Sys.getenv("SHINYAPPS_ACCOUNT", unset = NULL),
    forceUpdate = TRUE,
    launch.browser = TRUE
  )
}

# ──────────────────────────────────────────────────────────────────────────
# Option 2: Posit Cloud
# ──────────────────────────────────────────────────────────────────────────
deploy_posit_info <- function() {
  cat("── Posit Cloud Deployment ────────────────────────\n\n")
  cat("Steps to deploy on Posit Cloud (posit.cloud):\n\n")
  cat("1. Create a free account at https://posit.cloud/\n")
  cat("2. Click 'New Project' → 'New Project from Git Repository'\n")
  cat("3. Enter the repo URL (this repository)\n")
  cat("4. Once the project opens, run in the R console:\n")
  cat("     source('rdqa_web_tool/install_packages.R')\n")
  cat("     shiny::runApp('rdqa_web_tool')\n")
  cat("5. Click the 'Publish' button (top-right of viewer)\n")
  cat("6. Follow the prompts to publish to shinyapps.io\n\n")
  cat("Free tier limits:\n")
  cat("  - 25 project hours/month\n")
  cat("  - 1 GB RAM per project\n")
  cat("  - Up to 50 projects\n")
}

# ──────────────────────────────────────────────────────────────────────────
# Option 3: Hugging Face Spaces
# ──────────────────────────────────────────────────────────────────────────
deploy_hf_info <- function() {
  cat("── Hugging Face Spaces Deployment ────────────────\n\n")
  cat("Steps to deploy on Hugging Face Spaces:\n\n")
  cat("1. Create a free account at https://huggingface.co/\n")
  cat("2. Go to https://huggingface.co/new-space\n")
  cat("3. Name: 'rdqa-web-tool', SDK: 'Docker'\n")
  cat("4. Create a Dockerfile in the Space repo:\n\n")
  cat("   FROM rocker/shiny:4.4.0\n")
  cat("   RUN install2.r --error \\\\\n")
  cat("     shiny bslib DT dplyr tidyr purrr lubridate stringr \\\\\n")
  cat("     ggplot2 plotly scales rmarkdown knitr httr jsonlite \\\\\n")
  cat("     dhis2r khisr\n")
  cat("   COPY rdqa_web_tool/ /srv/shiny-server/\n")
  cat("   EXPOSE 3838\n")
  cat("   CMD [\"/usr/bin/shiny-server\"]\n\n")
  cat("5. Push the repo — the Space auto-builds and deploys\n\n")
  cat("Free tier limits:\n")
  cat("  - 2 vCPU, 16 GB RAM (generous!)\n")
  cat("  - Sleeps after 48h inactivity, wakes on access\n")
  cat("  - Unlimited active hours (no monthly cap)\n")
}

# ──────────────────────────────────────────────────────────────────────────
# Dispatch
# ──────────────────────────────────────────────────────────────────────────
switch(target,
  "shinyapps" = deploy_shinyapps(),
  "posit"     = deploy_posit_info(),
  "hf"        = deploy_hf_info(),
  "info"      = {
    cat("╔══════════════════════════════════════════════════════╗\n")
    cat("║  RDQA Web Tool — Deployment Guide                   ║\n")
    cat("╚══════════════════════════════════════════════════════╝\n\n")
    cat("Three free hosting options:\n\n")
    cat("  1. shinyapps.io  (25 active hrs/month — best for monthly reporting)\n")
    cat("     Deploy: Rscript deploy.R shinyapps\n\n")
    cat("  2. Posit Cloud   (posit.cloud — native R, easy setup)\n")
    cat("     Info:   Rscript deploy.R posit\n\n")
    cat("  3. Hugging Face Spaces (Docker-based, generous free tier)\n")
    cat("     Info:   Rscript deploy.R hf\n\n")
    cat("Local development:\n")
    cat("  shiny::runApp('rdqa_web_tool')\n\n")
    deploy_posit_info()
    cat("\n")
    deploy_hf_info()
  }
)
