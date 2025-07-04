@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":"; 
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}
desc                 { desc = desc "\\n" escape($0);                      next; }
/^::: \|>/ && !start { gsub("\"", ""); start = substr(zulu, 1, 8);        next; }
/^::: <\|/ && !due   { gsub("\"", ""); due = "D" substr($0, 8);           next; }
/^# / && !summary    { summary = "S" escape(substr($0, 3));               next; }
/^> / && !categories { categories = "C" escape_but_commas(substr($0, 3)); next; }
!$0 && !el           { el = 1;                                        next; }
!el                  { print "Unrecognized header on line "NR": " $0 > "/dev/stderr"; exit 1; }
                     { desc = "D" escape($0);                             next; }
END {
  # Sanitize input
  type = due ? "VTODO" : "VJOURNAL"
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

  # print ical
  print "BEGIN:VCALENDAR";
  print "VERSION:2.0";
  print "CALSCALE:GREGORIAN";
  print "PRODID:-//fzf-vjour//awk//EN";
  print "BEGIN:" type;
  print "DTSTAMP:" zulu;
  print "UID:" uid;
  print "CLASS:PRIVATE";
  print "CREATED:" zulu;
  print "SEQUENCE:1";
  print "LAST-MODIFIED:" zulu;
  if (type == "VTODO")
  {
    print "STATUS:NEEDS-ACTION";
    print "PERCENT-COMPLETE:0";
    if (due)
      print "DUE;VALUE=DATE:" due; 
  }
  else
  {
    print "STATUS:FINAL";
    if (start)
      print "DTSTART;VALUE=DATE:" start;
  }
  if (summary)    print_fold("SUMMARY:",     summary);
  if (categories) print_fold("CATEGORIES:",  categories);
  if (desc)       print_fold("DESCRIPTION:", desc);
  print "END:" type;
  print "END:VCALENDAR"
}
