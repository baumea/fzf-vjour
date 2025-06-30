#!/bin/sh

set -eu

err() {
  echo "❌ $1" >/dev/tty
}

if [ -z "${FZF_VJOUR_USE_EXPORTED:-}" ]; then
  # Read configuration
  CONFIGFILE="$HOME/.config/fzf-vjour/config"
  if [ ! -f "$CONFIGFILE" ]; then
    err "Configuration '$CONFIGFILE' not found."
    exit 1
  fi
  # shellcheck source=/dev/null
  . "$CONFIGFILE"
  if [ -z "${ROOT:-}" ] || [ -z "${SYNC_CMD:-}" ] || [ -z "${COLLECTION_LABELS:-}" ]; then
    err "Configuration is incomplete."
    exit 1
  fi
  export ROOT
  export SYNC_CMD
  export COLLECTION_LABELS

  # Tools
  if command -v "fzf" >/dev/null; then
    FZF="fzf"
  else
    err "Did not find the command-line fuzzy finder fzf."
    exit 1
  fi
  export FZF

  if command -v "uuidgen" >/dev/null; then
    UUIDGEN="uuidgen"
  else
    err "Did not find the uuidgen command."
    exit 1
  fi
  export UUIDGEN

  if command -v "bat" >/dev/null; then
    CAT="bat"
  elif command -v "batcat" >/dev/null; then
    CAT="batcat"
  fi
  CAT=${CAT:+$CAT --color=always --style=numbers --language=md}
  CAT=${CAT:-cat}
  export CAT

  ### AWK SCRIPTS
  AWK_ALTERTODO=$(
    cat <<'EOF'
@@include src/awk/altertodo.awk
EOF
  )
  export AWK_ALTERTODO

  AWK_EXPORT=$(
    cat <<'EOF'
@@include src/awk/export.awk
EOF
  )
  export AWK_EXPORT

  AWK_GET=$(
    cat <<'EOF'
@@include src/awk/get.awk
EOF
  )
  export AWK_GET

  AWK_LIST=$(
    cat <<'EOF'
@@include src/awk/list.awk
EOF
  )
  export AWK_LIST

  AWK_NEW=$(
    cat <<'EOF'
@@include src/awk/new.awk
EOF
  )
  export AWK_NEW

  AWK_UPDATE=$(
    cat <<'EOF'
@@include src/awk/update.awk
EOF
  )
  export AWK_UPDATE
  ### END OF AWK SCRIPTS
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
  echo "  --open                 Show open tasks only"
  echo "  --no-open              Ignore open tasks"
  echo "  --new                  Create new entry"
  exit
fi

# Command line arguments to be self-contained
# Generate preview of file from selection
if [ "${1:-}" = "--preview" ]; then
  name=$(echo "$2" | cut -d ' ' -f 3)
  file="$ROOT/$name"
  awk -v field="DESCRIPTION" "$AWK_GET" "$file" |
    $CAT
  exit
fi
# Delete file from selection
if [ "${1:-}" = "--delete" ]; then
  name=$(echo "$2" | cut -d ' ' -f 3)
  file="$ROOT/$name"
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$file")
  while true; do
    printf "Do you want to delete the entry with the title \"%s\"? (yes/no): " "$summary" >/dev/tty
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
  collection=$(echo "$COLLECTION_LABELS" | tr ';' '\n' | $FZF --delimiter='=' --with-nth=2 --accept-nth=1)
  file=""
  while [ -f "$file" ] || [ -z "$file" ]; do
    uuid=$($UUIDGEN)
    file="$ROOT/$collection/$uuid.ics"
  done
  tmpmd=$(mktemp --suffix='.md')
  {
    echo "::: |> <!-- keep this line to associate the entry to _today_ -->"
    echo "::: <| <!-- specify the due date for to-dos, can be empty, a date string, or even \"next Sunday\" -->"
    echo "# <!-- write summary here -->"
    echo "> <!-- comma-separated list of categories -->"
    echo ""
  } >"$tmpmd"
  checksum=$(cksum "$tmpmd")

  # Open in editor
  $EDITOR "$tmpmd" >/dev/tty

  # Update if changes are detected
  if [ "$checksum" != "$(cksum "$tmpmd")" ]; then
    tmpfile="$tmpmd.ics"
    awk -v uid="$uuid" "$AWK_NEW" "$tmpmd" >"$tmpfile"
    mv "$tmpfile" "$file"
  fi
  rm "$tmpmd"
fi
# Toggle completed flag
if [ "${1:-}" = "--toggle-completed" ]; then
  name=$(echo "$2" | cut -d ' ' -f 3)
  file="$ROOT/$name"
  tmpfile=$(mktemp)
  awk "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
fi
# Increase priority
if [ "${1:-}" = "--increase-priority" ]; then
  name=$(echo "$2" | cut -d ' ' -f 3)
  file="$ROOT/$name"
  tmpfile=$(mktemp)
  awk -v delta="1" "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
fi
# Decrease priority
if [ "${1:-}" = "--decrease-priority" ]; then
  name=$(echo "$2" | cut -d ' ' -f 3)
  file="$ROOT/$name"
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
if [ "${1:-}" = "--open" ]; then
  query="🔲"
fi
if [ "${1:-}" = "--no-open" ]; then
  query="!🔲"
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
query=${query:-!✅}
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
fi
rm "$filetmp"

exec "$0"
