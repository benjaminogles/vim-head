#!/bin/python3

import datetime
import sys

import headings

def keyword_weights(keywords):
    weights = {}
    if keywords:
        try:
            sep = keywords.index('|')
        except ValueError:
            sep = len(keywords) - 1
        for keyword in keywords[sep+1:]:
            weights[keyword] = len(keywords)
        idx = 1
        while idx <= sep:
            weights[keywords[sep - idx]] = idx
            idx += 1
    return weights

def priority_key(keywords):
    weights = keyword_weights(keywords)
    return lambda heading: weights[heading.keyword] if heading.keyword in weights else len(weights.keys()) - 1

def date_key(heading):
    date = heading.date
    if not len(date):
        return datetime.date(datetime.MAXYEAR, 1, 1)
    date_str = date.split(' ')[0].split('-')
    return datetime.date(int(date_str[0]), int(date_str[1]), int(date_str[2]))

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--keywords', default='TODO,NEXT,STARTED,|,DONE,MISSED,CANCELLED')
    parser.add_argument('--convert', action='store_true', default=False)
    args = parser.parse_args()
    keywords = args.keywords.split(',')
    inputs = headings.from_fields_file(sys.stdin)
    todos = sorted(inputs, key=priority_key(keywords))

    for todo in todos:
        if args.convert:
            print(headings.serialize_to_agenda(todo))
        else:
            print(headings.serialize_to_fields(todo))

