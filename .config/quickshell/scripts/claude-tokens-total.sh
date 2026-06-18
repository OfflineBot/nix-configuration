#!/bin/sh
# All-time Claude Code token total, computed locally from every transcript in
# ~/.claude/projects/**.jsonl (sum of input + output + cache read/write tokens
# across all assistant messages ever). ~1.5s over a few hundred MB.
#
# Output (one JSON line):  {"ok":true,"total":<tokens>,"msgs":<n>}

set -eu

dir="$HOME/.claude/projects"
[ -d "$dir" ] || { echo '{"ok":false}'; exit 0; }

find "$dir" -name '*.jsonl' 2>/dev/null | xargs cat 2>/dev/null | jq -r '
    select(.type == "assistant" and (.message.usage != null))
    | (.message.usage
        | (.input_tokens // 0)
        + (.output_tokens // 0)
        + (.cache_creation_input_tokens // 0)
        + (.cache_read_input_tokens // 0))
  ' 2>/dev/null | awk '
    { t += $1; n++ }
    END { printf "{\"ok\":true,\"total\":%d,\"msgs\":%d}\n", t+0, n+0 }'
