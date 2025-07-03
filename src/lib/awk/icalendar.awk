# Make string single-line
#
# @input str: String
# @return: String without newlines
function singleline(str) {
  gsub("\\n", " ", str)
  return str
}

# Escape string to be used as content in iCalendar files.
#
# @input str: String to escape
# @return: Escaped string
function escape(str)
{
  gsub("\\\\", "\\\\", str)
  gsub("\\n",  "\\n",  str)
  gsub(";",    "\\;",  str)
  gsub(",",    "\\,",  str)
  return str
}

# Escape string to be used as content in iCalendar files, but don't escape
# commas.
#
# @input str: String to escape
# @return: Escaped string
function escape_but_commas(str)
{
  gsub("\\\\", "\\\\", str)
  gsub("\\n",  "\\n",  str)
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

# Unescape string
#
# @local variables: i, c, c2, res
# @input str: String
# @return: Unescaped string
function unescape(str,    i, c, c2, res) {
  for(i = 1; i <= length(str); i++) {
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

# Isolate parameter part of an iCalendar line.
#
# @input str: String
# @return: Parameter part
function getparam(str,    i) {
  i = index(str, ";")
  if (!i)
    return ""
  return substr(str, i + 1, index(str, ":") - i)
}

# Isolate content part of an iCalendar line, and unescape.
#
# @input str: String
# @return: Unescaped content part
function getcontent(str) {
  return unescape(substr(str, index(str, ":") + 1))
}

# Time-zone aware parsing of DTSTART or DTEND entries.
#
# @local variables: tz
# @input dt_param: iCalendar DTSTART or DTEND parameter string
# @input dt_content: iCalendar DTSTART or DTEND content string
# @return: date or date-time string that can be used in date (1)
function parse_dt(dt_param, dt_content,    tz, a, i, k) {
  if (dt_param) {
    split(dt_param, a, ";")
    for (i in a) {
      k = index(a[i], "=")
      if (substr(a[i], 1, k-1) == "TZID") {
        tz = "TZ=\"" substr(a[i], k + 1) "\" "
        break
      }
    }
  }
  # Get date/date-time
  return length(dt_content) == 8 ?
    dt dt_content :
    dt gensub(/^([0-9]{8})T([0-9]{2})([0-9]{2})([0-9]{2})(Z)?$/, "\\1 \\2:\\3:\\4\\5", "g", dt_content)
}

# Map iCalendar duration specification into the format to be used in date (1).
#
# @local variables: dt, dta, i, n, a, seps
# @input duration: iCalendar duration string
# @return: relative-date/date-time specification to be used in date (1)
function parse_duration(duration,    dt, dta, i, n, a, seps) {
  n = split(duration, a, /[PTWHMSD]/, seps)
  for (i=2; i<=n; i++) {
    if(seps[i] == "W") dta["weeks"]   = a[i]
    if(seps[i] == "H") dta["hours"]   = a[i]
    if(seps[i] == "M") dta["minutes"] = a[i]
    if(seps[i] == "S") dta["seconds"] = a[i]
    if(seps[i] == "D") dta["days"]    = a[i]
  }
  dt = a[1] ? a[1] : "+"
  for (i in dta)
    dt = dt " " dta[i] " " i
  return dt
}
