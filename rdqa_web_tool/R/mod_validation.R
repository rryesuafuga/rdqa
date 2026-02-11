# ============================================================================
# Module: Data Validation Checks
# Implements datimvalidation-style business logic checks
# (checkDataElementOrgunitValidity, checkValueTypeCompliance,
#  checkNegativeValues, outlier detection)
# ============================================================================

mod_validation_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(8,
        h5("Validation Checks",
           class = "module-header"),
        p(class = "text-muted",
          "Automated data quality validation inspired by the ",
          tags$code("datimvalidation"), " R package. Checks include ",
          "value type compliance, negative value detection, org unit-data element ",
          "validity, completeness gaps, and statistical outliers.")
      ),
      column(4,
        div(class = "d-flex gap-2 justify-content-end mt-3",
          actionButton(ns("btn_run_checks"), "Run All Checks",
                       class = "btn-primary", icon = icon("play")),
          downloadButton(ns("dl_validation_report"), "Export CSV",
                         class = "btn-outline-secondary")
        )
      )
    ),

    hr(),

    # Summary cards
    fluidRow(
      column(2, uiOutput(ns("card_total_issues"))),
      column(2, uiOutput(ns("card_value_type"))),
      column(2, uiOutput(ns("card_negative"))),
      column(2, uiOutput(ns("card_completeness"))),
      column(2, uiOutput(ns("card_outliers"))),
      column(2, uiOutput(ns("card_pass_rate")))
    ),

    # Issues table
    fluidRow(
      column(12, card(
        card_header(
          div(class = "d-flex justify-content-between align-items-center",
            span("Validation Issues Log"),
            selectInput(ns("filter_check_type"), NULL,
                        choices = c("All Checks", "Value Type Compliance",
                                    "Negative Values", "Completeness",
                                    "Statistical Outlier"),
                        width = "220px")
          )
        ),
        card_body(DTOutput(ns("tbl_issues")))
      ))
    ),

    # Visualisations
    fluidRow(
      column(6, card(
        card_header("Issues by Check Type"),
        card_body(plotlyOutput(ns("plot_issues_by_type"), height = "300px"))
      )),
      column(6, card(
        card_header("Issues by Indicator"),
        card_body(plotlyOutput(ns("plot_issues_by_indicator"), height = "300px"))
      ))
    ),

    fluidRow(
      column(12, card(
        card_header("Outlier Detection — Modified Z-Score"),
        card_body(
          fluidRow(
            column(4, selectInput(ns("outlier_indicator"), "Indicator",
                                  choices = NULL)),
            column(4, sliderInput(ns("outlier_threshold"), "Z-Score Threshold",
                                  min = 2, max = 5, value = 3, step = 0.5)),
            column(4, br(), actionButton(ns("btn_run_outliers"), "Detect Outliers",
                                         class = "btn-outline-primary"))
          ),
          plotlyOutput(ns("plot_outliers"), height = "350px")
        )
      ))
    )
  )
}

mod_validation_server <- function(id, conn_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- reactiveValues(issues = NULL, run = FALSE)

    observe({
      d <- conn_data()
      req(d$connected, d$data)
      updateSelectInput(session, "outlier_indicator",
                        choices = sort(unique(d$data$data_element)))
    })

    # Run all checks
    observeEvent(input$btn_run_checks, {
      d <- conn_data()
      req(d$connected, d$data)
      df <- d$data

      withProgress(message = "Running validation checks...", {
        all_issues <- list()

        # 1. Value type compliance
        incProgress(0.2, detail = "Value type compliance...")
        vtc <- check_value_type_compliance(df)
        if (nrow(vtc) > 0) all_issues <- c(all_issues, list(vtc))

        # 2. Negative values
        incProgress(0.2, detail = "Negative values...")
        neg <- check_negative_values(df)
        if (nrow(neg) > 0) all_issues <- c(all_issues, list(neg))

        # 3. Completeness
        incProgress(0.2, detail = "Completeness gaps...")
        expected <- expand.grid(
          data_element = unique(df$data_element),
          org_unit     = unique(df$org_unit),
          period       = unique(df$period),
          stringsAsFactors = FALSE
        ) %>% as_tibble()
        comp <- check_completeness(df, expected)
        if (!is.null(comp) && nrow(comp) > 0) all_issues <- c(all_issues, list(comp))

        # 4. Outliers
        incProgress(0.2, detail = "Outlier detection...")
        out <- check_outliers(df, threshold = 3)
        if (nrow(out) > 0) all_issues <- c(all_issues, list(out))

        incProgress(0.2, detail = "Compiling results...")

        if (length(all_issues) > 0) {
          common_cols <- c("data_element", "org_unit", "check", "issue")
          rv$issues <- bind_rows(lapply(all_issues, function(x) {
            x %>% select(any_of(c(common_cols, "period", "value")))
          }))
        } else {
          rv$issues <- tibble(
            data_element = character(),
            org_unit     = character(),
            check        = character(),
            issue        = character()
          )
        }
        rv$run <- TRUE
      })
    })

    # --- Summary cards ---
    output$card_total_issues <- renderUI({
      req(rv$run)
      n <- nrow(rv$issues)
      clr <- if (n == 0) COLORS$success else COLORS$danger
      value_box_card("Total Issues", fmt_num(n), "across all checks", clr)
    })

    output$card_value_type <- renderUI({
      req(rv$run)
      n <- sum(rv$issues$check == "Value Type Compliance")
      value_box_card("Value Type", fmt_num(n), "non-compliant", COLORS$chart[2])
    })

    output$card_negative <- renderUI({
      req(rv$run)
      n <- sum(rv$issues$check == "Negative Values")
      value_box_card("Negatives", fmt_num(n), "negative values", COLORS$chart[4])
    })

    output$card_completeness <- renderUI({
      req(rv$run)
      n <- sum(rv$issues$check == "Completeness")
      value_box_card("Missing", fmt_num(n), "missing records", COLORS$chart[3])
    })

    output$card_outliers <- renderUI({
      req(rv$run)
      n <- sum(rv$issues$check == "Statistical Outlier")
      value_box_card("Outliers", fmt_num(n), "statistical outliers", COLORS$warning)
    })

    output$card_pass_rate <- renderUI({
      req(rv$run)
      d <- conn_data()
      total_records <- nrow(d$data)
      issues <- nrow(rv$issues)
      rate <- max(0, (1 - issues / total_records) * 100)
      clr <- if (rate >= 90) COLORS$success else COLORS$warning
      value_box_card("Pass Rate", fmt_pct(rate), "of records clean", clr)
    })

    # --- Issues table ---
    output$tbl_issues <- renderDT({
      req(rv$run)
      df <- rv$issues

      if (!is.null(input$filter_check_type) &&
          input$filter_check_type != "All Checks") {
        df <- df %>% filter(check == input$filter_check_type)
      }

      datatable(df, rownames = FALSE,
                options = list(pageLength = 20, scrollX = TRUE, dom = "lfrtip"),
                class = "compact stripe hover") %>%
        formatStyle("check",
                    backgroundColor = styleEqual(
                      c("Value Type Compliance", "Negative Values",
                        "Completeness", "Statistical Outlier"),
                      c("#fff3cd", "#f8d7da", "#cce5ff", "#fce4ec")
                    ))
    })

    # --- Issues by type chart ---
    output$plot_issues_by_type <- renderPlotly({
      req(rv$run, nrow(rv$issues) > 0)
      type_df <- rv$issues %>%
        count(check) %>%
        arrange(desc(n))

      plot_ly(type_df, x = ~reorder(check, n), y = ~n, type = "bar",
              marker = list(color = COLORS$chart[1:nrow(type_df)]),
              hoverinfo = "text",
              text = ~paste0(check, ": ", n, " issues")) %>%
        layout(xaxis = list(title = ""), yaxis = list(title = "Count"),
               margin = list(b = 80))
    })

    # --- Issues by indicator ---
    output$plot_issues_by_indicator <- renderPlotly({
      req(rv$run, nrow(rv$issues) > 0)
      ind_df <- rv$issues %>%
        filter(!is.na(data_element)) %>%
        count(data_element) %>%
        arrange(desc(n))

      plot_ly(ind_df, x = ~reorder(data_element, n), y = ~n, type = "bar",
              marker = list(color = COLORS$chart[2]),
              hoverinfo = "text",
              text = ~paste0(data_element, ": ", n)) %>%
        layout(xaxis = list(title = "", tickangle = -45),
               yaxis = list(title = "Count"),
               margin = list(b = 120))
    })

    # --- Outlier detection plot ---
    observeEvent(input$btn_run_outliers, {
      output$plot_outliers <- renderPlotly({
        d <- conn_data()
        req(d$connected, d$data, input$outlier_indicator)
        df <- d$data %>%
          filter(data_element == input$outlier_indicator) %>%
          mutate(num_val = as.numeric(value))

        med <- median(df$num_val, na.rm = TRUE)
        mad_val <- mad(df$num_val, na.rm = TRUE)
        threshold <- input$outlier_threshold

        df <- df %>%
          mutate(
            z_score = if (mad_val > 0) 0.6745 * (num_val - med) / mad_val else 0,
            is_outlier = abs(z_score) > threshold
          )

        p <- ggplot(df, aes(x = org_unit, y = num_val,
                             color = is_outlier, size = is_outlier)) +
          geom_point(alpha = 0.7) +
          geom_hline(yintercept = med, linetype = "solid",
                     color = COLORS$primary, linewidth = 0.5) +
          geom_hline(yintercept = med + threshold * mad_val / 0.6745,
                     linetype = "dashed", color = COLORS$danger) +
          geom_hline(yintercept = max(0, med - threshold * mad_val / 0.6745),
                     linetype = "dashed", color = COLORS$danger) +
          scale_color_manual(values = c("FALSE" = COLORS$muted,
                                        "TRUE" = COLORS$danger)) +
          scale_size_manual(values = c("FALSE" = 2, "TRUE" = 5)) +
          labs(x = "", y = input$outlier_indicator,
               title = paste0("Outliers (|Z| > ", threshold, ")")) +
          theme_minimal(base_size = 10) +
          theme(legend.position = "none",
                axis.text.x = element_text(angle = 45, hjust = 1, size = 8))
        ggplotly(p, tooltip = c("y", "x"))
      })
    })

    # --- CSV export ---
    output$dl_validation_report <- downloadHandler(
      filename = function() {
        paste0("rdqa_validation_", Sys.Date(), ".csv")
      },
      content = function(file) {
        req(rv$run, rv$issues)
        write.csv(rv$issues, file, row.names = FALSE)
      }
    )
  })
}
