#!/usr/bin/awk -f

BEGIN {
  OFS="|" 
  level = 1
  command = "sort"
}

function print_lines(to, lnum) {
  l = level
  while (l >= to)
  {
    if ((l, 1) in lines)
    {
      print lines[l, 1], lines[l, 2], lnum, lines[l, 3] | command
      delete lines[l, 1]
      delete lines[l, 2]
      delete lines[l, 3]
    }
    l--
  }
  level = to
}

FNR == 1 {
  print_lines(1, "$")
}

/^\*+ / {
  print_lines(index($0, " ") - 1, FNR - 1)
  lines[level, 1] = FILENAME
  lines[level, 2] = FNR
  lines[level, 3] = $0
}

END {
  print_lines(1, "$")
  close(command)
}

