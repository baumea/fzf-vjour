@include "lib/awk/icalendar.awk"

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
