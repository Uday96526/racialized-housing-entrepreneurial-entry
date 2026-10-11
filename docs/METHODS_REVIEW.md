# Methods review — internal implementation notes

**Audience:** Research team / author checklist (technical).  
**Not** a public “limitations of the paper” section — see README and `PROJECT_STATUS.md` for the outward-facing status.

**Scope:** Code in `code/df_wk.Rmd` and `code/Explanation.qmd`.  
**Purpose:** Track implementation details and open choices while the working paper develops.  
**Rule:** Presence of code ≠ validation. No coefficients or findings are reported here.

For a plain-language decision checklist, use [`DECISIONS_FOR_ME.md`](DECISIONS_FOR_ME.md).

Severity: **CRITICAL** / **HIGH** / **MEDIUM** / **LOW**  
Type: **Mechanical** (implementation) vs **Scientific** (design choice requiring approval)

---

## A. Longitudinal CPS matching

### A1. CRITICAL / Mechanical — No chronological sort before `shift()`

| | |
|--|--|
| **Where** | `code/df_wk.Rmd` chunk `entrepreneurship_variables_simple` (and any later rebuild of lags) |
| **Code does** | `shift(..., by = cpsidp)` on current row order |
| **Docs claim** | Lags represent prior interviews / “4-month” structure |
| **Why it matters** | After `merge()` / joins, person-months may be unsorted → wrong prior `classwkr` / `mish` |
| **Proposed fix** | `data.table::setorder(cps_data, cpsidp, year, month)` immediately before every `shift` |
| **Validation** | Within-person check that lagged `year`/`month` precede current; compare entrepreneurship counts before/after |

*Status:* Mechanical sort was added in the public copy with a validation note; **re-run diagnostics before trusting rates**.

### A2. HIGH / Scientific + mechanical — Four-row lag ≠ verified calendar interval

| | |
|--|--|
| **Where** | `entrepreneurship1` / `entrepreneurship2`: `shift(..., 4)` and `prev_mish == mish - 4` |
| **Code does** | Requires MIS arithmetic; does **not** assert calendar months between interviews |
| **Docs claim** | Often phrased as a “4-month” transition |
| **Why it matters** | CPS rotation: some MIS pairs span ~4 months; MIS 4→5 spans ~8 months off-sample. MIS checks alone do not prove calendar gap if row order or attrition is irregular |
| **Proposed alternatives (do not auto-select)** | (i) Keep MIS rule + add calendar-month gap check; (ii) match explicitly on `(cpsidp, mish)` pairs; (iii) redefine primary window (e.g., consecutive months only) |
| **Validation** | Histogram of calendar months between linked interviews among outcome==1 |

### A3. OK for Kauffman path — `mish != 5` on 1-month transitions

Present on `entrepreneurship_kauffman`. Correct for consecutive-month definitions. Not a substitute for sorting (A1).

### A4. MEDIUM / Mechanical — Inconsistent `haven::zap_labels` on MIS/classwkr

Main `entrepreneurship1/2` sometimes compare labelled vectors directly; Kauffman path uses `zap_labels`. Harmonize early in the pipeline.

---

## B. Outcome definition and at-risk population

### B1. HIGH / Scientific — Invalid links coded as `0`, not `NA`

| | |
|--|--|
| **Where** | `as.integer(condition)` for `entrepreneurship1/2/kauffman` |
| **Code does** | Failed panel conditions → `0` |
| **Docs claim** | `0` = “did not enter” |
| **Why it matters** | Inflates the “non-entry” mass; descriptive rates that divide by all person-months dilute entry rates |
| **Proposed fix** | Explicit `valid_match` / `at_risk` indicators; outcome `NA` if invalid; `0/1` only if at risk |
| **Decision needed** | Confirm paper definition of at-risk (prior non-owner? prior not incorporated? age?) |

### B2. HIGH / Scientific — Main descriptives vs Kauffman denominators

Kauffman rate chunk builds an at-risk weight from prior non-owners. Many race/tenure descriptive chunks use all weighted rows. Align before paper tables.

### B3. MEDIUM / Scientific — `entrepreneurship1` vs `2` prior-status asymmetry

Prior incorporated can count as “new” unincorporated (and vice versa). Kauffman excludes prior 13 **and** 14. Decide whether main outcomes are “type-specific entry” or “entry from non-SE.”

---

## C. Primary HPI exposure

### C1. CRITICAL / Scientific — Hybrid HPI built; some regressions use state-averaged county HPI

| | |
|--|--|
| **Where** | Hybrid: `hpi_final = coalesce(msa_hpi, county_hpi, nonmetro_hpi)`. Main LPM chunk: joins `actual_state_hpi_reg` and sets `hpi10 = actual_hpi / 10` |
| **Docs / README** | Emphasize hybrid local HPI |
| **Why it matters** | Within-state MSA variation is discarded in those regressions → different estimand |
| **Proposed options** | (i) Use hybrid `hpi_final`/`hpi10` in main models; (ii) keep state HPI but rewrite paper claims; (iii) report both as intended vs robustness |
| **Decision needed** | **Which exposure is primary?** Do not silently switch |

### C2. HIGH — Tenure-split regressions use state-averaged **HPI change**

Same geography compression; change vs level is a separate design choice (possibly intentional for collateral timing).

### C3. HIGH / Mechanical — `Explanation.qmd` hybrid chunk followed by older state-HPI `hpi_integration`

Risk of overwrite when knitting. Older chunk should remain `eval=FALSE` or be removed after review.

### C4. MEDIUM — County-only HPI chunk can replace hybrid columns if run later

Keep as a separate object (`cps_df_county`) once refactoring is approved.

### C5. MEDIUM / Scientific — Nonmetro HPI via coalesce may attach to suppressed-metro cases

Validate with `metro` × `hpi_geo_level` cross-tabs before treating hybrid as “local.”

### C6. Note — Level (`hpi10`) vs appreciation (`hpi_change`) 

Both appear. Paper must state which enters the preferred specification and why.

---

## D. Geographic matching and coverage

### D1. HIGH / Mechanical — `as.character(metfips_num)` can drop leading zeros

Use zero-padded 5-digit CBSA strings when joining FHFA MSA files.

### D2. MEDIUM — Inconsistent county FIPS padding across chunks

Standardize on `sprintf("%05d", ...)`.

### D3. HIGH / Scientific — Filtering to non-missing HPI before analysis

Match-rate diagnostics should use the **pre-drop** eligible sample as denominator (by year, race, geo tier). Current pipeline often reports coverage after filtering.

---

## E. Regression models and inference

### E1. CRITICAL / Mechanical — Placebo weight line uses `exists("wtfinl_annual") && ...`

`exists()` checks the R environment, not dataframe columns; `&&` is scalar. Intent appears to be “prefer annual weight.” **Mechanical fix:** `WEIGHT = dplyr::coalesce(wtfinl_annual, wtfinl)` (or equivalent).

### E2. LOW — Trailing comma after `WEIGHT = wtfinl_annual` in `mutate`

Legal in R; cosmetic only.

### E3. HIGH / Scientific — Main regression sample may omit age ≥ 18 filter present elsewhere

Align with stated analysis sample once confirmed.

### E4. MEDIUM — Labelled `age` / earnings coerced with `as.numeric()` without `zap_labels`

Follow project haven convention.

### E5. MEDIUM / Scientific — HC1 in main models; state clustering mainly in tenure split

If HPI varies at geo-year, clustering at that level (or state) should be reported for main specs as a candidate rule—decision pending.

### E6. MEDIUM — Logit + AME claimed in research strategy, not implemented on main HPI×race path

Gap vs intended robustness menu.

### E7. MEDIUM / Scientific — Education `TRUE ~ "High School"` dump category

Unknown codes mapped to HS. Prefer `NA` or explicit “Unknown.”

### E8. Interaction inference

Race-specific slopes from interactions need correct linear combinations / contrasts for SEs—not only raw interaction coefficients. Formal tests of slope differences across race remain to be standardized.

---

## F. Homeowner / renter comparison

### F1. HIGH / Scientific — Labeled “placebo” but is tenure heterogeneity / falsification

A null among renters does **not** prove homeowners’ coefficient differs from renters’. Prefer: (i) rename; (ii) estimate interaction or coefficient-difference test; (iii) discuss rent/demand channels for renters.

### F2. Mechanical — Weight bug (E1) affects this block

---

## G. Exploratory HPI residualization

### G1. HIGH — First-stage residuals may be built but not wired into preferred outcome `lm`s

Treat as **EXPLORATORY** until Stage-2 use is explicit and validated.

### G2. MEDIUM — Geo×year panels with gaps: prefer calendar-year lags over row lags

### G3. Scientific — Residualization ≠ IV

Do not label as 2SLS / causal without an instrument and exclusion argument.

---

## H. Survey weights and recoding

### H1. HIGH / Documentation mismatch — Annual weights

| | |
|--|--|
| **Code** | Often `group_by(year)` then `months_in_year = n_distinct(month)` (≈12 for all) |
| **Older docs** | “Divide by months **that person** appears” |
| **Implication** | Current code is closer to a uniform `/12` scale factor than person-specific appearance counts |
| **Decision** | Document as `/12` **or** change to `group_by(cpsidp, year)` |

### H2. Race coding

Four mutually exclusive groups with Hispanic override; other races dropped. Acceptable if stated as sample restriction.

---

## I. External benchmark validation (Kauffman-style)

### I1. HIGH / Mechanical + docs — Year labels inconsistent (headers cite 2017; filters often ≤2011)

Align captions, filters, and benchmark years.

### I2. Label as **VALIDATION IN PROGRESS** until rates match published tables within a pre-registered tolerance (project target often ±0.05 percentage points).

### I3. Hours variable: comments may mention `uhrsworkt`; implementation uses `ahrsworkt` (prefer documenting the choice).

---

## J. Packages vs README

Used in analysis chunks but historically under-listed: `sandwich`, `lmtest`, `broom`, `Hmisc`, `maps`, `mapdata`, `viridis`, `scales`, `readr`, `openxlsx`, `haven`, `readxl`, `writexl`, etc. README package list should match imports.

---

## K. Author / YAML metadata

| File | Issue |
|------|--------|
| `df_wk.Rmd` YAML | `author: "alfred ijeomah"`; title `cps_df` |
| `Explanation.qmd` | Malformed YAML (title/author/format not valid Quarto front matter) |
| README | Maintainer listed as Uday Kumar |

**Do not silently overwrite attribution.** Confirm correct author list with the research team, then update YAML.

---

## L. Outputs written to working directory

Many `write_xlsx(paste0(..., Sys.Date(), ".xlsx"))` calls ignore `output/`. Prefer `file.path(PATH_OUTPUT, ...)` once paths are configured.

---

## Priority order (recommended)

1. Confirm chronological sort + recompute outcomes (A1).  
2. Decide primary HPI exposure; stop undocumented overwrite (C1–C3).  
3. Fix weight `exists`/`&&` bug (E1).  
4. Decide NA vs 0 / at-risk rules (B1–B2).  
5. Geography padding + coverage audits (D1–D3).  
6. Align sample filters (age), inference, and validation labels (E3, E5, I).

---

## Scientific decisions requiring researcher approval

See the change report section “Research questions requiring my decision” in the session summary / keep this list synchronized:

1. Primary entrepreneurship definition and at-risk rule.  
2. Primary HPI measure (hybrid local vs state aggregate; level vs change).  
3. Calendar vs MIS linking rules for the main outcome.  
4. Clustering / inference standard for publication tables.  
5. Role of residualized HPI (exploratory vs preferred).  
6. Tenure design: falsification naming + formal interaction test.  
7. Author attribution in YAML.  
8. Annual-weight formula (`/12` vs person-month counts).
