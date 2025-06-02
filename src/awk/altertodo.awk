# Increase/decrease priority, or toggle completed status
#
# If `delta` is specified using `-v`, then the priority value is increased by
# `delta.` If `delta` is unspecified (or equal to 0), then the completeness
# status is toggled.
BEGIN { 
  FS=":";
  zulu = strftime("%Y%m%dT%H%M%SZ", systime(), 1);
  delta = delta + 0; # cast as integer
}
/^END:VTODO/ && inside     { 
  # Print sequence and last-modified, if not yet printed
  if (!seq) print "SEQUENCE:1";
  if (!lm) print "LAST-MODIFIED:" zulu;

  # Print priority
  prio = prio ? prio + delta : 0 + delta;
  prio = prio < 0 ? 0 : prio;
  prio = prio > 9 ? 9 : prio;
  print "PRIORITY:" prio;

  # Print status (toggle if needed)
  bit_status = status == "COMPLETED" ? 1 : 0;
  bit_toggle = delta ? 0 : 1;
  percent = xor(bit_status, bit_toggle) ? 100 : 0;
  status = xor(bit_status, bit_toggle) ? "COMPLETED" : "NEEDS-ACTION";
  print "STATUS:" status
  print "PERCENT-COMPLETE:" percent

  # print rest
  inside = ""; 
  print $0;
  next
}
/^BEGIN:VTODO/                { inside = 1;    print;                       next }
/^SEQUENCE/ && inside         { seq = 1;       print "SEQUENCE:" $2+1;      next }
/^LAST-MODIFIED/ && inside    { lm = 1;        print "LAST-MODIFIED:" zulu; next }
/^PRIORITY:/ && inside        { prio = $2;                                  next }
/^STATUS/ && inside           { status = $2;                                next }
/^PERCENT-COMPLETE/ && inside {                                             next } # ignore, we take STATUS:COMPLETED as reference
{ print }
