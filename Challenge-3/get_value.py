#!/usr/bin/python
#

import json
#import json.decoder.JSONDecodeError
import sys


some_object = """{"a":{"b":{"c":"d"}}}"""
key = "a/b/c"


def get_value(o, k):
    dict_object = {}
    if not isinstance(o, dict):
        try:
            dict_object = json.loads(o)
        except TypeError:
            sys.exit("Please input your json object as a string.")
        except json.decoder.JSONDecodeError:
            sys.exit("This does not appear to be a properly formatted json string.")
    else:
        dict_object = o

    tmp_object = dict_object
    path = k.split('/')
    l = len(path)
    for i, value in enumerate(path):
        tmp_object = tmp_object[value]
        if i == l - 1:
            print(tmp_object)
            sys.exit(0)


get_value(some_object, key)
