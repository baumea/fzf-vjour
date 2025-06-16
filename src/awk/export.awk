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

BEGIN                     { FS = "[:;]"; }
/^BEGIN:(VJOURNAL|VTODO)/ { type = $2 }
/^END:/ && $2 == type     { exit }
/^(CATEGORIES|DESCRIPTION|SUMMARY|DUE)/ { prop = $1; c[prop] = $0; next; }
/^[^ ]/ && prop           { prop = ""; next; }
/^ / && prop              { c[prop] = c[prop] substr($0, 2); next; }
END {
  if (!type)
    exit
  # Process content lines
  c["CATEGORIES"]  = getcontent(c["CATEGORIES"])
  c["DESCRIPTION"] = getcontent(c["DESCRIPTION"])
  c["SUMMARY"]     = getcontent(c["SUMMARY"])
  c["DUE"]         = getcontent(c["DUE"])
  # Print
  if (c["DUE"])
    print "::: <| " substr(c["DUE"], 1, 4) "-" substr(c["DUE"], 5, 2) "-" substr(c["DUE"], 7, 2);
  print "# " c["SUMMARY"];
  print "> " c["CATEGORIES"];
  print "";
  print c["DESCRIPTION"];
}
