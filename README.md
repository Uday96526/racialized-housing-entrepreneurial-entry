# Who Becomes an Entrepreneur When Home Prices Rise?

**Racialized Housing Markets and Entrepreneurial Entry**

> **Research status: Working paper in progress**
>
> This repository contains research code for an ongoing empirical study of housing-price appreciation and entrepreneurial entry across racial and ethnic groups. The research design, outcome construction, geographic matching, regression specifications, and robustness analyses are still being developed and validated. The code and analytical choices may change as the research progresses. Any exploratory outputs should be interpreted as preliminary, and this repository should not be treated as a source of finalized findings or causal conclusions.

The research **question** is established. The **primary empirical specification is not**. This repo documents the working pipeline—not peer-reviewed results, not a finished replication package, and not a claim of causal identification.

**Data are not included.** IPUMS CPS microdata and merged person-level files are excluded by design ([`docs/DATA_ACCESS.md`](docs/DATA_ACCESS.md)).

For stage-of-work detail, see [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md). For implementation caveats, see [`docs/METHODS_REVIEW.md`](docs/METHODS_REVIEW.md).

**Open choices (for the author, later):** [`docs/DECISIONS_FOR_ME.md`](docs/DECISIONS_FOR_ME.md) — a plain-language checklist. You do not need to resolve these before sharing the repo as work in progress.

---

## Research question and motivation

This project **examines** whether house-price appreciation is associated with transitions into entrepreneurship, and whether that association differs by race and ethnicity.

Motivation (theoretical, not empirical claims):

- Housing wealth and collateral constraints as resources for business entry  
- Racialized housing markets and unequal access to entrepreneurial finance  
- Resource-Based View and Stratification Economics as organizing frames  

Language in this README intentionally avoids “proves,” “causes,” or “finds that…” pending validation.

---

## Data sources

| Source | Use | Redistributed here? |
|--------|-----|---------------------|
| [IPUMS CPS](https://cps.ipums.org/) | Matched monthly person panel; class of worker; demographics; weights | **No** |
| [FHFA HPI](https://www.fhfa.gov/data/hpi) | MSA, county, and state-nonmetro house price series | **No** (download locally) |
| BEA state GDP (optional) | Exploratory residualization of HPI changes | **No** |

Users must obtain CPS under IPUMS terms and configure local paths (`config/paths.example.R` → `config/paths.R`, gitignored).

---

## Current analytical workflow

Implemented as **candidate / exploratory** code in `code/df_wk.Rmd` (primary notebook) and narrated in part in `code/Explanation.qmd`:

1. Load CPS extract; construct annualized weights; recode race/ethnicity  
2. Build longitudinal lags via `CPSIDP` + `MISH` (see methods review on sorting)  
3. Construct candidate entrepreneurship indicators (`entrepreneurship1/2`, Kauffman-style)  
4. Merge FHFA HPI (hybrid MSA→county→nonmetro is coded; some regression blocks currently use state-averaged HPI—**under review**)  
5. Descriptives; candidate weighted LPMs; tenure splits; exploratory residualization; Kauffman-style rate checks  

**Not every chunk has been validated in a clean end-to-end run.** Distinguish intended design ([`PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)) from current implementation ([`METHODS_REVIEW.md`](docs/METHODS_REVIEW.md)).

The absence of result tables or coefficients in this README is **intentional**.

---

## Repository structure

```
code/
  df_wk.Rmd                 # main working analysis notebook
  Explanation.qmd           # narrative Quarto companion (partial; evolving)
  create_ent_inc_variables.R
  class_object/cps.R        # optional helper class
config/
  paths.example.R           # copy to paths.R (gitignored)
data/
  raw/                      # IPUMS extract only (gitignored)
  external/                 # FHFA / BEA downloads (gitignored)
  processed/                # merged person-level (gitignored)
docs/
  PROJECT_STATUS.md         # working-paper stage
  METHODS_REVIEW.md         # implementation audit
  DECISIONS_FOR_ME.md       # open choices checklist (author)
  DATA_ACCESS.md
  CODE_CHUNK_EXPLANATIONS.md
output/                     # intended location for figures/tables (gitignored)
```

---

## Setup and data access

1. Clone this repository.  
2. Obtain an authorized IPUMS CPS extract and FHFA files ([`docs/DATA_ACCESS.md`](docs/DATA_ACCESS.md)).  
3. `cp config/paths.example.R config/paths.R` and edit paths (never commit `paths.R`).  
4. Install R packages actually used by the notebooks (see below).  
5. Open the project in RStudio; knit or interactively run `code/df_wk.Rmd` first (it is the fuller pipeline).  
6. Generated Excel/figures currently often write to the working directory; prefer routing to `output/` once `PATH_OUTPUT` is set.

### R packages (non-exhaustive; matches current imports)

Core: `dplyr`, `tidyr`, `stringr`, `ggplot2`, `scales`, `data.table`, `dtplyr`, `haven`, `ipumsr`, `lubridate`, `knitr`, `rvest`

I/O: `readxl`, `writexl`, `readr`, `openxlsx`

Stats / tables: `sandwich`, `lmtest`, `broom`, `Hmisc`

Maps / viz (optional chunks): `maps`, `mapdata`, `viridis`

Recommended: `here` for project-root paths  

Optional later: `renv` for a lockfile — **not claimed until generated and tested**.

### IPUMS API key

Set in `~/.Renviron` only: `IPUMS_API_KEY=...`. Never hard-code keys in scripts.

---

## Current limitations and reproducibility status

- Primary outcome, HPI exposure, and inference rules are **still under development** ([`METHODS_REVIEW.md`](docs/METHODS_REVIEW.md)).  
- Hybrid HPI merge and state-HPI regression blocks can disagree; do not assume README marketing equals the active `lm()` RHS.  
- Kauffman-style section is a **validation attempt**, not a certified replication.  
- Full workflow has not been certified end-to-end from a blank machine in this documentation.  
- `.gitignore` blocks new data adds; it does not rewrite past Git history (none of the tracked files are CPS extracts).

---

## Citation and authorship

**Working paper:** *Who Becomes an Entrepreneur When Home Prices Rise? Racialized Housing Markets and Entrepreneurial Entry* (in progress).

**Authors:** Uday Kumar and Dr. Rachel M. Atkins.

**Note:** `code/df_wk.Rmd` YAML currently lists a different `author` field (`alfred ijeomah`). Notebook YAML attribution should be confirmed with the research team before treating it as authoritative.

If you use this code, also cite data providers (IPUMS CPS; FHFA) and, for CPS matching context, Madrian & Lefgren (2000), *Journal of Economic and Social Measurement*.

---

## License and data-use notice

- **Code** in this repository is released under the MIT License (`LICENSE`), copyright Uday Kumar (2026), **for the software and documentation files only**.  
- **Data** remain subject to [IPUMS](https://www.ipums.org/about/terms), FHFA, and BEA terms. Redistribution of CPS microdata via this repo is not authorized.  
- Exploratory outputs you generate locally remain your responsibility under those terms.
