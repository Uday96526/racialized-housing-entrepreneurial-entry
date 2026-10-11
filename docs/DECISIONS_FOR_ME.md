# Decisions for me (private working checklist — fill in later)

**Purpose:** Walk through open research choices one by one, in plain language.  
**You do not need to decide everything today.**  
**When ready:** write your choice under each item (or tell Cursor in chat), then we implement only what you approve.

This file is for **you** (and collaborators). It is intentionally more detailed than the public README. Outsiders should see “working paper in progress,” not a list of unresolved technical doubts.

**Related:** [`PROJECT_STATUS.md`](PROJECT_STATUS.md) · [`METHODS_REVIEW.md`](METHODS_REVIEW.md)

---

## Public vs this checklist

| Show publicly | Keep here (decide later) |
|---------------|--------------------------|
| Working paper in progress | Exact HPI primary series |
| Research question / motivation | 0 vs NA / at-risk rules |
| Code + data-access rules | Clustering / logit AME menu |
| No microdata; no final results | Residualized HPI role, etc. |

Showing the repo as active work does **not** require locking the items below first.

---

## How to use this checklist

For each decision:

1. Read **What this is about** (plain language).  
2. Read **Why it matters**.  
3. Pick an option (or write “defer”).  
4. Optional: note *why* in one sentence.

When you finish a section, you can message Cursor like:

> For Decision 2 I choose option A. Please update the code only for that.

---

# Decision 1 — What counts as “becoming an entrepreneur”?

### What this is about
We build several outcomes in code:

- `entrepreneurship2` — move into **incorporated** self-employment  
- `entrepreneurship1` — move into **unincorporated**  
- `entrepreneurship_kauffman` — 1-month, both types, for validation only  

Also: if someone cannot be linked to a valid prior interview, the code often records `0` (“did not enter”) instead of “we don’t know.”

### Why it matters
This defines the paper’s main dependent variable and who is in the “at risk” group.

### Options (pick later)

| Option | Meaning |
|--------|---------|
| **A** | Primary DV = `entrepreneurship2` (incorporated only). Invalid links → set to missing (`NA`), not zero. At risk = had a valid prior interview and was not already that type of SE. |
| **B** | Same as A, but at risk = prior **non-business-owner** (not 13 and not 14), closer to Kauffman spirit. |
| **C** | Something else (write it). |
| **Defer** | Keep current code; document as candidate. |

**My choice:** _______________  
**Notes:** _______________

---

# Decision 2 — Which house-price measure is “the” main one?

### What this is about
Code has **two different** HPI ideas:

1. **Hybrid local HPI** — MSA → county → state nonmetro (`hpi_final`)  
2. **State-averaged HPI** — average of county HPIs in the state (used in some regression chunks)

Also: **level** (`hpi10`) vs **year-over-year % change**.

### Why it matters
Readers (and you) need one clear “main exposure.” Right now README sounds local/hybrid, but some regressions use state averages.

### Options

| Option | Meaning |
|--------|---------|
| **A** | Primary = **hybrid local** HPI level (`hpi_final` / `hpi10`). State average = robustness only. |
| **B** | Primary = **hybrid local HPI change**. Level = robustness. |
| **C** | Primary = **state-averaged** HPI (level or change — specify). Hybrid = robustness / coverage. |
| **D** | Report both as co-equal “specifications” (no single primary yet). |
| **Defer** | Keep code; leave labels as candidate/exploratory. |

**My choice:** _______________  
**Level or change for primary?** _______________  
**Notes:** _______________

---

# Decision 3 — How do we link the same person over time?

### What this is about
CPS interviews people in a rotation (`MISH`). Code uses:

- Person ID `CPSIDP`  
- Row lags (`shift`) + checks on `MISH`  
- For Kauffman (1-month): exclude `MISH == 5` (the big gap after month 4)

We added **sorting by person–year–month** so lags aren’t scrambled. Still open: whether “4 rows + MISH check” is enough, or we also require a **calendar-month** gap check.

### Why it matters
Wrong links → fake transitions or missed ones.

### Options

| Option | Meaning |
|--------|---------|
| **A** | Keep MIS-based rules; require sort; add a diagnostic table of calendar gaps (don’t change DV yet). |
| **B** | Keep MIS rules **and** require calendar gap ≈ expected months for that pair. |
| **C** | Redefine primary window (e.g. consecutive months only) — big design change. |
| **Defer** | Rely on sort + current MIS rules for now. |

**My choice:** _______________  
**Notes:** _______________

---

# Decision 4 — How should standard errors / inference work?

### What this is about
Main models often use **HC1** robust SE. Tenure-split code sometimes **clusters by state**. HPI varies by geography and year, so clustering choice affects how “significant” results look.

### Options

| Option | Meaning |
|--------|---------|
| **A** | Main tables: cluster at **state** (or geo of HPI). Also show HC1 in appendix. |
| **B** | Main tables: HC1; clustering as robustness. |
| **C** | Cluster at finer geo (e.g. MSA/county where available). |
| **Defer** | Leave as coded; document both as candidates. |

**My choice:** _______________  
**Notes:** _______________

---

# Decision 5 — What do we do with “unanticipated” / residualized HPI?

### What this is about
There is exploratory code that residualizes HPI change on unemployment, GDP growth, etc. (Fairlie-style). That is **not** automatically an instrument or causal design. Residuals may not even enter the main entrepreneurship regressions yet.

### Options

| Option | Meaning |
|--------|---------|
| **A** | Keep as **exploratory appendix** only; main paper uses raw HPI (per Decision 2). |
| **B** | Make residualized HPI a **preferred** robustness / preferred RHS (specify which). |
| **C** | Drop from near-term paper focus. |
| **Defer** | Leave labeled EXPLORATORY. |

**My choice:** _______________  
**Notes:** _______________

---

# Decision 6 — Homeowners vs renters: what is the claim?

### What this is about
Code runs similar models on homeowners and renters (often called a “placebo”).  
Important: “significant for owners, not for renters” is **not** the same as “the two effects are statistically different.”

### Options

| Option | Meaning |
|--------|---------|
| **A** | Rename to **tenure heterogeneity / collateral falsification**; add a formal interaction or difference test later. |
| **B** | Keep split-sample presentation; add clear wording that it is not a classical placebo. |
| **C** | Prefer a **triple interaction** (Race × HPI × Homeowner) as the main mechanism table. |
| **Defer** | Keep code; wording already softened in comments. |

**My choice:** _______________  
**Notes:** _______________

---

# Decision 7 — Whose name goes on `df_wk.Rmd`?

### What this is about
GitHub / README: **Uday Kumar**.  
`df_wk.Rmd` YAML still says author **`alfred ijeomah`** (likely from an older template or collaboration).

### Options

| Option | Meaning |
|--------|---------|
| **A** | Change YAML author to Uday Kumar. |
| **B** | List both (specify order). |
| **C** | Leave as-is for now. |

**My choice:** _______________  
**Notes:** _______________

---

# Decision 8 — Annual survey weights: what did we mean?

### What this is about
Code often does `wtfinl / months_in_year` where `months_in_year` is “how many months exist in that year in the file” (often 12 for everyone).  
Older notes said “months **this person** appears.” Those are different ideas.

### Options

| Option | Meaning |
|--------|---------|
| **A** | Document current behavior as **divide by 12** (or distinct months in the year file). |
| **B** | Change code to divide by **person–year month count**. |
| **Defer** | Document the mismatch; don’t change code yet. |

**My choice:** _______________  
**Notes:** _______________

---

## Suggested order (if you want a sequence)

Don’t do all eight at once. A practical order:

1. **Decision 2** (HPI) — biggest “what is the paper about?” clarity  
2. **Decision 1** (outcome / at-risk)  
3. **Decision 3** (linking) — mostly diagnostics unless you pick C  
4. **Decision 6** (tenure wording) — easy  
5. **Decision 7** (name) — easy  
6. **Decision 4, 5, 8** — when you start writing results tables  

---

## When you’re ready to tell Cursor

Copy something like this:

```text
I've decided:
1 → A
2 → A, primary = hybrid level
3 → Defer
4 → Defer
5 → A
6 → A
7 → A
8 → Defer

Please implement only the non-defer choices, and keep the working-paper status language.
Do not push until I say so.
```

---

*Last updated for the working-paper documentation pass. No decision in this file is binding until you write it in.*
