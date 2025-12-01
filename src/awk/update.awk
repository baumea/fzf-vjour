@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":";
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}

ENDFILE { 
  if (NR == FNR) {
    due = substr(due, 2)
    summary = substr(summary, 2)
    categories = substr(categories, 2)
    desc = substr(desc, 2)
    if (categories) {
      split(categories, a, ",")
      categories = ""
      for (i in a)
        if (a[i])
          categories = categories "," a[i]
      categories = substr(categories, 2)
    }
    if (due) {
      # Use command line `date` for parsing
      cmd = "date -d \"" due "\" +\"%Y%m%d\"";
      suc = cmd | getline due
      close(cmd)
      if (suc != 1)
        exit 1
    }
  }
}

NR == FNR && desc                 { desc = desc "\\n" escape($0);                      next; }
NR == FNR && /^::: <\|/ && !due   { gsub("\"",""); due = "D" substr($0, 8);            next; }
NR == FNR && /^# / && !summary    { summary = "S" escape(substr($0, 3));               next; }
NR == FNR && /^> / && !categories { categories = "C" escape_but_commas(substr($0, 3)); next; }
NR == FNR && !$0 && !el           { el = 1;                                            next; }
NR == FNR && !el                  { print "Unrecognized header on line "NR": " $0 > "/dev/stderr"; exit 1; }
NR == FNR                         { desc = "D" escape($0);                             next; }
due && type == "VJOURNAL"         { print "Notes and journal entries do not have due dates." > "/dev/stderr"; exit 1; }
/^BEGIN:(VJOURNAL|VTODO)/         { type = $2; print;                                  next; }
/^ / && drop                      {                                                    next; } # drop this folded line
/^X-ALT-DESC/ && type             { drop = 1;                                          next; } # drop this alternative description
/^(DUE|SUMMARY|CATEGORIES|DESCRIPTION|LAST-MODIFIED)/ && type { drop = 1;              next; } # skip for now, we will write updated fields at the end
                                  { drop = 0 } # keep everything else
/^SEQUENCE/ && type               { seq = $2;                                          next; } # store sequence number and skip
/^END:/ && type == $2 {
  seq = seq ? seq + 1 : 1;
  print_cr("SEQUENCE:" seq);
  print_cr("LAST-MODIFIED:" zulu);
  if (due) print_cr("DUE;VALUE=DATE:" due);
  print_fold("SUMMARY:",     summary);
  print_fold("CATEGORIES:",  categories);
  print_fold("DESCRIPTION:", desc);
  type = "";
}
{ print }
