# Script to create entrepreneurship income variables
# This script creates conditional income variables where:
# - If ent == 0, then ent_inc_* = 0
# - Otherwise, ent_inc_* = corresponding income variable

# Load required libraries
library('dplyr')
library('data.table')

# Source the CPS class object
# Note: Adjust the path based on your working directory
# If running from dev_work/, use: source(file.path('class_object', 'cps.R'))  # run with WD = code/
# If running from EDJE-cps/, use: source('class_object/cps.R')
source(file.path('class_object', 'cps.R'))  # run with WD = code/

# ============================================================================
# Function to create entrepreneurship income variables
# ============================================================================
# Creates conditional income variables for entrepreneurs.
#
# Parameters:
#   cps_df : data.frame
#     The CPS dataframe (can be from entrepreneurship.df() or entrepreneurship.df.from.existing())
#   ent_var : character
#     The entrepreneurship variable name (default: "entrepreneurship2")
#     Options: "entrepreneurship1" or "entrepreneurship2"
#
# Returns:
#   data.frame with new ent_inc_* variables added
create_ent_inc_variables <- function(cps_df, ent_var = "entrepreneurship2") {
  
  # Convert to data.table for efficient operations
  setDT(cps_df)
  
  # Check if entrepreneurship variable exists
  if (!ent_var %in% names(cps_df)) {
    stop(paste("Error: Entrepreneurship variable '", ent_var, "' not found in dataframe.", sep = ""))
  }
  
  # Create ent variable (0 or 1) for easier conditional logic
  cps_df[, ent := as.integer(get(ent_var) == 1)]
  
  # ============================================================================
  # Create ent_inc variables based on available income variables
  # ============================================================================
  
  # 1. ent_inc: Basic income (incwage if available, otherwise earnweek2 * 52)
  if ("incwage" %in% names(cps_df)) {
    cps_df[, ent_inc := ifelse(ent == 0, 0, incwage)]
  } else if ("earnweek2" %in% names(cps_df)) {
    # Convert weekly earnings to annual if incwage not available
    cps_df[, ent_inc := ifelse(ent == 0, 0, earnweek2 * 52)]
  } else {
    warning("Neither 'incwage' nor 'earnweek2' found. ent_inc will be set to 0.")
    cps_df[, ent_inc := 0]
  }
  
  # 2. ent_inc_adj: Adjusted income (incwage_adj if available)
  if ("incwage_adj" %in% names(cps_df)) {
    cps_df[, ent_inc_adj := ifelse(ent == 0, 0, incwage_adj)]
  } else {
    warning("'incwage_adj' not found. ent_inc_adj will be set to 0.")
    cps_df[, ent_inc_adj := 0]
  }
  
  # 3. ent_inc_adj_2024: 2024-adjusted income
  if ("incwage_adj_2024" %in% names(cps_df)) {
    cps_df[, ent_inc_adj_2024 := ifelse(ent == 0, 0, incwage_adj_2024)]
  } else {
    warning("'incwage_adj_2024' not found. ent_inc_adj_2024 will be set to 0.")
    cps_df[, ent_inc_adj_2024 := 0]
  }
  
  # 4. ent_inc_adj_2024_annual: Annual 2024-adjusted income
  if ("incwage_adj_2024_annual" %in% names(cps_df)) {
    cps_df[, ent_inc_adj_2024_annual := ifelse(ent == 0, 0, incwage_adj_2024_annual)]
  } else {
    warning("'incwage_adj_2024_annual' not found. ent_inc_adj_2024_annual will be set to 0.")
    cps_df[, ent_inc_adj_2024_annual := 0]
  }
  
  # 5. ent_inc_adj_2024_annual_avg: Average annual 2024-adjusted income
  if ("incwage_adj_2024_annual_avg" %in% names(cps_df)) {
    cps_df[, ent_inc_adj_2024_annual_avg := ifelse(ent == 0, 0, incwage_adj_2024_annual_avg)]
  } else {
    warning("'incwage_adj_2024_annual_avg' not found. ent_inc_adj_2024_annual_avg will be set to 0.")
    cps_df[, ent_inc_adj_2024_annual_avg := 0]
  }
  
  # 6. ent_inc_adj_2024_annual_avg_avg: Double average annual 2024-adjusted income
  if ("incwage_adj_2024_annual_avg_avg" %in% names(cps_df)) {
    cps_df[, ent_inc_adj_2024_annual_avg_avg := ifelse(ent == 0, 0, incwage_adj_2024_annual_avg_avg)]
  } else {
    warning("'incwage_adj_2024_annual_avg_avg' not found. ent_inc_adj_2024_annual_avg_avg will be set to 0.")
    cps_df[, ent_inc_adj_2024_annual_avg_avg := 0]
  }
  
  # 7. ent_inc_adj_2024_annual_avg_avg_avg: Triple average annual 2024-adjusted income
  if ("incwage_adj_2024_annual_avg_avg_avg" %in% names(cps_df)) {
    cps_df[, ent_inc_adj_2024_annual_avg_avg_avg := ifelse(ent == 0, 0, incwage_adj_2024_annual_avg_avg_avg)]
  } else {
    warning("'incwage_adj_2024_annual_avg_avg_avg' not found. ent_inc_adj_2024_annual_avg_avg_avg will be set to 0.")
    cps_df[, ent_inc_adj_2024_annual_avg_avg_avg := 0]
  }
  
  # 8. ent_inc_adj_2024_annual_avg_avg_avg_avg: Quadruple average annual 2024-adjusted income
  if ("incwage_adj_2024_annual_avg_avg_avg_avg" %in% names(cps_df)) {
    cps_df[, ent_inc_adj_2024_annual_avg_avg_avg_avg := ifelse(ent == 0, 0, incwage_adj_2024_annual_avg_avg_avg_avg)]
  } else {
    warning("'incwage_adj_2024_annual_avg_avg_avg_avg' not found. ent_inc_adj_2024_annual_avg_avg_avg_avg will be set to 0.")
    cps_df[, ent_inc_adj_2024_annual_avg_avg_avg_avg := 0]
  }
  
  # Convert back to data.frame
  cps_df <- as.data.frame(cps_df)
  
  # Print summary
  cat("\n=== Entrepreneurship Income Variables Created ===\n")
  cat("Entrepreneurship variable used:", ent_var, "\n")
  cat("Total observations:", nrow(cps_df), "\n")
  cat("Entrepreneurs (ent == 1):", sum(cps_df$ent == 1, na.rm = TRUE), "\n")
  cat("Non-entrepreneurs (ent == 0):", sum(cps_df$ent == 0, na.rm = TRUE), "\n\n")
  
  # Show summary statistics for created variables
  ent_inc_vars <- grep("^ent_inc", names(cps_df), value = TRUE)
  if (length(ent_inc_vars) > 0) {
    cat("Created variables:\n")
    for (var in ent_inc_vars) {
      if (var != "ent") {
        non_zero <- sum(cps_df[[var]] != 0, na.rm = TRUE)
        mean_val <- mean(cps_df[[var]][cps_df$ent == 1], na.rm = TRUE)
        cat(sprintf("  %s: %d non-zero values, mean (ent==1) = %.2f\n", 
                    var, non_zero, mean_val))
      }
    }
  }
  
  return(cps_df)
}

# ============================================================================
# Example Usage
# ============================================================================
# 
# # Option 1: Create from existing CPS data
# # First, load your CPS data using the class object
# cps_obj <- cps(poi = c(c(2002,7), c(2020,7)),
#                voi = c('race','hispan','nchild','sex','educ','ind1990','age',
#                        'statefip','county','individcc','classwkr','mish',
#                        'marst','earnweek2','hhtenure','wtfinl','earnwt'),
#                importType = 'local',
#                localPath = 'dev_work/cps_00040.xml')
# 
# # Get entrepreneurship dataframe
# cps_df <- cps_obj$entrepreneurship.df.from.existing(
#   existing_df = read_ipums_micro('dev_work/cps_00040.xml') %>% 
#                 setNames(tolower(names(.))),
#   ind1990Link = 'https://cps.ipums.org/cps-action/variables/IND1990#codes_section',
#   hpiCountyLink = 'class_object/hpi_at_bdl_county.xlsx'
# )
# 
# # Create entrepreneurship income variables
# cps_df <- create_ent_inc_variables(cps_df, ent_var = "entrepreneurship2")
# 
# # Option 2: Use with entrepreneurship1 instead
# # cps_df <- create_ent_inc_variables(cps_df, ent_var = "entrepreneurship1")
# 
# # View the new variables
# head(cps_df[, c("entrepreneurship2", "ent", "ent_inc", "ent_inc_adj", 
#                 "ent_inc_adj_2024", "ent_inc_adj_2024_annual")])
# 
# # Summary statistics
# summary(cps_df[, grep("^ent_inc", names(cps_df), value = TRUE)])

