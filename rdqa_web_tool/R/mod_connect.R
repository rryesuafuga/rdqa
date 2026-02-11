# ============================================================================
# Module: DHIS2 Connection
# Provides UI and server logic for connecting to a DHIS2 instance
# or switching to demo mode.
# ============================================================================

mod_connect_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(
      class = "connection-panel",
      h3(icon("plug"), "DHIS2 Connection", class = "module-header"),
      p(class = "text-muted",
        "Connect to a live DHIS2 instance or use demo data to explore the tool."),

      # Package availability badges
      div(
        class = "pkg-status-row",
        h5("R Package Status"),
        uiOutput(ns("pkg_badges"))
      ),

      hr(),

      # Connection mode toggle
      radioButtons(
        ns("mode"), "Data Source",
        choices = c("Demo Mode (simulated data)" = "demo",
                    "Live DHIS2 Connection"       = "live"),
        selected = "demo", inline = TRUE
      ),

      # Live connection fields (conditionally shown)
      conditionalPanel(
        condition = sprintf("input['%s'] === 'live'", ns("mode")),
        div(
          class = "live-conn-fields",
          textInput(ns("base_url"), "DHIS2 Base URL",
                    placeholder = "https://play.dhis2.org/40.4.0"),
          textInput(ns("username"), "Username", placeholder = "admin"),
          passwordInput(ns("password"), "Password"),

          selectInput(ns("api_pkg"), "API Package",
                      choices = c("khisr (recommended)" = "khisr",
                                  "dhis2r"              = "dhis2r",
                                  "datimutils"          = "datimutils"),
                      selected = "khisr"),

          actionButton(ns("btn_connect"), "Connect",
                       class = "btn-primary", icon = icon("link")),
          actionButton(ns("btn_test"), "Test Connection",
                       class = "btn-outline-secondary", icon = icon("stethoscope"))
        )
      ),

      # Demo mode config
      conditionalPanel(
        condition = sprintf("input['%s'] === 'demo'", ns("mode")),
        div(
          class = "demo-config",
          sliderInput(ns("demo_facilities"), "Number of facilities",
                      min = 6, max = 54, value = 12, step = 6),
          sliderInput(ns("demo_months"), "Number of months",
                      min = 3, max = 10, value = 6, step = 1),
          actionButton(ns("btn_demo"), "Load Demo Data",
                       class = "btn-success", icon = icon("play"))
        )
      ),

      hr(),
      # Connection status
      uiOutput(ns("conn_status"))
    )
  )
}

mod_connect_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      connected  = FALSE,
      mode       = "demo",
      data       = NULL,
      systems    = NULL,
      root_causes = NULL,
      facilities = NULL,
      indicators = NULL,
      message    = ""
    )

    # Package badges
    output$pkg_badges <- renderUI({
      badges <- lapply(names(pkg_status), function(pkg) {
        if (pkg_status[[pkg]]) {
          span(class = "badge bg-success", icon("check"), pkg)
        } else {
          span(class = "badge bg-secondary", icon("xmark"), pkg)
        }
      })
      div(class = "d-flex gap-2 flex-wrap", badges)
    })

    # Load demo data
    observeEvent(input$btn_demo, {
      withProgress(message = "Generating demo RDQA data...", {
        incProgress(0.3)
        rv$data <- generate_demo_rdqa_data(
          n_facilities = input$demo_facilities,
          n_months     = input$demo_months
        )
        incProgress(0.3)
        rv$systems     <- generate_demo_systems_assessment(input$demo_facilities)
        rv$root_causes <- generate_demo_root_causes()
        rv$facilities  <- generate_demo_facilities() %>%
          slice_head(n = input$demo_facilities)
        rv$indicators  <- generate_demo_indicators()
        incProgress(0.3)
        rv$connected <- TRUE
        rv$mode      <- "demo"
        rv$message   <- paste0(
          "Demo data loaded: ",
          fmt_num(nrow(rv$data)), " records across ",
          input$demo_facilities, " facilities and ",
          input$demo_months, " months."
        )
      })
    })

    # Live DHIS2 connection
    observeEvent(input$btn_connect, {
      req(input$base_url, input$username, input$password)
      pkg <- input$api_pkg

      if (!pkg_status[[pkg]]) {
        rv$message <- paste0("Package '", pkg, "' is not installed. ",
                             "Run install_packages.R or use demo mode.")
        return()
      }

      withProgress(message = paste0("Connecting via ", pkg, "..."), {
        tryCatch({
          if (pkg == "khisr") {
            khisr::khis_cred(
              username = input$username,
              password = input$password,
              base_url = input$base_url
            )
            # Test by fetching org units
            orgs <- khisr::get_organisation_units(
              level = "%.eq.4",
              fields = "id,name,level",
              page_size = 10
            )
            rv$message <- paste0("Connected via khisr. Found ",
                                 nrow(orgs), " org units at level 4.")
          } else if (pkg == "dhis2r") {
            conn <- dhis2r::Dhis2r$new(
              base_url = input$base_url,
              username = input$username,
              password = input$password
            )
            rv$message <- "Connected via dhis2r."
          } else if (pkg == "datimutils") {
            datimutils::loginToDATIM(
              base_url = input$base_url,
              username = input$username,
              password = input$password
            )
            rv$message <- "Connected via datimutils."
          }

          rv$connected <- TRUE
          rv$mode      <- "live"
        }, error = function(e) {
          rv$message <- paste0("Connection failed: ", e$message)
          rv$connected <- FALSE
        })
      })
    })

    # Test connection
    observeEvent(input$btn_test, {
      req(input$base_url)
      tryCatch({
        resp <- httr::GET(paste0(input$base_url, "/api/system/info"),
                          httr::authenticate(input$username, input$password))
        if (httr::status_code(resp) == 200) {
          info <- httr::content(resp)
          rv$message <- paste0(
            "Connection OK. DHIS2 v", info$version,
            " | Revision: ", info$revision
          )
        } else {
          rv$message <- paste0("HTTP ", httr::status_code(resp),
                               ": Check credentials and URL.")
        }
      }, error = function(e) {
        rv$message <- paste0("Connection test failed: ", e$message)
      })
    })

    # Status display
    output$conn_status <- renderUI({
      if (rv$connected) {
        div(class = "alert alert-success",
            icon("circle-check"), rv$message)
      } else if (nchar(rv$message) > 0) {
        div(class = "alert alert-warning",
            icon("triangle-exclamation"), rv$message)
      } else {
        div(class = "alert alert-info",
            icon("info-circle"),
            "Select a data source and click Load / Connect.")
      }
    })

    # Return reactive data to parent
    reactive(list(
      connected   = rv$connected,
      mode        = rv$mode,
      data        = rv$data,
      systems     = rv$systems,
      root_causes = rv$root_causes,
      facilities  = rv$facilities,
      indicators  = rv$indicators
    ))
  })
}
