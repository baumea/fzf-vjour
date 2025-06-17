# awk script to generate summary line for iCalendar VJOURNAL and VTODO entries
#
# See https://datatracker.ietf.org/doc/html/rfc5545 for the RFC 5545 that
# describes iCalendar, and its syntax

# Make string single-line
#
# @input str: String
# @return: String without newlines
function singleline(str) {
  gsub("\\n", " ", str)
  return str
}

# Isolate and unescape the content part of an iCalendar line.
#
# @local variables: i, c, c2, res
# @input str: String
# @return: Unescaped string
function unescape(str,    i, c, c2, res) {
  for(i=1; i<=length(str);i++) {
    c = substr(str, i, 1)
    if (c != "\\") {
      res = res c
      continue
    }
    i++
    c2 = substr(str, i, 1)
    if (c2 == "n" || c2 == "N") {
      res = res "\n"
      continue
    }
    # Alternatively, c2 is "\\" or "," or ";". In each case, append res with
    # c2. If the strings has been escaped correctly, then the character c2
    # cannot be anything else. To be fail-safe, simply append res with c2.
    res = res c2
  }
  return res
}

# Isolate content part of an iCalendar line, and unescape.
#
# @input str: String
# @return: Unescaped content part
function getcontent(str) {
  return unescape(substr(str, index(str, ":") + 1))
}

# formatdate
# Generate kind-of-pretty date strings.
#
# @local variables: ts, ts_y, ts_m, ts_d, delta
# @input date: Date in the format YYYYMMDD
# @input todaystamp: Today, seconds since epoch
# @return: string
function formatdate(date, todaystamp,       ts, ts_y, ts_m, ts_d, delta)
{
  ts_y = substr(date, 1, 4);
  ts_m = substr(date, 5, 2);
  ts_d = substr(date, 7);
  ts = mktime(ts_y " " ts_m " " ts_d " 00 00 00");
  delta = (ts - todaystamp) / 86400;
  if (delta >= 0 && delta < 1) {
    return "         today";
  }
  if (delta >= 1 && delta < 2) {
    return "      tomorrow";
  }
  if (delta >= 2 && delta < 3) {
    return "   in two days";
  }
  if (delta >= 3 && delta < 4) {
    return " in three days";
  }
  if (delta < 0 && delta >= -1) {
    return "     yesterday";
  }
  if (delta < -1 && delta >= -2) {
    return "  two days ago";
  }
  if (delta < -2 && delta >= -3) {
    return "three days ago";
  }
  return "    " substr(date, 1, 4) "-" substr(date, 5, 2) "-" substr(date, 7);
}

BEGIN {
  # We require the following variables to be set using -v
  # collection_lables: ;-delimited collection=label strings
  # flag_open:      symbol for open to-dos
  # flag_completed: symbol for completed to-dos
  # flag_journal:   symbol for journal entries
  # flag_note:      symbol for note entries

  FS = "[:;]";
  # Collections
  split(collection_labels, mapping, ";");
  for (map in mapping)
  {
    split(mapping[map], m, "=");
    collection2label[m[1]] = m[2];
  }
  # Colors
  GREEN = "\033[1;32m";
  RED = "\033[1;31m";
  WHITE = "\033[1;97m";
  CYAN = "\033[1;36m";
  OFF = "\033[m";

  # For date comparision
  today = strftime("%Y%m%d");
  todaystamp = mktime(substr(today, 1, 4) " " substr(today, 5, 2) " " substr(today, 7) " 00 00 00");
}

# Reset variables
BEGINFILE {
  type = "";
  prop = "";
  delete c;
}

/^BEGIN:(VJOURNAL|VTODO)/ {
  type = $2
}

/^END:/ && $2 == type {
  nextfile
}

/^(CATEGORIES|DESCRIPTION|PRIORITY|STATUS|SUMMARY|COMPLETED|DUE|DTSTART|DURATION|CREATED|DTSTAMP|LAST-MODIFIED)/ {
  prop = $1;
  c[prop] = $0;
  next;
}
/^[^ ]/ && prop {
  prop = "";
  next;
}
/^ / && prop {
  c[prop] = c[prop] substr($0, 2); 
  next; 
}

ENDFILE {
  if (!type) {
    exit
  }
  # Construct path, and check for validity
  depth = split(FILENAME, path, "/");
  fpath = path[depth-1] "/" path[depth]
  if (index(fpath, " "))
  {
    print 10,
          "-",
          "-",
          RED "ERROR: file '" fpath "' contains whitespaces!" OFF
    exit
  }
  # Collection name
  collection = path[depth-1]
  collection = collection in collection2label ? collection2label[collection] : collection;

  # Process content lines
  # strings
  cat = singleline(unescape(getcontent(c["CATEGORIES"])))
  des = singleline(unescape(getcontent(c["DESCRIPTION"])))
  sta = singleline(unescape(getcontent(c["STATUS"])))
  sum = singleline(unescape(getcontent(c["SUMMARY"])))

  # integers
  pri = unescape(getcontent(c["PRIORITY"]))
  pri = pri ? pri + 0 : 0

  # dates
  due = substr(unescape(getcontent(c["DUE"])), 1, 8)
  dts = substr(unescape(getcontent(c["DTSTART"])), 1, 8)
  
  # date-times
  com = unescape(getcontent(c["COMPLETED"]))
  dur = unescape(getcontent(c["DURATION"]))
  cre = unescape(getcontent(c["CREATED"]))
  stp = unescape(getcontent(c["DTSTAMP"]))
  lmd = unescape(getcontent(c["LAST-MODIFIED"]))

  # Priority field, primarly used for sorting
  psort = 0;
  priotext = ""
  if (pri > 0)
  {
    priotext = "❗(" pri ") "
    psort = 10 - pri
  }

  # Last modification/creation time stamp, used for sorting
  # LAST-MODIFIED: Optional field for VTODO and VJOURNAL entries, date-time in
  #                UTC time format
  # DTSTAMP:       mandatory field in VTODO and VJOURNAL, date-time in UTC time
  #                format
  mod = lmd ? lmd : stp

  # Date field. For VTODO entries, we show the due date, for journal entries,
  # the associated date.
  datecolor = CYAN;
  summarycolor = GREEN;

  if (type == "VTODO")
  {
    # Either DUE or DURATION may appear. If DURATION appears, then also DTSTART
    d = due ? due : (dur ? dts " for " dur : "");
    if (d && d <= today && sta != "COMPLETED")
    {
      datecolor = RED;
      summarycolor = RED;
    }
  } else {
    d = dts
  }
  d = d ? formatdate(d, todaystamp) : "              ";

  # flag: - "journal"   for VJOURNAL with DTSTART
  #       - "note"      for VJOURNAL without DTSTART
  #       - "completed" for VTODO with c["STATUS"] == COMPLETED
  #       - "open"      for VTODO with c["STATUS"] != COMPLETED
  if (type == "VTODO")
    flag = sta == "COMPLETED" ? flag_completed : flag_open;
  else
    flag = dts ? flag_journal : flag_note;
  
  # summary
  # c["SUMMARY"]
  summary = sum ? sum : " "

  # categories
  categories = cat ? cat : " "

  # filename
  # FILENAME

  print psort,
        mod,
        fpath,
        collection,
        datecolor d OFF,
        flag,
        priotext summarycolor summary OFF,
        WHITE categories OFF;
}
