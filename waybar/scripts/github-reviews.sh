#!/usr/bin/env bash
set -u

count=$(gh api -X GET search/issues \
  -f q='is:open is:pr user-review-requested:@me archived:false' \
  --jq '.total_count' 2>/dev/null)

if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -le 0 ]; then
  echo '{"text":"","tooltip":"No PR reviews requested","class":"empty"}'
  exit 0
fi

printf '{"text":" %s","tooltip":"%s PR review(s) requested","class":"has-reviews"}\n' "$count" "$count"
