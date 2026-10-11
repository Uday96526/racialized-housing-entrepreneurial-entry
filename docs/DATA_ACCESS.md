# Data access (not redistributed in this repository)

This repository contains **analysis code only**. Per [IPUMS terms of use](https://www.ipums.org/about/terms), CPS microdata extracts and any merged person-level files must **not** be posted publicly.

## 1. IPUMS CPS (required)

1. Create a free account at [IPUMS CPS](https://cps.ipums.org/).
2. Build an extract that includes (at minimum) the variables used in `code/df_wk.Rmd` / `code/Explanation.qmd`, e.g.:
   - Identifiers / panel: `YEAR`, `MONTH`, `CPSIDP`, `MISH`, `STATEFIP`, `COUNTY`, `METFIPS`
   - Demographics: `AGE`, `SEX`, `RACE`, `HISPAN`, `EDUC`, `MARST`, `NCHILD`, `HHTENURE`
   - Labor: `CLASSWKR`, `EMPSTAT`, `IND1990`, `AHRSWORKT`, `WTFINL`, `EARNWT` (if used)
   - Allocation flags: `QCLASSWK`, `QEMPSTAT`, `QAHRSWORKT`
3. Download the extract (`.dat` / `.dat.gz` + `.xml` DDI).
4. Place files in `data/raw/` and set names in `config/paths.R`.

**Do not commit** anything under `data/raw/`.

## 2. FHFA House Price Index (public)

Download from [FHFA HPI](https://www.fhfa.gov/data/hpi):

| File (place in `data/external/`) | Role |
|----------------------------------|------|
| `hpi_at_cbsa.xlsx` | MSA / CBSA annual HPI |
| `hpi_at_bdl_county.xlsx` | County annual HPI |
| `hpi_at_nonmetro.xlsx` | State nonmetro HPI |

Hybrid merge in code: `coalesce(msa_hpi, county_hpi, nonmetro_hpi)`.

## 3. BEA state GDP (optional — unanticipated HPI)

For Fairlie-style residualized HPI:

- BEA regional accounts / SAGDP real GDP by state
- Clean file path: `data/external/bea_state_real_gdp_clean.csv` (see `df_wk.Rmd` BEA prep chunk)

## 4. Secrets

- Store your IPUMS API key in `~/.Renviron` as `IPUMS_API_KEY=...`
- Never hard-code keys in `.R` / `.Rmd` / `.qmd` files
- If a key was ever committed or emailed, **revoke it** in your IPUMS account and create a new one

## 5. Reproduce

```r
# From project root in RStudio:
setwd("path/to/racialized-housing-entrepreneurial-entry")
file.copy("config/paths.example.R", "config/paths.R")  # once
# edit config/paths.R
source("config/paths.R")
# then knit code/df_wk.Rmd or code/Explanation.qmd
```
