# Generate new entry
if [ "${1:-}" = "--new" ]; then
  shift
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
fi
