case "${1:-}" in
"--git-init")
  shift
  if [ -n "${GIT:-}" ]; then
    err "Git already enabled"
    return 1
  fi
  if ! command -v "git" >/dev/null; then
    err "Git not installed"
    return 1
  fi
  git -C "$ROOT" init
  git -C "$ROOT" add -A
  git -C "$ROOT" commit -m 'Initial commit: Start git tracking'
  exit
  ;;
"--git")
  shift
  if [ -z "${GIT:-}" ]; then
    err "Git not supported, run \`$0 --git-init\` first"
    return 1
  fi
  $GIT "$@"
  exit
  ;;
"--new")
  shift
  __new
  export next_filter=1
  ;;
"--list")
  shift
  export next_filter=1
  export list_option=1
  ;;
esac

if [ -z "${next_filter:-}" ]; then
  # else [FILTER] are the next options
  # Here, we have --add-xyz with --collection or nothign
  case "${1:-}" in
  "--add-note" | "--add-task" | "--add-jour" | "--collection")
    noninteractive=1
    ;;
  esac
  if [ -n "${noninteractive:-}" ]; then
    while [ -n "${1:-}" ]; do
      case "$1" in
      "--add-note" | "--add-task" | "--add-jour")
        if [ -n "${add_option:-}" ]; then
          err "What do you want to add?"
          exit 1
        fi
        add_option="$1"
        shift
        summary=${1-}
        if [ -z "$summary" ]; then
          err "You did not give a summary"
          exit 1
        fi
        shift
        if [ "$add_option" = "--add-task" ] && [ -n "${1:-}" ]; then
          case "$1" in
          "--"*)
            continue
            ;;
          *)
            due=$(printf "%s" "$1" | tr -dc "[:alnum:][:blank:]")
            shift
            if [ -z "$due" ] || ! date -d "$due" >/dev/null 2>&1; then
              err "Invalid due date"
              exit 1
            fi
            ;;
          esac
        fi
        ;;
      "--collection")
        shift
        collection="$(printf "%s" "$COLLECTION_LABELS" |
          cut -d ";" -f "${1:-}" 2>/dev/null |
          cut -d "=" -f 1 2>/dev/null)"
        if [ -z "$collection" ]; then
          err "Invalid collection"
          exit 1
        fi
        shift
        ;;
      *)
        err "Unknown non-interactive option: $1"
        exit 1
        ;;
      esac
    done
  fi
fi

if [ -n "${noninteractive:-}" ]; then
  if [ -z "${add_option:-}" ]; then
    err "Specified collection, but nothing to add"
    exit 1
  fi
  if [ -z "${collection:-}" ]; then
    collection="$(
      printf "%s" "$COLLECTION_LABELS" |
        cut -d ";" -f 1 |
        cut -d "=" -f 1
    )"
  fi
  case "$add_option" in
  "--add-note")
    __add_note "$collection" "$summary"
    ;;
  "--add-task")
    __add_task "$collection" "$summary" "${due:-}"
    ;;
  "--add-jour")
    __add_jour "$collection" "$summary"
    ;;
  esac
  exit 0
fi
