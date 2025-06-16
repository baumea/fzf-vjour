# Escape string to be used as content in iCalendar files.
#
# @input str: String to escape
# @return: Escaped string
function escape(str)
{
  gsub("\\\\", "\\",  str)
  gsub(";",    "\\;", str)
  gsub(",",    "\\,", str)
  return str
}

# Escape string to be used as content in iCalendar files.
#
# @input str: String to escape
# @return: Escaped string
function escape_categories(str)
{
  gsub("\\\\", "\\",  str)
  gsub(";",    "\\;", str)
  return str
}

# Print property with its content and fold according to the iCalendar
# specification.
#
# @local variables: i, s
# @input nameparam: Property name with optional parameters
# @input content: Escaped content
function print_fold(nameparam, content,    i, s)
{
  i = 74 - length(nameparam)
  s = substr(content, 1, i)
  print nameparam s
  s = substr(content, i+1, 73)
  i = i + 73
  while (s)
  {
    print " " s
    s = substr(content, i+1, 73)
    i = i + 73
  }
}

BEGIN { 
  FS=":"; 
  type = "VJOURNAL"; 
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
}
desc { desc = desc "\\n" $0; next; }
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
  summary = substr($0, 1, 2) != "# " ? "" : substr($0, 3);
  getline;
  categories = substr($0, 1, 1) != ">" ? "" : substr($0, 3);
  getline; # This line should be empty
  getline; # First line of description
  desc = $0;
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
  summary = escape(summary);
  desc = escape(desc);
  categories = escape_categories(categories);

  # print ical
  print "BEGIN:VCALENDAR";
  print "VERSION:2.0";
  print "CALSCALE:GREGORIAN";
  print "PRODID:-//fab//awk//EN";
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
