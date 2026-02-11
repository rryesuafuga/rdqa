# ============================================================================
# Module: Data Quality Dashboard
# Overview metrics, KPIs, and summary visualisations
# ============================================================================

mod_dashboard_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Filters row
    div(
      class = "filter-row",
      fluidRow(
        column(3, selectInput(ns("sel_district"), "District",
                              choices = NULL, multiple = TRUE)),
        column(3, selectInput(ns("sel_period"), "Period",
                              choices = NULL, multiple = TRUE)),
        column(3, selectInput(ns("sel_indicator"), "Indicator",
                              choices = NULL, multiple = TRUE)),
        column(3, selectInput(ns("sel_facility_type"), "Facility Type",
                              choices = NULL, multiple = TRUE))
      )
    ),

    # KPI cards
    div(
      class = "kpi-row",
      fluidRow(
        column(3, uiOutput(ns("kpi_total_records"))),
        column(3, uiOutput(ns("kpi_avg_vf"))),
        column(3, uiOutput(ns("kpi_acceptable_pct"))),
        column(3, uiOutput(ns("kpi_completeness")))
      )
    ),

    # Charts row 1
    fluidRow(
      column(6, card(
        card_header("Verification Factor Distribution"),
        card_body(plotlyOutput(ns("plot_vf_dist"), height = "350px"))
      )),
      column(6, card(
        card_header("VF by Indicator"),
        card_body(plotlyOutput(ns("plot_vf_indicator"), height = "350px"))
      ))
    ),

    # Charts row 2
    fluidRow(
      column(6, card(
        card_header("Completeness by Facility"),
        card_body(plotlyOutput(ns("plot_completeness"), height = "350px"))
      )),
      column(6, card(
        card_header("Discrepancy Trends Over Time"),
        card_body(plotlyOutput(ns("plot_trends"), height = "350px"))
      ))
    ),

    # Charts row 3
    fluidRow(
      column(4, card(
        card_header("VF Classification Summary"),
        card_body(plotlyOutput(ns("plot_vf_pie"), height = "300px"))
      )),
      column(4, card(
        card_header("District Comparison"),
        card_body(plotlyOutput(ns("plot_district_compare"), height = "300px"))
      )),
      column(4, card(
        card_header("Root Cause Distribution"),
        card_body(plotlyOutput(ns("plot_root_cause"), height = "300px"))
      ))
    )
  )
}

mod_dashboard_server <- function(id, conn_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Update filter choices when data loads
    observe({
      d <- conn_data()
      req(d$connected, d$data)
      df <- d$data

      updateSelectInput(session, "sel_district",
                        choices = sort(unique(df$district)),
                        selected = unique(df$district))
      updateSelectInput(session, "sel_period",
                        choices = sort(unique(df$period)),
                        selected = unique(df$period))
      updateSelectInput(session, "sel_indicator",
                        choices = sort(unique(df$data_element)),
                        selected = unique(df$data_element))
      updateSelectInput(session, "sel_facility_type",
                        choices = sort(unique(df$facility_type)),
                        selected = unique(df$facility_type))
    })

    # Filtered data
    filt <- reactive({
      d <- conn_data()
      req(d$connected, d$data)
      df <- d$data

      if (!is.null(input$sel_district) && length(input$sel_district) > 0)
        df <- df %>% filter(district %in% input$sel_district)
      if (!is.null(input$sel_period) && length(input$sel_period) > 0)
        df <- df %>% filter(period %in% input$sel_period)
      if (!is.null(input$sel_indicator) && length(input$sel_indicator) > 0)
        df <- df %>% filter(data_element %in% input$sel_indicator)
      if (!is.null(input$sel_facility_type) && length(input$sel_facility_type) > 0)
        df <- df %>% filter(facility_type %in% input$sel_facility_type)
      df
    })

    # --- KPIs ---
    output$kpi_total_records <- renderUI({
      df <- filt()
      value_box_card("Total Records", fmt_num(nrow(df)),
                     paste(n_distinct(df$org_unit), "facilities"),
                     COLORS$primary)
    })

    output$kpi_avg_vf <- renderUI({
      df <- filt()
      avg <- mean(df$vf, na.rm = TRUE)
      clr <- if (avg >= VF_LOWER & avg <= VF_UPPER) COLORS$success else COLORS$warning
      value_box_card("Mean VF", fmt_pct(avg), "Target: 90-110%", clr)
    })

    output$kpi_acceptable_pct <- renderUI({
      df <- filt()
      pct <- mean(df$vf_class == "Acceptable", na.rm = TRUE) * 100
      clr <- if (pct >= 70) COLORS$success else COLORS$warning
      value_box_card("Acceptable VF Rate", fmt_pct(pct),
                     paste(sum(df$vf_class == "Acceptable"), "of", nrow(df)),
                     clr)
    })

    output$kpi_completeness <- renderUI({
      df <- filt()
      # Completeness = reported records / expected records
      expected <- n_distinct(df$org_unit) * n_distinct(df$data_element) *
                  n_distinct(df$period)
      actual   <- nrow(df %>% filter(!is.na(reported), reported > 0))
      pct      <- (actual / expected) * 100
      value_box_card("Reporting Completeness", fmt_pct(pct),
                     paste(fmt_num(actual), "of", fmt_num(expected)),
                     if (pct >= 80) COLORS$success else COLORS$danger)
    })

    # --- VF Distribution histogram ---
    output$plot_vf_dist <- renderPlotly({
      df <- filt()
      req(nrow(df) > 0)

      p <- ggplot(df, aes(x = vf, fill = vf_class)) +
        geom_histogram(binwidth = 5, color = "white", alpha = 0.85) +
        geom_vline(xintercept = c(VF_LOWER, VF_UPPER),
                   linetype = "dashed", color = COLORS$primary, linewidth = 0.7) +
        scale_fill_manual(values = c(
          "Acceptable"     = COLORS$success,
          "Over-reported"  = COLORS$warning,
          "Under-reported" = COLORS$danger,
          "No Data"        = COLORS$muted
        )) +
        labs(x = "Verification Factor (%)", y = "Count", fill = "") +
        theme_minimal(base_size = 11) +
        theme(legend.position = "bottom")
      ggplotly(p, tooltip = c("x", "fill")) %>%
        layout(legend = list(orientation = "h", y = -0.2))
    })

    # --- VF by Indicator ---
    output$plot_vf_indicator <- renderPlotly({
      df <- filt()
      req(nrow(df) > 0)

      summary_df <- df %>%
        group_by(data_element) %>%
        summarise(
          mean_vf = mean(vf, na.rm = TRUE),
          median_vf = median(vf, na.rm = TRUE),
          n = n(),
          .groups = "drop"
        ) %>%
        arrange(mean_vf)

      summary_df$data_element <- factor(summary_df$data_element,
                                        levels = summary_df$data_element)

      p <- ggplot(summary_df, aes(x = data_element, y = mean_vf,
                                   fill = ifelse(mean_vf >= VF_LOWER & mean_vf <= VF_UPPER,
                                                 "Acceptable", "Flagged"))) +
        geom_col(alpha = 0.85) +
        geom_hline(yintercept = c(VF_LOWER, VF_UPPER),
                   linetype = "dashed", color = COLORS$primary) +
        scale_fill_manual(values = c("Acceptable" = COLORS$success,
                                     "Flagged" = COLORS$warning)) +
        coord_flip() +
        labs(x = "", y = "Mean VF (%)", fill = "") +
        theme_minimal(base_size = 11) +
        theme(legend.position = "none")
      ggplotly(p, tooltip = c("y", "x"))
    })

    # --- Completeness by Facility ---
    output$plot_completeness <- renderPlotly({
      df <- filt()
      req(nrow(df) > 0)

      expected_per_facility <- n_distinct(df$data_element) * n_distinct(df$period)

      comp_df <- df %>%
        group_by(org_unit, district) %>%
        summarise(
          reported_n = sum(!is.na(reported) & reported > 0),
          completeness = (reported_n / expected_per_facility) * 100,
          .groups = "drop"
        ) %>%
        arrange(completeness) %>%
        mutate(org_unit = factor(org_unit, levels = org_unit))

      p <- ggplot(comp_df, aes(x = org_unit, y = completeness, fill = district)) +
        geom_col(alpha = 0.85) +
        geom_hline(yintercept = 80, linetype = "dashed",
                   color = COLORS$danger, linewidth = 0.5) +
        scale_fill_manual(values = c(COLORS$chart[1], COLORS$chart[2])) +
        coord_flip() +
        labs(x = "", y = "Completeness (%)", fill = "District") +
        theme_minimal(base_size = 10) +
        theme(legend.position = "bottom",
              axis.text.y = element_text(size = 7))
      ggplotly(p, tooltip = c("y", "fill")) %>%
        layout(legend = list(orientation = "h", y = -0.2))
    })

    # --- Trends over time ---
    output$plot_trends <- renderPlotly({
      df <- filt()
      req(nrow(df) > 0)

      trend_df <- df %>%
        group_by(period) %>%
        summarise(
          mean_vf       = mean(vf, na.rm = TRUE),
          pct_acceptable = mean(vf_class == "Acceptable") * 100,
          avg_disc      = mean(platform_disc + dhis2_disc, na.rm = TRUE),
          .groups = "drop"
        )

      p <- ggplot(trend_df, aes(x = period)) +
        geom_line(aes(y = mean_vf, color = "Mean VF"),
                  linewidth = 1, group = 1) +
        geom_point(aes(y = mean_vf, color = "Mean VF"), size = 3) +
        geom_line(aes(y = pct_acceptable, color = "% Acceptable"),
                  linewidth = 1, group = 1, linetype = "dashed") +
        geom_point(aes(y = pct_acceptable, color = "% Acceptable"), size = 3) +
        geom_hline(yintercept = c(VF_LOWER, VF_UPPER),
                   linetype = "dotted", color = COLORS$muted) +
        scale_color_manual(values = c("Mean VF" = COLORS$primary,
                                      "% Acceptable" = COLORS$accent)) +
        labs(x = "Period", y = "Value (%)", color = "") +
        theme_minimal(base_size = 11) +
        theme(legend.position = "bottom",
              axis.text.x = element_text(angle = 45, hjust = 1))
      ggplotly(p) %>%
        layout(legend = list(orientation = "h", y = -0.25))
    })

    # --- VF Classification pie ---
    output$plot_vf_pie <- renderPlotly({
      df <- filt()
      req(nrow(df) > 0)

      pie_df <- df %>%
        count(vf_class) %>%
        mutate(pct = n / sum(n) * 100)

      plot_ly(pie_df, labels = ~vf_class, values = ~n, type = "pie",
              marker = list(colors = c(
                "Acceptable" = COLORS$success,
                "Over-reported" = COLORS$warning,
                "Under-reported" = COLORS$danger,
                "No Data" = COLORS$muted
              )[pie_df$vf_class]),
              textinfo = "label+percent",
              hoverinfo = "text",
              text = ~paste0(vf_class, ": ", n, " (", round(pct, 1), "%)")) %>%
        layout(showlegend = FALSE,
               margin = list(l = 10, r = 10, t = 10, b = 10))
    })

    # --- District comparison ---
    output$plot_district_compare <- renderPlotly({
      df <- filt()
      req(nrow(df) > 0)

      dist_df <- df %>%
        group_by(district) %>%
        summarise(
          `Mean VF`        = mean(vf, na.rm = TRUE),
          `% Acceptable`   = mean(vf_class == "Acceptable") * 100,
          `Avg Discrepancy` = mean(abs(recounted - reported), na.rm = TRUE),
          .groups = "drop"
        ) %>%
        pivot_longer(-district, names_to = "metric", values_to = "value")

      p <- ggplot(dist_df, aes(x = metric, y = value, fill = district)) +
        geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
        scale_fill_manual(values = c(COLORS$chart[1], COLORS$chart[2])) +
        labs(x = "", y = "", fill = "District") +
        theme_minimal(base_size = 10) +
        theme(legend.position = "bottom")
      ggplotly(p) %>%
        layout(legend = list(orientation = "h", y = -0.3))
    })

    # --- Root cause distribution ---
    output$plot_root_cause <- renderPlotly({
      d <- conn_data()
      req(d$connected, d$root_causes)
      rc <- d$root_causes

      # Apply district filter
      if (!is.null(input$sel_district) && length(input$sel_district) > 0) {
        rc <- rc %>% filter(district %in% input$sel_district)
      }

      rc_df <- rc %>%
        count(root_cause) %>%
        arrange(desc(n)) %>%
        mutate(root_cause = factor(root_cause, levels = root_cause))

      plot_ly(rc_df, labels = ~root_cause, values = ~n, type = "pie",
              hole = 0.45,
              marker = list(colors = COLORS$chart[1:nrow(rc_df)]),
              textinfo = "label+percent") %>%
        layout(showlegend = FALSE,
               margin = list(l = 10, r = 10, t = 10, b = 10))
    })
  })
}
