# crawler/spikes

Throwaway / exploratory scripts. Not production code, not imported by the crawler.

## cf_stealth_probe.py

Story 2.1 SPIKE — measures whether Playwright + `playwright-stealth` can fetch
real content from a Cloudflare-fronted target site (default: `tailstar.net`).
Prints JSON-line results plus a summary. Re-run when validating a new site or
after a Cloudflare update.

Run from repo root:

```
crawler/.venv/bin/python crawler/spikes/cf_stealth_probe.py
```
