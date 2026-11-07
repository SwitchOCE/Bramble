"""Throwaway steering test (issue 19): token totals and the last message from a transcript."""

import json
import sys

path, mode = sys.argv[1], sys.argv[2]
totals = {"input": 0, "output": 0, "cache_read": 0, "cache_write": 0}
seen = set()
last = ""
with open(path, encoding="utf-8") as transcript:
    for line in transcript:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("type") != "assistant":
            continue
        message = entry.get("message") or {}
        usage = message.get("usage") or {}
        if message.get("id") not in seen:
            seen.add(message.get("id"))
            totals["input"] += usage.get("input_tokens", 0)
            totals["output"] += usage.get("output_tokens", 0)
            totals["cache_read"] += usage.get("cache_read_input_tokens", 0)
            totals["cache_write"] += usage.get("cache_creation_input_tokens", 0)
        text = "".join(
            part.get("text", "")
            for part in message.get("content") or []
            if isinstance(part, dict) and part.get("type") == "text"
        )
        if text:
            last = text
print(f"tokens: {totals} over {len(seen)} calls")
if mode == "full":
    print(f"last message, {len(last)} characters:\n{last}")
