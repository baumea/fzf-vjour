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
  print_cr("BEGIN:VCALENDAR")
  print_cr("VERSION:2.0")
  print_cr("CALSCALE:GREGORIAN")
  print_cr("PRODID:-//fzf-vjour//awk//EN")
  print_cr("BEGIN:" type)
  print_cr("DTSTAMP:" zulu)
  print_cr("UID:" uid)
  print_cr("CLASS:PRIVATE")
  print_cr("CREATED:" zulu)
  print_cr("SEQUENCE:1")
  print_cr("LAST-MODIFIED:" zulu)
  if (type == "VTODO")
  {
    print_cr("STATUS:NEEDS-ACTION")
    print_cr("PERCENT-COMPLETE:0")
    if (due)
      print_cr("DUE;VALUE=DATE:" due)
  }
  else
  {
    print_cr("STATUS:FINAL")
    if (start)
      print_cr("DTSTART;VALUE=DATE:" start)
  }
  if (summary)    print_fold("SUMMARY:",     summary);
  if (categories) print_fold("CATEGORIES:",  categories);
  if (desc)       print_fold("DESCRIPTION:", desc);
  print_cr("END:" type)
  print_cr("END:VCALENDAR")
}
