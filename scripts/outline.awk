#!/usr/bin/awk -f

BEGIN {
  FS = "|"
  OFS = "|" 
}

function path(to, j, p) {
  j = 0
  p = ""
  while (++j < to)
    p = p "/" data[j, 8]
  return p ? p : "/"
}

function print_lines(to, lnum, old, j, k) {
  old = idx
  for (j = 1; j <= old; j++)
  {
    if (levels[j] < to)
      continue
    idx--

    print data[j, 1], data[j, 2], lnum, length(data[j, 3]), data[j, 4], data[j, 5], data[j, 6], data[j, 7], path(j), data[j, 8], data[j, 9]

    for (k = 1; k <= metalen[j]; k++)
      print meta[j, k]
  }
}

FNR == 1 {
  print_lines(1, "$")
}

NF == 9 {
  level = length($3)
  print_lines(level, $2 - 1)
  levels[++idx] = level
  for (i = 1; i <= 9; i++)
    data[idx, i] = $i
  metalen[idx] = 0
}

NF == 4 {
  meta[idx, ++metalen[idx]] = $0
}

END {
  print_lines(1, "$")
}

