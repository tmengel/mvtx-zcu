"""!@file polling_functions.py : Purpose
8/17/18:17
@author = Magnus (magnus.ersdal@uib.no)
"""
from utils.timeout import timeout

@timeout(0.6)
def poll(reg, condexpr, name):
    i = 0
    kvalues = set()
    while True:
        k = reg.read()
        ready = condexpr(k)
        kvalues.add(hex(k))
        if ready:
            break
        i += 1
        if i % 100 == 0:
            pass
            # print("{} waiting, i:{}, k:{:02X} \n values:{}".format(name, i, k, kvalues))
