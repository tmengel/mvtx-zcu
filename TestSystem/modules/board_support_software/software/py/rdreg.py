#!/usr/bin/env python
import os
import sys
import array
import time
import platform

from module_includes import *
from communication import *

VID = 0x04b4
PID = 0x0008
# windows = 0, Linux = 2
if (platform.system() == 'Windows'):
    ITFID = 0
else:
    ITFID = 2

if(len(sys.argv) < 3):
    exit("usage: rdreg <mod_address> <register_address> [<serial_number>]");

try:
    mod_addr  = (int(sys.argv[1])) & 0xFFFF
except ValueError:
    exit("Could not extract register_address. Exit.")

try:
    reg_addr  = (int(sys.argv[2])) & 0xFFFF
except ValueError:
    exit("Could not extract register_address. Exit.")

#print "mod_addr 0x%x" % mod_addr
#print "reg_addr 0x%x" % reg_addr

if(len(sys.argv) == 4):
    comm = PyUsbComm(VID=VID,PID=PID,IF=ITFID,serialNr=sys.argv[3])
else:
    comm = PyUsbComm(VID=VID,PID=PID,IF=ITFID)

results = comm.single_read(mod_addr,reg_addr)
print("return: {0:#06x}".format(results))
