"""Story 2.1 SPIKE — Cloudflare bypass probe (Phase A: Playwright + stealth).

Run from repo root with crawler venv:
    crawler/.venv/bin/python crawler/spikes/cf_stealth_probe.py

This is a SPIKE script. It is not production code. It exists to gather
N>=3 measurements of whether Playwright+stealth can fetch real content
from a Cloudflare-fronted target site, classified as one of:
  Pass | CF Challenge | Block | Timeout | Error

Results are printed as JSON lines to stdout for easy capture into
docs/cloudflare-spike-result.md.
"""

import asyncio
import json
import re
import sys
import time
from dataclasses import asdict, dataclass

from playwright.async_api import (
    TimeoutError as PlaywrightTimeoutError,
    async_playwright,
)
from playwright_stealth import Stealth

TARGET_URL = "https://tailstar.net/"
ATTEMPTS = 3
NAV_TIMEOUT_MS = 30_000

# Selectors that indicate real content on tailstar.net (XpressEngine board layout).
CONTENT_SELECTORS = [
    "title",
    "link[rel='canonical'][href*='tailstar.net']",
    "meta[name='Generator'][content*='XpressEngine']",
]

# Cloudflare challenge / block markers.
CF_CHALLENGE_RE = re.compile(
    r"(Just a moment…|cf-challenge|cdn-cgi/challenge-platform|"
    r"Checking your browser|cf-mitigated)",
    re.IGNORECASE,
)
CF_BLOCK_RE = re.compile(
    r"(Access denied|Cloudflare Ray ID:.*?You have been blocked|"
    r"Sorry, you have been blocked)",
    re.IGNORECASE,
)


@dataclass
class AttemptResult:
    attempt: int
    classification: str  # Pass | CF Challenge | Block | Timeout | Error
    status_code: int | None
    elapsed_ms: int
    title: str | None
    content_marker_found: bool
    notes: str


async def probe_once(attempt_idx: int) -> AttemptResult:
    start = time.monotonic()
    title = None
    status = None
    content_marker = False
    notes = ""

    try:
        async with Stealth().use_async(async_playwright()) as p:
            browser = await p.chromium.launch(headless=True)
            try:
                context = await browser.new_context(
                    user_agent=(
                        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                        "AppleWebKit/537.36 (KHTML, like Gecko) "
                        "Chrome/124.0.0.0 Safari/537.36"
                    ),
                    locale="ko-KR",
                )
                page = await context.new_page()
                response = await page.goto(
                    TARGET_URL,
                    timeout=NAV_TIMEOUT_MS,
                    wait_until="domcontentloaded",
                )
                status = response.status if response else None
                html = await page.content()
                title = await page.title()

                if CF_CHALLENGE_RE.search(html):
                    classification = "CF Challenge"
                    notes = "challenge marker present in HTML"
                elif CF_BLOCK_RE.search(html):
                    classification = "Block"
                    notes = "block marker present in HTML"
                else:
                    # Verify real content via at least one selector.
                    for sel in CONTENT_SELECTORS:
                        if await page.query_selector(sel):
                            content_marker = True
                            break
                    if content_marker and status and 200 <= status < 400:
                        classification = "Pass"
                        notes = "content selector matched, no CF marker"
                    else:
                        classification = "Block"
                        notes = (
                            f"no challenge/block marker but content_marker="
                            f"{content_marker}, status={status}"
                        )
            finally:
                await browser.close()

    except PlaywrightTimeoutError:
        classification = "Timeout"
        notes = "playwright navigation timeout"
    except asyncio.TimeoutError:
        classification = "Timeout"
        notes = "asyncio cancellation/timeout"
    except Exception as exc:
        classification = "Error"
        notes = f"unexpected exception: {type(exc).__name__}: {exc}"

    elapsed_ms = int((time.monotonic() - start) * 1000)
    return AttemptResult(
        attempt=attempt_idx,
        classification=classification,
        status_code=status,
        elapsed_ms=elapsed_ms,
        title=title,
        content_marker_found=content_marker,
        notes=notes,
    )


async def main() -> int:
    results: list[AttemptResult] = []
    for i in range(1, ATTEMPTS + 1):
        result = await probe_once(i)
        results.append(result)
        print(json.dumps(asdict(result), ensure_ascii=False))
        sys.stdout.flush()
        # small delay between attempts to vary timing
        if i < ATTEMPTS:
            await asyncio.sleep(2)

    summary = {
        "target": TARGET_URL,
        "attempts": len(results),
        "passes": sum(1 for r in results if r.classification == "Pass"),
        "challenges": sum(1 for r in results if r.classification == "CF Challenge"),
        "blocks": sum(1 for r in results if r.classification == "Block"),
        "timeouts": sum(1 for r in results if r.classification == "Timeout"),
        "errors": sum(1 for r in results if r.classification == "Error"),
    }
    print(json.dumps({"summary": summary}, ensure_ascii=False))
    return 0 if summary["passes"] == len(results) else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
