# Security / data hygiene

## Never commit

- IPUMS CPS microdata (`.dat`, `.dat.gz`) or extract files whose redistribution is unauthorized
- Merged person-level analysis datasets (`.rds`, `.RData`, processed CPS–HPI files)
- `config/paths.R`, `.Renviron`, API keys, passwords
- Hard-coded absolute paths to a personal machine
- Unreviewed outputs that could contain individual-level records

## `.gitignore` vs Git history

`.gitignore` prevents *new* untracked files from being added easily. It does **not** remove files that were already committed. If restricted data or secrets ever appear in history, stop and remediate deliberately (rotate credentials; consider history rewrite only with explicit approval).

## Tracked-file checks (this repository)

At documentation time, tracked paths are code and docs only (no `cps_*.dat*`, no `.xlsx` extracts). Re-check with `git ls-files` before each push.

## If an API key was exposed

1. Log in to IPUMS and **revoke / regenerate** the key immediately.
2. Put the new key only in `~/.Renviron` as `IPUMS_API_KEY=...`.
3. Confirm it never appears in git history (`git log -p -S 'set_ipums_api_key'` / `-S 'IPUMS_API_KEY'`).

This public repository is a **code-and-documentation** package; working folders with extracts stay private.
