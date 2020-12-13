#!/usr/bin/sed -Ef

/^\*/!d

s/^(\*+)\s*(TODO|NEXT|STARTED|WAITING|DONE|MISSED|CANCELLED|MEETING)?\s*(<(.*)>)?\s*([^:]+)\s*(:.*:)?\s*/\1|\2|\4|\5|\6/

