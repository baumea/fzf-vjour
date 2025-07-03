# Print error message
err() {
  echo "❌ $1" >/dev/tty
}

# Strip whitespaces from argument
stripws() {
  echo "$@" | sed "s/^ *//" | sed "s/ *$//"
}
