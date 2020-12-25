#!/usr/bin/sed -Ef

# expects input to come from `grep -Hn '^\(\*\|\s*:.*:\)' *.hd`

s/^(.*):([0-9]+):(\*|\s*:.*:)/\1|\2|\3/

T

s/(\*+)\s*(TODO|NEXT|STARTED|WAITING|DONE|MISSED|CANCELLED|MEETING)?\s*(<([0-9]+-[0-9]+-[0-9]+\s*([0-9]+:[0-9]+)?)\s*(-[0-9]+[mdyh])?\s*(\+[0-9]+[mdyh])?>)?\s*([^:]+)\s*(:.*)?\s*/\1|\2|\4|\6|\7|\8|\9/

t

s/\s*:(.*):\s*(.*)$/\1|\2/

