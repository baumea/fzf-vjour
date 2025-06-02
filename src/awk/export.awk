function getcontent(content_line, prop)
{
  return substr(content_line[prop], index(content_line[prop], ":") + 1);
}

function storetext_line(content_line, c, prop)
{
  c[prop] = getcontent(content_line, prop);
  gsub("\\\\n",    "\n", c[prop]);
  gsub("\\\\N",    "\n", c[prop]);
  gsub("\\\\,",    ",",  c[prop]);
  gsub("\\\\;",    ";",  c[prop]);
  gsub("\\\\\\\\", "\\", c[prop]);
}

BEGIN                                   { FS = "[:;]"; }
/^BEGIN:(VJOURNAL|VTODO)/               { type = $2 }
/^END:/ && $2 == type                   { exit }
/^(CATEGORIES|DESCRIPTION|SUMMARY|DUE)/ { prop = $1; content_line[prop] = $0;                               next; }
/^[^ ]/ && prop                         { prop = "";                                                        next; }
/^ / && prop                            {            content_line[prop] = content_line[prop] substr($0, 2); next; }

END {
  if (!type) {
    exit
  }
  # Process content lines
  storetext_line(content_line, c, "CATEGORIES" );
  storetext_line(content_line, c, "DESCRIPTION");
  storetext_line(content_line, c, "SUMMARY"    );
  storetext_line(content_line, c, "DUE"        );
  # Print
  if (c["DUE"])
    print "::: <| " substr(c["DUE"], 1, 4) "-" substr(c["DUE"], 5, 2) "-" substr(c["DUE"], 7, 2);
  print "# " c["SUMMARY"];
  print "> " c["CATEGORIES"];
  print "";
  print c["DESCRIPTION"];
}
