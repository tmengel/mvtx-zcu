#!/usr/bin/env python3
"""Generic Testbench for testing different routines and interactive access to RU modules"""
import logging
import os
import sys
import errno
import fire
import time

script_path = os.path.dirname(os.path.realpath(__file__))
modules_path = os.path.join(
    script_path, '../../modules/board_support_software/software/py/')
sys.path.append(modules_path)
from module_includes import *

import communication
import ru_board
import can_hlp

# Static configuration parameters

USE_CRU = True
USB_COMM_EXEC = os.path.join(
    script_path, "../../modules/usb_if/software/usb_comm_server/build/usb_comm")
SERIAL_RDO = "000000"
SERIAL_CRU = "000001"

# Flag this module to run standalone. If yes, performe advanced setup
STANDALONE_RUN = False


class Testbench(object):
    """Testbench for executing different tests"""

    def __init__(self):
        # setup comms
        self.logger = None
        self.comm_rdo = None
        self.comm_cru = None
        self.rdo = None
        self.cru = None

        self.logger = logging.getLogger("testbench")
        if STANDALONE_RUN:
            self.setup_standalone()

    def setup_standalone(self):
        self.setup_logging()
        self.setup_comm_rdo()
        if USE_CRU:
            self.setup_comm_cru()
        self.setup_boards()

    def setup_logging(self):
        # Logging folder
        self.logdir = os.path.join(
            os.getcwd(),
            'logs/Testbench')
        try:
            os.makedirs(self.logdir)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        # setup logging
        logger = logging.getLogger()
        logger.setLevel(logging.INFO)

        log_file = os.path.join(self.logdir, "testbench.log")
        log_file_errors = os.path.join(self.logdir,
                                       "testbench_errors.log")

        fh = logging.FileHandler(log_file)
        fh.setLevel(logging.DEBUG)

        fh2 = logging.FileHandler(log_file_errors)
        fh2.setLevel(logging.ERROR)

        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

        fh.setFormatter(formatter)
        fh2.setFormatter(formatter)
        ch.setFormatter(formatter)

        logger.addHandler(fh)
        logger.addHandler(fh2)
        logger.addHandler(ch)

        self.logger = logger

    def setup_comm_rdo(self):
        """Setup Communication interface for RDO"""
        self.comm_rdo = communication.PyUsbComm(serialNr=SERIAL_RDO)

    def setup_comm_cru(self):
        """Setup Communication interface for CRU"""
        self.comm_cru = communication.PyUsbComm(serialNr=SERIAL_CRU)

    def stop(self):
        self.comm_rdo.stop()
        if USE_CRU:
            self.comm_cru.stop()

    def setup_rdo(self):
        self.rdo = ru_board.RUv1(self.comm_rdo)

    def setup_cru(self):
        self.cru = ru_board.RUv0_CRU(self.comm_cru)

    def setup_boards(self):
        """Setup board classes"""
        self.setup_rdo()
        if USE_CRU:
            self.setup_cru()

    def initialize_gbtx(self, gbtx=3, xml="../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml"):
        assert gbtx in range(4)
        comm_old = self.comm_rdo
        self.comm_rdo.stop()
        self.comm_rdo = communication.PyUsbComm(serialNr=SERIAL_RDO)
        self.setup_rdo()
        self.rdo.initialize()
        if gbtx < 3:
            self.rdo.i2c_gbtx.gbtx_config(filename=xml, gbtx=gbtx)
        else:
            self.rdo.i2c_gbtx.gbtx_config(filename=xml, gbtx=0)
            #self.rdo.i2c_gbtx.gbtx_config(filename=xml, gbtx=1)
            self.rdo.i2c_gbtx.gbtx_config(filename=xml, gbtx=2)
        self.comm_rdo.stop()
        self.comm_rdo = comm_old
        self.setup_rdo()

    def initialize_boards(self):
        self.rdo.initialize()

    def get_dna_value(self):
        return(hex(self.rdo.status.get_dna_value()))

    def version(self, get_pa3=False):
        git_hash_cru = self.cru.status.get_git_hash()
        git_hash_rdo = self.rdo.status.get_git_hash()
        if get_pa3:
            pa3_version = self.cru.pa3.get_version()

        self.logger.info("CRU Version: {0:07X}".format(git_hash_cru))
        self.logger.info("RDO Version: {0:07X}".format(git_hash_rdo))
        if get_pa3:
            self.logger.info("PA3 Version: {0:04X}".format(pa3_version))

    def can_read(self, wb_mod, reg, can_if='can0', can_dev_id=1, timeout_ms=100):
        """Do a CAN HLP read from wishbone module wb_mod, register reg"""
        can = can_hlp.CanHlp(can_if)
        return can.readHLP(can_dev_id, (wb_mod << 8 | reg), timeout_ms)

    def can_write(self, wb_mod, reg, data, can_if='can0', can_dev_id=1, timeout_ms=100):
        """Do a CAN HLP write to wishbone module wb_mod, register reg, value = data"""
        can = can_hlp.CanHlp(can_if)
        can.writeHLP(can_dev_id, (wb_mod << 8 | reg), data, timeout_ms)

    def calibrate_gbtx_phaseSel(self, gbtx_number):
        """Calibrate the phaseSel values of GBTx gbtx_number by determining the range of error free operation"""

        # i2c addresses of the phaseSel registers (triplicated)
        phaseSelAddr = [[69, 73, 77],     # Group 0 Ch 0
                        [67, 71, 75],     # Group 0 Ch 4
                        [93, 97, 101],    # Group 1 Ch 0
                        [91, 95, 99],     # Group 1 Ch 4
                        [117, 121, 125],  # Group 2 Ch 0
                        [115, 119, 123],  # Group 2 Ch 4
                        [141, 145, 149],  # Group 3 Ch 0
                        [139, 143, 147],  # Group 3 Ch 4
                        [165, 169, 173],  # Group 4 Ch 0
                        [163, 167, 171]]  # Group 4 Ch 4

        self.cru.comm.discardall_dp1(20)
        self.rdo.comm.discardall_dp1(20)
        # since we are sending random patterns,
        # make sure they are not interpreted as wishbone transactions
        self.cru.set_gbtx_forward_to_usb(0)
        self.cru.set_test_pattern(0)
        # load config files
        # self.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv2.xml", 0)
        self.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
        # self.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx2_Config_RUv2.xml", 2)
        self.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 2)
        time.sleep(1)
        self.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx1_Config.xml", 1)
        time.sleep(1)
        # make sure GBTx connected to CRU
        assert self.cru.is_gbt_rx_ready()

        # set PRBS pattern mode (requires branch JS_add_prbs_pattern in CRU emulator)
        self.cru.set_test_pattern(7)
        self.cru.reset_error_flags()
        st_flags = self.cru.get_status_flags()
        self.logger.info(st_flags)
        assert (st_flags['GbtRxDataErrorseenFlag'] == 0) and (st_flags['GbtRxReadyLostFlag'] == 0)

        # read current phaseSel values and vary over whole range,
        # finding values where the error flags are 0
        for i in range(10):
            current = self.rdo.i2c_gbtx.read_data(gbtx_number, phaseSelAddr[i][0])
            low = 0
            hi = 0
            foundLo = False
            foundHi = False
            for j in range(16):
                for k in range(3):
                    self.rdo.i2c_gbtx.write_data(gbtx_number, phaseSelAddr[i][k], j)
                time.sleep(0.05)
                self.cru.reset_error_flags()
                time.sleep(0.5)
                st_flags = self.cru.get_status_flags()
                if (st_flags['GbtRxDataErrorseenFlag'] == 0) and (not foundLo):
                    low = j
                    foundLo = True
                elif (st_flags['GbtRxDataErrorseenFlag'] == 1) and foundLo and (not foundHi):
                    hi = j - 1
                    foundHi = True
            # reset phaseSel to original value
            for k in range(3):
                self.rdo.i2c_gbtx.write_data(gbtx_number, phaseSelAddr[i][k], current)
            self.cru.reset_error_flags()
            self.logger.info("elink {}: current {:>2d} range {:>2d} to {:2d}, middle {:>2d}"
                             .format(i, current, low, hi, int((hi - low)/2 + low)))
        self.cru.set_test_pattern(0)
        self.cru.reset_error_flags()


if __name__ == "__main__":
    STANDALONE_RUN = True
    tb = Testbench()
    try:
        fire.Fire(tb)
    except:
        raise
    finally:
        tb.stop()
