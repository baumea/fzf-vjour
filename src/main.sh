#!/bin/sh

set -eu

if [ ! "${SCRIPT_LOADED:-}" ]; then
  # Helper functions
  . "sh/helper.sh"
  # Read theme
  . "sh/theme.sh"
  # Read configuration
  . "sh/config.sh"
  # Load awk scripts
  . "sh/awkscripts.sh"
  # iCalendar routines
  . "sh/icalendar.sh"
  # Attachment handling
  . "sh/attachment.sh"
  # Categories handling
  . "sh/categories.sh"
  # Mark as loaded
  export SCRIPT_LOADED=1
fi

__lines() {
  find "$ROOT" -type f -name '*.ics' -print0 | xargs -0 -P 0 \
    awk \
    -v collection_labels="$COLLECTION_LABELS" \
    -v flag_open="$FLAG_OPEN" \
    -v flag_completed="$FLAG_COMPLETED" \
    -v flag_journal="$FLAG_JOURNAL" \
    -v flag_note="$FLAG_NOTE" \
    -v flag_priority="$FLAG_PRIORITY" \
    -v flag_attachment="$FLAG_ATTACHMENT" \
    -v style_collection="$STYLE_COLLECTION" \
    -v style_date="$STYLE_DATE" \
    -v style_summary="$STYLE_SUMMARY" \
    -v style_expired="$STYLE_EXPIRED" \
    -v style_category="$STYLE_CATEGORY" \
    "$AWK_LIST" |
    sort -g -r
}

# Program starts here
if [ "${1:-}" = "--help" ]; then
  bn="$(basename "$0")"
  shift
  echo "Usage: $bn [OPTION] [FILTER]...

[OPTION]
    --help                        Show this help and exit

  Git Integration:
    --git-init                    Activate git usage and exit
    --git <cmd>                   Run git command and exit

  Interactive Mode:
    --new [FILTER..]              Create new entry interactively and start
    [FILTER..]                    Start with the specified filter

  Non-Interactive Mode:
    --list [FILTER..]             List entries and exit
    --add-note <summary>          Read note from stdin and add it with the
                                  specified summary
    --add-task <summary> [<due>]  Read task from stdin and add it with the
                                  specified summary and optional due date
    --add-jour <summary>          Read journal from stdin and add it with the
                                  specified summary
    --collection <nr>             Select collection to which the note, task, or
                                  journal entry is added non-interactively. The
                                  argument <nr> is the ordinal describing the
                                  collection. It defaults to the starting value
                                  of 1.

[FILTER]
  You may specify any of these filters. Filters can be negated using the
  --no-... versions, e.g., --no-tasks. Multiple filters are applied in
  conjuction. By default, the filter --no-completed is used. Note that
  --no-completed is not the same as --open, and similarly, --no-open is not the
  same as --completed.

  --tasks                         Show tasks only
  --notes                         Show notes only
  --journal                       Show journal only
  --completed                     Show completed tasks only
  --open                          Show open tasks only
  --filter <query>                Specify custom query

Examples:
  $bn --git log
  $bn --new
  $bn --journal
  $bn --no-tasks --filter \"Beauregard\"
  $bn --list --open
  $bn --add-task \"Improve code to respect timezone information\" \"next month\"
  cat proof.tex | $bn --add-journal \"Proof of Fixed-point Theorem\" --collection 2
"
  exit
fi

# Command line arguments: Interal use
. "sh/cliinternal.sh"

# Command line arguments
. "sh/cli.sh"

# Parse command-line filter (if any)
. "sh/filter.sh"

if [ -n "${list_option:-}" ]; then
  __lines |
    $FZF \
      --filter="$query" \
      --no-sort \
      --with-nth=5.. |
    tac
  exit 0
fi

while true; do
  query=$(stripws "$query")
  selection=$(
    __lines | $FZF \
      --ansi \
      --query="$query " \
      --no-sort \
      --no-hscroll \
      --with-nth=5.. \
      --print-query \
      --accept-nth=4 \
      --preview="$0 --preview {4}" \
      --expect="ctrl-n,ctrl-alt-d,alt-v,ctrl-a,ctrl-t" \
      --bind="ctrl-r:reload($0 --reload)" \
      --bind="ctrl-x:reload($0 --reload --toggle-completed {4})" \
      --bind="alt-up:reload($0 --reload --change-priority '+1' {4})" \
      --bind="alt-down:reload($0 --reload --change-priority '-1' {4})" \
      --bind="alt-0:change-query(!$FLAG_COMPLETED )" \
      --bind="alt-1:change-query(${COLLECTION1:-} )" \
      --bind="alt-2:change-query(${COLLECTION2:-} )" \
      --bind="alt-3:change-query(${COLLECTION3:-} )" \
      --bind="alt-4:change-query(${COLLECTION4:-} )" \
      --bind="alt-5:change-query(${COLLECTION5:-} )" \
      --bind="alt-6:change-query(${COLLECTION6:-} )" \
      --bind="alt-7:change-query(${COLLECTION7:-} )" \
      --bind="alt-8:change-query(${COLLECTION8:-} )" \
      --bind="alt-9:change-query(${COLLECTION9:-} )" \
      --bind="alt-j:change-query($FLAG_JOURNAL )" \
      --bind="alt-n:change-query($FLAG_NOTE )" \
      --bind="alt-t:change-query($FLAG_COMPLETED | $FLAG_OPEN )" \
      --bind='focus:transform:[ {3} = "VTODO" ] && echo "rebind(ctrl-x)+rebind(alt-up)+rebind(alt-down)" || echo "unbind(ctrl-x)+unbind(alt-up)+unbind(alt-down)"' \
      --bind="alt-w:toggle-preview-wrap" \
      --bind="ctrl-d:preview-half-page-down" \
      --bind="ctrl-u:preview-half-page-up" \
      --bind="ctrl-s:execute($SYNC_CMD; [ -n \"${GIT:-}\" ] && ${GIT:-echo} add -A && ${GIT:-echo} commit -am 'Synchronized'; printf 'Press <enter> to continue.'; read -r tmp)" ||
      true
  )

  # Line 1: query
  # Line 2: key ("" for enter)
  # Line 3: relative file path
  lines=$(echo "$selection" | wc -l)
  if [ "$lines" -eq 1 ]; then
    return 0
  fi
  query=$(echo "$selection" | head -n 1)
  key=$(echo "$selection" | head -n 2 | tail -n 1)
  fname=$(echo "$selection" | head -n 3 | tail -n 1)
  file="$ROOT/$fname"

  case "$key" in
  "ctrl-n")
    __new
    ;;
  "ctrl-alt-d")
    __delete "$file"
    ;;
  "alt-v")
    $EDITOR "$file"
    ;;
  "ctrl-a")
    __attachment_view "$file"
    ;;
  "ctrl-t")
    cat="$(__select_category)"
    [ -n "$cat" ] && query="'$cat'"
    ;;
  "")
    __edit "$file"
    ;;
  esac
done
