#!/bin/python3

import datetime
import itertools
import sys

days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

def keyword_weights():
    weights = {}
    if KEYWORDS:
        sep = KEYWORDS.index('|')
        for keyword in KEYWORDS[sep+1:]:
            weights[keyword] = len(KEYWORDS)
        idx = 1
        while idx <= sep:
            weights[KEYWORDS[sep - idx]] = idx
            idx += 1
    return weights

def priority_key():
    weights = keyword_weights(KEYWORDS)
    return lambda heading: weights[heading.keyword] if heading.keyword in weights else len(weights.keys()) - 1

def date_key(heading):
    if heading.date is None:
        return datetime.date(datetime.MAXYEAR, 1, 1)
    return heading.date

def has_date(heading):
    return heading.date is not None

def is_pending(heading):
    if heading.keyword not in KEYWORDS:
        return False
    return KEYWORDS.index(heading.keyword) < KEYWORDS.index('|')

if __name__ == '__main__':
    import argparse
    inputs = from_fields_file(sys.stdin)
    todos = filter(has_date, inputs)
    todos = filter(is_pending, todos)
    todos = sorted(todos, key=date_key)
    todos = itertools.groupby(todos, key=date_key)
    today = datetime.date.today()
    warned = False

    for date, todo_group in todos:
        if date < today and not warned:
            warned = True
            print('\n! Overdue !')
        elif date == today:
            print ('\n= Today =')
        elif date > today:
            print('\n= %s %s =' % (days[date.weekday()], date))
        prioritized = sorted(todo_group, key=priority_key())
        for todo in prioritized:
            print(todo)

