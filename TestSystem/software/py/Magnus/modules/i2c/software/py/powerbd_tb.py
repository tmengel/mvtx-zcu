#!/usr/bin/env python

# JS: This script uses Google Fire to provide an interactive
#     interface for calling the various class methods
#     https://github.com/google/python-fire
#     To install Google Fire do:
#
#     pip install fire
#
#     To call one of the methods, use e.g. the following:
#
#     python ./powerbd_tb.py RaiseThresholdsToMax 1
#

import logging
import logging.handlers
import sys
import os
import fire

sys.path.append('../../../../modules/board_support_software/software/py/')
from module_includes import *

import communication
from userdefinedexceptions import *

import powerbd

SERIAL_RDO = '000000'


if __name__ == "__main__":
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    # create console handler and set level to INFO
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    # connect to USB
    #comm = communication.PyUsbComm()
    comm = communication.PyUsbComm(serialNr=SERIAL_RDO)

    pb = powerbd.PowerBoard(comm, logger, 4)

    # start fire
    fire.Fire(pb)
