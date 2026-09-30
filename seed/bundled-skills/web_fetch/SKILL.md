---
name: web_fetch
description: Fetch the text content of a public URL as clean readable text. No API key required. Use when the user asks you to read or summarize a specific page, article, or video page.
---
# web_fetch

Fetches the text content of a public URL via [r.jina.ai](https://r.jina.ai), which returns clean readable text for almost any page (including YouTube pages with their auto-generated transcript).

**Inputs:** `url` (string, required) — the full URL, including `https://`.

**Run:**

```
curl -sSL --max-time 30 -H 'Accept: text/plain' "https://r.jina.ai/<url>" | head -c 8000
```

**Returns:** the page text, truncated to 8000 characters. If the output hit the limit, say it was truncated. If curl fails or returns an error, report the error to the user instead of guessing at the page's contents.
