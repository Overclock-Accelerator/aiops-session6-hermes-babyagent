---
name: tavily_research
description: Run a research query via Tavily and get a synthesized, cited answer. Use when the user asks about current events, facts, or anything that benefits from web sources.
---
# tavily_research

Runs a real research query against Tavily's search API and returns a synthesized answer with sources.

**Inputs:** `query` (string, required) — the research question in natural language.

**Requires:** `TAVILY_API_KEY`. It is normally already in the container's environment; if it isn't, check `/opt/data/secrets.env`. If neither has it, ask the user for a key (free at https://tavily.com), store it with set_secret as `TAVILY_API_KEY`, then retry.

**Run** (substitute the user's question for `<query>`; the query goes in as an environment variable so quotes in it can't break the command):

```
set -a; [ -f /opt/data/secrets.env ] && . /opt/data/secrets.env; set +a
QUERY='<query>' python3 - <<'PY'
import json, os, sys, urllib.request
key = os.environ.get("TAVILY_API_KEY")
if not key:
    sys.exit("ERROR: TAVILY_API_KEY is not set")
req = urllib.request.Request(
    "https://api.tavily.com/search",
    data=json.dumps({"query": os.environ["QUERY"], "include_answer": True, "max_results": 5}).encode(),
    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
)
try:
    data = json.load(urllib.request.urlopen(req, timeout=60))
except Exception as e:
    sys.exit(f"ERROR calling Tavily: {e}")
print(data.get("answer") or "(no synthesized answer)")
results = data.get("results", [])[:5]
if results:
    print("\nSources:")
    for i, r in enumerate(results, 1):
        print(f"[{i}] {r['title']} — {r['url']}")
PY
```

**Returns:** the synthesized answer followed by the numbered sources. If the output is an error (missing/invalid key, quota), tell the user exactly that.
