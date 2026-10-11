# =============================================================================
# Local path configuration (DO NOT COMMIT paths.R with real machine paths)
# =============================================================================
# 1. Copy this file:  cp config/paths.example.R config/paths.R
# 2. Edit paths.R to point at your local downloads
# 3. config/paths.R is gitignored
#
# Expected layout after download (see docs/DATA_ACCESS.md):
#   data/raw/cps_XXXXX.xml + cps_XXXXX.dat(.gz)   # IPUMS extract (not in git)
#   data/external/hpi_at_cbsa.xlsx
#   data/external/hpi_at_bdl_county.xlsx
#   data/external/hpi_at_nonmetro.xlsx
#   data/external/bea_state_real_gdp_clean.csv    # optional (unanticipated HPI)
# =============================================================================

# Project root = folder containing this config/ directory's parent
ROOT <- if (requireNamespace("here", quietly = TRUE)) {
  here::here()
} else {
  normalizePath("..")  # if sourced from config/ while cwd is project root, use getwd()
}

# Prefer setting ROOT explicitly when knitting from RStudio:
# ROOT <- "/path/to/racialized-housing-entrepreneurial-entry"

PATH_CPS_DDI  <- file.path(ROOT, "data", "raw", "cps_00048.xml")
PATH_CPS_DATA <- file.path(ROOT, "data", "raw", "cps_00048.dat.gz")  # or .dat

PATH_MSA      <- file.path(ROOT, "data", "external", "hpi_at_cbsa.xlsx")
PATH_COUNTY   <- file.path(ROOT, "data", "external", "hpi_at_bdl_county.xlsx")
PATH_NONMETRO <- file.path(ROOT, "data", "external", "hpi_at_nonmetro.xlsx")

# Optional: BEA state GDP (Fairlie-style unanticipated HPI)
PATH_BEA_GDP  <- file.path(ROOT, "data", "external", "bea_state_real_gdp_clean.csv")
PATH_SAGDP1   <- file.path(ROOT, "data", "external", "SAGDP1__ALL_AREAS_1997_2025.csv")

PATH_CPS_CLASS <- file.path(ROOT, "code", "class_object", "cps.R")

# IPUMS API key: set in ~/.Renviron as IPUMS_API_KEY=...  (never hard-code in scripts)
# Then: ipumsr::set_ipums_api_key(Sys.getenv("IPUMS_API_KEY"))
