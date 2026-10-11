# Project status — working paper in progress

**Title:** Who Becomes an Entrepreneur When Home Prices Rise? Racialized Housing Markets and Entrepreneurial Entry

**Status:** Active working paper. Research design, measurement, and regression specifications are still being developed and validated. This document describes the *current stage* of the codebase, not finalized findings.

---

## Research question

This project investigates whether housing-price appreciation is associated with transitions into entrepreneurship, and whether that association differs across racial and ethnic groups in the United States.

The theoretical motivation draws on housing wealth and collateral constraints, racialized housing markets, and unequal access to entrepreneurial resources (Resource-Based View and Stratification Economics perspectives).

**No empirical relationship is claimed as established** in this repository. The question is fixed; the answers are not.

---

## Data sources

| Source | Role in the project | In this repo? |
|--------|---------------------|---------------|
| **IPUMS CPS** microdata | Person-month panel; class of worker; demographics; weights; geography | **No** (obtain separately; see [`DATA_ACCESS.md`](DATA_ACCESS.md)) |
| **FHFA HPI** | Local / regional house price indices and annual changes | **No** (public download; local `data/external/`) |
| **BEA state GDP** (optional) | Controls / residualization for exploratory “unanticipated” HPI | **No** |

Person-level merged CPS–HPI analysis files are created locally and must not be posted publicly under IPUMS terms of use.

---

## Current stage

The codebase is under **active development**. As of the latest documentation pass:

- Descriptive pipeline (race coding, industry mapping, education bins, tenure) is largely implemented.
- Candidate entrepreneurship outcomes and HPI merges exist in code.
- Candidate weighted LPM specifications (race, HPI, interactions, controls, FE) exist.
- Tenure split regressions, Kauffman-style rate comparisons, and exploratory HPI residualization exist as **candidate / exploratory** modules.
- Primary outcome definition, primary HPI exposure (local hybrid vs state aggregate), inference (clustering), and identification strategy remain **open research decisions**.
- A full clean, end-to-end knit of every chunk on a fresh machine with a fresh extract has **not** been certified in this repository documentation.

---

## Components currently represented in the code

Described as *present in code*, not as *validated*:

1. **CPS preparation** — local IPUMS import; weight annualization; race/ethnicity recode; industry scrape/map; education labels.
2. **Longitudinal linking** — person ID `CPSIDP` with `data.table::shift()` lags by month-in-sample (`MISH`).
3. **Entrepreneurship outcomes** — `entrepreneurship1` (to unincorporated), `entrepreneurship2` (to incorporated), `entrepreneurship_kauffman` (1-month, both SE types, hours filter).
4. **Descriptive / weighted summaries** — rates and charts by race, tenure, industry, earnings.
5. **HPI merging** — candidate hybrid MSA → county → state-nonmetro coalesce; also separate state-averaged county-HPI constructions used in some regression chunks.
6. **Candidate regressions** — weighted LPMs with race × HPI interactions, controls, state and year FE, HC1 robust SE (and state clustering in tenure-split code).
7. **Tenure comparisons** — separate homeowner vs renter regressions (often labeled “placebo” in code comments; see methods review).
8. **Kauffman-style validation attempts** — annual average monthly entry rates vs published benchmarks.
9. **Exploratory HPI residualization** — candidate first-stage residualization of HPI change for later robustness work.

Detailed author-facing notes on open choices are kept in [`DECISIONS_FOR_ME.md`](DECISIONS_FOR_ME.md) (working checklist, not a public findings claim).

---

## Development status (public summary)

The project is an **active working paper**. Core data construction and candidate analyses are implemented in code. Preferred measurement definitions, geographic HPI exposure, and final regression tables are still being refined before journal submission. That is normal for empirical work at this stage.

This repository is meant to show an organized, ongoing research pipeline—not a claim that every specification is locked.

---

## Interpretation

Notebook output and exploratory tables should be read as **preliminary**. They are not peer-reviewed findings and should not be interpreted as established causal effects.

---

## Reproducibility

**To run the code:** obtain an authorized IPUMS CPS extract and FHFA files, configure `config/paths.R`, and install packages listed in the README ([`DATA_ACCESS.md`](DATA_ACCESS.md)).

A fuller replication package (locked environment, finalized primary specification, verified aggregate outputs) will be prepared as the paper approaches submission.
