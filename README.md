# Who Becomes an Entrepreneur When Home Prices Rise?

Replication **code** for research on racial disparities in entrepreneurial entry, linking **CPS panel** transitions to **FHFA house price indices** (collateral / housing-wealth channel).

> **Data are not included.** IPUMS CPS microdata and merged person-level files are excluded by design. See [`docs/DATA_ACCESS.md`](docs/DATA_ACCESS.md).

## Paper focus

- **Outcome:** entry into incorporated self-employment (`entrepreneurship2`, 4-month CPS transition)
- **Validation:** Kauffman-style rate of new entrepreneurs (`entrepreneurship_kauffman`, 1-month; age 20–64; 15+ hours)
- **Key RHS:** housing prices (hybrid MSA → county → state nonmetro HPI), race × HPI
- **Mechanisms:** homeowner vs renter placebo; optional unanticipated HPI (Fairlie-style)

Theoretical frame: Resource-Based View + Stratification Economics + collateral channel.

## Repository layout

```
code/
  df_wk.Rmd                 # main analysis notebook
  Explanation.qmd           # documented Quarto write-up
  create_ent_inc_variables.R
  class_object/cps.R        # optional CPS helper class
config/
  paths.example.R           # copy → paths.R (gitignored)
data/
  raw/                      # IPUMS extract only (gitignored)
  external/                 # FHFA / BEA downloads (gitignored)
  processed/                # merged person-level (gitignored)
docs/
  DATA_ACCESS.md
  CODE_CHUNK_EXPLANATIONS.md
output/                     # figures & tables (gitignored)
```

## Quick start

1. Clone this repo.
2. Obtain IPUMS CPS + FHFA HPI files ([`docs/DATA_ACCESS.md`](docs/DATA_ACCESS.md)).
3. `cp config/paths.example.R config/paths.R` and edit paths.
4. Open `code/df_wk.Rmd` or `code/Explanation.qmd` in RStudio.
5. At the top of the session (or first chunk), run:

```r
source(file.path("..", "config", "paths.R"))  # if knitting from code/
# or from project root:
source("config/paths.R")
```

### R packages

`dplyr`, `ipumsr`, `ggplot2`, `stringr`, `tidyr`, `rvest`, `knitr`, `lubridate`, `dtplyr`, `data.table`, `readxl`, `writexl`, `haven`, `here` (recommended)

## What is intentionally excluded

| Excluded | Why |
|----------|-----|
| `cps_*.dat`, `cps_*.dat.gz`, IPUMS `.xml` extracts | IPUMS redistribution rules |
| Merged person-level `.rds` / processed CPS | Individual-level research data |
| `config/paths.R`, `.Renviron` | Local paths & API keys |
| Dated `*.xlsx` analysis dumps | Regenerable; some may embed sensitive extracts |

Aggregate tables and figures can be regenerated after you load your own extract.

## Citation

If you use this code, please cite the working paper / published version (update when available) and IPUMS CPS / FHFA as data providers.

Madrian, B. C., & Lefgren, L. J. (2000). An approach to longitudinally matching Current Population Survey (CPS) respondents. *Journal of Economic and Social Measurement*.

## License

Code in this repository is provided for academic replication. Data remain subject to IPUMS and FHFA terms. Add a formal `LICENSE` if/when you choose (e.g., MIT for code only).

## Author

Uday Kumar and Dr. Rachel M. Atkins
