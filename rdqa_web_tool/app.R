# ============================================================================
# RDQA Web Tool — Main Application Entry Point
# Routine Data Quality Audit Tool for DHIS2-integrated Health Programmes
#
# Authors : Paul Mubiri & Raymond R. Wayesu
# Version : 1.0.0
# Licence : MIT
#
# Hosting options:
#   1. shinyapps.io (free tier — 25 active hrs/month)
#   2. Posit Cloud  (posit.cloud — free tier, native R support)
#   3. Hugging Face Spaces (huggingface.co/spaces — free Docker-based hosting)
#
# R packages for DHIS2 data quality (integrated or emulated):
#   - dhis2r           : R6-class DHIS2 API client
#   - khisr            : User-friendly DHIS2 data retrieval
#   - datimutils       : DATIM/DHIS2 authentication & metadata
#   - datimvalidation  : DE-OrgUnit validity, value type, negative checks
#   - dhisextractr     : DHIS2 data extraction & formatting
# ============================================================================

source("global.R")

# ── UI ──────────────────────────────────────────────────────────────────────

ui <- page_navbar(
  title = div(
    class = "brand-title",
    span(class = "brand-icon", "MW"),
    span("RDQA Web Tool")
  ),
  id = "main_nav",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary   = "#1A365D",
    secondary = "#66C2A5",
    success   = "#2A9D8F",
    warning   = "#FC8D62",
    danger    = "#E63946",
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    "navbar-bg" = "#1A365D"
  ),
  header = tags$head(
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$link(rel = "icon",
              href = "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='80' font-weight='bold' fill='%231A365D'>R</text></svg>")
  ),
  bg = "#1A365D",

  # --- Tab: Home / Connection ---
  nav_panel(
    title = "Home",
    icon  = icon("house"),
    div(
      class = "home-container",
      fluidRow(
        column(4, mod_connect_ui("conn")),
        column(8,
          div(
            class = "welcome-panel",
            h2("Routine Data Quality Audit Tool"),
            p(class = "lead",
              "An interactive platform for conducting, visualising, and reporting ",
              "on Routine Data Quality Audits (RDQAs) for DHIS2-integrated ",
              "health programmes."),
            hr(),
            h5("Capabilities"),
            fluidRow(
              column(6,
                div(class = "feature-item",
                  icon("chart-bar", class = "feature-icon"),
                  div(
                    h6("Verification Factor Analysis"),
                    p("Compute and visualise VFs across facilities, indicators, and periods ",
                      "with tolerance band analysis (90-110%).")
                  )
                ),
                div(class = "feature-item",
                  icon("spider", class = "feature-icon"),
                  div(
                    h6("M&E Systems Assessment"),
                    p("MEASURE Evaluation RDQA Tool Part 2 systems assessment with ",
                      "radar charts and grading (Strong / Moderate / Weak).")
                  )
                ),
                div(class = "feature-item",
                  icon("shield-halved", class = "feature-icon"),
                  div(
                    h6("datimvalidation Checks"),
                    p("Data element-org unit validity, value type compliance, ",
                      "negative value detection, and statistical outlier analysis.")
                  )
                )
              ),
              column(6,
                div(class = "feature-item",
                  icon("arrows-turn-to-dots", class = "feature-icon"),
                  div(
                    h6("Three-Way Triangulation"),
                    p("Cross-reference digital platform data, facility HMIS registers, ",
                      "and national DHIS2 reported values.")
                  )
                ),
                div(class = "feature-item",
                  icon("database", class = "feature-icon"),
                  div(
                    h6("Live DHIS2 Integration"),
                    p("Connect to any DHIS2 instance via ",
                      tags$code("dhis2r"), ", ",
                      tags$code("khisr"), ", or ",
                      tags$code("datimutils"), " packages.")
                  )
                ),
                div(class = "feature-item",
                  icon("file-export", class = "feature-icon"),
                  div(
                    h6("Report Generation"),
                    p("Export facility scorecards, VF summaries, systems assessments, ",
                      "and validation logs as HTML or CSV.")
                  )
                )
              )
            ),
            hr(),
            div(class = "text-muted small",
              p(icon("info-circle"),
                " This tool integrates capabilities from five R packages for DHIS2 ",
                "data quality: ",
                tags$strong("dhis2r"), ", ",
                tags$strong("khisr"), ", ",
                tags$strong("datimutils"), ", ",
                tags$strong("datimvalidation"), ", and ",
                tags$strong("dhisextractr"), ". ",
                "When these packages are not installed, the tool operates in demo mode ",
                "with realistic simulated RDQA data."),
              p(icon("globe"),
                " Interactive demo website: ",
                tags$a(href = "https://rdqa-demo.vercel.app/",
                       "rdqa-demo.vercel.app", target = "_blank"))
            )
          )
        )
      )
    )
  ),

  # --- Tab: Dashboard ---
  nav_panel(
    title = "Dashboard",
    icon  = icon("chart-line"),
    mod_dashboard_ui("dashboard")
  ),

  # --- Tab: Verification Factors ---
  nav_panel(
    title = "Verification",
    icon  = icon("magnifying-glass-chart"),
    mod_verification_ui("verification")
  ),

  # --- Tab: Systems Assessment ---
  nav_panel(
    title = "Systems",
    icon  = icon("spider"),
    mod_systems_ui("systems")
  ),

  # --- Tab: Validation ---
  nav_panel(
    title = "Validation",
    icon  = icon("shield-halved"),
    mod_validation_ui("validation")
  ),

  # --- Tab: Reports ---
  nav_panel(
    title = "Reports",
    icon  = icon("file-lines"),
    mod_reports_ui("reports")
  ),

  # --- Footer nav ---
  nav_spacer(),
  nav_item(
    tags$a(
      href = "https://rdqa-demo.vercel.app/",
      target = "_blank",
      class = "nav-link",
      icon("globe"), "Demo Site"
    )
  ),
  nav_item(
    span(class = "nav-link text-light small",
         paste0("v", APP_VERSION))
  )
)

# ── Server ──────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Connection module returns reactive data
  conn_data <- mod_connect_server("conn")

  # Pass connection data to all other modules
  mod_dashboard_server("dashboard", conn_data)
  mod_verification_server("verification", conn_data)
  mod_systems_server("systems", conn_data)
  mod_validation_server("validation", conn_data)
  mod_reports_server("reports", conn_data)
}

# ── Launch ──────────────────────────────────────────────────────────────────

shinyApp(ui = ui, server = server)
