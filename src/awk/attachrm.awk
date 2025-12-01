## src/awk/attachrm.awk
## Remove attachment from iCalendar file.
##
## @assign id: Attachment number to remove

BEGIN                       { FS="[:;]" }
/^END:(VTODO|VJOURNAL)/     { ins = 0 }
/^[^ ]/ && a                { a = 0 }
/^ / && a                   { next }
/^ATTACH/ && ins            { i++; }
/^ATTACH/ && ins && i == id { a = 1; next }
/^BEGIN:(VTODO|VJOURNAL)/   { ins = 1 }
{ print }
