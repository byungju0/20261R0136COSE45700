from __future__ import annotations

from contextlib import asynccontextmanager
from unittest.mock import AsyncMock, MagicMock

import pytest

from crawler.src.browser.stealth_browser import BrowserError, StealthBrowser


def _build_mock_chain(*, html: str, status: int = 200):
    """Build a mocked Playwright object graph mirroring StealthBrowser usage.

    Mirrors:
        async with Stealth().use_async(async_playwright()) as p:
            browser = await p.chromium.launch(headless=...)
            context = await browser.new_context(...)
            page = await context.new_page()
            response = await page.goto(url, ...)
            html = await page.content()
            await browser.close()
    """
    page = AsyncMock()
    page.content.return_value = html

    response = MagicMock()
    response.status = status
    page.goto = AsyncMock(return_value=response)

    context = AsyncMock()
    context.new_page = AsyncMock(return_value=page)

    browser = AsyncMock()
    browser.new_context = AsyncMock(return_value=context)
    browser.close = AsyncMock(return_value=None)

    pw = MagicMock()
    pw.chromium = MagicMock()
    pw.chromium.launch = AsyncMock(return_value=browser)

    @asynccontextmanager
    async def fake_use_async(_pw_arg):
        yield pw

    stealth_instance = MagicMock()
    stealth_instance.use_async = fake_use_async
    return stealth_instance


@pytest.mark.asyncio
async def test_fetch_html_returns_html_on_success(monkeypatch):
    real_html = (
        "<html><head><title>real</title></head>"
        "<body>real content</body></html>"
    )
    stealth_inst = _build_mock_chain(html=real_html, status=200)
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.Stealth",
        lambda: stealth_inst,
    )
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.async_playwright",
        lambda: MagicMock(),
    )

    result = await StealthBrowser().fetch_html(
        "https://example.com",
        correlation_id="test-success",
    )

    assert "real content" in result


@pytest.mark.asyncio
async def test_fetch_html_raises_browser_error_on_cf_challenge(monkeypatch):
    challenge_html = (
        "<html><head><title>Just a moment…</title></head>"
        "<body>cdn-cgi/challenge-platform</body></html>"
    )
    stealth_inst = _build_mock_chain(html=challenge_html, status=200)
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.Stealth",
        lambda: stealth_inst,
    )
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.async_playwright",
        lambda: MagicMock(),
    )

    with pytest.raises(BrowserError) as exc_info:
        await StealthBrowser().fetch_html(
            "https://example.com",
            correlation_id="test-challenge",
        )

    assert "challenge" in str(exc_info.value).lower()
    assert exc_info.value.correlation_id == "test-challenge"


@pytest.mark.asyncio
async def test_fetch_html_raises_browser_error_on_bad_status(monkeypatch):
    stealth_inst = _build_mock_chain(html="<html></html>", status=500)
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.Stealth",
        lambda: stealth_inst,
    )
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.async_playwright",
        lambda: MagicMock(),
    )

    with pytest.raises(BrowserError) as exc_info:
        await StealthBrowser().fetch_html(
            "https://example.com",
            correlation_id="test-status",
        )

    assert "500" in str(exc_info.value)
    assert exc_info.value.correlation_id == "test-status"


@pytest.mark.asyncio
async def test_fetch_html_raises_browser_error_on_cf_block(monkeypatch):
    block_html = (
        "<html><head><title>Access Denied</title></head>"
        "<body><h1>Sorry, you have been blocked</h1>"
        "<p>You are unable to access this site.</p></body></html>"
    )
    stealth_inst = _build_mock_chain(html=block_html, status=200)
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.Stealth",
        lambda: stealth_inst,
    )
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.async_playwright",
        lambda: MagicMock(),
    )

    with pytest.raises(BrowserError) as exc_info:
        await StealthBrowser().fetch_html(
            "https://example.com",
            correlation_id="test-block",
        )

    assert "block" in str(exc_info.value).lower()
    assert exc_info.value.correlation_id == "test-block"


@pytest.mark.asyncio
async def test_fetch_html_raises_browser_error_on_cf_block_multiline(monkeypatch):
    """Verify _CF_BLOCK_RE matches across newlines (re.DOTALL)."""
    block_html = (
        "<html><body>\n"
        "<div>Cloudflare Ray ID: 9f2e291af9b608e6</div>\n"
        "<div>You have been blocked</div>\n"
        "</body></html>"
    )
    stealth_inst = _build_mock_chain(html=block_html, status=200)
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.Stealth",
        lambda: stealth_inst,
    )
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.async_playwright",
        lambda: MagicMock(),
    )

    with pytest.raises(BrowserError) as exc_info:
        await StealthBrowser().fetch_html(
            "https://example.com",
            correlation_id="test-block-multiline",
        )

    assert "block" in str(exc_info.value).lower()
    assert exc_info.value.correlation_id == "test-block-multiline"


@pytest.mark.asyncio
async def test_fetch_html_raises_browser_error_on_empty_html(monkeypatch):
    stealth_inst = _build_mock_chain(html="", status=200)
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.Stealth",
        lambda: stealth_inst,
    )
    monkeypatch.setattr(
        "crawler.src.browser.stealth_browser.async_playwright",
        lambda: MagicMock(),
    )

    with pytest.raises(BrowserError) as exc_info:
        await StealthBrowser().fetch_html(
            "https://example.com",
            correlation_id="test-empty",
        )

    assert "empty" in str(exc_info.value).lower()
    assert exc_info.value.correlation_id == "test-empty"
