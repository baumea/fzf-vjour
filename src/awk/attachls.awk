# Decide if we need to read more to get all properties
# 
# @input str: strin read so far
# @return: 1 if we need more data, 0 otherwise
function cont_reading(str) {
  return index(str, ":") ? 0 : 1
}

# Get information about attachment
#
# @input i: Attachment index
# @input str: Attachment string (at least up to content separator `:`)
# @return: informative string
function att_info(i, str,    cnt, k, info) {
  str = substr(str, 1, index(str, ":") - 1)
  cnt = split(str, props)
  if (cnt > 1) {
    for (k=2; k<=cnt; k++) {
      pname = substr(props[k], 1, index(props[k], "=") - 1)
      pvalu = substr(props[k], index(props[k], "=") + 1)
      if (pname == "ENCODING" && pvalu = "BASE64")
        enc = "base64"
      if (pname == "FILENAME")
        fin = pvalu
      if (pname == "VALUE")
        val = pvalu
      if (pname == "FMTTYPE")
        type = pvalu
    }
    if (enc)
      info = "inline"
  }
  print i, fin, type, enc, info
}

BEGIN                      { FS="[:;]"; OFS="\t" }
{ gsub("\r", "") }
/^END:(VTODO|VJOURNAL)$/   { ins = 0; exit }
l && !r                    { att_info(i, l); l = "" }
/^ / && r                  { l = l substr($0, 2); r = cont_reading($0) }
/^ATTACH/ && ins           { i++; l = $0; r = cont_reading($0) }
/^BEGIN:(VTODO|VJOURNAL)$/ { ins = 1 }
