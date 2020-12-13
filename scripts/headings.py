#!/usr/bin/python3

import collections
import datetime
import re
import sys

Heading = collections.namedtuple('Heading', ['filename', 'lnum', 'bottom', 'level', 'keyword', 'date', 'warning', 'repeat', 'path', 'tags', 'meta'])

filter_regex = re.compile('^#')
path_regex = re.compile('^#\s*/(.*)$')
meta_regex = re.compile('\s*:(\S+):(.*)$')
grep_regex = re.compile('^(.*\.hd):(\d+):(.*)$')

class Filter:
    def __init__(self, keywords, filters):
        self.keywords = keywords
        self.tags = []
        self.words = []
        self.paths = []
        for filter_line in filters:
            self.add(filter_line)

    def add(self, spec):
        m = path_regex.match(spec)
        if m:
            self.paths.append(m.group(1).strip())
        else:
            specs = spec[1:].strip().split()
            for word in specs:
                if word in self.keywords:
                    self.words.append(word)
                elif word[0] in ('+', '-'):
                    self.tags.append(word)

    def passes(self, heading):
        if self.words and heading.keyword not in self.words:
            return False
        if self.paths:
            for path in self.paths:
                if not heading.path.strip('/').startswith(path):
                    return False
        if self.tags:
            for tag in self.tags:
                if tag[0] == '-' and tag[1:] in heading.tags:
                    return False
                elif tag[0] == '+' and tag[1:] not in heading.tags:
                    return False
        return True

def is_pending(keywords):
    try:
        sep = keywords.index('|')
    except ValueError:
        sep = len(keywords)
    return lambda heading: heading.keyword in keywords[:sep]

def has_date(heading):
    return bool(len(heading.date))

def build_regex(keywords):
    words = filter(lambda s: '|' not in s, keywords)
    stars = '^(\*+)\s*'
    keyword = '(' + '|'.join(words) + ')?\s*'
    date = '(<([-0-9]{10})\s*([:0-9]{5})?\s*(-[0-9]+[mdyhM])?\s*(\+[0-9]+[mdyhM])?>)?\s*'
    title = '([^:]+)?\s*'
    tags = '(:.*:)?\s*$'
    return re.compile(stars + keyword + date + title + tags)

def from_fields(fields):
    tags = [t for t in fields[9] if t]
    meta = {}
    for metastr in fields[10:]:
        parts = metastr.strip().split('=')
        if len(parts) == 2:
            if parts[0] not in meta:
                meta[parts[0]] = []
            meta[parts[0]].append(parts[1])
    filename = fields[0]
    lnum = int(fields[1])
    bottom = int(fields[2]) if isinstance(fields[2], str) and fields[2].isdigit() else fields[2]
    level = int(fields[3])
    return Heading(filename, lnum, bottom, level, *fields[4:9], tags, meta)

def from_field_str(field_str):
    fields = field_str.strip().split('|')
    if len(fields) >= 10 and fields[8].strip():
        fields[8] = fields[8].strip()
        fields[9] = fields[9].strip(': \t\n').split(':')
        return from_fields(fields)
    return None

def from_fields_strs(lines):
    return filter(None, map(from_field_str, lines))

def from_fields_file(stream):
    return from_fields_strs(stream.readlines())

class Parser:
    def __init__(self, keywords, filters):
        self.regex = build_regex(keywords)
        self.filter = Filter(keywords, filters)
        self.stack = []
        self.fields = []

    def parse(self, filename, lnum, line, headings):
        m = grep_regex.match(line)
        if m:
            filename = m.group(1)
            lnum = m.group(2)
            line = m.group(3)
        heading_m = self.regex.match(line)
        meta_m = meta_regex.match(line)

        if heading_m:
            groups = [heading_m.group(g) if heading_m.group(g) is not None else '' for g in range(10)]
            level = len(groups[1])
            keyword, _, date, time, warning, repeat, title = groups[2:9]
            datetime = date
            if time:
                datetime += ' ' + time
            tags = set(groups[9].strip(': \t\n').split(':'))

            while self.stack and self.stack[-1][3] >= level:
                parent = self.stack.pop()
                parent[2] = lnum - 1 # bottom
                heading = from_fields(parent)
                if self.filter.passes(heading):
                    headings.append(heading)
            for h in self.stack:
                tags.update(h[9])
            if self.stack:
                path = self.stack[-1][8] + '/' + title.strip()
            else:
                path = title.strip()

            self.fields = [filename, lnum, -1, level, keyword, datetime, warning, repeat, path, list(tags)]
            self.stack.append(self.fields)

        elif meta_m:
            self.fields.append(meta_m.group(1).strip() + '=' + meta_m.group(2).strip())

        return headings

    def finish(self, headings):
        while self.stack:
            fields = self.stack.pop()
            fields[2] = '$'
            heading = from_fields(fields)
            if self.filter.passes(heading):
                headings.append(heading)
        self.fields = []
        return headings

def from_source_file(stream, parser, headings=None):
    headings = headings if headings is not None else []
    lnum = 1
    line = stream.readline()
    while line:
        parser.parse(stream.name, lnum, line, headings)
        line = stream.readline()
        lnum += 1
    parser.finish(headings)
    return headings

def read_filters(stream):
    line = stream.readline()
    filters = []
    while line:
        if filter_regex.match(line):
            filters.append(line)
        else:
            break
        line = stream.readline()
    return filters

def serialize_to_fields(heading):
    parts = list(heading[:9])
    parts.append(':'.join(heading.tags))
    for key in heading.meta.keys():
        serialize_meta = lambda val: key + '=' + val
        parts.append('|'.join(map(serialize_meta, heading.meta[key])))
    return '|'.join(map(str, parts))

def serialize_to_agenda(heading):
    parts = list(heading[:3])
    pad = lambda s: s if not s else s + ' '
    datetime = lambda dt, w, r: '<' + ' '.join([dt, w, r]).strip() + '>' if dt else ''
    tags = lambda l: (':' + ':'.join(l) + ':') if l else ''
    text = pad('*' * heading.level)
    text += pad(heading.keyword)
    text += pad(datetime(heading.date, heading.warning, heading.repeat))
    text += pad(heading.path.split('/')[-1])
    text += pad(tags(heading.tags))
    parts.append(text)
    return '|'.join(map(str, parts))

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('filenames', nargs='*', default='')
    parser.add_argument('--keywords', default='TODO,NEXT,STARTED,|,DONE,MISSED,CANCELLED')
    args = parser.parse_args()
    keywords = args.keywords.split(',')
    heading_parser = Parser(keywords, read_filters(sys.stdin))
    for heading in from_source_file(sys.stdin, heading_parser):
        print(serialize_to_fields(heading))
    for filename in args.filenames:
        with open(filename, 'r') as stream:
            for heading in from_source_file(stream, heading_parser):
                print(serialize_to_fields(heading))

