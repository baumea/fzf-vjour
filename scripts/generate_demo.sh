#!/bin/sh

set -eu

BOLD="\033[1m"
GREEN="\033[0;32m"
OFF="\033[m"
DEMO="demo"
FVJ="./fzf-vjour"
ROOT="$DEMO/journal/"
COLLECTION_LABELS="745ae7a0-d723-4cd8-80c4-75f52f5b7d90=shared 👫🏼;12cacb18-d3e1-4ad4-a1d0-e5b209012e85=work   💼;"

export CONFIGFILE="$DEMO/config"
rm -rf "$ROOT"
collection1="$(printf "%s" "$COLLECTION_LABELS" | cut -d ";" -f 1 | cut -d "=" -f 1)"
collection2="$(printf "%s" "$COLLECTION_LABELS" | cut -d ";" -f 2 | cut -d "=" -f 1)"
mkdir -p "$ROOT/$collection1"
mkdir -p "$ROOT/$collection2"
cat <<EOF >"$CONFIGFILE"
ROOT="$ROOT"
COLLECTION_LABELS="$COLLECTION_LABELS"
EOF
echo "⚙️ ${BOLD}${GREEN}Building demo$OFF"
## Fill in data
cal 2028 | $FVJ --add-note "2028 will be a leap year"
$FVJ --add-task "Finish proof of admissibility theorem" "tomorrow" --collection 2
cat <<EOF | $FVJ --add-task "Respond to referee report" "yesterday" --collection 2
- [x] Report 1: Answer prepared
- [ ] Report 2: Write response, revise manuscript
EOF
echo "Chinese" | $FVJ --add-task "Reserve dinner table" "next Sunday"
cat <<EOF | $FVJ --add-jour "Demo Coding"
### Demo code
Our demo now contains a script that self-generets the demo.
It's located in \`./scripts/\`
There are some upcoming steps:

1. Generate screenshot
2. Demonstrate attachment window
3. Extend code to handle timezones and alarms
EOF
cat <<EOF | $FVJ --add-note "Shopping list"
- [ ] Banana
- [ ] Bread
- [ ] Yoghurt
EOF
cat <<EOF | $FVJ --add-jour "Today's code" --collection 2
# Source code of current program

\`\`\`sh
$(cat "$0")
\`\`\`
EOF
$FVJ --add-task "Look for typos in readme" --collection 2 <"README.md"
## End of data
echo "🚀 ${BOLD}${GREEN}DONE.$OFF"
echo ""
echo "${GREEN}Run '${OFF}CONFIGFILE=$CONFIGFILE $FVJ$GREEN' to start demo$OFF"
