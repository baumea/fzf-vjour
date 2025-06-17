# Escape string to be used as content in iCalendar files.
#
# @input str: String to escape
# @return: Escaped string
function escape(str)
{
  gsub("\\\\", "\\\\", str)
  gsub(";",    "\\;",  str)
  gsub(",",    "\\,",  str)
  return str
}

# Escape string to be used as content in iCalendar files.
#
# @input str: String to escape
# @return: Escaped string
function escape_categories(str)
{
  gsub("\\\\", "\\\\", str)
  gsub(";",    "\\;",  str)
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
  categories = substr($0, 1, 1) != ">" ? "" : escape_categories(substr($0, 3));
  getline; # This line should be empty
  getline; # First line of description
  desc = escape($0);
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
  print_fold("DESCRIPTION:", desc);
  type = "";
}
{ print }
