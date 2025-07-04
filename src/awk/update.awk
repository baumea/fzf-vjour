@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":";
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}

ENDFILE { 
  if (NR == FNR && due) {
    # Use command line `date` for parsing
    cmd = "date -d \"" due "\" +\"%Y%m%d\"";
    suc = cmd | getline res
    close(cmd)
    if (suc != 1)
      exit 1
    due = res ? res : ""
  }
}

NR == FNR && desc                 { desc = desc "\\n" escape($0);                  next; }
NR == FNR && /^::: <\| / && !due  { gsub("\"",""); due = substr($0, 8);            next; }
NR == FNR && /^# / && !summary    { summary = escape(substr($0, 3));               next; }
NR == FNR && /^> / && !categories { categories = escape_but_commas(substr($0, 3)); next; }
NR == FNR && !$0 && !el           { el = 1;                                        next; }
NR == FNR && !el                  { print "Unrecognized header on line "NR": " $0 > "/dev/stderr"; exit 1; }
NR == FNR                         { desc = "D" escape($0);                         next; }
due && type == "VJOURNAL"         { print "Notes and journal entries do not have due dates." > "/dev/stderr"; exit 1; }
/^BEGIN:(VJOURNAL|VTODO)/         { type = $2; print;                              next; }
/^X-ALT-DESC/ && type             {                                                next; } # drop this alternative description
/^ / && type                      {                                                next; } # drop this folded line (the only content with folded lines will be updated)
/^(DUE|SUMMARY|CATEGORIES|DESCRIPTION|LAST-MODIFIED)/ && type {                    next; } # skip for now, we will write updated fields at the end
/^SEQUENCE/ && type               { seq = $2;                                      next; } # store sequence number and skip
/^END:/ && type == $2 {
  seq = seq ? seq + 1 : 1;
  print "SEQUENCE:" seq;
  print "LAST-MODIFIED:" zulu;
  if (due) print "DUE;VALUE=DATE:" due;
  print_fold("SUMMARY:",     summary);
  print_fold("CATEGORIES:",  categories);
  print_fold("DESCRIPTION:", substr(desc, 2));
  type = "";
}
{ print }
