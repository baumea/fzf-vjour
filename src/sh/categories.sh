# List all categories and lest user select
__select_category() {
  find "$ROOT" -type f -name "*.ics" -print0 |
    xargs -0 -P 0 \
      awk -v field="CATEGORIES" -v format="csv" "$AWK_GET" |
    tr ',' '\n' |
    sort |
    uniq |
    grep '.' |
    $FZF --prompt="Select category> " \
      --no-sort \
      --tac \
      --margin="30%,30%" \
      --border=bold \
      --border-label="Categories" ||
    true
}
