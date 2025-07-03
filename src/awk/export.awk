@include "lib/awk/icalendar.awk"

BEGIN                     { FS = "[:;]"; }
/^BEGIN:(VJOURNAL|VTODO)/ { type = $2 }
/^END:/ && $2 == type     { exit }
/^(CATEGORIES|DESCRIPTION|SUMMARY|DUE)/ { prop = $1; c[prop] = $0; next; }
/^[^ ]/ && prop           { prop = ""; next; }
/^ / && prop              { c[prop] = c[prop] substr($0, 2); next; }
END {
  if (!type)
    exit
  # Process content lines, force CATEGORIES and SUMMARY as single-line
  c["CATEGORIES"]  = singleline(getcontent(c["CATEGORIES"]))
  c["DESCRIPTION"] = getcontent(c["DESCRIPTION"])
  c["SUMMARY"]     = singleline(getcontent(c["SUMMARY"]))
  c["DUE"]         = getcontent(c["DUE"])
  # Print
  if (c["DUE"])
    print "::: <| " substr(c["DUE"], 1, 4) "-" substr(c["DUE"], 5, 2) "-" substr(c["DUE"], 7, 2);
  print "# " c["SUMMARY"];
  print "> " c["CATEGORIES"];
  print "";
  print c["DESCRIPTION"];
}
