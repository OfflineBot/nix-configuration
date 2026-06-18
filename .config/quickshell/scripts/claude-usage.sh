#!/bin/sh
# Real Claude usage limits — the same data the in-app `/usage` shows.
#
# Reads the OAuth access token from ~/.claude/.credentials.json AT RUNTIME (it is
# never written anywhere, so this repo stays safe to push) and queries the
# internal endpoint /api/oauth/usage. The token is handed to curl via a config
# file on stdin (`-K -`), so it never appears in the process list / `ps`.
#
# Note: this is an UNDOCUMENTED endpoint — it may change/break on Claude updates.
# Output (one JSON line); ok=false on any failure (no token, expired, network…):
#   {"ok":true,"session":4,"session_resets":"…","week":6,"week_resets":"…",
#    "opus":null,"sonnet":0}

set -eu

cred="$HOME/.claude/.credentials.json"
[ -f "$cred" ] || { echo '{"ok":false}'; exit 0; }

tok=$(jq -r '.claudeAiOauth.accessToken // .accessToken // empty' "$cred" 2>/dev/null || true)
[ -n "$tok" ] || { echo '{"ok":false}'; exit 0; }

resp=$(printf 'header = "Authorization: Bearer %s"\n' "$tok" \
  | curl -sS -m 12 -K - \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "anthropic-version: 2023-06-01" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null || true)

[ -n "$resp" ] || { echo '{"ok":false}'; exit 0; }

echo "$resp" | jq -c '
  if (.five_hour != null or .seven_day != null) then {
    ok: true,
    session:        (.five_hour.utilization  // null),
    session_resets: (.five_hour.resets_at    // null),
    week:           (.seven_day.utilization   // null),
    week_resets:    (.seven_day.resets_at     // null),
    opus:           (.seven_day_opus.utilization   // null),
    sonnet:         (.seven_day_sonnet.utilization // null)
  } else {ok:false} end
' 2>/dev/null || echo '{"ok":false}'
