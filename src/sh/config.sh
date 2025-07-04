CONFIGFILE="${CONFIGFILE:-$HOME/.config/fzf-vjour/config}"
if [ ! -f "$CONFIGFILE" ]; then
  err "Configuration '$CONFIGFILE' not found."
  exit 1
fi
# shellcheck source=/dev/null
. "$CONFIGFILE"
if [ -z "${ROOT:-}" ] || [ -z "${COLLECTION_LABELS:-}" ]; then
  err "Configuration is incomplete."
  exit 1
fi
SYNC_CMD="${SYNC_CMD:-}"
export ROOT
export SYNC_CMD
export COLLECTION_LABELS
for i in $(seq 9); do
  label=$(printf "%s" "$COLLECTION_LABELS" | cut -d ';' -f "$i" | cut -d '=' -f 2)
  if [ -z "$label" ]; then
    export COLLECTION_COUNT=$((i - 1))
    break
  fi
  export "COLLECTION$i=$label"
done

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
  export GIT
fi

export OPEN=${OPEN:-open}
