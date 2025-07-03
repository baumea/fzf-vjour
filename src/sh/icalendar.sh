# Interface to modify iCalendar files

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
  collection=$(printf "%s" "$COLLECTION_LABELS" | tr ';' '\n' | $FZF --delimiter='=' --with-nth=2 --accept-nth=1)
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
    if [ -n "${GIT:-}" ]; then
      $GIT add "$file"
      $GIT commit -q -m "File added" -- "$file"
    fi
  fi
  rm "$tmpmd"
}
