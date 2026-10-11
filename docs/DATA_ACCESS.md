# Data access (not redistributed in this repository)

This repository contains **analysis code and documentation only**. Per [IPUMS terms of use](https://www.ipums.org/about/terms), CPS microdata extracts and any merged person-level files must **not** be posted publicly.

Working-paper context: [`PROJECT_STATUS.md`](PROJECT_STATUS.md). Implementation caveats: [`METHODS_REVIEW.md`](METHODS_REVIEW.md).

---

## 1. IPUMS CPS (required)

1. Create a free account at [IPUMS CPS](https://cps.ipums.org/).
2. Build an extract covering the months your analysis requires (code notebooks have used windows on the order of early 2000s through late 2010s—confirm against the chunk you will run).
3. Include at least the variables referenced by `code/df_wk.Rmd` / `code/Explanation.qmd`. A practical checklist:

### Identifiers / panel / geography
`YEAR`, `MONTH`, `CPSIDP`, `MISH`, `STATEFIP`, `COUNTY`, `METFIPS`, `METRO` (recommended for nonmetro diagnostics)

### Demographics
`AGE`, `SEX`, `RACE`, `HISPAN`, `EDUC`, `MARST`, `NCHILD`, `HHTENURE`

### Labor / entrepreneurship
`CLASSWKR`, `EMPSTAT`, `IND1990`, `AHRSWORKT` (hours filter for Kauffman-style checks), `WTFINL`, `EARNWT` (if earnings-weighted analyses are used), `EARNWEEK` / `EARNWEEK2` (if present in your extract for earnings controls)

### Allocation flags (recommended for Kauffman-style validation)
`QCLASSWK`, `QEMPSTAT`, `QAHRSWORKT`

4. Download `.dat` or `.dat.gz` plus the `.xml` DDI.  
5. Place files under `data/raw/` and set `PATH_CPS_DDI` / `PATH_CPS_DATA` in `config/paths.R`.

**Do not commit** anything under `data/raw/`.

**Note:** Commented API extract blocks in the notebooks may omit some variables that later chunks expect (e.g., allocation flags, `AHRSWORKT`). Prefer this checklist over the commented API list when building a new extract.

---

## 2. FHFA House Price Index (public)

Download from [FHFA HPI](https://www.fhfa.gov/data/hpi) (file names may vary slightly by vintage):

| Local filename (suggested) | Role in code |
|----------------------------|--------------|
| `hpi_at_cbsa.xlsx` | MSA / CBSA annual HPI |
| `hpi_at_bdl_county.xlsx` | County annual HPI |
| `hpi_at_nonmetro.xlsx` | State nonmetro HPI |

Place under `data/external/`.

**Implementation note:** A hybrid `coalesce(msa, county, nonmetro)` merge is coded. Some regression chunks currently rebuild **state-averaged** HPI from the county file instead. Which series is primary remains an open research decision ([`METHODS_REVIEW.md`](METHODS_REVIEW.md) §C).

---

## 3. BEA state GDP (optional — exploratory residualization)

Used only if you run Fairlie-style residualization / “unanticipated” HPI chunks:

- BEA regional GDP (e.g. SAGDP) → clean CSV such as `bea_state_real_gdp_clean.csv`
- Paths: `PATH_BEA_GDP`, `PATH_SAGDP1` in `config/paths.R`

Treat these modules as **exploratory** until wired into a preferred outcome model and validated.

---

## 4. Secrets

- Store IPUMS API key in `~/.Renviron` as `IPUMS_API_KEY=...`
- Never hard-code keys in `.R` / `.Rmd` / `.qmd`
- If a key was ever exposed, revoke it in IPUMS and issue a new one
- See [`../SECURITY.md`](../SECURITY.md)

---

## 5. Local setup checklist

```bash
git clone https://github.com/Uday96526/racialized-housing-entrepreneurial-entry.git
cd racialized-housing-entrepreneurial-entry
cp config/paths.example.R config/paths.R
# edit config/paths.R
# place CPS under data/raw/ and FHFA under data/external/
```

```r
# From project root in R:
source("config/paths.R")
stopifnot(file.exists(PATH_CPS_DDI), file.exists(PATH_CPS_DATA))
stopifnot(file.exists(PATH_MSA), file.exists(PATH_COUNTY), file.exists(PATH_NONMETRO))
# Then open / knit code/df_wk.Rmd
```

### What has / has not been certified here

| Item | Status |
|------|--------|
| Paths template + gitignore for microdata | Documented |
| Fresh-machine end-to-end knit | **Not certified** in this repo |
| Package lockfile (`renv`) | **Not provided** |
| Numerical Kauffman match | **Validation in progress** (see methods review) |

---

## 6. Outputs

Generated tables/figures should ideally land under `output/tables` and `output/figures` via `PATH_OUTPUT`. Many existing `write_xlsx()` calls still write to the working directory—treat cleanup as ongoing housekeeping, not as a claim that outputs are publication-ready.
