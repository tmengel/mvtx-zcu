import sys
import re
import os
#from decimal import Decimal
from collections import OrderedDict

TIMING_START=r"Design Timing Summary"
TIMING_VALUES=r"\s*(\S*)\s*(\S*)\s*(\S*\s\S*\s\S*)\s*(\S*\s\S*\s\S*)\s*(\S*)\s*(\S*)\s*(\S*\s\S*\s\S*)\s*(\S*\s\S*\s\S*)\s*(\S*)\s*(\S*)\s*(\S*\s\S*\s\S*)\s*(\S*\s\S*\s\S*).*"
#TIMING_VALUES=r"\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*(\S*).*"


def match_string(line, values_re):
    match_list = []
    #print(line)
    val = values_re.match(line)
    if val:
        for group_index in range(1,13):
            match_list.append(val.group(group_index))
    return match_list


def parse(filename):
    start_re = re.compile(TIMING_START)
    values_re = re.compile(TIMING_VALUES)
    raw = OrderedDict()
    with open(filename) as f:
        found_start = False
        for line in f:
            if start_re.search(line):
                found_start = True
                count = -1
            if found_start:
                count += 1
                if count == 4:
                    keys = match_string(line, values_re)
                if count == 6:
                    values = match_string(line, values_re)
                    break
        assert len(keys) == len(values)
        for key, value in zip(keys, values):
            raw[key] = float(value)

    return raw

def abort(raw, key, value):
    print(raw)
    sys.exit("Timing violation for {0} with {1:.03f}".format(key, value))

def analyse(raw):
    for key in raw.keys():
        value = raw[key]
        if key == 'WNS(ns)':
            if value < 0:
                abort(raw, key, value)
        if key == 'TNS Failing Endpoints':
            if value > 0:
                abort(raw, key, value)
        if key == 'WHS(ns)':
            if value < 0:
                abort(raw, key, value)
        if key == 'WPWS(ns)':
            if value < 0:
                abort(raw, key, value)

def main(filename):
        raw = parse(filename)
        print(raw)
        analyse(raw)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit("Usage \"python {0} timing_report.rpt\"".format(sys.argv[0]))
    filename = sys.argv[1]
    if not os.path.isfile(filename):
        sys.exit("{0} not existing".format(filename))

    main(filename)
