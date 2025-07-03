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

if command -v "git" >/dev/null && [ -d "$ROOT/.git" ]; then
  GIT="git -C $ROOT"
fi
export GIT
