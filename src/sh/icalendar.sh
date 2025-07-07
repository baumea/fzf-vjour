# Interface to modify iCalendar files

# Wrapper to add entry from markdown file
#
# @input $1: path to markdown file
# @input $2: collection to add to
__add_from_md() {
  tmpmd="$1"
  shift
  collection="$1"
  shift
  file=""
  while [ -f "$file" ] || [ -z "$file" ]; do
    uuid=$($UUIDGEN)
    file="$ROOT/$collection/$uuid.ics"
  done
  tmpfile="$tmpmd.ics"
  if awk -v uid="$uuid" "$AWK_NEW" "$tmpmd" >"$tmpfile"; then
    if [ ! -d "$ROOT/$collection" ]; then
      mkdir -p "$ROOT/$collection"
    fi
    mv "$tmpfile" "$file"
    if [ -n "${GIT:-}" ]; then
      $GIT add "$file"
      $GIT commit -q -m "File added" -- "$file"
    fi
  else
    rm -f "$tmpfile"
    err "Failed to create new entry."
  fi
  rm "$tmpmd"
}

# Noninteractively add note, and fill description from stdin
#
# @input $1: Collection
# @input $2: Summary
__add_note() {
  collection="$1"
  shift
  summary="$1"
  shift
  tmpmd=$(mktemp --suffix='.md')
  {
    echo "# $summary"
    echo ""
  } >"$tmpmd"
  if [ ! -t 0 ]; then
    cat /dev/stdin >>"$tmpmd"
  fi
  __add_from_md "$tmpmd" "$collection"
}

# Noninteractively add task, and fill description from stdin
#
# @input $1: Collection
# @input $2: Summary
# @input $3: Due date (optional)
__add_task() {
  collection="$1"
  shift
  summary="$1"
  shift
  due="${1:-}"
  tmpmd=$(mktemp --suffix='.md')
  {
    echo "::: <| $due"
    echo "# $summary"
    echo ""
  } >"$tmpmd"
  if [ ! -t 0 ]; then
    cat /dev/stdin >>"$tmpmd"
  fi
  __add_from_md "$tmpmd" "$collection"
}

# Noninteractively add jounral, and fill description from stdin
#
# @input $1: Collection
# @input $2: Summary
__add_jour() {
  collection="$1"
  shift
  summary="$1"
  shift
  tmpmd=$(mktemp --suffix='.md')
  {
    echo "::: |> <!-- keep this line to associate the entry to _today_ -->"
    echo "# $summary"
    echo ""
  } >"$tmpmd"
  if [ ! -t 0 ]; then
    cat /dev/stdin >>"$tmpmd"
  fi
  __add_from_md "$tmpmd" "$collection"
}

# Toggle completed status of VTODO
#
# @input $1: Relative path to iCalendar file
__toggle_completed() {
  fname="$1"
  shift
  file="$ROOT/$fname"
  tmpfile=$(mktemp)
  awk "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "Completed toggle" -- "$file"
  fi
}

# Change priority of VTODO entry
#
# @input $1: Delta, can be any integer
# @input $2: Relative path to iCalendar file
__change_priority() {
  delta=$1
  shift
  fname="$1"
  shift
  file="$ROOT/$fname"
  tmpfile=$(mktemp)
  awk -v delta="$delta" "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "Priority changed by $delta" -- "$file"
  fi
}

# Edit file
#
# @input $1: File path
__edit() {
  file="$1"
  shift
  tmpmd=$(mktemp --suffix='.md')
  due=$(awk -v field="DUE" -v format="date" "$AWK_GET" "$file")
  if [ -n "$due" ]; then
    echo "::: <| $due" >"$tmpmd"
  fi
  {
    echo "# $(awk -v field="SUMMARY" -v oneline=1 "$AWK_GET" "$file")"
    echo "> $(awk -v field="CATEGORIES" -v format="csv" -v oneline=1 "$AWK_GET" "$file")"
    echo ""
    awk -v field="DESCRIPTION" "$AWK_GET" "$file"
  } >>"$tmpmd"
  checksum=$(cksum "$tmpmd")

  # Open in editor
  $EDITOR "$tmpmd" >/dev/tty

  # Update only if changes are detected
  while [ "$checksum" != "$(cksum "$tmpmd")" ]; do
    tmpfile="$tmpmd.ics"
    if awk "$AWK_UPDATE" "$tmpmd" "$file" >"$tmpfile"; then
      mv "$tmpfile" "$file"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$file"
        $GIT commit -q -m "File modified" -- "$file"
      fi
      break
    else
      rm -f "$tmpfile"
      err "Failed to update entry. Press <enter> to continue."
      read -r tmp
      # Re-open in editor
      $EDITOR "$tmpmd" >/dev/tty
    fi
  done
  rm "$tmpmd"
}

# Delete file
#
# @input $1: File path
__delete() {
  file="$1"
  shift
  summary=$(awk -v field="SUMMARY" "$AWK_GET" "$file")
  while true; do
    printf "Do you want to delete the entry with the title \"%s\"? (yes/no): " "$summary" >/dev/tty
    read -r yn
    case $yn in
    "yes")
      rm -v "$file"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$file"
        $GIT commit -q -m "File deleted" -- "$file"
      fi
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
}

# Add file
__new() {
  collection=$(printf "%s" "$COLLECTION_LABELS" |
    tr ';' '\n' |
    $FZF \
      --ansi \
      --prompt="Choose collection> " \
      --select-1 \
      --no-sort \
      --tac \
      --margin="30%,30%" \
      --delimiter='=' \
      --border=bold \
      --border-label="Collections" \
      --with-nth=2 \
      --accept-nth=1 || true)
  if [ -z "$collection" ]; then
    return
  fi
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
  while [ "$checksum" != "$(cksum "$tmpmd")" ]; do
    tmpfile="$tmpmd.ics"
    if awk -v uid="$uuid" "$AWK_NEW" "$tmpmd" >"$tmpfile"; then
      if [ ! -d "$ROOT/$collection" ]; then
        mkdir -p "$ROOT/$collection"
      fi
      mv "$tmpfile" "$file"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$file"
        $GIT commit -q -m "File added" -- "$file"
      fi
      break
    else
      rm -f "$tmpfile"
      err "Failed to create new entry. Press <enter> to continue."
      read -r tmp
      # Re-open in editor
      $EDITOR "$tmpmd" >/dev/tty
    fi
  done
  rm "$tmpmd"
}
