# ============================================================================
# Utility functions shared across modules
# ============================================================================

# --- Verification Factor calculation ---
compute_vf <- function(recounted, reported) {
  ifelse(reported == 0, NA_real_, (recounted / reported) * 100)
}

classify_vf <- function(vf, lower = VF_LOWER, upper = VF_UPPER) {
  case_when(
    is.na(vf)       ~ "No Data",
    vf >= lower & vf <= upper ~ "Acceptable",
    vf < lower       ~ "Under-reported",
    vf > upper       ~ "Over-reported"
  )
}

# --- Completeness rate ---
completeness_rate <- function(reported, expected) {
  ifelse(expected == 0, NA_real_, (reported / expected) * 100)
}

# --- Consistency ratio (current vs previous period) ---
consistency_ratio <- function(current, previous) {
  ifelse(previous == 0, NA_real_, (current / previous) * 100)
}

# --- Outlier detection (modified Z-score) ---
detect_outliers_zscore <- function(x, threshold = 3) {
  med <- median(x, na.rm = TRUE)
  mad_val <- mad(x, na.rm = TRUE)
  if (mad_val == 0) return(rep(FALSE, length(x)))
  modified_z <- 0.6745 * (x - med) / mad_val
  abs(modified_z) > threshold
}

# --- Systems assessment scoring ---
score_systems_assessment <- function(scores_vector) {
  # Scores are 1-3 per MEASURE Evaluation RDQA tool
  # 1 = "Not at all / No", 2 = "Partially", 3 = "Completely / Yes"
  mean(scores_vector, na.rm = TRUE)
}

systems_assessment_grade <- function(avg_score) {
  case_when(
    avg_score >= 2.5 ~ "Strong",
    avg_score >= 1.5 ~ "Moderate",
    TRUE             ~ "Weak"
  )
}

# --- Colour helper for VF classification ---
vf_color <- function(classification) {
  case_when(
    classification == "Acceptable"     ~ COLORS$success,
    classification == "Over-reported"  ~ COLORS$warning,
    classification == "Under-reported" ~ COLORS$danger,
    TRUE                               ~ COLORS$muted
  )
}

# --- Format helpers ---
fmt_pct  <- function(x) paste0(round(x, 1), "%")
fmt_num  <- function(x) format(round(x), big.mark = ",")

# --- Value box helper ---
value_box_card <- function(title, value, subtitle = NULL, color = COLORS$primary) {
  div(
    class = "rdqa-value-box",
    style = paste0("border-left: 4px solid ", color, ";"),
    div(class = "vb-title", title),
    div(class = "vb-value", value),
    if (!is.null(subtitle)) div(class = "vb-subtitle", subtitle)
  )
}

# --- datimvalidation-style checks (reimplemented for portability) ---

# Check 1: Data Element — Org Unit validity
# Ensures data elements are reported only by authorised org units
check_de_orgunit_validity <- function(df, valid_combos) {
  # df must have columns: data_element, org_unit, value

# valid_combos must have: data_element, org_unit
  if (is.null(valid_combos)) return(NULL)

  invalid <- df %>%
    anti_join(valid_combos, by = c("data_element", "org_unit")) %>%
    mutate(check = "DE-OrgUnit Validity",
           issue = paste0(data_element, " should not be reported by ", org_unit))
  invalid
}

# Check 2: Value type compliance
# Ensures numeric fields contain numbers, no text in numeric fields, etc.
check_value_type_compliance <- function(df) {
  # df must have columns: data_element, value, value_type
  issues <- df %>%
    mutate(
      is_valid = case_when(
        value_type == "NUMBER"          ~ !is.na(suppressWarnings(as.numeric(value))),
        value_type == "INTEGER"         ~ grepl("^-?\\d+$", as.character(value)),
        value_type == "POSITIVE_INTEGER" ~ grepl("^\\d+$", as.character(value)) &
                                            as.numeric(value) > 0,
        value_type == "ZERO_OR_POSITIVE" ~ grepl("^\\d+$", as.character(value)) &
                                            as.numeric(value) >= 0,
        value_type == "BOOLEAN"         ~ value %in% c("true", "false", "0", "1"),
        TRUE                            ~ TRUE
      )
    ) %>%
    filter(!is_valid) %>%
    mutate(check = "Value Type Compliance",
           issue = paste0("Value '", value, "' invalid for type ", value_type))
  issues
}

# Check 3: Negative value detection
check_negative_values <- function(df) {
  # df must have columns: data_element, org_unit, value
  issues <- df %>%
    mutate(num_val = suppressWarnings(as.numeric(value))) %>%
    filter(!is.na(num_val), num_val < 0) %>%
    mutate(check = "Negative Values",
           issue = paste0(data_element, " has negative value: ", value))
  issues
}

# Check 4: Completeness check
check_completeness <- function(df, expected_combos) {
  # expected_combos: data_element x org_unit x period combinations expected
  if (is.null(expected_combos)) return(NULL)

  missing <- expected_combos %>%
    anti_join(df, by = c("data_element", "org_unit", "period")) %>%
    mutate(check = "Completeness",
           issue = paste0(data_element, " missing for ", org_unit, " in ", period))
  missing
}

# Check 5: Outlier check
check_outliers <- function(df, threshold = 3) {
  df %>%
    group_by(data_element) %>%
    mutate(
      num_val    = suppressWarnings(as.numeric(value)),
      is_outlier = detect_outliers_zscore(num_val, threshold)
    ) %>%
    ungroup() %>%
    filter(is_outlier) %>%
    mutate(check = "Statistical Outlier",
           issue = paste0(data_element, " value ", value, " is a statistical outlier"))
}
