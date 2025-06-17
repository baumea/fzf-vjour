# unescape
# Isolate and unescape the content part of an iCalendar line.
#
# @local variables: i, c, c2, res
# @input str: String
# @return: Unescaped string
function unescape(str,    i, c, c2, res) {
  for(i=1; i<=length(str);i++) {
    c = substr(str, i, 1)
    if (c != "\\") {
      res = res c
      continue
    }
    i++
    c2 = substr(str, i, 1)
    if (c2 == "n" || c2 == "N") {
      res = res "\n"
      continue
    }
    # Alternatively, c2 is "\\" or "," or ";". In each case, append res with
    # c2. If the strings has been escaped correctly, then the character c2
    # cannot be anything else. To be fail-safe, simply append res with c2.
    res = res c2
  }
  return res
}

# getcontent
# Isolate content part of an iCalendar line, and unescape.
#
# @input str: String
# @return: Unescaped content part
function getcontent(str) {
  return unescape(substr(str, index(str, ":") + 1))
}

# print content of field `field`
BEGIN                     { FS = ":"; regex = "^" field; }
/^BEGIN:(VJOURNAL|VTODO)/ { type = $2 }
/^END:/ && $2 == type     { exit }
$0 ~ field                { line = $0;                 next; }
/^ / && line              { line = line substr($0, 2); next; }
/^[^ ]/ && line           { exit }
END {
  if (!type) { exit }
  # Process line
  print getcontent(line)
}
