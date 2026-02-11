# ============================================================================
# Module: Systems Assessment
# M&E Systems Assessment based on MEASURE Evaluation RDQA Tool Part 2
# ============================================================================

mod_systems_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(4,
        selectInput(ns("sel_sys_facility"), "Select Facility",
                    choices = NULL, width = "100%")
      ),
      column(4,
        radioButtons(ns("sys_view"), "View",
                     choices = c("Radar Chart"     = "radar",
                                 "Comparison Table" = "table"),
                     inline = TRUE)
      ),
      column(4,
        checkboxInput(ns("show_district_avg"), "Show district average", TRUE)
      )
    ),

    conditionalPanel(
      condition = sprintf("input['%s'] === 'radar'", ns("sys_view")),
      fluidRow(
        column(6, card(
          card_header("Facility Systems Assessment — Spider Chart"),
          card_body(plotlyOutput(ns("plot_radar"), height = "450px"))
        )),
        column(6, card(
          card_header("Domain Score Breakdown"),
          card_body(plotlyOutput(ns("plot_domain_bars"), height = "450px"))
        ))
      )
    ),

    conditionalPanel(
      condition = sprintf("input['%s'] === 'table'", ns("sys_view")),
      fluidRow(
        column(12, card(
          card_header("Systems Assessment Scores — All Facilities"),
          card_body(DTOutput(ns("tbl_systems")))
        ))
      )
    ),

    fluidRow(
      column(12, card(
        card_header("Systems Assessment Grade Distribution"),
        card_body(plotlyOutput(ns("plot_grade_dist"), height = "300px"))
      ))
    )
  )
}

mod_systems_server <- function(id, conn_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observe({
      d <- conn_data()
      req(d$connected, d$systems)
      facs <- sort(unique(d$systems$org_unit))
      updateSelectInput(session, "sel_sys_facility", choices = facs)
    })

    # --- Spider / Radar chart ---
    output$plot_radar <- renderPlotly({
      d <- conn_data()
      req(d$connected, d$systems, input$sel_sys_facility)
      sa <- d$systems

      fac_scores <- sa %>%
        filter(org_unit == input$sel_sys_facility) %>%
        group_by(domain) %>%
        summarise(avg = mean(score, na.rm = TRUE), .groups = "drop")

      domains <- fac_scores$domain
      values  <- fac_scores$avg

      # Close the polygon
      domains_closed <- c(domains, domains[1])
      values_closed  <- c(values, values[1])

      p <- plot_ly(type = "scatterpolar", mode = "lines+markers") %>%
        add_trace(
          theta = domains_closed,
          r     = values_closed,
          name  = input$sel_sys_facility,
          fill  = "toself",
          fillcolor = paste0(COLORS$accent, "40"),
          line  = list(color = COLORS$accent, width = 2),
          marker = list(size = 8, color = COLORS$accent)
        )

      # District average overlay
      if (input$show_district_avg) {
        fac_district <- sa %>%
          filter(org_unit == input$sel_sys_facility) %>%
          pull(district) %>% unique()

        dist_scores <- sa %>%
          filter(district == fac_district) %>%
          group_by(domain) %>%
          summarise(avg = mean(score, na.rm = TRUE), .groups = "drop")

        dist_vals <- dist_scores$avg
        dist_closed <- c(dist_vals, dist_vals[1])

        p <- p %>%
          add_trace(
            theta = domains_closed,
            r     = dist_closed,
            name  = paste0(fac_district, " Avg"),
            fill  = "toself",
            fillcolor = paste0(COLORS$chart[3], "25"),
            line  = list(color = COLORS$chart[3], width = 2, dash = "dash"),
            marker = list(size = 6, color = COLORS$chart[3])
          )
      }

      p %>% layout(
        polar = list(
          radialaxis = list(
            range = c(0, 3),
            tickvals = c(1, 2, 3),
            ticktext = c("Weak", "Moderate", "Strong"),
            gridcolor = "#e2e8f0"
          ),
          angularaxis = list(tickfont = list(size = 10))
        ),
        legend = list(orientation = "h", y = -0.15),
        margin = list(t = 30, b = 50)
      )
    })

    # --- Domain score bars ---
    output$plot_domain_bars <- renderPlotly({
      d <- conn_data()
      req(d$connected, d$systems, input$sel_sys_facility)
      sa <- d$systems

      fac_scores <- sa %>%
        filter(org_unit == input$sel_sys_facility) %>%
        group_by(domain) %>%
        summarise(
          avg   = mean(score, na.rm = TRUE),
          grade = systems_assessment_grade(mean(score, na.rm = TRUE)),
          n_questions = n(),
          .groups = "drop"
        )

      p <- ggplot(fac_scores, aes(x = reorder(domain, avg), y = avg, fill = grade)) +
        geom_col(alpha = 0.85, width = 0.6) +
        geom_hline(yintercept = c(1.5, 2.5),
                   linetype = "dashed", color = COLORS$muted, linewidth = 0.4) +
        scale_fill_manual(values = c(
          "Strong"   = COLORS$success,
          "Moderate" = COLORS$warning,
          "Weak"     = COLORS$danger
        )) +
        scale_y_continuous(limits = c(0, 3),
                           breaks = c(1, 2, 3),
                           labels = c("Weak", "Moderate", "Strong")) +
        coord_flip() +
        labs(x = "", y = "Average Score", fill = "Grade",
             title = input$sel_sys_facility) +
        theme_minimal(base_size = 11) +
        theme(legend.position = "bottom")
      ggplotly(p) %>%
        layout(legend = list(orientation = "h", y = -0.2))
    })

    # --- Systems assessment table ---
    output$tbl_systems <- renderDT({
      d <- conn_data()
      req(d$connected, d$systems)
      sa <- d$systems

      pivot_df <- sa %>%
        group_by(org_unit, district, domain) %>%
        summarise(avg_score = round(mean(score, na.rm = TRUE), 2),
                  .groups = "drop") %>%
        pivot_wider(names_from = domain, values_from = avg_score) %>%
        rowwise() %>%
        mutate(Overall = round(mean(c_across(-c(org_unit, district)), na.rm = TRUE), 2),
               Grade   = systems_assessment_grade(Overall)) %>%
        ungroup() %>%
        arrange(desc(Overall))

      datatable(pivot_df, rownames = FALSE,
                options = list(pageLength = 20, scrollX = TRUE, dom = "lfrtip"),
                class = "compact stripe hover") %>%
        formatStyle("Grade",
                    backgroundColor = styleEqual(
                      c("Strong", "Moderate", "Weak"),
                      c("#d4edda", "#fff3cd", "#f8d7da")
                    )) %>%
        formatStyle("Overall",
                    background = styleColorBar(c(0, 3), COLORS$accent),
                    backgroundSize = "98% 80%",
                    backgroundRepeat = "no-repeat",
                    backgroundPosition = "center")
    })

    # --- Grade distribution ---
    output$plot_grade_dist <- renderPlotly({
      d <- conn_data()
      req(d$connected, d$systems)
      sa <- d$systems

      grade_df <- sa %>%
        group_by(org_unit) %>%
        summarise(avg = mean(score, na.rm = TRUE), .groups = "drop") %>%
        mutate(grade = systems_assessment_grade(avg)) %>%
        count(grade)

      plot_ly(grade_df, x = ~grade, y = ~n, type = "bar",
              marker = list(color = c(
                "Strong" = COLORS$success,
                "Moderate" = COLORS$warning,
                "Weak" = COLORS$danger
              )[grade_df$grade]),
              hoverinfo = "text",
              text = ~paste0(grade, ": ", n, " facilities")) %>%
        layout(xaxis = list(title = ""),
               yaxis = list(title = "Number of Facilities"),
               margin = list(b = 40))
    })
  })
}
