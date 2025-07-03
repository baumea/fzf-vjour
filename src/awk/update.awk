@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":";
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}

ENDFILE { 
  if (NR == FNR)
  {
    # Sanitize input
    if (due) {
      # Use command line `date` for parsing
      cmd = "date -d \"" due "\" +\"%Y%m%d\"";
      cmd | getline res
      due = res ? res : ""
    }
  }
}

NR == FNR && desc { desc = desc "\\n" escape($0); next; }
NR == FNR {
  if (substr($0, 1, 6) == "::: <|")
  {
    due = substr($0, 8);
    getline;
  }
  summary = substr($0, 1, 2) != "# " ? "" : escape(substr($0, 3));
  getline;
  categories = substr($0, 1, 1) != ">" ? "" : escape_but_commas(substr($0, 3));
  getline; # This line should be empty
  getline; # First line of description
  desc = "D" escape($0);
  next;
}

/^BEGIN:(VJOURNAL|VTODO)/                                     { type = $2; print; next }
/^X-ALT-DESC/ && type                                         { next } # drop this alternative description
/^ / && type                                                  { next } # drop this folded line (the only content with folded lines will be updated)
/^(DUE|SUMMARY|CATEGORIES|DESCRIPTION|LAST-MODIFIED)/ && type { next } # skip for now, we will write updated fields at the end
/^SEQUENCE/ && type                                           { seq = $2; next } # store sequence number and skip
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
