# Command-line interface for internal use only

# Generate preview of file from selection
if [ "${1:-}" = "--preview" ]; then
  shift
  name=$(echo "$1" | cut -d ' ' -f 3)
  shift
  file="$ROOT/$name"
  awk -v field="DESCRIPTION" "$AWK_GET" "$file" |
    $CAT
  exit
fi

# Delete file from selection
if [ "${1:-}" = "--delete" ]; then
  shift
  name=$(echo "$1" | cut -d ' ' -f 3)
  shift
  file="$ROOT/$name"
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
fi

# Toggle completed flag
if [ "${1:-}" = "--toggle-completed" ]; then
  shift
  name=$(echo "$1" | cut -d ' ' -f 3)
  shift
  file="$ROOT/$name"
  tmpfile=$(mktemp)
  awk "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "Completed toggle" -- "$file"
  fi
fi

# Increase priority
if [ "${1:-}" = "--increase-priority" ]; then
  shift
  name=$(echo "$1" | cut -d ' ' -f 3)
  shift
  file="$ROOT/$name"
  tmpfile=$(mktemp)
  awk -v delta="1" "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "Priority increased" -- "$file"
  fi
fi

# Decrease priority
if [ "${1:-}" = "--decrease-priority" ]; then
  shift
  name=$(echo "$1" | cut -d ' ' -f 3)
  shift
  file="$ROOT/$name"
  tmpfile=$(mktemp)
  awk -v delta="-1" "$AWK_ALTERTODO" "$file" >"$tmpfile"
  mv "$tmpfile" "$file"
  if [ -n "${GIT:-}" ]; then
    $GIT add "$file"
    $GIT commit -q -m "Priority decreased" -- "$file"
  fi
fi

# Reload view
if [ "${1:-}" = "--reload" ]; then
  shift
  __lines
  exit
fi
