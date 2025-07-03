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
