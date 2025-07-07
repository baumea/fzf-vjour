# Add attachment to iCalendar file
#
# @input $1: Path to iCalendar file
__add_attachment() {
  file="$1"
  shift
  sel=$(
    $FZF \
      --ansi \
      --prompt="Select attachment> " \
      --walker="file,hidden" \
      --walker-root="$HOME" \
      --expect="ctrl-c,ctrl-g,ctrl-q,esc"
  )
  key=$(echo "$sel" | head -1)
  f=$(echo "$sel" | tail -1)
  if [ -n "$key" ]; then
    f=""
  fi
  if [ -z "$f" ] || [ ! -f "$f" ]; then
    return
  fi
  filename=$(basename "$f")
  mime=$(file -b -i "$f" | cut -d ';' -f 1)
  if [ -z "$mime" ]; then
    mime="application/octet-stream"
  fi
  fenc=$(mktemp)
  base64 "$f" >"$fenc"
  filetmp=$(mktemp)
  awk -v file="$fenc" -v mime="$mime" -v filename="$filename" "$AWK_ATTACH" "$file" >"$filetmp"
  mv "$filetmp" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "Added attachment" -- "$file"
  fi
  rm "$fenc"
}

# Open attachment from iCalendar file
#
# @input $1: Attachment id
# @input $2: Attachment name
# @input $3: Attachment format
# @input $4: Attachment encoding
# @input $5: Path to iCalendar file
__open_attachment() {
  attid="$1"
  shift
  attname="$1"
  shift
  attfmt="$1"
  shift
  attenc="$1"
  shift
  file="$1"
  shift
  if [ "$attenc" != "base64" ]; then
    err "Unsupported attachment encoding: $attenc. Press <enter> to continue."
    read -r tmp
    return
  fi
  if [ -n "$attname" ]; then
    tmpdir=$(mktemp -d)
    attpath="$tmpdir/$attname"
  elif [ -n "$attfmt" ]; then
    attext=$(echo "$attfmt" | cut -d "/" -f 2)
    attpath=$(mktemp --suffix="$attext")
  else
    attpath=$(mktemp)
  fi
  # Get file and decode
  awk -v id="$attid" "$AWK_ATTACHDD" "$file" | base64 -d >"$attpath"
  fn=$(file "$attpath")
  while true; do
    printf "Are you sure you want to open \"%s\"? (yes/no): " "$fn" >/dev/tty
    read -r yn
    case $yn in
    "yes")
      $OPEN "$attpath"
      printf "Press <enter> to continue." >/dev/tty
      read -r tmp
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
  # Clean up
  rm -f "$attpath"
  if [ -n "${tmpdir:-}" ] && [ -d "${tmpdir:-}" ]; then
    rm -rf "$tmpdir"
  fi
}

# Delete attachment from iCalendar file
#
# @input $1: Attachment id
# @input $2: Path to iCalendar File
__del_attachment() {
  attid="$1"
  shift
  file="$1"
  shift
  while true; do
    printf "Are you sure you want to delete attachment \"%s\"? (yes/no): " "$attid" >/dev/tty
    read -r yn
    case $yn in
    "yes")
      filetmp=$(mktemp)
      awk -v id="$attid" "$AWK_ATTACHRM" "$file" >"$filetmp"
      mv "$filetmp" "$file"
      if [ -n "${GIT:-}" ]; then
        $GIT add "$file"
        $GIT commit -q -m "Deleted attachment" -- "$file"
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

# Show attachment window
#
# @input $1: Path to iCalendar file
__attachment_view() {
  file="$1"
  shift
  att=$(
    awk "$AWK_ATTACHLS" "$file" |
      $FZF \
        --ansi \
        --delimiter="\t" \
        --accept-nth=1,2,3,4 \
        --with-nth="Attachment {1}: \"{2}\" {3} ({5})" \
        --no-sort \
        --tac \
        --margin="30%,30%" \
        --border=bold \
        --border-label="Attachment View     Keys: <enter> open, <ctrl-alt-d> delete, <ctrl-a> add" \
        --expect="ctrl-a" \
        --expect="ctrl-c,ctrl-g,ctrl-q,ctrl-d,esc,q,backspace" \
        --print-query \
        --bind="start:hide-input" \
        --bind="ctrl-alt-d:show-input+change-query(ctrl-alt-d)+accept" \
        --bind='load:transform:[ "$FZF_TOTAL_COUNT" -eq 0 ] && echo "unbind(enter)+unbind(ctrl-alt-d)"' \
        --bind="w:toggle-wrap" \
        --bind="j:down" \
        --bind="k:up" ||
      true
  )
  key=$(echo "$att" | head -2 | xargs)
  sel=$(echo "$att" | tail -1)
  attid=$(echo "$sel" | cut -f 1)
  attname=$(echo "$sel" | cut -f 2)
  attfmt=$(echo "$sel" | cut -f 3)
  attenc=$(echo "$sel" | cut -f 4)
  case "$key" in
  "ctrl-c" | "ctrl-g" | "ctrl-q" | "ctrl-d" | "esc" | "q" | "backspace") ;;
  "ctrl-alt-d")
    __del_attachment "$attid" "$file"
    ;;
  "ctrl-a")
    __add_attachment "$file"
    ;;
  *)
    __open_attachment "$attid" "$attname" "$attfmt" "$attenc" "$file"
    ;;
  esac
  #
}
