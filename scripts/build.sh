#!/bin/sh

BOLD="\033[1m"
GREEN="\033[0;32m"
OFF="\033[m"
NAME="fzf-vjour"
SRC="./src/main.sh"
echo "🐔 ${GREEN}Building${OFF} ${BOLD}$NAME${OFF}"
sed -E 's|@@include (.+)$|cat \1|e' "$SRC" >"$NAME"
chmod +x "$NAME"
echo "🥚 ${GREEN}Done${OFF}"
