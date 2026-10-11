# =============================================================================
# Local path configuration (DO NOT COMMIT paths.R with real machine paths)
# =============================================================================
# 1. Copy:  cp config/paths.example.R config/paths.R
# 2. Edit paths.R for your machine
# 3. config/paths.R is gitignored
#
# Expected layout (see docs/DATA_ACCESS.md):
#   data/raw/cps_XXXXX.xml + cps_XXXXX.dat(.gz)
#   data/external/hpi_at_cbsa.xlsx
#   data/external/hpi_at_bdl_county.xlsx
#   data/external/hpi_at_nonmetro.xlsx
#   data/external/bea_state_real_gdp_clean.csv   # optional
# =============================================================================

# Project root = repository root (directory that contains config/ and code/)
# Prefer an explicit ROOT when knitting from RStudio if `here` is ambiguous:
# ROOT <- "/absolute/path/to/racialized-housing-entrepreneurial-entry"

ROOT <- NULL
if (requireNamespace("here", quietly = TRUE)) {
  # here::here() resolves to the project root when an .Rproj or .here marker exists
  ROOT <- tryCatch(here::here(), error = function(e) NULL)
}
if (is.null(ROOT) || !dir.exists(file.path(ROOT, "config"))) {
  # Fallback: if cwd is repo root, use getwd(); if cwd is code/, use parent
  if (dir.exists("config") && dir.exists("code")) {
    ROOT <- normalizePath(getwd())
  } else if (dir.exists("../config") && dir.exists("../code")) {
    ROOT <- normalizePath("..")
  } else {
    stop(
      "Could not resolve project ROOT. Set ROOT <- '/path/to/repo' at the top of config/paths.R"
    )
  }
}

PATH_CPS_DDI  <- file.path(ROOT, "data", "raw", "cps_00048.xml")
PATH_CPS_DATA <- file.path(ROOT, "data", "raw", "cps_00048.dat.gz")  # or .dat

PATH_MSA      <- file.path(ROOT, "data", "external", "hpi_at_cbsa.xlsx")
PATH_COUNTY   <- file.path(ROOT, "data", "external", "hpi_at_bdl_county.xlsx")
PATH_NONMETRO <- file.path(ROOT, "data", "external", "hpi_at_nonmetro.xlsx")

PATH_BEA_GDP  <- file.path(ROOT, "data", "external", "bea_state_real_gdp_clean.csv")
PATH_SAGDP1   <- file.path(ROOT, "data", "external", "SAGDP1__ALL_AREAS_1997_2025.csv")

PATH_CPS_CLASS <- file.path(ROOT, "code", "class_object", "cps.R")
PATH_OUTPUT    <- file.path(ROOT, "output")
PATH_OUT_TABLES <- file.path(PATH_OUTPUT, "tables")
PATH_OUT_FIGS   <- file.path(PATH_OUTPUT, "figures")

# IPUMS API key: ~/.Renviron → IPUMS_API_KEY=...
# ipumsr::set_ipums_api_key(Sys.getenv("IPUMS_API_KEY"))
