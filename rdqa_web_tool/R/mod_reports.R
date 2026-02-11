# ============================================================================
# Module: Report Generation
# Generate downloadable RDQA reports in HTML, PDF (via rmarkdown), and CSV
# ============================================================================

mod_reports_ui <- function(id) {
  ns <- NS(id)

  tagList(
    h3(icon("file-lines"), "Report Generation", class = "module-header"),
    p(class = "text-muted",
      "Generate comprehensive RDQA reports for submission to programme teams. ",
      "Reports include VF analysis, systems assessment summaries, validation ",
      "findings, and recommended corrective actions."),

    hr(),

    fluidRow(
      column(4, card(
        card_header("Report Configuration"),
        card_body(
          textInput(ns("report_title"), "Report Title",
                    value = "Monthly RDQA Report"),
          textInput(ns("report_programme"), "Programme Name",
                    value = "Health Programme"),
          selectInput(ns("report_period"), "Reporting Period",
                      choices = NULL),
          textInput(ns("report_author"), "Author(s)",
                    value = APP_AUTHORS),
          checkboxGroupInput(ns("report_sections"), "Include Sections",
                             choices = c(
                               "Executive Summary"      = "exec_summary",
                               "Verification Factors"   = "vf_analysis",
                               "Systems Assessment"     = "systems",
                               "Validation Checks"      = "validation",
                               "Root Cause Analysis"    = "root_cause",
                               "Triangulation Summary"  = "triangulation",
                               "Recommendations"        = "recommendations"
                             ),
                             selected = c("exec_summary", "vf_analysis",
                                          "systems", "validation",
                                          "root_cause", "recommendations")),
          hr(),
          h6("Export Options"),
          div(
            class = "d-flex gap-2 flex-wrap",
            downloadButton(ns("dl_html"), "HTML Report",
                           class = "btn-primary"),
            downloadButton(ns("dl_csv_data"), "Raw Data (CSV)",
                           class = "btn-outline-secondary"),
            downloadButton(ns("dl_csv_vf"), "VF Summary (CSV)",
                           class = "btn-outline-secondary"),
            downloadButton(ns("dl_csv_systems"), "Systems Assessment (CSV)",
                           class = "btn-outline-secondary")
          )
        )
      )),

      column(8, card(
        card_header("Report Preview"),
        card_body(
          uiOutput(ns("report_preview"))
        )
      ))
    )
  )
}

mod_reports_server <- function(id, conn_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observe({
      d <- conn_data()
      req(d$connected, d$data)
      periods <- sort(unique(d$data$period))
      updateSelectInput(session, "report_period",
                        choices = c("All Periods", periods))
    })

    # Report data
    report_df <- reactive({
      d <- conn_data()
      req(d$connected, d$data)
      df <- d$data
      if (!is.null(input$report_period) && input$report_period != "All Periods") {
        df <- df %>% filter(period == input$report_period)
      }
      df
    })

    # --- Report preview ---
    output$report_preview <- renderUI({
      d <- conn_data()
      req(d$connected, d$data)
      df <- report_df()

      n_fac <- n_distinct(df$org_unit)
      n_ind <- n_distinct(df$data_element)
      avg_vf <- mean(df$vf, na.rm = TRUE)
      pct_acc <- mean(df$vf_class == "Acceptable") * 100

      districts <- paste(unique(df$district), collapse = ", ")

      # Systems assessment summary
      sa_summary <- ""
      if (!is.null(d$systems) && "systems" %in% input$report_sections) {
        sa <- d$systems
        overall <- mean(sa$score, na.rm = TRUE)
        grade <- systems_assessment_grade(overall)
        sa_summary <- tagList(
          h5("Systems Assessment Summary"),
          p(paste0("Overall M&E systems assessment score: ",
                   round(overall, 2), "/3.00 (", grade, ")")),
          tags$ul(
            lapply(unique(sa$domain), function(dom) {
              avg <- mean(sa$score[sa$domain == dom], na.rm = TRUE)
              tags$li(paste0(dom, ": ", round(avg, 2),
                             " (", systems_assessment_grade(avg), ")"))
            })
          )
        )
      }

      # Root cause summary
      rc_summary <- ""
      if (!is.null(d$root_causes) && "root_cause" %in% input$report_sections) {
        rc <- d$root_causes %>% count(root_cause, sort = TRUE)
        rc_summary <- tagList(
          h5("Root Cause Analysis"),
          p("Most common root causes of data discrepancies:"),
          tags$ol(
            lapply(seq_len(min(5, nrow(rc))), function(i) {
              tags$li(paste0(rc$root_cause[i], " (",
                             round(rc$n[i] / sum(rc$n) * 100, 1), "%)"))
            })
          )
        )
      }

      tagList(
        div(class = "report-preview-container",
          h3(input$report_title),
          p(class = "text-muted",
            paste0(input$report_programme, " | ",
                   input$report_period, " | ", input$report_author)),
          hr(),

          if ("exec_summary" %in% input$report_sections) tagList(
            h5("Executive Summary"),
            p(paste0(
              "This report presents findings from the Routine Data Quality Audit ",
              "covering ", n_fac, " health facilities across ", districts, ", ",
              "examining ", n_ind, " indicators."
            )),
            p(paste0(
              "The overall mean Verification Factor is ", round(avg_vf, 1), "%. ",
              round(pct_acc, 1), "% of all facility-indicator combinations ",
              "fall within the acceptable range (", VF_LOWER, "-", VF_UPPER, "%)."
            ))
          ),

          if ("vf_analysis" %in% input$report_sections) tagList(
            h5("Verification Factor Analysis"),
            p(paste0("Total records analysed: ", fmt_num(nrow(df)))),
            tags$ul(
              tags$li(paste0("Acceptable (", VF_LOWER, "-", VF_UPPER, "%): ",
                             sum(df$vf_class == "Acceptable"), " records")),
              tags$li(paste0("Over-reported (>", VF_UPPER, "%): ",
                             sum(df$vf_class == "Over-reported"), " records")),
              tags$li(paste0("Under-reported (<", VF_LOWER, "%): ",
                             sum(df$vf_class == "Under-reported"), " records"))
            )
          ),

          sa_summary,
          rc_summary,

          if ("recommendations" %in% input$report_sections) tagList(
            h5("Recommendations"),
            tags$ol(
              tags$li("Targeted retraining on indicator definitions for facilities ",
                      "with persistent VF deviations."),
              tags$li("Strengthen data management practices at facilities rated ",
                      "'Weak' in the systems assessment."),
              tags$li("Implement monthly register stock verification to reduce ",
                      "missing source document issues."),
              tags$li("Schedule quarterly data review sessions to discuss findings ",
                      "and track corrective action implementation.")
            )
          )
        )
      )
    })

    # --- HTML report download ---
    output$dl_html <- downloadHandler(
      filename = function() {
        paste0("rdqa_report_", Sys.Date(), ".html")
      },
      content = function(file) {
        d <- conn_data()
        df <- report_df()

        # Generate a self-contained HTML report
        html_content <- paste0(
          "<!DOCTYPE html><html><head>",
          "<meta charset='utf-8'>",
          "<title>", htmltools::htmlEscape(input$report_title), "</title>",
          "<style>",
          "body{font-family:Helvetica,Arial,sans-serif;max-width:900px;margin:40px auto;padding:0 20px;color:#1a365d;line-height:1.6}",
          "h1{color:#1a365d;border-bottom:3px solid #66C2A5;padding-bottom:8px}",
          "h2{color:#2c5282;margin-top:30px}",
          "table{border-collapse:collapse;width:100%;margin:15px 0}",
          "th{background:#1a365d;color:white;padding:8px 12px;text-align:left}",
          "td{padding:6px 12px;border-bottom:1px solid #e2e8f0}",
          "tr:nth-child(even){background:#f7fafc}",
          ".kpi{display:inline-block;background:#f7fafc;border-left:4px solid #66C2A5;padding:12px 20px;margin:8px;border-radius:4px}",
          ".kpi .value{font-size:24px;font-weight:bold;color:#1a365d}",
          ".acceptable{color:#2a9d8f}.flagged{color:#e63946}",
          "</style></head><body>",
          "<h1>", htmltools::htmlEscape(input$report_title), "</h1>",
          "<p><em>", htmltools::htmlEscape(input$report_programme),
          " | ", input$report_period,
          " | ", htmltools::htmlEscape(input$report_author),
          " | Generated: ", Sys.Date(), "</em></p>",
          "<hr>"
        )

        # KPIs
        avg_vf <- mean(df$vf, na.rm = TRUE)
        pct_acc <- mean(df$vf_class == "Acceptable") * 100

        html_content <- paste0(html_content,
          "<div class='kpi'><div>Facilities</div><div class='value'>",
          n_distinct(df$org_unit), "</div></div>",
          "<div class='kpi'><div>Mean VF</div><div class='value'>",
          round(avg_vf, 1), "%</div></div>",
          "<div class='kpi'><div>Acceptable Rate</div><div class='value'>",
          round(pct_acc, 1), "%</div></div>",
          "<div class='kpi'><div>Records</div><div class='value'>",
          nrow(df), "</div></div>"
        )

        # VF Summary table
        vf_summary <- df %>%
          group_by(`Indicator` = data_element) %>%
          summarise(
            N = n(),
            `Mean VF (%)` = round(mean(vf, na.rm = TRUE), 1),
            `Median VF (%)` = round(median(vf, na.rm = TRUE), 1),
            `% Acceptable` = round(mean(vf_class == "Acceptable") * 100, 1),
            .groups = "drop"
          )

        html_content <- paste0(html_content,
          "<h2>Verification Factor Summary by Indicator</h2><table><tr>",
          paste0("<th>", names(vf_summary), "</th>", collapse = ""),
          "</tr>"
        )
        for (i in seq_len(nrow(vf_summary))) {
          html_content <- paste0(html_content, "<tr>",
            paste0("<td>", vf_summary[i, ], "</td>", collapse = ""),
            "</tr>")
        }
        html_content <- paste0(html_content, "</table>")

        # Facility scorecard
        scorecard <- df %>%
          group_by(Facility = org_unit, District = district) %>%
          summarise(
            `Mean VF (%)` = round(mean(vf, na.rm = TRUE), 1),
            `% Acceptable` = round(mean(vf_class == "Acceptable") * 100, 1),
            .groups = "drop"
          ) %>%
          arrange(desc(`% Acceptable`))

        html_content <- paste0(html_content,
          "<h2>Facility Scorecard</h2><table><tr>",
          paste0("<th>", names(scorecard), "</th>", collapse = ""),
          "</tr>"
        )
        for (i in seq_len(nrow(scorecard))) {
          html_content <- paste0(html_content, "<tr>",
            paste0("<td>", scorecard[i, ], "</td>", collapse = ""),
            "</tr>")
        }
        html_content <- paste0(html_content, "</table>")

        html_content <- paste0(html_content,
          "<hr><p style='color:#718096;font-size:12px'>",
          "Generated by RDQA Web Tool v", APP_VERSION,
          " | ", APP_AUTHORS,
          " | <a href='https://rdqa-demo.vercel.app/'>rdqa-demo.vercel.app</a></p>",
          "</body></html>")

        writeLines(html_content, file)
      }
    )

    # --- CSV data export ---
    output$dl_csv_data <- downloadHandler(
      filename = function() paste0("rdqa_raw_data_", Sys.Date(), ".csv"),
      content = function(file) {
        write.csv(report_df(), file, row.names = FALSE)
      }
    )

    output$dl_csv_vf <- downloadHandler(
      filename = function() paste0("rdqa_vf_summary_", Sys.Date(), ".csv"),
      content = function(file) {
        df <- report_df() %>%
          group_by(org_unit, district, data_element, period) %>%
          summarise(
            reported = sum(reported), recounted = sum(recounted),
            vf = compute_vf(sum(recounted), sum(reported)),
            classification = classify_vf(vf),
            .groups = "drop"
          )
        write.csv(df, file, row.names = FALSE)
      }
    )

    output$dl_csv_systems <- downloadHandler(
      filename = function() paste0("rdqa_systems_assessment_", Sys.Date(), ".csv"),
      content = function(file) {
        d <- conn_data()
        if (!is.null(d$systems)) {
          write.csv(d$systems, file, row.names = FALSE)
        }
      }
    )
  })
}
