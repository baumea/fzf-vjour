# Retrieve content from iCalendar files
#
# Mandatory variable: `field`.
# Name of field to retrieve.
#
# Optional variable: `format`.
# If `format` is set to "csv", then the content is interpreted as
# comma-separated values, and empty values are dropped.
# If `format` is set to "date", then the content is interpreted as
# a date the output is in the form YYYY-MM-DD.
#
# Optional variable: `oneline`.
# If `oneline` is set, then the all newlines will be replaced by white spaces
@include "lib/awk/icalendar.awk"

# print content of field `field`
BEGIN                     { FS = ":"; regex = "^" field; }
BEGINFILE                 { type = ""; line = ""; }
{ gsub("\r", "") }
/^BEGIN:(VJOURNAL|VTODO)/ { type = $2 }
/^END:/ && $2 == type     { nextfile }
$0 ~ regex                { line = $0;                 next; }
/^ / && line              { line = line substr($0, 2); next; }
/^[^ ]/ && line           { nextfile }
ENDFILE {
  if (type) {
    # Process line
    content = getcontent(line)
    if (oneline)
      content = singleline(content)
    switch (format) {
      case "csv" : 
        split(content, a, ",")
        res = ""
        for (i in a) {
          if (a[i])
            res = res "," a[i]
        }
        print substr(res, 2)
        break
      case "date" : 
        if (content)
          print substr(parse_dt("", content), 1, 10)
        break
      default :
        print content
        break
    }
  }
}
