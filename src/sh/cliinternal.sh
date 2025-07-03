# Command-line interface for internal use only

# Generate preview of file from selection
if [ "${1:-}" = "--preview" ]; then
  shift
  name="$1"
  shift
  file="$ROOT/$name"
  awk -v field="DESCRIPTION" "$AWK_GET" "$file" |
    $CAT
  exit
fi

# Reload view
if [ "${1:-}" = "--reload" ]; then
  shift
  case "${1:-}" in
  "--toggle-completed")
    shift
    fname="$1"
    shift
    __toggle_completed "$fname" >/dev/null
    ;;
  "--change-priority")
    shift
    delta=$1
    shift
    fname="$1"
    shift
    __change_priority "$delta" "$fname" >>/tmp/foo
    ;;
  esac
  __lines
  exit
fi
