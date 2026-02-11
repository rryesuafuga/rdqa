# ============================================================================
# Module: Verification Factor Analysis
# Detailed facility-level VF analysis with drill-down
# ============================================================================

mod_verification_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(4,
        selectInput(ns("sel_facility"), "Select Facility",
                    choices = NULL, width = "100%")
      ),
      column(4,
        selectInput(ns("sel_vf_period"), "Period",
                    choices = NULL, width = "100%")
      ),
      column(4,
        radioButtons(ns("vf_view"), "View",
                     choices = c("Facility Detail" = "facility",
                                 "All Facilities Heatmap" = "heatmap"),
                     inline = TRUE)
      )
    ),

    # Facility detail view
    conditionalPanel(
      condition = sprintf("input['%s'] === 'facility'", ns("vf_view")),
      fluidRow(
        column(6, card(
          card_header("Verification Factors by Indicator"),
          card_body(plotlyOutput(ns("plot_facility_vf"), height = "400px"))
        )),
        column(6, card(
          card_header("Three-Way Data Triangulation"),
          card_body(plotlyOutput(ns("plot_triangulation"), height = "400px"))
        ))
      ),
      fluidRow(
        column(12, card(
          card_header("Facility VF Detail Table"),
          card_body(DTOutput(ns("tbl_facility_vf")))
        ))
      )
    ),

    # Heatmap view
    conditionalPanel(
      condition = sprintf("input['%s'] === 'heatmap'", ns("vf_view")),
      fluidRow(
        column(12, card(
          card_header("VF Heatmap: Facilities x Indicators"),
          card_body(plotlyOutput(ns("plot_heatmap"), height = "500px"))
        ))
      ),
      fluidRow(
        column(12, card(
          card_header("Facility Scorecard Summary"),
          card_body(DTOutput(ns("tbl_scorecard")))
        ))
      )
    )
  )
}

mod_verification_server <- function(id, conn_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observe({
      d <- conn_data()
      req(d$connected, d$data)
      df <- d$data

      updateSelectInput(session, "sel_facility",
                        choices = sort(unique(df$org_unit)))
      updateSelectInput(session, "sel_vf_period",
                        choices = c("All Periods", sort(unique(df$period))),
                        selected = "All Periods")
    })

    filt_data <- reactive({
      d <- conn_data()
      req(d$connected, d$data)
      df <- d$data
      if (!is.null(input$sel_vf_period) && input$sel_vf_period != "All Periods") {
        df <- df %>% filter(period == input$sel_vf_period)
      }
      df
    })

    # --- Facility VF bar chart ---
    output$plot_facility_vf <- renderPlotly({
      df <- filt_data()
      req(input$sel_facility)
      fac_df <- df %>% filter(org_unit == input$sel_facility)
      req(nrow(fac_df) > 0)

      summary_df <- fac_df %>%
        group_by(data_element) %>%
        summarise(
          mean_vf = mean(vf, na.rm = TRUE),
          vf_class = classify_vf(mean(vf, na.rm = TRUE)),
          .groups = "drop"
        )

      p <- ggplot(summary_df, aes(x = reorder(data_element, mean_vf),
                                   y = mean_vf, fill = vf_class)) +
        geom_col(alpha = 0.85, width = 0.7) +
        geom_hline(yintercept = c(VF_LOWER, VF_UPPER),
                   linetype = "dashed", color = COLORS$primary) +
        annotate("rect", xmin = -Inf, xmax = Inf,
                 ymin = VF_LOWER, ymax = VF_UPPER,
                 fill = COLORS$success, alpha = 0.08) +
        scale_fill_manual(values = c(
          "Acceptable" = COLORS$success,
          "Over-reported" = COLORS$warning,
          "Under-reported" = COLORS$danger
        )) +
        coord_flip() +
        labs(x = "", y = "Verification Factor (%)", fill = "",
             title = input$sel_facility) +
        theme_minimal(base_size = 11) +
        theme(legend.position = "none")
      ggplotly(p, tooltip = c("y"))
    })

    # --- Triangulation chart (reported vs recounted vs DHIS2 vs platform) ---
    output$plot_triangulation <- renderPlotly({
      df <- filt_data()
      req(input$sel_facility)
      fac_df <- df %>% filter(org_unit == input$sel_facility)
      req(nrow(fac_df) > 0)

      tri_df <- fac_df %>%
        group_by(data_element) %>%
        summarise(
          `Facility Reported` = mean(reported, na.rm = TRUE),
          `RDQA Recounted`    = mean(recounted, na.rm = TRUE),
          `DHIS2 Value`       = mean(dhis2_value, na.rm = TRUE),
          `Platform Value`    = mean(platform_value, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        pivot_longer(-data_element, names_to = "source", values_to = "value")

      p <- ggplot(tri_df, aes(x = data_element, y = value,
                               fill = source)) +
        geom_col(position = position_dodge(width = 0.8), width = 0.7, alpha = 0.85) +
        scale_fill_manual(values = c(
          "Facility Reported" = COLORS$chart[1],
          "RDQA Recounted"    = COLORS$chart[2],
          "DHIS2 Value"       = COLORS$chart[3],
          "Platform Value"    = COLORS$chart[4]
        )) +
        labs(x = "", y = "Value", fill = "") +
        theme_minimal(base_size = 10) +
        theme(legend.position = "bottom",
              axis.text.x = element_text(angle = 45, hjust = 1, size = 8))
      ggplotly(p) %>%
        layout(legend = list(orientation = "h", y = -0.35))
    })

    # --- Facility detail table ---
    output$tbl_facility_vf <- renderDT({
      df <- filt_data()
      req(input$sel_facility)
      fac_df <- df %>%
        filter(org_unit == input$sel_facility) %>%
        select(Period = period, Indicator = data_element,
               Reported = reported, Recounted = recounted,
               DHIS2 = dhis2_value, Platform = platform_value,
               `VF (%)` = vf, Classification = vf_class) %>%
        mutate(`VF (%)` = round(`VF (%)`, 1))

      datatable(fac_df, rownames = FALSE,
                options = list(pageLength = 15, scrollX = TRUE,
                               dom = "lfrtip"),
                class = "compact stripe hover") %>%
        formatStyle("Classification",
                    backgroundColor = styleEqual(
                      c("Acceptable", "Over-reported", "Under-reported"),
                      c("#d4edda", "#fff3cd", "#f8d7da")
                    )) %>%
        formatStyle("VF (%)",
                    color = styleInterval(
                      c(VF_LOWER, VF_UPPER),
                      c(COLORS$danger, COLORS$success, COLORS$warning)
                    ))
    })

    # --- VF Heatmap ---
    output$plot_heatmap <- renderPlotly({
      df <- filt_data()
      req(nrow(df) > 0)

      heat_df <- df %>%
        group_by(org_unit, data_element) %>%
        summarise(mean_vf = mean(vf, na.rm = TRUE), .groups = "drop")

      plot_ly(heat_df, x = ~data_element, y = ~org_unit,
              z = ~mean_vf, type = "heatmap",
              colorscale = list(
                list(0, COLORS$danger),
                list(0.45, "#fff3cd"),
                list(0.5, COLORS$success),
                list(0.55, "#fff3cd"),
                list(1, COLORS$warning)
              ),
              zmin = 70, zmax = 130,
              hoverinfo = "text",
              text = ~paste0(org_unit, "\n", data_element,
                             "\nVF: ", round(mean_vf, 1), "%")) %>%
        layout(
          xaxis = list(title = "", tickangle = -45),
          yaxis = list(title = "", tickfont = list(size = 9)),
          margin = list(l = 120, b = 100)
        )
    })

    # --- Scorecard table ---
    output$tbl_scorecard <- renderDT({
      df <- filt_data()
      req(nrow(df) > 0)

      sc <- df %>%
        group_by(org_unit, district) %>%
        summarise(
          `Records`          = n(),
          `Mean VF (%)`      = round(mean(vf, na.rm = TRUE), 1),
          `Median VF (%)`    = round(median(vf, na.rm = TRUE), 1),
          `% Acceptable`     = round(mean(vf_class == "Acceptable") * 100, 1),
          `% Over-reported`  = round(mean(vf_class == "Over-reported") * 100, 1),
          `% Under-reported` = round(mean(vf_class == "Under-reported") * 100, 1),
          .groups = "drop"
        ) %>%
        arrange(desc(`% Acceptable`))

      datatable(sc, rownames = FALSE,
                options = list(pageLength = 20, scrollX = TRUE, dom = "lfrtip"),
                class = "compact stripe hover") %>%
        formatStyle("% Acceptable",
                    background = styleColorBar(c(0, 100), COLORS$success),
                    backgroundSize = "98% 80%",
                    backgroundRepeat = "no-repeat",
                    backgroundPosition = "center") %>%
        formatStyle("Mean VF (%)",
                    color = styleInterval(
                      c(VF_LOWER, VF_UPPER),
                      c(COLORS$danger, COLORS$success, COLORS$warning)
                    ))
    })
  })
}
