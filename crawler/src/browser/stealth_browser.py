from __future__ import annotations

import os
import re
from typing import Final

from playwright.async_api import (
    TimeoutError as PlaywrightTimeoutError,
    async_playwright,
)
from playwright_stealth import Stealth

from shared.exceptions.base_exception import CrawlerException
from shared.structured_logger import get_logger

_logger = get_logger(__name__)

_DEFAULT_NAV_TIMEOUT_MS: Final[int] = 30_000
_DEFAULT_USER_AGENT: Final[str] = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)
_DEFAULT_LOCALE: Final[str] = "ko-KR"
_SERVICE_NAME: Final[str] = os.environ.get("SERVICE_NAME", "crawler")

_CF_CHALLENGE_RE: Final[re.Pattern[str]] = re.compile(
    r"(Just a moment…|cf-challenge|cdn-cgi/challenge-platform|"
    r"Checking your browser|cf-mitigated)",
    re.IGNORECASE,
)
_CF_BLOCK_RE: Final[re.Pattern[str]] = re.compile(
    r"(Sorry, you have been blocked|"
    r"Cloudflare Ray ID:.*?You have been blocked|Access denied)",
    re.IGNORECASE | re.DOTALL,
)


class BrowserError(CrawlerException):
    """Raised when the headless browser fails to fetch real content."""


class StealthBrowser:
    def __init__(
        self,
        *,
        nav_timeout_ms: int = _DEFAULT_NAV_TIMEOUT_MS,
        user_agent: str = _DEFAULT_USER_AGENT,
        locale: str = _DEFAULT_LOCALE,
        headless: bool = True,
    ) -> None:
        self._nav_timeout_ms = nav_timeout_ms
        self._user_agent = user_agent
        self._locale = locale
        self._headless = headless

    async def fetch_html(self, url: str, *, correlation_id: str) -> str:
        extra = {"correlation_id": correlation_id, "service": _SERVICE_NAME}
        _logger.info(f"fetch_html.start url={url}", extra=extra)

        try:
            async with Stealth().use_async(async_playwright()) as p:
                browser = await p.chromium.launch(headless=self._headless)
                context = None
                try:
                    context = await browser.new_context(
                        user_agent=self._user_agent,
                        locale=self._locale,
                    )
                    page = await context.new_page()
                    response = await page.goto(
                        url,
                        timeout=self._nav_timeout_ms,
                        wait_until="domcontentloaded",
                    )
                    status = response.status if response else None
                    html = await page.content()
                finally:
                    if context is not None:
                        try:
                            await context.close()
                        except Exception as close_exc:
                            _logger.warning(
                                f"fetch_html.context_close_failed url={url} "
                                f"type={type(close_exc).__name__}",
                                extra=extra,
                            )
                    try:
                        await browser.close()
                    except Exception as close_exc:
                        _logger.warning(
                            f"fetch_html.browser_close_failed url={url} "
                            f"type={type(close_exc).__name__}",
                            extra=extra,
                        )
        except BrowserError:
            raise
        except PlaywrightTimeoutError as exc:
            _logger.warning(
                f"fetch_html.timeout url={url} timeout_ms={self._nav_timeout_ms}",
                extra=extra,
            )
            raise BrowserError(
                f"playwright navigation timed out after "
                f"{self._nav_timeout_ms}ms for {url}",
                correlation_id=correlation_id,
            ) from exc
        except Exception as exc:
            _logger.error(
                f"fetch_html.exception url={url} type={type(exc).__name__}",
                extra=extra,
            )
            raise BrowserError(
                f"playwright navigation failed for {url}: {exc}",
                correlation_id=correlation_id,
            ) from exc

        if status is None or not (200 <= status < 400):
            _logger.warning(
                f"fetch_html.bad_status url={url} status={status}",
                extra=extra,
            )
            raise BrowserError(
                f"unexpected HTTP status {status} for {url}",
                correlation_id=correlation_id,
            )

        if _CF_CHALLENGE_RE.search(html):
            _logger.warning(
                f"fetch_html.cf_challenge url={url}",
                extra=extra,
            )
            raise BrowserError(
                f"Cloudflare challenge detected for {url}",
                correlation_id=correlation_id,
            )

        if _CF_BLOCK_RE.search(html):
            _logger.warning(
                f"fetch_html.cf_block url={url}",
                extra=extra,
            )
            raise BrowserError(
                f"Cloudflare block page detected for {url}",
                correlation_id=correlation_id,
            )

        if not html:
            _logger.warning(
                f"fetch_html.empty url={url} status={status}",
                extra=extra,
            )
            raise BrowserError(
                f"empty HTML response for {url}",
                correlation_id=correlation_id,
            )

        _logger.info(
            f"fetch_html.ok url={url} status={status} bytes={len(html)}",
            extra=extra,
        )
        return html
