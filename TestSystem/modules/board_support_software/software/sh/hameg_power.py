#!/usr/bin/env python
import os
import sys
import array
import time
import platform
import logging
import logging.handlers
from datetime import datetime

sys.path.append('../py')
sys.path.append('../../../usb_if/software/usb_communication')

from hameg import Hameg

if(len(sys.argv) < 2):
    exit("usage: hameg_power <1/0/setup>");

do_power = sys.argv[1]

ps = Hameg('/dev/ttyHAMEG',reset=False)

if do_power == 'setup':
    ps.activate_output(False)
    ps.configure_channel(1,5.0,2.5)
    ps.configure_channel(2,5.0,2.0)
    ps.activate_channels([1,2])
elif do_power == '1':
    ps.activate_output(True)
elif do_power == '0':
    ps.activate_output(False)
    time.sleep(1)
    print(ps.get_voltage(1))
else:
    print("Power command not recognized: {0}".format(do_power))
