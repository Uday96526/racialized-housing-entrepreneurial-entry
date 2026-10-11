# CPS & HPI Research Pipeline — Code Chunk Explanations

**Purpose of this document:** Plain-English explanation of every code chunk in `df_wk.Rmd`, written so that anyone (including a professor or first-time reader) can understand what each piece of code does, why it exists, and what it produces.

---

## Chunk 1 — libraries | functions

- This chunk runs at the very beginning of the document. Its only job is to load all the tools and helper code that the rest of the analysis depends on. Nothing is produced here — think of it as turning on the lights before starting work.
- It loads a set of R "packages" (pre-built toolboxes made by other researchers) — for example: `dplyr` (for filtering and summarizing data), `ggplot2` (for drawing charts), `ipumsr` (for reading IPUMS survey files), and `data.table` (for fast data processing).
- It turns off scientific notation globally — so numbers like 1,000,000 stay readable instead of appearing as `1e+06`.
- It defines a custom shortcut called `%notin%`, which is simply the opposite of `%in%`. It means: "give me all rows where this value is NOT in this list."
- It loads an external R script called `cps.R`, which contains a custom class object with pre-built functions for handling CPS data (e.g. building industry and entrepreneurship variables). This class is used in later chunks.
- The chunk is hidden from the final report output because readers don't need to see setup code — it runs silently in the background.

---

## Chunk 2 — parameter definitions

- This chunk defines the time window of the study and creates a lookup table that links every month in that window to its official IPUMS sample name.
- It starts by setting two date boundaries: a start (e.g. July 2002) and an end (e.g. July 2020). These control which CPS samples will be used across the entire project.
- It builds a sequence of monthly dates between those two points (like a calendar), then labels each month with a human-readable description (e.g. "IPUMS-CPS, July 2002").
- Each description is then matched to the official IPUMS sample code using `get_sample_info('cps')` — a function from the custom `cps.R` script. This gives the exact file/extract name the data provider uses.
- Output: A table called `code_data` with one row per month, containing the date, description, and IPUMS sample name. Later chunks use this table to pull or read the right data files.

---

## Chunk 3 — cps import through api

- This chunk shows how CPS data could be downloaded automatically over the internet from IPUMS (the data provider), but it is intentionally turned **off** (using `eval=FALSE`) so it does not run every time the document is built.
- It begins by listing all the variables to request from CPS — such as race, Hispanic origin, age, education, industry, earnings, class of worker (employee vs. self-employed), homeownership, and two types of survey weights.
- It then connects to the IPUMS API (API = a way for code to "talk" to a website and fetch data automatically), submits the data request, waits for it to be ready, downloads it, and reads it into R.
- Column names are converted to lowercase for consistency with the rest of the code.
- Output: Would create `cps_data` — the main person-level dataset. In practice, this chunk is skipped and data is loaded locally in the next chunk instead, since the file was already downloaded once.

---

## Chunk 4 — cps import through local

- This chunk loads the already-downloaded CPS data file from the local computer instead of re-downloading it from IPUMS every time.
- It uses `read_ipums_micro()` to read the IPUMS-formatted file (which contains coded values and labels for variables like race, education, etc.) directly into R as a data frame.
- All column names are immediately converted to lowercase to keep naming consistent throughout the project.
- A critical safety step: the original numeric race column is saved as `race_orig` before any recoding happens. This backup ensures the raw IPUMS race codes are always available for the classification step later, even if the `race` column gets modified.
- Output: `cps_data` — the master person-level dataset with one row per survey respondent. This is the foundation for all analysis in the project.

---

## Chunk 5 — survey_weights_setup

- This chunk creates "annualized" survey weights — adjusted versions of the standard weights that are appropriate for yearly-level analysis rather than monthly.
- Background: The CPS survey is conducted monthly, so a person can appear multiple times in one year. The standard weight (`wtfinl`) treats each monthly observation as equally important. To summarize things at the year level without double-counting people, the weight must be divided by the number of months that person appears in that year.
- For each year, the chunk counts how many distinct months are present, then creates `wtfinl_annual = wtfinl / months_in_year`. If an earnings-specific weight (`earnwt`) is also available, the same adjustment is made to create `earnwt_annual`.
- After creating the weights, it prints a quick diagnostic report showing coverage percentages — confirming that the weights exist for (nearly) all records before any analysis begins.
- Output: Two new columns added to `cps_data` — `wtfinl_annual` and `earnwt_annual`. A printed report confirming weight coverage.

---

## Chunk 6 — race_visualization

- This chunk defines the study's key grouping variable — a clean 4-category race classification — and then produces the first descriptive chart of the sample.
- It starts by checking whether the backup column `race_orig` was created in the import step. If yes, it uses those original numeric codes; if no, it tries to use `race` directly. This safety check prevents errors from attempting to re-classify already-modified values.
- It combines the race code and Hispanic origin code (`hispan`) to create four mutually exclusive groups: "White Non-Hispanic," "Black Non-Hispanic," "Asian & Pacific Islander Non-Hispanic," and "Hispanic." All other categories (e.g. American Indian, Multi-racial, Other) are set to missing and dropped from the dataset. Hispanic origin takes priority regardless of the race code.
- After classifying, the data is grouped by year and race to compute the weighted count and percentage share of each race group per year (excluding boundary years 2002 and 2020 which may have incomplete data).
- Output: An updated `cps_data` with a four-level race factor; a weighted summary table; an Excel export; and a stacked bar chart showing the racial composition of the sample year by year.

---

## Chunk 7 — html setup

- This chunk fetches the official list of CPS industry codes (IND1990) directly from the IPUMS website and converts the raw web data into a usable table.
- It connects to a specific IPUMS webpage using `read_html()`, then targets a JavaScript block embedded in that page which contains all the industry categories and their codes as structured text.
- A pattern-matching step extracts just the categories section from the JavaScript, then the text is split into individual entries — one per industry or sub-sector. A loop processes each entry to extract: the numeric code, label, indentation level (which indicates whether it's a top-level sector or a sub-sector), and general category flag.
- Output: A table called `ind_code_df` — one row per industry entry, with columns for code, label, indent level, and general category. This table is used in the next two chunks to map each CPS respondent's raw industry code to a readable name and NAICS sector category (NAICS = North American Industry Classification System, the standard way governments group industries).

---

## Chunk 8 — industry headers

- This chunk organizes the raw scraped industry codes into a clean hierarchy: top-level major sectors ("headers") and detailed sub-sectors ("body"), each with their corresponding NAICS codes.
- Starting from `ind_code_df`, it flags rows that represent major sector headings using the indent level — certain indent patterns identify top-level categories like "Manufacturing" or "Construction." A cumulative sum (`ind_category`) is used to assign a group number to each row based on how many headers have been passed.
- Each group number is then manually mapped to a NAICS code (e.g. group 4 = NAICS 23 = Construction, group 5 = NAICS 31 = Manufacturing, etc.). Two labels are also corrected to match the full official NAICS sector names.
- Output: Two separate tables — `header_ind_code_df` (one row per major sector with NAICS code) and `body_ind_code_df` (one row per sub-sector). Both are used in the next chunk to label every CPS respondent's industry.

---

## Chunk 9 — industry body

- This chunk assigns a final NAICS sector code and readable sector name to every detailed sub-sector in the `body_ind_code_df` table, then attaches the result to the main CPS data.
- Because IPUMS IND1990 codes don't map perfectly to NAICS, many sub-sectors require manual correction — for example, specific IND1990 codes for communications and utilities are reassigned to NAICS 51, real estate codes to NAICS 53, health codes to NAICS 62, and so on. These overrides use a series of `case_when` conditions (like a switch statement — "if the code is X, assign category Y").
- Once every sub-sector has a correct NAICS code, it is mapped to a full readable name (e.g. NAICS 62 → "Health Care and Social Assistance").
- Output: A lookup table `naics_code_df`; then `cps_data` is merged with this table so every respondent now has a new column `ind` containing their readable industry sector name. This enables all the industry-based analysis that follows.

---

## Chunk 10 — industry_trends_visualization

- This chunk calculates and visualizes how the share of workers in each industry sector has shifted over time across the study period (2003–2019).
- It filters out the boundary years 2002 and 2020, then groups by year and industry. For each group, it sums the survey weights (`wtfinl`) to get a population-weighted count of workers, then calculates each industry's percentage share of the total workforce that year.
- Output: A printed summary table, an Excel file, and a stacked bar chart where each bar represents one year, split into colored segments showing each industry's share of total workers.
- This chart helps document structural economic change — for example, whether the manufacturing sector shrank while the health care sector grew over the study period.

---

## Chunk 11 — industry_trends_by_race_stacked_bar

- This chunk extends the industry analysis by breaking it down separately for each racial group, answering: "Are different races concentrated in different industries?"
- It filters to the four race groups, then for each year-race combination, calculates the weighted share of workers in each industry *within* that race group (not as a share of the total population, but as a share within each race).
- Output: A summary table and Excel file; a faceted stacked bar chart — one panel per race — showing industry composition within each group over time. This makes it easy to visually compare, for example, whether Black workers are more concentrated in public administration while White workers are more concentrated in finance.
- This analysis is relevant for the research because racial differences in industry can partly explain differences in entrepreneurship rates.

---

## Chunk 12 — educational attainment

- This chunk creates a clean, ordered education variable and shows how the educational composition of the sample has changed over time.
- It first saves the raw IPUMS education codes in a backup column (`educ_orig`), then groups those numeric codes into six meaningful categories labeled a through f: (a) Less than High School, (b) High School Graduate, (c) Some College with no degree, (d) Associate Degree or College Diploma, (e) Bachelor's Degree, (f) Postgraduate. Unrecognized codes are labeled "Unknown/Missing" and excluded from the charts.
- For each year, it calculates the weighted share of people at each education level and plots the results two ways: a stacked bar chart (showing composition in each year) and a line chart (showing trends for each education level over time).
- Output: Two new columns added to `cps_data` (`educ_letter` and `educ_desc`); a summary table; an Excel export; and two charts covering the 2003–2019 period.

---

## Chunk 13 — entrepreneurship_variables_simple

- This is one of the most important chunks in the project. It defines the two core outcome variables — whether a person *transitioned into* entrepreneurship — by comparing each person's employment type at two different time points.
- The CPS re-surveys the same person roughly 4 months later (this is the "rotation group" design). The chunk creates 4-month lags of the employment type (`classwkr`) and survey rotation month (`mish`) for each person, identified by their unique ID (`cpsidp`).
- **entrepreneurship1 = 1** if a person was previously *not* in unincorporated self-employment (classwkr ≠ 13) and is now in unincorporated self-employment (classwkr = 13). Unincorporated self-employed = freelancers, sole traders — informal business owners.
- **entrepreneurship2 = 1** if a person was previously *not* in incorporated self-employment (classwkr ≠ 14) and is now in incorporated self-employment (classwkr = 14). Incorporated = formal business with legal registration — the focus of the paper.
- Both variables include conditions to ensure the person was actually observed at both time points (no missing lag values, and the month sequence is consistent with a 4-month gap).
- Output: Two new binary columns — `entrepreneurship1` and `entrepreneurship2` — added to `cps_data`. A value of 1 means "this person newly entered this type of self-employment"; 0 means they did not. These are the outcome variables used in all regression and visualization chunks.

---

## Chunk 14 — entrepreneurship_variables_based_on_race

- This chunk calculates the annual rate at which people in each racial group transitioned into incorporated self-employment (`entrepreneurship2`) and visualizes how those rates changed over time.
- For each combination of year and race, it multiplies the entrepreneurship indicator by the survey weight (`wtfinl`) to get a weighted count of transitions, divides by the total weighted population in that race-year group, and expresses the result as a percentage.
- Output: A summary table and Excel file showing the weighted transition rate by race and year; a line chart (with one line per race and optional faceted panels) tracking trends from 2003 to 2019.
- This chart is central to the paper's narrative — it shows whether the racial gap in incorporated entrepreneurship has widened, narrowed, or stayed constant over time.

---

## Chunk 15 — entrepreneurship_variables_based_on_white_and_black_race

- This chunk zooms in on just the Black–White comparison in incorporated entrepreneurship, producing both weighted and unweighted (raw) transition rates for a sharper, more focused analysis.
- It filters to White and Black respondents only and computes four metrics per year-race cell: unweighted count, weighted count, unweighted percentage, and weighted percentage (using `wtfinl_annual`).
- Output: A focused summary table and Excel file; a line chart with one colored line per race (White = orange, Black = light blue) showing annual transition rates, with optional facets and data labels on each point.
- This direct comparison supports the research's core question: does a persistent racial gap in incorporated entrepreneurship exist, and how large is it?

---

## Chunk 16 — earning_per_race

- This chunk estimates mean yearly earnings by race and year — using the most appropriate weight and adjusting for inflation so earnings across different years can be meaningfully compared.
- It selects the best available weight: `earnwt_annual` (designed specifically for earnings questions) if it exists, otherwise falls back to `wtfinl_annual`. It then cleans the weekly earnings variable by removing codes that indicate missing, top-coded, or special values (e.g. 999, 1923), and multiplies valid values by 52 to get yearly earnings.
- Inflation adjustment: it merges Consumer Price Index (CPI — a measure of how much the average basket of goods costs; used to adjust for the fact that $50,000 in 2003 is not the same as $50,000 in 2020) data from the Bureau of Labor Statistics, then converts all earnings to real 2020 dollars.
- Output: A table and Excel file with both nominal (unadjusted) and real (inflation-adjusted) yearly earnings by race and year; a line chart showing mean yearly earnings per race over time.

---

## Chunk 17 — tenure

- This chunk labels household tenure (whether a person owns, rents, or has some other arrangement for their home) and summarizes its distribution in the sample.
- Starting from the raw numeric variable `hhtenure`, it assigns human-readable labels: 1 = "Owned or being bought," 2 = "Rented," 3 = "No cash rent," 0 = "NIU" (Not in Universe — meaning the person was not asked this question), and anything else = "Unknown."
- It calculates the weighted count and percentage share for each tenure category and displays the result in a formatted table and two charts — a bar chart and a pie chart.
- Output: A new column `tenure_status` added to `cps_data`; a summary table; two charts.
- Tenure is a foundational variable for the paper because homeownership is the key mechanism through which housing prices might affect someone's ability to start a business (e.g. using home equity as collateral for a business loan).

---

## Chunk 18 — entrepreneurship2_rate_by_homeowners_plot

- This chunk calculates and visualizes the rate of transitioning into incorporated self-employment for **homeowners only** (`hhtenure == 1`), broken down by race and year.
- It filters to homeowners, then for each year-race combination computes the weighted count of entrepreneurship transitions and divides by the total weighted count of homeowners in that group.
- Output: A summary table and Excel file; a line chart showing the transition rate over time for each race among homeowners.
- This subset is theoretically important: if rising house prices give homeowners more wealth and collateral to start a business, homeowners should show a stronger HPI–entrepreneurship relationship than renters. This chunk documents the baseline trend for the collateral-channel group.

---

## Chunk 19 — entrepreneurship2_rate_by_renters_plot

- This chunk mirrors the homeowners analysis but applies it to **renters only** (`hhtenure == 2`), producing a side-by-side comparison group.
- The logic and structure are identical to the homeowners chunk — same race groups, same year range, same weighted calculation — just filtered to renters instead of owners.
- Output: A summary table, Excel file, and line chart of transition rates among renters by race and year.
- Renters do not own an asset that appreciates with housing prices, so they should be *less* affected by HPI changes. Comparing renters vs. homeowners is the foundation for the formal placebo test in Chunk 24.

---

## Chunk 20 — Unnamed chunk (data inspection)

- This is a quick data check: it prints the first 20 rows of `cps_data` to the console.
- It exists purely as a visual sanity check — the researcher can scan the table to confirm that all variables created so far (race, entrepreneurship indicators, industry, education, tenure, weights) are correctly formatted and contain sensible values before moving to the HPI integration stage.
- Output: A printed table in the console. No new data is created or saved.

---

## Chunk 21 — hpi_integration

- This chunk is the bridge between the CPS person-level data and the housing market data. It attaches a House Price Index (HPI — a number that tracks how housing prices in an area change over time; higher HPI = more expensive housing market) to each CPS respondent based on the state they live in.
- It starts by creating the working analysis data frame `cps_df` from `cps_data` using the CPS class object. This step ensures entrepreneurship and industry variables are in the correct format.
- It loads the HPI data file (published by the Federal Housing Finance Agency, provided as a county-level Excel file), then averages it up to the **state level** by computing the mean HPI and mean annual percentage change per state per year.
- A lookup table translates CPS state codes (called FIPS codes — e.g. "6") into standard two-letter state abbreviations (e.g. "CA"), so the two datasets can be linked on a common key.
- The state-level HPI is merged onto `cps_df`, and two new columns are created: `hpi_final` (the HPI index value for the person's state and year) and `hpi_change_final` (the year-over-year % price change).
- Output: `cps_df` — the full working dataset with HPI attached. A printed summary reports how many records successfully received an HPI value. Note: county-level matching (more precise but with more missing values) is handled in Chunk 27.

---

## Chunk 22 — Hpi visualization

- This is the main exploratory chunk for housing prices. It produces multiple charts and tables that together show how HPI varies by geography and race, and how it relates to entrepreneurship rates.
- **Time series by state:** Computes weighted average HPI for each state-year and plots one line per state, showing how housing prices moved over time. Saved to Excel.
- **US map:** Joins state HPI to a US map shapefile and draws a color-coded map — blue = lower/more affordable housing, red = higher/more expensive. Useful for showing geographic variation at a glance.
- **HPI change by race:** Calculates the weighted mean year-over-year % change in HPI for each race group and year (people are assigned the HPI of their state), then plots as a line chart. A dashed line at zero separates years of rising vs. falling prices.
- **Entrepreneurship vs. HPI scatter:** Creates one data point per state-year-race combination, with HPI on the x-axis and entrepreneurship rate on the y-axis, and adds a trend line for each race. This gives a visual preview of the regression relationship.
- **HPI quartile analysis:** Divides the sample into four HPI groups (Q1 = lowest 25%, Q4 = highest 25%) within each year, then calculates entrepreneurship rates in each quartile by race. Shows whether entrepreneurship is higher in high-HPI areas.
- **Entrepreneur-homeowner HPI:** For entrepreneurs who are also homeowners, calculates their average HPI change by race and year — showing how housing market conditions for this specific group evolved.
- Output: Multiple Excel files and charts. All calculations are population-weighted.

---

## Chunk 23 — Hpi Regression

- This is the core statistical analysis of the paper. It estimates four increasingly detailed regression models (a statistical technique that isolates the relationship between two variables while holding others constant) to test how local housing prices relate to the probability of transitioning into incorporated self-employment.
- **Data preparation:** Loads actual (not pre-merged) state-level HPI from the source file to ensure accuracy. Builds a clean regression dataset from `cps_df` with: race (4 groups, White as the reference group — the group other groups are compared to), HPI scaled by dividing by 10 (`hpi10`, so coefficients show the effect of a 10-unit HPI increase), and a full set of control variables (gender, age, marital status, children, homeownership, education, industry, earnings, state fixed effects, year fixed effects).
- **Four models:** Model 1 = race only. Model 2 = race + HPI. Model 3 = race × HPI (an "interaction" — tests whether HPI has a *different* effect for different races). Model 4 = full Model 3 plus all controls and fixed effects.
- All models use HC1 robust standard errors (a technical correction that makes uncertainty estimates reliable when data variance is unequal across observations).
- **Race-specific slopes:** From Model 4, the total HPI effect for each race is calculated by combining the base HPI coefficient and the race-HPI interaction term, with proper standard errors and 95% confidence intervals (CI = the range where the true effect likely falls 95% of the time).
- Output: Four coefficient tables, a model summary (N, R², Adjusted R²), and a race-specific HPI slopes table — all exported to a single Excel workbook.

---

## Chunk 24 — Hpi PLACEBO TEST: Homeowners vs Renters

- A placebo test checks whether a finding shows up where it theoretically *should not*. The logic here: if housing prices affect entrepreneurship by increasing homeowners' wealth and collateral, the effect should exist for homeowners but be weak or absent for renters (who don't own an appreciating asset). This chunk runs that test.
- It uses **HPI change** (year-over-year % price change, not the price level itself) as the key variable — because it is the *change* in prices that determines whether a homeowner gains or loses wealth in a given year.
- The same full regression model from Chunk 23 is run separately on two subsamples: homeowners (`hhtenure == 1`) and renters (`hhtenure == 2` only — renters paying no cash are excluded to keep the comparison clean).
- State-clustered standard errors (a stricter form of error correction that accounts for the fact that people in the same state share the same housing market) are used instead of just HC1 robust SEs.
- Output: Coefficient tables for both subsamples. The expected result: HPI change significantly predicts entrepreneurship for homeowners but not for renters — providing evidence that the mechanism is collateral/wealth, not something else that affects all state residents equally.

---

## Chunk 25 — Hpi visualization Heat Map for Black and White Race with HPI

- This chunk visualizes the relationship between housing prices and entrepreneurship rates for Black and White respondents using a heat map — a grid of colored tiles where color intensity represents the magnitude of a value.
- It filters to Black and White respondents, then bins HPI into 10 equal groups (deciles — e.g. the bottom 10% of HPI values, the next 10%, etc.). For each combination of race and HPI decile, the weighted entrepreneurship rate is calculated.
- The first heat map uses HPI deciles on the x-axis, race on the y-axis, and color (using the "plasma" color scale — dark = low rates, bright = high rates) to show entrepreneurship rates, with numeric labels on each tile.
- A second version uses fixed, interpretable HPI ranges (e.g. "Very Low < 150", "Low 150–200", "Medium 200–250", etc.) for clearer communication.
- Output: Two heat map charts and an Excel file with the underlying data. The charts make it immediately visible whether Black and White entrepreneurship rates diverge at specific housing price levels and whether the pattern is linear or non-linear.

---

## Chunk 26 — county_name_diagnostic

- Before doing county-level matching (attaching HPI at the county level instead of the state level), this chunk inspects the geographic information available in both datasets to determine what matching strategies are feasible.
- It checks what geographic columns exist in `cps_data` (e.g. `statefip`, `county`) and examines the `county` variable: its data type, how many unique values it has, sample values, and how many records have missing county codes.
- It loads the HPI data file and looks for FIPS code columns (FIPS = Federal Information Processing Standards — standardized numeric codes that uniquely identify every US county, e.g. "06037" = Los Angeles County, CA), county name columns, and state columns.
- It performs a trial FIPS-based merge and reports what percentage of CPS records successfully matched to an HPI record. If county names exist in the HPI file, it also creates a FIPS-to-county-name lookup table for potential backup matching.
- Output: A series of printed diagnostic messages — no data is modified. This chunk documents the geographic matching challenge and informs the three-tier strategy implemented in the next chunk.

---

## Chunk 27 — hpi_integration_county_level_only

- This chunk implements a more precise HPI match than the state-level approach: it links each CPS respondent to the HPI of their specific county using up to two methods, and records which method succeeded.
- **Tier 1 — FIPS matching (primary):** The CPS county code is formatted into a standard 5-digit FIPS code (combining the 2-digit state code + 3-digit county code). This is then joined to the HPI file on FIPS + year.
- **Tier 2 — County name matching (backup):** For records that still have no HPI after Tier 1, the chunk uses a county name lookup (built from the HPI file) to try matching by county name + state abbreviation + year.
- Records with no county information (county code = 0, meaning the survey suppressed it for confidentiality) remain unmatched — there is no state-level fallback here.
- Every record is labeled with how it was matched: `FIPS_Direct`, `FIPS_Reconstructed`, `County_Name`, or `Unmatched`.
- Output: Updated `cps_df` with `hpi_final` and `hpi_change_final` filled where a county-level match exists; a printed summary table showing the count and percentage of each match method.

---

## Chunk 28 — hpi_missing_data_diagnostic

- This chunk investigates and transparently documents *why* some records are missing county-level HPI — so that missing data can be explained as a structural data limitation rather than an unexplained gap.
- It categorizes missing data into three types: (a) county code = 0 in CPS (the survey deliberately suppressed the county to protect respondent privacy), (b) valid county code but not covered in the HPI file (e.g. very small counties), (c) successfully matched.
- It examines these patterns by year and by state — to check if certain years or states have systematically higher missingness — and lists specific CPS county codes that could not be matched.
- It also checks HPI file coverage by year to confirm whether the external data file itself has gaps for certain periods.
- Output: A series of printed tables. The data itself is not modified. This chunk is designed to be cited directly in the paper's data section or appendix to explain the match rate.

---

## Chunk 29 — hpi_checking bias for certain race

- This chunk checks whether the records that successfully matched to county-level HPI are racially balanced — i.e., do all four race groups have similar match rates? If one group is systematically less likely to be matched, the county-level analysis could be biased toward over- or under-representing that group.
- It computes three things: (1) the overall racial composition of the full analysis sample, (2) the racial composition of the matched subset (those with HPI), and (3) the racial composition of the unmatched subset. It then directly compares these.
- A simple threshold rule: if the difference between the highest and lowest match rate across races is less than 5 percentage points, the missingness is considered "random" (not systematically related to race). Otherwise, it is flagged as "race-specific" and may require further investigation.
- Output: Printed tables and a one-sentence conclusion. No changes to the dataset.

---

## Chunk 30 — hpi county level

- This chunk re-runs the key HPI descriptive analyses from Chunk 22, but uses **only** records with county-level HPI (no state fallback), as a robustness check to confirm results hold at finer geographic detail.
- It filters to the analysis years (2003–2019), valid county codes, non-missing `hpi_final`, and the four race groups, then replicates: HPI change by race and year, entrepreneurship rate vs. HPI, quartile-based entrepreneurship rates, and any relevant charts.
- Output: The same types of charts and Excel files as in Chunk 22, but labeled as county-level only. This is an important robustness check: if the county-level results match the state-level results, it strengthens confidence in the findings; if they differ, it is worth investigating why.

---

## Chunk 31 — County-Level Data Race-Specific or Random?

- This chunk repeats the bias check from Chunk 29 but applied specifically to the version of the dataset produced by the county-level-only integration in Chunk 27. It asks the same question: is the county match rate similar across races?
- Same structure as Chunk 29 — overall race distribution, matched vs. unmatched racial breakdowns, match rate by race, and a threshold-based automated conclusion.
- Output: Printed tables and a one-line summary (e.g. "matched county-level data is RANDOMLY distributed across racial groups").
- Together with Chunk 29, this provides double assurance that neither the state-level nor the county-level matching strategy introduces racial selection bias into the analysis.

---

## Chunk 32 — Model validation

- This chunk performs a **Fairlie Decomposition** — a standard econometric technique used to explain a gap between two groups. Here, it breaks down the Black–White gap in incorporated entrepreneurship into: (a) the "explained" part (differences due to measurable characteristics like education, age, or HPI) and (b) the "unexplained" part (differences that cannot be accounted for by observables — potentially reflecting structural barriers or discrimination).
- It filters to Black and White respondents and prepares covariates: HPI, education (collapsed to 4 categories to avoid empty cells), age, marital status, and class of worker. Separate logistic regression models (a statistical model for binary outcomes — "did this person start a business or not?") are fitted for White and Black groups, both weighted by survey weights.
- The decomposition logic: for each variable, it asks "If Black individuals had the same distribution of this variable as White individuals, how much of the gap would close?" This is done by substituting White values (or distributions) into the Black group's predictions using the White model as the benchmark.
- The explained component = sum of contributions from all variables. The unexplained component = total gap − explained.
- Output: A printed report of total gap, explained, unexplained, and each variable's contribution; two bar charts — one showing the explained vs. unexplained split, and one showing each variable's individual contribution to the explained gap. Results are weighted throughout.

---

## Chunk 33 — summary_statistics_by_race

- This chunk assembles a comprehensive descriptive statistics table — the kind of "Table 1" found in academic papers — showing weighted averages and percentages for key variables, broken down by race.
- It builds the summary in four parts: (1) basic demographics and employment (entrepreneurship rates, homeownership, gender, age, marital status, children, earnings), (2) education distribution (% in each level per race), (3) industry distribution (% in each sector per race), and (4) HPI statistics if available.
- All four parts are stacked into a single long table with Variable as rows and the four race groups as columns. Separator rows are inserted between sections for readability.
- Output: A printed table in the console and an Excel file (e.g. `summary_statistics_by_race_weighted_*.xlsx`) with all values rounded to two decimal places. This is a publication-ready descriptive table.

---

## Chunk 34 — summary_statistics_by_race updated

- This chunk produces an upgraded, more complete version of the summary statistics table — designed to meet the standards expected in a peer-reviewed journal submission.
- Unlike Chunk 33 (which uses the filtered regression sample), this chunk starts from **raw `cps_data`** before any regression-related sample restrictions, keeping everyone aged 16 and older. This means the table honestly reflects the full analysis sample and shows true missingness rates.
- For each variable (entrepreneurship, race dummies, gender, age, marital status, children, homeownership, education levels, yearly earnings, and HPI if available), it computes: number of valid observations, sum of survey weights (representing the estimated U.S. population size), weighted mean, weighted standard deviation, minimum, maximum, count of missing observations, percentage missing, weighted missing count, and weighted missing percentage.
- Formatting is handled carefully: binary variables (yes/no) are shown as percentages; earnings are formatted with dollar commas; the earnings-specific weight (`earnwt_annual`) is used for earnings when available.
- Output: A formatted Excel workbook named `Table1_ProfessorStyle_RawCPS_Age16_EarningsMin10_*.xlsx` with one worksheet. This is the formal Table 1 submitted with the paper — fully transparent about sample size, data coverage, and missingness.

---

*End of explanations. If you need a longer write-up or a specific section expanded for a methods or appendix section, please ask.*
