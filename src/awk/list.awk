# awk script to generate summary line for iCalendar VJOURNAL and VTODO entries
#
# See https://datatracker.ietf.org/doc/html/rfc5545 for the RFC 5545 that
# describes iCalendar, and its syntax

function getcontent(content_line, prop)
{
  return substr(content_line[prop], index(content_line[prop], ":") + 1);
}

function storetext_line(content_line, c, prop)
{
  c[prop] = getcontent(content_line, prop);
  gsub("\\\\n",    " ",  c[prop]);
  gsub("\\\\N",    " ",  c[prop]);
  gsub("\\\\,",    ",",  c[prop]);
  gsub("\\\\;",    ";",  c[prop]);
  gsub("\\\\\\\\", "\\", c[prop]);
  #gsub(" ",    "_",  c[prop]);
}

function storeinteger(content_line, c, prop)
{
  c[prop] = getcontent(content_line, prop);
  c[prop] = c[prop] ? c[prop] : 0;
}

function storedatetime(content_line, c, prop)
{
  c[prop] = getcontent(content_line, prop);
}

function storedate(content_line, c, prop)
{
  c[prop] = substr(getcontent(content_line, prop), 1, 8);
}

function formatdate(date, today, todaystamp,       ts, ts_y, ts_m, ts_d, delta)
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
  FAINT = "\033[2m";
  OFF = "\033[m";

  # For date comparision
  today = strftime("%Y%m%d");
  todaystamp = mktime(substr(today, 1, 4) " " substr(today, 5, 2) " " substr(today, 7) " 00 00 00");
}

# Reset variables
BEGINFILE {
  type = "";
  prop = "";
  delete content_line;
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
  content_line[prop] = $0;
  next;
}
/^[^ ]/ && prop {
  prop = "";
  next;
}
/^ / && prop {
  content_line[prop] = content_line[prop] substr($0, 2); 
  next; 
}

ENDFILE {
  if (!type) {
    exit
  }
  # Process content lines
  storetext_line(content_line, c, "CATEGORIES"   );
  storetext_line(content_line, c, "DESCRIPTION"  );
  storeinteger(  content_line, c, "PRIORITY"     );
  storetext_line(content_line, c, "STATUS"       );
  storetext_line(content_line, c, "SUMMARY"      );
  storedatetime( content_line, c, "COMPLETED"    );
  storedate(     content_line, c, "DUE"          );
  storedate(     content_line, c, "DTSTART"      );
  storedatetime( content_line, c, "DURATION"     );
  storedatetime( content_line, c, "CREATED"      );
  storedatetime( content_line, c, "DTSTAMP"      );
  storedatetime( content_line, c, "LAST-MODIFIED");

  # Priority field, primarly used for sorting
  priotext = "";
  prio = 0;
  if (c["PRIORITY"] > 0)
  {
    priotext = "❗(" c["PRIORITY"] ") ";
    prio = 10 - c["PRIORITY"];
  }

  # Last modification/creation time stamp, used for sorting
  # LAST-MODIFIED: Optional field for VTODO and VJOURNAL entries, date-time in
  #                UTC time format
  # DTSTAMP:       mandatory field in VTODO and VJOURNAL, date-time in UTC time
  #                format
  mod = c["LAST-MODIFIED"] ? c["LAST-MODIFIED"] : c["DTSTAMP"];

  # Collection name
  depth = split(FILENAME, path, "/");
  collection = depth > 1 ? path[depth-1] : "";
  collection = collection in collection2label ? collection2label[collection] : collection;

  # Date field. For VTODO entries, we show the due date, for journal entries,
  # the associated date.
  datecolor = CYAN;
  summarycolor = GREEN;

  if (type == "VTODO")
  {
    # Either DUE or DURATION may appear. If DURATION appears, then also DTSTART
    d = c["DUE"] ? c["DUE"] : 
      (c["DURATION"] ? c["DTSTART"] " for " c["DURATION"] : "");
    if (d && d <= today && c["STATUS"] != "COMPLETED")
    {
      datecolor = RED;
      summarycolor = RED;
    }
  } else {
    d = c["DTSTART"];
  }
  d = d ? formatdate(d, today, todaystamp       ts, ts_y, ts_m, ts_d, delta) : "              ";

  # flag: - "journal"   for VJOURNAL with DTSTART
  #       - "note"      for VJOURNAL without DTSTART
  #       - "completed" for VTODO with c["STATUS"] == COMPLETED
  #       - "open"      for VTODO with c["STATUS"] != COMPLETED
  if (type == "VTODO")
    flag = c["STATUS"] == "COMPLETED" ? flag_completed : flag_open;
  else
    flag = c["DTSTART"] ? flag_journal : flag_note;
  
  # summary
  # c["SUMMARY"]
  summary = c["SUMMARY"] ? c["SUMMARY"] : " "

  # categories
  categories = c["CATEGORIES"] ? c["CATEGORIES"] : " "

  # filename
  # FILENAME

  print prio,
        mod,
        collection,
        datecolor d OFF,
        flag,
        priotext summarycolor summary OFF,
        WHITE categories OFF,
        "                                                                                                                                                                    " FAINT FILENAME OFF;
}
