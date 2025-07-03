#!/bin/sh

set -eu

# Helper functions
. "sh/helper.sh"

# Read configuration
. "sh/config.sh"

# Load awk scripts
. "sh/awkscripts.sh"

__lines() {
  find "$ROOT" -type f -name '*.ics' -print0 | xargs -0 -P 0 \
    awk \
    -v collection_labels="$COLLECTION_LABELS" \
    -v flag_open="🔲" \
    -v flag_completed="✅" \
    -v flag_journal="📘" \
    -v flag_note="🗒️" \
    "$AWK_LIST" |
    sort -g -r
}

# Program starts here
if [ "${1:-}" = "--help" ]; then
  shift
  echo "Usage: $0 [--help | --new [FILTER..] | [FILTER..] ]
  --help                 Show this help and exit
  --new                  Create new entry and do not exit
  --git-init             Activate git usage and exit
  --git <cmd>            Run git command and exit

[FILTER]
  You may specify any of these filters. Filters can be negated using the
  --no-... versions, e.g., --no-tasks. Multiple filters are applied in
  conjuction. By default, the filter --no-completed is used. Note that
  --no-completed is not the same as --open, and similarly, --no-open is not the
  same as --completed.

  --tasks                 Show tasks only
  --notes                 Show notes only
  --journal               Show jounral only
  --completed             Show completed tasks only
  --open                  Show open tasks only
  --filter <query>        Specify custom query"
  exit
fi

# iCalendar routines
. "sh/icalendar.sh"

# Command line arguments: Interal use
. "sh/cliinternal.sh"

# Command line arguments: Interal use
. "sh/cli.sh"

while true; do
  query=$(stripws "$query")
  selection=$(
    __lines | $FZF --ansi \
      --query="$query " \
      --no-sort \
      --no-hscroll \
      --with-nth=5.. \
      --print-query \
      --accept-nth=4 \
      --preview="$0 --preview {4}" \
      --expect="ctrl-n,ctrl-alt-d" \
      --bind="ctrl-r:reload($0 --reload)" \
      --bind="ctrl-x:reload($0 --reload --toggle-completed {4})" \
      --bind="alt-up:reload($0 --reload --change-priority '+1' {4})" \
      --bind="alt-down:reload($0 --reload --change-priority '-1' {4})" \
      --bind="alt-0:change-query(!✅)" \
      --bind="alt-1:change-query(📘)" \
      --bind="alt-2:change-query(🗒️)" \
      --bind="alt-3:change-query(✅ | 🔲)" \
      --bind='focus:transform:[ {3} = "VTODO" ] && echo "rebind(ctrl-x)+rebind(alt-up)+rebind(alt-down)" || echo "unbind(ctrl-x)+unbind(alt-up)+unbind(alt-down)"' \
      --bind="ctrl-s:execute($SYNC_CMD ; printf 'Press <enter> to continue.'; read -r tmp)"
  )

  # Line 1: query
  # Line 2: key ("" for enter)
  # Line 3: relative file path
  query=$(echo "$selection" | head -n 1)
  key=$(echo "$selection" | head -n 2 | tail -n 1)
  fname=$(echo "$selection" | head -n 3 | tail -n 1)
  if [ "$fname" = "$key" ]; then
    fname=""
  fi

  file="$ROOT/$fname"
  if [ ! -f "$file" ]; then
    err "File '$file' does not exist!"
    return 1
  fi

  case "$key" in
  "ctrl-n")
    __new
    ;;
  "ctrl-alt-d")
    __delete "$file"
    ;;
  *)
    __edit "$file"
    ;;
  esac
done
