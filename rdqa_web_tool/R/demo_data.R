# ============================================================================
# Demo data generator — realistic RDQA data for offline / demo mode
# ============================================================================

generate_demo_facilities <- function() {
  tibble::tibble(
    org_unit_id = paste0("OU_", sprintf("%03d", 1:54)),
    org_unit    = c(
      paste0("Facility A", sprintf("%02d", 1:27)),
      paste0("Facility B", sprintf("%02d", 1:27))
    ),
    district = rep(c("District A (Urban)", "District B (Peri-Urban)"), each = 27),
    facility_type = sample(
      c("Health Centre III", "Health Centre IV", "Hospital"),
      54, replace = TRUE, prob = c(0.55, 0.30, 0.15)
    ),
    ownership = sample(
      c("Public", "Private (Franchised)", "Private (Non-Franchised)"),
      54, replace = TRUE, prob = c(0.45, 0.35, 0.20)
    )
  )
}

generate_demo_indicators <- function() {
  tibble::tibble(
    data_element_id = paste0("DE_", sprintf("%03d", 1:8)),
    data_element = c(
      "ANC 1st Visit", "ANC 4th Visit", "Facility Deliveries",
      "Family Planning New Acceptors", "HIV Testing (F 15-24)",
      "Post-Natal Care (48hrs)", "OPD Attendance (Total)",
      "Immunisation (DPT3)"
    ),
    value_type = rep("ZERO_OR_POSITIVE", 8),
    category = c(
      "Maternal Health", "Maternal Health", "Maternal Health",
      "Family Planning", "HIV/AIDS", "Maternal Health",
      "Outpatient", "Child Health"
    )
  )
}

generate_demo_rdqa_data <- function(n_facilities = 12, n_months = 6) {
  set.seed(2026)

  facilities <- generate_demo_facilities() %>% slice_head(n = n_facilities)
  indicators <- generate_demo_indicators()
  periods    <- paste0("2026", sprintf("%02d", 3:(3 + n_months - 1)))

  base <- expand.grid(
    org_unit_id     = facilities$org_unit_id,
    data_element_id = indicators$data_element_id,
    period          = periods,
    stringsAsFactors = FALSE
  ) %>%
    as_tibble() %>%
    left_join(facilities, by = "org_unit_id") %>%
    left_join(indicators, by = "data_element_id")

  base <- base %>%
    rowwise() %>%
    mutate(
      # Reported value (what the facility reported to DHIS2)
      base_value   = case_when(
        data_element == "OPD Attendance (Total)" ~ round(runif(1, 200, 800)),
        data_element == "ANC 1st Visit"          ~ round(runif(1, 15, 60)),
        data_element == "ANC 4th Visit"          ~ round(runif(1, 8, 35)),
        data_element == "Facility Deliveries"    ~ round(runif(1, 10, 45)),
        data_element == "Family Planning New Acceptors" ~ round(runif(1, 20, 80)),
        data_element == "HIV Testing (F 15-24)"  ~ round(runif(1, 25, 100)),
        data_element == "Post-Natal Care (48hrs)" ~ round(runif(1, 8, 40)),
        data_element == "Immunisation (DPT3)"    ~ round(runif(1, 12, 55)),
        TRUE ~ round(runif(1, 10, 50))
      ),
      reported     = base_value,

      # Recounted value (RDQA field recount from source documents)
      # Introduce realistic discrepancies:
      #   ~60% exact match, ~25% minor variance, ~15% significant
      disc_type = sample(c("exact", "minor", "significant"),
                         1, prob = c(0.60, 0.25, 0.15)),
      recounted = case_when(
        disc_type == "exact"       ~ reported,
        disc_type == "minor"       ~ reported + round(rnorm(1, 0, reported * 0.05)),
        disc_type == "significant" ~ reported + round(rnorm(1, 0, reported * 0.20))
      ),
      recounted = pmax(0L, as.integer(recounted)),

      # DHIS2 value (what was entered in national system — may differ from facility)
      dhis2_value = case_when(
        runif(1) < 0.70 ~ reported,
        runif(1) < 0.85 ~ reported + round(rnorm(1, -2, 3)),
        TRUE            ~ reported + round(rnorm(1, 0, reported * 0.10))
      ),
      dhis2_value = pmax(0L, as.integer(dhis2_value)),

      # Digital platform value
      platform_value = case_when(
        runif(1) < 0.75 ~ reported,
        TRUE            ~ reported + round(rnorm(1, 1, 2))
      ),
      platform_value = pmax(0L, as.integer(platform_value))
    ) %>%
    ungroup() %>%
    mutate(
      # Compute Verification Factor
      vf            = compute_vf(recounted, reported),
      vf_class      = classify_vf(vf),
      # Compute triangulation discrepancies
      platform_disc = abs(platform_value - reported),
      dhis2_disc    = abs(dhis2_value - reported),
      # For value type compliance demo
      value = as.character(reported)
    ) %>%
    select(-base_value, -disc_type)

  base
}

generate_demo_systems_assessment <- function(n_facilities = 12) {
  set.seed(42)
  facilities <- generate_demo_facilities() %>% slice_head(n = n_facilities)

  domains <- c(
    "M&E Structure",
    "Indicator Definitions",
    "Data Collection & Reporting",
    "Data Management",
    "Data Quality Mechanisms"
  )

  questions_per_domain <- c(4, 3, 5, 4, 4)

  purrr::map_dfr(seq_len(n_facilities), function(i) {
    purrr::map_dfr(seq_along(domains), function(d) {
      tibble::tibble(
        org_unit_id = facilities$org_unit_id[i],
        org_unit    = facilities$org_unit[i],
        district    = facilities$district[i],
        domain      = domains[d],
        question_n  = seq_len(questions_per_domain[d]),
        # Scores 1-3 with realistic distribution
        score       = sample(1:3, questions_per_domain[d],
                             replace = TRUE,
                             prob = c(0.15, 0.40, 0.45))
      )
    })
  })
}

generate_demo_root_causes <- function(n = 200) {
  set.seed(99)
  categories <- c(
    "Transcription Error",
    "Calculation Error",
    "Missing Source Documents",
    "Late Reporting",
    "Definition Misunderstanding"
  )
  probs <- c(0.30, 0.20, 0.18, 0.17, 0.15)

  tibble::tibble(
    root_cause = sample(categories, n, replace = TRUE, prob = probs),
    severity   = sample(c("Minor", "Moderate", "Critical"), n,
                        replace = TRUE, prob = c(0.50, 0.35, 0.15)),
    district   = sample(c("District A (Urban)", "District B (Peri-Urban)"),
                        n, replace = TRUE)
  )
}
