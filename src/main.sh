#!/bin/sh

set -eu

# Read configuration
# shellcheck source=/dev/null
. "$HOME/.config/fzf-vjour/config"
if [ -z "$ROOT" ] || [ -z "$SYNC_CMD" ] || [ -z "$COLLECTION_LABELS" ]; then
  echo "Failed to get configuration." >/dev/tty
  exit 1
fi

### AWK SCRIPTS
AWK_ALTERTODO=$(
  cat <<'EOF'
@@include src/awk/altertodo.awk
EOF
)

AWK_EXPORT=$(
  cat <<'EOF'
@@include src/awk/export.awk
EOF
)

AWK_GET=$(
  cat <<'EOF'
@@include src/awk/get.awk
EOF
)

AWK_LIST=$(
  cat <<'EOF'
@@include src/awk/list.awk
EOF
)

AWK_NEW=$(
  cat <<'EOF'
@@include src/awk/new.awk
EOF
)

AWK_UPDATE=$(
  cat <<'EOF'
@@include src/awk/update.awk
EOF
)
### END OF AWK SCRIPTS

__lines() {
  find "$ROOT" -type f -name '*.ics' -print0 | xargs -0 -P 0 \
    awk \
    -v collection_labels="$COLLECTION_LABELS" \
    -v flag_open="🔲" \
    -v flag_completed="✅" \
    -v flag_journal="📘" \
    -v flag_note="🗒️" \
    "$AWK_LIST" |
    sort -g -r |
    cut -d ' ' -f 3-
}

__filepath_from_selection() {
  echo "$1" | grep -o ' \{50\}.*$' | xargs
}

# Program starts here
if [ "${1:-}" = "--help" ]; then
  echo "Usage: $0 [OPTION]"
  echo ""
  echo "You may specify at most one option."
  echo "  --help                 Show this help and exit"
  echo "  --tasks                Show tasks only"
  echo "  --no-tasks             Ignore tasks"
  echo "  --notes                Show notes only"
  echo "  --no-notes             Ignore notes"
  echo "  --journal              Show journal only"
  echo "  --no-journal           Ignore journal"
  echo "  --completed            Show completed tasks only"
  echo "  --no-completed         Ignore completed tasks"
  echo "  --new                  Create new entry"
  echo ""
  echo "The following options are for internal use."
  echo "  --reload                            Reload list"
  echo "  --preview <selection>               Generate preview"
  echo "  --delete <selection>                Delete selected entry"
  echo "  --decrease-priority <selection>     Decrease priority of selected task"
  echo "  --increase-priority <selection>     Increase priority of selected task"
  echo "  --toggle-completed <selection>      Toggle completion flag of task"
  exit
fi

# Command line arguments to be self-contained
# Generate preview of file from selection
if [ "${1:-}" = "--preview" ]; then
  file=$(__filepath_from_selection "$2")
  awk -v field="DESCRIPTION" "$AWK_GET" "$file" |
    batcat --color=always --style=numbers --language=md
  exit
fi
# Delete file from selection
if [ "${1:-}" = "--delete" ]; then
  file=$(__filepath_from_selection "$2")
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$file")
  while true; do
    printf "Do you want to delete the entry with the title \"%s\"? " "$summary" >/dev/tty
    read -r yn
    case $yn in
    "yes")
      rm -v "$file"
      break
      ;;
    "no")
      break
      ;;
    *)
      echo "Please answer \"yes\" or \"no\"." >/dev/tty
      ;;
    esac
  done
fi
# Generate new entry
if [ "${1:-}" = "--new" ]; then
  label=$(printf "%s" "$COLLECTION_LABELS" |
    awk 'BEGIN { FS="="; RS=";"; } {print $2}' |
    fzf \
      --margin 20% \
      --prompt="Select collection> ")

  collection=$(printf "%s" "$COLLECTION_LABELS" |
    awk -v label="$label" 'BEGIN { FS="="; RS=";"; } $2 == label {print $1}')
  file=""
  while [ -f "$file" ] || [ -z "$file" ]; do
    uuid=$(uuidgen)
    file="$ROOT/$collection/$uuid.ics"
  done
  tmpmd=$(mktemp --suffix='.md')
  tmpsha="$tmpmd.sha"
  {
    echo "::: |> <!-- keep this line to associate the entry to _today_ -->"
    echo "::: <| <!-- specify the due date for to-dos, can be empty, a date string, or even \"next Sunday\" -->"
    echo "# <!-- write summary here -->"
    echo "> <!-- comma-separated list of categories -->"
    echo ""
  } >"$tmpmd"
  sha1sum "$tmpmd" >"$tmpsha"

  # Open in editor
  $EDITOR "$tmpmd" >/dev/tty

  # Update if changes are detected
  if ! sha1sum -c "$tmpsha" >/dev/null 2>&1; then
    tmpfile="$tmpmd.ics"
    awk -v uid="$uuid" "$AWK_NEW" "$tmpmd" >"$tmpfile"
    mv "$tmpfile" "$file"
  fi
  rm "$tmpmd" "$tmpsha"
fi
# Toggle completed flag
if [ "${1:-}" = "--toggle-completed" ]; then
  file=$(__filepath_from_selection "$2")
  tmpfile=$(mktemp)
  awk "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
fi
# Increase priority
if [ "${1:-}" = "--increase-priority" ]; then
  file=$(__filepath_from_selection "$2")
  tmpfile=$(mktemp)
  awk -v delta="1" "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
fi
# Decrease priority
if [ "${1:-}" = "--decrease-priority" ]; then
  file=$(__filepath_from_selection "$2")
  tmpfile=$(mktemp)
  awk -v delta="-1" "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
fi
if [ "${1:-}" = "--reload" ]; then
  __lines
  exit
fi

query="${FZF_QUERY:-}"
if [ "${1:-}" = "--no-completed" ]; then
  query="!✅"
fi
if [ "${1:-}" = "--completed" ]; then
  query="✅"
fi
if [ "${1:-}" = "--tasks" ]; then
  query="✅ | 🔲"
fi
if [ "${1:-}" = "--no-tasks" ]; then
  query="!✅ !🔲"
fi
if [ "${1:-}" = "--notes" ]; then
  query="🗒️"
fi
if [ "${1:-}" = "--no-notes" ]; then
  query="!🗒️"
fi
if [ "${1:-}" = "--journal" ]; then
  query="📘"
fi
if [ "${1:-}" = "--no-journal" ]; then
  query="!📘"
fi
if [ -z "$query" ]; then
  query="!✅"
fi
query=$(echo "$query" | sed 's/ *$//g')

selection=$(
  __lines | fzf --ansi \
    --query="$query " \
    --no-sort \
    --no-hscroll \
    --ellipsis='' \
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
    --bind="ctrl-s:execute($SYNC_CMD)"
)
if [ -z "$selection" ]; then
  return 0
fi

file=$(__filepath_from_selection "$selection")

if [ ! -f "$file" ]; then
  echo "ERROR: File '$file' does not exist!" >/dev/tty
  return 1
fi

# Prepare file to be edited
filetmp=$(mktemp --suffix='.md')
filesha="$filetmp.sha"
awk "$AWK_EXPORT" "$file" >"$filetmp"
sha1sum "$filetmp" >"$filesha"

# Open in editor
$EDITOR "$filetmp" >/dev/tty

# Update only if changes are detected
if ! sha1sum -c "$filesha" >/dev/null 2>&1; then
  echo "Uh... chages detected!" >/dev/tty
  file_new="$filetmp.ics"
  awk "$AWK_UPDATE" "$filetmp" "$file" >"$file_new"
  mv "$file_new" "$file"
fi
rm "$filetmp" "$filesha"

exec "$0"
