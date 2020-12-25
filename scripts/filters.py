#!/usr/bin/python3

import datetime

from heading import *

class KeywordFilter:
    def __init__(self, word):
        self.word = word

    def __repr__(self):
        return self.word

    def passed(self, heading):
        return heading.keyword == self.word

class TagFilter:
    def __init__(self, tag):
        self.tag = tag

    def __repr__(self):
        return self.tag

    def passed(self, heading):
        if self.tag[0] == '+':
            return self.tag[1:] in heading.tags
        if self.tag[0] == '-':
            return self.tag[1:] not in heading.tags
        raise RuntimeError('Used invalid tag filter')

class PathFilter:
    def __init__(self, path):
        self.path = path

    def __repr__(self):
        return self.path

    def passed(self, heading):
        return heading.path == self.path[0:len(heading.path)]

class DateFilter:
    def __init__(self, date):
        if date[1] == '=':
            self.cmp = date[0:2]
            self.date = datetime.datetime.strptime(date[2:], '%Y-%m-%d')
        else:
            self.cmp = date[0]
            self.date = datetime.datetime.strptime(date[1:], '%Y-%m-%d')

    def __repr__(self):
        return f"{self.cmp}{self.date}"

    def passed(self, heading):
        if heading.date is None:
            return False
        if self.cmp == '<':
            return heading.date < self.date
        elif self.cmp == '>':
            return heading.date > self.date
        elif self.cmp == '=':
            return heading.date == self.date
        elif self.cmp == '<=':
            return heading.date <= self.date
        elif self.cmp == '>=':
            return heading.date >= self.date

class Query:
    def __init__(self, lines):
        self.paths = []
        self.keywords = []
        self.tags = []
        self.dates = []
        self.parse(lines)

    def __str__(self):
        return f"Paths: {self.paths}\nKeywords: {self.keywords}\nTags: {self.tags}\nDates: {self.dates}"

    def parse(self, lines):
        for line in lines:
            words = line.split()
            for i, word in enumerate(words):
                if word[0] == '/':
                    self.paths.append(PathFilter(word))
                elif word[0] in ('+', '-'):
                    self.tags.append(TagFilter(word))
                elif word in KEYWORDS:
                    self.keywords.append(KeywordFilter(word))
                elif word[0] in ('<', '>', '='):
                    self.dates.append(DateFilter(word))

    def passed(self, heading):
        if self.keywords and not any(f.passed(heading) for f in self.keywords):
            return False
        if self.tags and not all(f.passed(heading) for f in self.tags):
            return False
        if self.dates and not all(f.passed(heading) for f in self.dates):
            return False
        return (not self.paths) or any(f.passed(heading) for f in self.paths)

if __name__ == '__main__':
    import sys
    query = Query(sys.argv[1:])
    for heading in from_fields_file(sys.stdin):
        if query.passed(heading):
            print(heading)

