#!/bin/python3

import datetime
import itertools
import sys

import headings
import priority

days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--keywords', default='TODO,NEXT,STARTED,|,DONE,MISSED,CANCELLED')
    parser.add_argument('--convert', action='store_true', default=False)
    args = parser.parse_args()
    keywords = args.keywords.split(',')
    inputs = headings.from_fields_file(sys.stdin)
    todos = filter(headings.has_date, inputs)
    todos = filter(headings.is_pending(keywords), todos)
    todos = sorted(todos, key=priority.date_key)
    todos = itertools.groupby(todos, key=priority.date_key)
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
        prioritized = sorted(todo_group, key=priority.priority_key(keywords))
        for todo in prioritized:
            if args.convert:
                print(headings.serialize_to_agenda(todo))
            else:
                print(headings.serialize_to_fields(todo))

