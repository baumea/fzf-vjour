@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":"; 
  type = "VJOURNAL"; 
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}
desc { desc = desc "\\n" escape($0); next; }
{
  if (substr($0, 1, 6) == "::: |>")
  {
    start = substr(zulu, 1, 8);
    getline;
  }
  if (substr($0, 1, 6) == "::: <|")
  {
    type = "VTODO"
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
END {
  # Sanitize input
  if (due) {
    # Use command line `date` for parsing
    cmd = "date -d \"" due "\" +\"%Y%m%d\"";
    cmd | getline res
    due = res ? res : ""
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
  if (desc)       print_fold("DESCRIPTION:", substr(desc, 2));
  print "END:" type;
  print "END:VCALENDAR"
}
