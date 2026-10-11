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
9. **Exploratory HPI residualization** — geo×year first-stage residualization of HPI change (Fairlie-style); use in outcome models is incomplete / under review.

See [`METHODS_REVIEW.md`](METHODS_REVIEW.md) for discrepancies between intent and implementation.

---

## Current limitations

Items that require confirmation before treating results as paper-ready:

- Primary transition window (MIS-based 4-step lag vs verified calendar months).
- Coding of non-matches as `0` vs `NA` and the at-risk denominator for main outcomes.
- Primary HPI exposure: hybrid local series vs state-averaged HPI levels/changes used in some regression blocks.
- Geographic match quality (CBSA padding, nonmetro fallback eligibility, missingness by race).
- Weight construction (`wtfinl / months_in_year` definition) and placebo-chunk weight selection bug (see methods review).
- Inference: HC1 vs clustering at the geography of HPI variation; rare-events / logit AME robustness.
- Whether residualized HPI enters the preferred outcome model (and under what interpretation).

---

## Interpretation

Preliminary plots, Excel dumps, and coefficients produced while exploring the code **must not** be interpreted as evidence of causal effects of house prices on entrepreneurship, nor as peer-reviewed findings.

Where code comments say “placebo,” “replication,” or “2SLS,” treat those labels as **aspirational or exploratory** until the corresponding validation is complete and documented.

---

## Reproducibility status

**Required for any independent run:** authorized IPUMS CPS extract; FHFA HPI files; local `config/paths.R`; R packages listed in the README.

**Not yet claimed:** locked package versions (`renv`); certified end-to-end knit; successful Kauffman numerical match within a stated tolerance; finalized primary specification.

A future replication package should include: locked environment, explicit analysis sample rules, a single canonical analysis script path, and aggregate (non-person) verified outputs.
