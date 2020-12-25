
import datetime

def parse_date(date_str):
    if not len(date_str):
        return None
    date_parts = date_str.split(' ')[0].split('-')
    return datetime.date(int(date_parts[0]), int(date_parts[1]), int(date_parts[2]))

class Heading:
    def __init__(self, line):
        self.fields = line.split('|')
        self.valid = False
        if len(self.fields) == 11:
            self.filename = self.fields[0]
            self.startlnum = int(self.fields[1])
            self.endlnum = self.fields[2]
            self.level = int(self.fields[3])
            self.keyword = self.fields[4].strip()
            self.date = parse_date(self.fields[5].strip())
            self.warning = self.fields[6]
            self.repeat = self.fields[7]
            self.title = self.fields[8]
            self.path = self.fields[9]
            self.tags = filter(None, map(lambda s: s.strip(), self.fields[10].split(':')))
            self.valid = True

    def __str__(self):
        return '|'.join(self.fields)

    def __repr__(self):
        return str(self)

    def __bool__(self):
        return self.valid

KEYWORDS = ['TODO', 'NEXT', 'STARTED', 'WAITING', '|', 'DONE', 'MISSED', 'CANCELLED', 'MEETING']

def from_fields_file(stream):
    return filter(None, map(lambda s: Heading(s.strip()), stream.readlines()))

