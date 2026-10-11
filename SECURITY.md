# Security / data hygiene

## Never commit

- IPUMS CPS microdata (`.dat`, `.dat.gz`) or extract DDI shipped with restricted extracts
- Merged person-level analysis datasets (`.rds`, `.RData`, processed CPS)
- `config/paths.R`, `.Renviron`, API keys
- Hard-coded absolute paths to a personal machine

## If an API key was exposed

1. Log in to IPUMS and **revoke / regenerate** the key immediately.
2. Put the new key only in `~/.Renviron` as `IPUMS_API_KEY=...`.
3. Confirm it never appears in git history (`git log -p -S 'set_ipums_api_key'`).

This public repository was built from a **clean copy** of analysis code; the working folder with extracts stays private.
