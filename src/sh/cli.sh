# Git
if [ "${1:-}" = "--git-init" ]; then
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
fi

if [ "${1:-}" = "--git" ]; then
  shift
  if [ -z "${GIT:-}" ]; then
    err "Git not supported, run \`$0 --git-init\` first"
    return 1
  fi
  $GIT "$@"
  exit
fi

# Generate new entry
if [ "${1:-}" = "--new" ]; then
  shift
  __new
fi

# Build query
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
query=${cliquery:-!✅}
export query
