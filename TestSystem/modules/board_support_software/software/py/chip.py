"""file for the abstraction chip abstraction layer"""
import logging


class Chip(object):
    """Basic Chip class describing a generic ALPIDE/pALPDIDE chip.

    This abstract class provides the basic W/R blocks used
    to write and read data between chip and host.

    This is an abstract class, and is NOT intended to be used
    directly. Instead, use the actual implementations ALPIDE/pALPIDE instead

    """

    def __init__(self, board, chipid, modulename,
                 readback=False, log=False, commitTransaction=True):
        assert chipid | 0x7F == 0x7F
        self.chipid = chipid
        self.readback = readback
        self.log = log
        self.commitTransaction = commitTransaction
        self.board = board
        self.modulename = modulename
        self.logger = logging.getLogger(self.modulename)

    def write_reg(self, address, data,
                  commitTransaction=None, readback=None, log=None, verbose=False):
        """Basic write function which makes use of a single address"""
        assert address | 0xFFFF == 0xFFFF
        assert data | 0xFFFF == 0xFFFF
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if log == None:
            log = self.log
        if readback == None:
            readback = self.readback
        self.board.write_chip_reg(address=address, data=data,
                                  chipid=self.chipid, commitTransaction=commitTransaction,
                                  readback=readback)
        if verbose:
            print(("Chip: write to register: 0x{0:04X}, \tvalue: 0x{1:04X}," +
                   " \tchipid: {2:02X}, commit={3}").format(address, data, self.chipid,commitTransaction))
        if log:
            logmessage = "Chip: write to register: 0x{0:04X}, \tvalue: 0x{1:04X}".format(
                address, data)
            if verbose:
                self.logger.info(logmessage)
            else:
                self.logger.debug(logmessage)

    def write_region_reg(self, rgn_add, base_add, sub_add, data,
                         readback=None, log=None, commitTransaction=None, verbose=False):
        """Basic function to write to a chip register using the extended address"""
        assert rgn_add | 0x1F == 0x1F
        assert base_add | 0x7 == 0x7
        assert sub_add | 0xFF == 0xFF
        self.write_reg(address=(rgn_add & 0x1F) << 11 | (base_add & 0x7) << 8 | sub_add & 0xFF, data=data,
                       readback=readback, log=log,
                       commitTransaction=commitTransaction, verbose=verbose)

    def write_opcode(self, opcode, commitTransaction=None, log=None, verbose=False):
        """basic function to send an opcode to the chip by calling the corresponding
           function on the board"""
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        self.board.write_chip_opcode(opcode=opcode, commitTransaction=commitTransaction)
        if verbose:
            print(("Chip: write opcode: 0x{0:04X} [chipid ignored!]").format(opcode))
        if log:
            logmessage = "Chip: write opcode: 0x{0:04X}".format(opcode)
            if verbose:
                self.logger.info(logmessage)
            else:
                self.logger.debug(logmessage)

#        result = self.getreg_cmu_and_dmu_status()
#        self.logger.info("Chipid: {0:#02x}, cmu_dmu_cfg: {1}".format(self.chipid,result[1]))

    def read_reg(self, address, commitTransaction=True, log=None, verbose=False):
        """basic read_reg function invoking the corresponding board function"""
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if log == None:
            log = self.log
        assert address | 0xFFFF == 0xFFFF
        ret = self.board.read_chip_reg(address=address, chipid=self.chipid,
                                       commitTransaction=commitTransaction)
        if verbose:
            print(("Chip: read register: 0x{0:04X}, \tvalue: 0x{1:04X}," +
                   " \tchipid: {2:02X}").format(address, ret, self.chipid))
        if log:
            logmessage = "Chip: read register: 0x{0:04X}, \tvalue: 0x{1:04X}".format(
                address, ret)
            if verbose:
                self.logger.info(logmessage)
            else:
                self.logger.debug(logmessage)
        return ret

    def read_region_reg(self, rgn_add, base_add, sub_add, log=None, commitTransaction=None, verbose=False):
        """Basic function to write to a chip register using the extended address"""
        assert rgn_add | 0x1F == 0x1F
        assert base_add | 0x7 == 0x7
        assert sub_add | 0xFF == 0xFF
        self.read_reg(address=(rgn_add & 0x1F) << 11 | (base_add & 0x7) << 8 | sub_add & 0xFF,
                      commitTransaction=commitTransaction, verbose=verbose, log=log)

    ######################################
    # HLF common to pALPIDE and pALPIDE3 #
    ######################################

    def is_outer_barrel_master(self):
        """Check if chip is OB master"""
        return self.chipid > 0b0001111 and self.chipid & 0b111 == 0

    def is_outer_barrel_slave(self):
        """Check if chip is OB slave"""
        return self.chipid > 0b0001111 and self.chipid & 0b111 > 0

    def is_inner_barrel(self):
        """Check if chip is IB"""
        return self.chipid <= 0b1111

    def write_read_test(self, repeat, quiet=False):
        """abstract function (to be implemented on two different addresses in pALPIDE3 and pALPIDE) to execute multiple times the readback on the given register"""
        raise NotImplementedError

    # Higher level user functions
    def reset(self):
        """Reset the chip"""
        raise NotImplementedError

    def initialize(self):
        """Perform chip initialization procedure"""
        raise NotImplementedError

    def configure_dtu(self):
        """Configure DTU"""
        raise NotImplementedError

    def initialize_readout(self, PLLDAC=None, DriverDAC=None, PreDAC=None,
                           PLLDelayStages=None, PLLBandwidthControl=None,
                           commitTransaction=None, log=None, readback = None):
        """Perform initialization sequenca for readout"""
        raise NotImplementedError

    def reset_pll(self, commitTransaction=None, readback=None, log=None, verbose=False):
        """Reset the pll"""
        raise NotImplementedError

    def trigger(self, commitTransaction=None, readback=None, log=None, verbose=False):
        """Send a trigger to the chip"""
        raise NotImplementedError

    def propagate_comma(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate COMMA pattern from chip (for realignment)"""
        raise NotImplementedError

    def propagate_data(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate Data from chip"""
        raise NotImplementedError

    def propagate_prbs(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate PRBS test pattern from chip"""
        raise NotImplementedError

    def propagate_clock(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate 600 MHz clock from chip"""
        raise NotImplementedError

    def set_xoff(self,XOff=1,commitTransaction=None, readback=None, log=None, verbose=False):
        """Send XOFF to the chip. 1 -> Xoff, 0 -> Xon"""
        raise NotImplementedError

    def dump_config(self):
        """Return a configuration string of all registers on the chip"""
        raise NotImplementedError
