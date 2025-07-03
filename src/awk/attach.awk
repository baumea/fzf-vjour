## src/awk/attach.awk
## Prepend attachment to iCalendar file.
##
## @assign file: Path to base64-encoded content
## @assign mime: Mime
## @assign filename: Original filename

# Functions

# Write attachment
#
# @local variables: line, aline
function write_attachment(    line, aline, fl) {
  line = "ATTACH;ENCODING=BASE64;VALUE=BINARY;FMTTYPE="mime";FILENAME="filename":"
  fl = 1
  while (getline aline <file) {
    line = line aline
    if (fl && length(line) >= 73) {
      print substr(line, 1, 73)
      line = substr(line, 74)
      fl = 0
    }
    while (length(line) >= 72) {
      print " "substr(line, 1, 72)
      line = substr(line, 73)
    }
  }
  if (line)
    print " "line
}

# AWK program

/^END:(VTODO|VJOURNAL)$/ { write_attachment() }
{ print }
