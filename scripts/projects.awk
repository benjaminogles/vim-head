#!/usr/bin/awk -f

BEGIN {
  FS = "|"
}

$4 == 2 && $9 == "/Projects" {
  go = 1
  print ""
  print "--", $10, "--"
}

$4 <= 2 && $9 != "/Projects" {
  go = 0
}

go && ($5 == "TODO" || $5 == "NEXT") {
  print $0
}


