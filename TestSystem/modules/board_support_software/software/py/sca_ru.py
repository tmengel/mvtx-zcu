""" Generic SCA module

"""

import collections
import logging
import time
import collections
import datetime
from collections import OrderedDict
from enum import IntEnum
import json
import os
import traceback

from wishbone_module import WishboneModule
from gbt_sca import Sca
from gbt_sca import ScaBadErrorFlagError

class RuScaReg(IntEnum):
    """SCA wishbone module register mapping"""
    CTRL_STATUS    = 0
    TRID_CHANNEL   = 1
    LENGTH_COMMAND = 2 # writing
    LENGTH_ERROR   = 2 # reading
    DATA_LSB       = 3
    DATA_MSB       = 4


class Sca_RU(Sca, WishboneModule):
    """Class to implement SCA GBT transactions"""

    def __init__(self, moduleid, board_obj, use_adc=True, use_gpio=True, use_pa3_i2c=True, use_us_i2c=True):
        WishboneModule.__init__(self, moduleid=moduleid, name="Sca_RU", board_obj=board_obj)
        Sca.__init__(self, use_adc=use_adc, use_gpio=use_gpio, use_pa3_i2c=use_pa3_i2c, use_us_i2c=use_us_i2c)

    def _sca_write(self, channel, length, command, scadata, trid=0x12, commitTransaction=True, wait=500):
        if not commitTransaction:
            self.logger.warning("commitTransaction==False is ignored")
        assert (channel & 0xffffff00) == 0, "channel must be 8bit"
        assert (length & 0xffffff00) == 0, "length must be 8bit"
        assert (command & 0xffffff00) == 0, "command must be 8bit"
        assert (trid & 0xffffff00) == 0, "trid must be 8bit"

        # fill HDLC payload
        val = (trid<<8) | (channel & 0xff)
        self.write(RuScaReg.TRID_CHANNEL, val, False)

        val = ((length&0xff)<<8) | (command & 0xff)
        self.write(RuScaReg.LENGTH_COMMAND, val, False)

        val = scadata & 0xFFFF
        self.write(RuScaReg.DATA_LSB, val, False)

        val = (scadata>>16) & 0xFFFF
        self.write(RuScaReg.DATA_MSB, val, False)

        # Send SCA Payload
        self.write(RuScaReg.CTRL_STATUS, 0x4, False)

        if wait > 0:
            self.firmware_wait(wait, False)
        self.sca_write_check_results(trid=trid)                
                
    def sca_write_check_results(self, trid=0x12):
        self.read(RuScaReg.CTRL_STATUS,False)  # status
        self.read(RuScaReg.TRID_CHANNEL,False) # TRID & CH
        self.read(RuScaReg.LENGTH_ERROR,False) # LEN & ERR
        results = self.read_all()
        retlen = len(results)

        # consider only the last 3 values read,
        # in case the previous transaction was not committed.

        # check the various status flags
        try:
            assert retlen==3, "returned {0} values, expected 3".format(retlen)
            ctrl_status_read = results[retlen-3]
            trid_read = results[retlen-2]>>8
            sca_error_flags = results[retlen-1]&0xff
            
            assert (ctrl_status_read & 0x1) == 1, "Status register return incorrect {0:04X} expected 0x0001 (SCA DID NOT FINISH THE READ? => try waiting for longer time...)".format(ctrl_status_read)
            if (sca_error_flags) != 0:
                raise ScaBadErrorFlagError(sca_error_flags)
            assert (trid_read) == (trid), \
                "Transaction ID sent 0x{0:04X}, received 0x{1:04X}".format(trid,trid_read)
        except AssertionError as ae:
            self.logger.warning(traceback.format_exc())
            message = ae.args[0]
            message += "\n results value is {0}".format(results)
            message += "\n Trying to read data from DP1"
            message += "\n{0} bytes read (0 expected)".format(self.board.comm.discardall_dp1(10))
            ae.args = (message,)
            raise ae
        
    def _sca_read(self):
        self.read(RuScaReg.DATA_LSB,False)
        self.read(RuScaReg.DATA_MSB,False)
        results = self.read_all()
        retlen = len(results)

        # consider only the last 2 values read,
        # in case the previous transaction was not committed.

        # check the various status flags
        try:
            assert retlen==2, "returned {0} values, expected 2".format(retlen)
        except AssertionError as ae:
            self.logger.warning(traceback.format_exc())
            message = ae.args[0]
            message += "\n results value is {0}".format(results)
            message += "\n Trying to read data from DP1"
            message += "\n{0} bytes read (0 expected)".format(self.board.comm.discardall_dp1(10))
            ae.args = (message,)
            raise ae
        # return the data 32bit formatted
        return ((results[retlen-1]<<16) | (results[retlen-2]))

    def init_communication(self):
        self.HDLC_reset(commitTransaction=True)
        self.HDLC_connect(commitTransaction=True)
        self.clear_status_latch(commitTransaction=True)

    def HDLC_reset(self, commitTransaction=True):
        self.write(RuScaReg.CTRL_STATUS,0x2,commitTransaction=commitTransaction)

    def HDLC_connect(self, commitTransaction=True):
        self.write(RuScaReg.CTRL_STATUS,0x1,commitTransaction=commitTransaction)

    def get_status_latch(self, commitTransaction=True):
        """Returns the value of the status latch,
        ignore the value for clear"""
        return self.read(RuScaReg.CTRL_STATUS,commitTransaction=commitTransaction)

    def clear_status_latch(self, commitTransaction=True):
        """Reads the status
        latch ignoring the return value to clear it"""
        self.get_status_latch(commitTransaction=commitTransaction)
