#!/bin/sh

set -eu

err() {
  echo "❌ $1" >/dev/tty
}

if [ -z "${FZF_VJOUR_USE_EXPORTED:-}" ]; then
  # Read configuration
  . "sh/config.sh"

  # Load awk scripts
  . "sh/awkscripts.sh"

  FZF_VJOUR_USE_EXPORTED="yes"
  export FZF_VJOUR_USE_EXPORTED
fi

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

# Git
. "sh/cligit.sh"

# Command line arguments: Interal use
. "sh/cli.sh"

# Command line arguments: Interal use
. "sh/cliinternal.sh"

while [ -n "${1:-}" ]; do
  case "${1:-}" in
  "--completed")
    shift
    cliquery="${cliquery:-} ✅"
    ;;
  "--no-completed")
    shift
    cliquery="${cliquery:-} !✅"
    ;;
  "--open")
    shift
    cliquery="${cliquery:-} 🔲"
    ;;
  "--no-open")
    shift
    cliquery="${cliquery:-} !🔲"
    ;;
  "--tasks")
    shift
    cliquery="${cliquery:-} ✅ | 🔲"
    ;;
  "--no-tasks")
    shift
    cliquery="${cliquery:-} !✅ !🔲"
    ;;
  "--notes")
    shift
    cliquery="${cliquery:-} 🗒️"
    ;;
  "--no-notes")
    shift
    cliquery="${cliquery:-} !🗒️"
    ;;
  "--journal")
    shift
    cliquery="${cliquery:-} 📘"
    ;;
  "--no-journal")
    shift
    cliquery="${cliquery:-} !📘"
    ;;
  "--filter")
    shift
    cliquery="${cliquery:-} $1"
    shift
    ;;
  "--no-filter")
    shift
    cliquery="${cliquery:-} !$1"
    shift
    ;;
  *)
    err "Unknown option \"$1\""
    exit 1
    ;;
  esac
done
query=${cliquery:-${FZF_QUERY:-!✅}}
query=$(echo "$query" | sed "s/^ *//" | sed "s/ *$//")

selection=$(
  __lines | $FZF --ansi \
    --query="$query " \
    --no-sort \
    --no-hscroll \
    --ellipsis='' \
    --with-nth=4.. \
    --accept-nth=3 \
    --preview="$0 --preview {}" \
    --bind="ctrl-r:reload-sync($0 --reload)" \
    --bind="ctrl-alt-d:become($0 --delete {})" \
    --bind="ctrl-x:become($0 --toggle-completed {})" \
    --bind="alt-up:become($0 --increase-priority {})" \
    --bind="alt-down:become($0 --decrease-priority {})" \
    --bind="ctrl-n:become($0 --new)" \
    --bind="alt-0:change-query(!✅)" \
    --bind="alt-1:change-query(📘)" \
    --bind="alt-2:change-query(🗒️)" \
    --bind="alt-3:change-query(✅ | 🔲)" \
    --bind="ctrl-s:execute($SYNC_CMD ; printf 'Press <enter> to continue.'; read -r tmp)"
)
if [ -z "$selection" ]; then
  return 0
fi

file="$ROOT/$selection"

if [ ! -f "$file" ]; then
  echo "ERROR: File '$file' does not exist!" >/dev/tty
  return 1
fi

# Prepare file to be edited
filetmp=$(mktemp --suffix='.md')
awk "$AWK_EXPORT" "$file" >"$filetmp"
checksum=$(cksum "$filetmp")

# Open in editor
$EDITOR "$filetmp" >/dev/tty

# Update only if changes are detected
if [ "$checksum" != "$(cksum "$filetmp")" ]; then
  file_new="$filetmp.ics"
  awk "$AWK_UPDATE" "$filetmp" "$file" >"$file_new"
  mv "$file_new" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "File modified" -- "$file"
  fi
fi
rm "$filetmp"

exec "$0"
