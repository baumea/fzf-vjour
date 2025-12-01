# Increase/decrease priority, or toggle completed status
#
# If `delta` is specified using `-v`, then the priority value is increased by
# `delta.` If `delta` is unspecified (or equal to 0), then the completeness
# status is toggled.

@include "lib/awk/icalendar.awk"

BEGIN { 
  FS=":";
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
  delta = delta + 0; # cast as integer
}
{ gsub("\r", "") }
/^END:VTODO/ && inside     { 
  # Print sequence and last-modified, if not yet printed
  if (!seq) print_cr("SEQUENCE:1");
  if (!lm) print_cr("LAST-MODIFIED:" zulu);

  # Print priority
  prio = prio ? prio + delta : 0 + delta;
  prio = prio < 0 ? 0 : prio;
  prio = prio > 9 ? 9 : prio;
  print_cr("PRIORITY:" prio);

  # Print status (toggle if needed)
  bit_status = status == "COMPLETED" ? 1 : 0;
  bit_toggle = delta ? 0 : 1;
  percent = xor(bit_status, bit_toggle) ? 100 : 0;
  status = xor(bit_status, bit_toggle) ? "COMPLETED" : "NEEDS-ACTION";
  print_cr("STATUS:" status)
  print_cr("PERCENT-COMPLETE:" percent)

  # print rest
  inside = ""; 
  print_cr($0);
  next
}
/^BEGIN:VTODO/                { inside = 1;    print_cr($0);                    next }
/^SEQUENCE/ && inside         { seq = 1;       print_cr("SEQUENCE:" $2+1);      next }
/^LAST-MODIFIED/ && inside    { lm = 1;        print_cr("LAST-MODIFIED:" zulu); next }
/^PRIORITY:/ && inside        { prio = $2;                                      next }
/^STATUS/ && inside           { status = $2;                                    next }
/^PERCENT-COMPLETE/ && inside {                                                 next } # ignore, we take STATUS:COMPLETED as reference
{ print_cr($0) }
