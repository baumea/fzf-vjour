# print content of field `field`
BEGIN                     { FS = ":"; regex = "^" field; }
/^BEGIN:(VJOURNAL|VTODO)/ { type = $2 }
/^END:/ && $2 == type     { exit }
$0 ~ field                { content = $0;                    next; }
/^ / && content           { content = content substr($0, 2); next; }
/^[^ ]/ && content        { exit }
END {
  if (!type) { exit }
  # Process content line
  content = substr(content, index(content, ":") + 1);
  gsub("\\\\n",    "\n", content);
  gsub("\\\\N",    "\n", content);
  gsub("\\\\,",    ",",  content);
  gsub("\\\\;",    ";",  content);
  gsub("\\\\\\\\", "\\", content);
  print content;
}
