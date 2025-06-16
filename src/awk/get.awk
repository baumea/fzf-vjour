# unescape
# Isolate and unescape the content part of an iCalendar line.
#
# @local variables: tmp
# @input str: String
# @return: Unescaped string
function unescape(str) {
  gsub("\\\\n",    "\n", str)
  gsub("\\\\N",    "\n", str)
  gsub("\\\\,",    ",",  str)
  gsub("\\\\;",    ";",  str)
  gsub("\\\\\\\\", "\\", str)
  return str
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
