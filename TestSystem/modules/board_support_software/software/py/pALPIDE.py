# coding: utf-8

"""file containing the ALPIDE class"""
# Imports
import logging
import random
import time
from collections import OrderedDict

from chip import Chip
from userdefinedexceptions import DataReadbackMismatchError
# Valid opcodes:


class Opcode(object):
    """Opcodes supported by ALPIDE"""
    GRST = 0x00D2
    PRST = 0x00E4
    PULSE = 0x0078
    BCRST = 0x0036
    RORST = 0x0063
    DEBUG = 0x00AA
    TRIGGER = 0x00B1
    TRIGGER1 = 0x0055
    TRIGGER2 = 0x00C9
    TRIGGER3 = 0x002D
    WROP = 0x009C
    RDOP = 0x004E

class CommandRegisterOpcode(Opcode):
    """Class extending the opcodes the command register available commands"""
    CMUCLRERR = 0xFF00
    FIFOTEST = 0xFF01
    LOADOBDEFCFG = 0xFF02
    XOFF = 0xFF10
    XON = 0xFF11
    ADCMEASURE = 0xFF20


class Addr(object):
    """Addresses supported by ALPIDE (NOTE that only region indipendent addresses are supported here)"""

    CMD = (0 << 8) | 0
    MODE_CTRL = (0 << 8) | 1
    DISABLE_REGIONS_LSBS = (0 << 8) | 2
    DISABLE_REGIONS_MSBS = (0 << 8) | 3
    FROMU_CFG_1 = (0 << 8) | 4
    FROMU_CFG_2 = (0 << 8) | 5
    FROMU_CFG_3 = (0 << 8) | 6
    FROMU_PULSING1 = (0 << 8) | 7
    FROMU_PULSING_2 = (0 << 8) | 8
    FROMU_STATUS_1 = (0 << 8) | 9
    FROMU_STATUS_2 = (0 << 8) | 10
    FROMU_STATUS_3 = (0 << 8) | 11
    FROMU_STATUS_4 = (0 << 8) | 12
    FROMU_STATUS_5 = (0 << 8) | 13
    DAC_SETTINGS_DCLK_AND_MCLK_IO_BUFFERS = (0 << 8) | 14
    DAC_SETTINGS_CMU_IO_BUFFERS = (0 << 8) | 15
    CMU_AND_DMU_CFG = (0 << 8) | 16
    CMU_AND_DMU_STATUS = (0 << 8) | 17
    DMU_DATA_FIFO_LSBS = (0 << 8) | 18
    DMU_DATA_FIFO_MSBS = (0 << 8) | 19
    DTU_CFG = (0 << 8) | 20
    DTU_DACS = (0 << 8) | 21
    DTU_PLL_LOCK_1 = (0 << 8) | 22
    DTU_PLL_LOCK_2 = (0 << 8) | 23
    DTU_TEST_1 = (0 << 8) | 24
    DTU_TEST_2 = (0 << 8) | 25
    DTU_TEST_3 = (0 << 8) | 26
    BUSY_MIN_WIDTH = (0 << 8) | 27
    PIXEL_CFG = (5 << 8) | 0
    ANALOG_MONITOR_AND_OVERRIDE = (6 << 8) | 0
    VRESETP = (6 << 8) | 1
    VRESETD = (6 << 8) | 2
    VCASP = (6 << 8) | 3
    VCASN = (6 << 8) | 4
    VPULSEH = (6 << 8) | 5
    VPULSEL = (6 << 8) | 6
    VCASN2 = (6 << 8) | 7
    VCLIP = (6 << 8) | 8
    VTEMP = (6 << 8) | 9
    IAUX2 = (6 << 8) | 10
    IRESET = (6 << 8) | 11
    IDB = (6 << 8) | 12
    IBIAS = (6 << 8) | 13
    ITHR = (6 << 8) | 14
    BUFFER_BYPASS = (6 << 8) | 15
    ADC_CTRL = (6 << 8) | 16
    ADC_DAC_INPUT_VALUE_ = (6 << 8) | 17
    ADC_CALIBRATION_VALUE = (6 << 8) | 18
    ADC_AVSS_VALUE_ = (6 << 8) | 19
    ADC_DVSS_VALUE = (6 << 8) | 20
    ADC_AVDD_VALUE = (6 << 8) | 21
    ADC_DVDD_VALUE = (6 << 8) | 22
    ADC_VCASN_VALUE = (6 << 8) | 23
    ADC_VCASP_VALUE = (6 << 8) | 24
    ADC_VPULSEH_VALUE = (6 << 8) | 25
    ADC_VPULSEL_VALUE = (6 << 8) | 26
    ADC_VRESETP_VALUE = (6 << 8) | 27
    ADC_VRESETD_VALUE = (6 << 8) | 28
    ADC_VCASN2_VALUE = (6 << 8) | 20
    ADC_VCLIP_VALUE = (6 << 8) | 30
    ADC_VTEMP_VALUE = (6 << 8) | 31
    ADC_ITHR_VALUE = (6 << 8) | 32
    ADC_IREF_VALUE = (6 << 8) | 33
    ADC_IDB_VALUE = (6 << 8) | 34
    ADC_IBIAS_VALUE = (6 << 8) | 35
    ADC_IAUX2_VALUE = (6 << 8) | 36
    ADC_IRESET_VALUE = (6 << 8) | 37
    ADC_BG2V_VALUE = (6 << 8) | 38
    ADC_T2V_VALUE = (6 << 8) | 39
    SEU_ERROR_COUNTER = 0x700
    TEST_CONTROL = 0x0701


class Alpide(Chip):
    """ALPIDE chip

    agreed basic function structure

    setreg_<REGNAME>(self, <list of parameters=ManualDefaults>,
                  commitTransaction=None, log=None,
                  readback=None, verbose=False):
        \"\"\"DOCSTRING\"\"\"
        <Input Assertions>
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if log == None:
            log = self.log
        if readback == None:
            readback = self.readback

        datawrite = <parameter assignment>
        self.write_reg(address=address,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    getreg_<REGNAME>(self, commitTransaction=None, log=None, verbose=False):
        \"\"\"DOCSTRING\"\"\"
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if log == None:
            log = self.log

        dataread = self.read_reg(address=address,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)

        <dataread unwrap in dictionary>
        ret = {"ret": dataread, ...:...}
    """

    def __init__(self, board, chipid,
                 readback=False, log=False,
                 commitTransaction=True, chip_number = None):
        super(Alpide, self).__init__(board=board, chipid=chipid, modulename="ALPIDE.{0}".format(chipid),
                                     readback=readback, log=log,
                                     commitTransaction=commitTransaction)
        self.chipid = chipid
        self.logger = logging.getLogger(self.modulename)
        self.PLLLockCounter = None
        self.chip_number = chip_number

    # User functions
    def reset(self):
        """Reset the chip"""
        self.write_opcode(Opcode.GRST)
        self.logger.info("resetting chip")
        self.board.log_currents()

    def initialize(self, disable_manchester=1, grst=True, grst_use_opcode=True, cfg_ob_module=False):
        """Perform chip initialization procedure ([grst], manchester, RORST)"""
        assert disable_manchester | 1 == 1
        if grst:
            if grst_use_opcode:
                self.board.write_chip_opcode(Opcode.GRST)
            else:
                self.setreg_cmd(Command=Opcode.GRST)
        if cfg_ob_module:
            self.setreg_cmd(Command=Opcode.LOADOBDEFCFG)
            #TODO does not work
            self.logger.warning("Manchester will be enabled by default.")
        else:
            self.setreg_cmu_and_dmu_cfg(PreviousChipID=self.chipid&0xF, InitialToken=True, DisableManchester=disable_manchester,
                                        EnableDDR=True, commitTransaction=False)
        self.logger.info("initializing chip")
        self.board.log_currents()

    def configure_dtu(self,
                      PLLDAC=None, DriverDAC=None, PreDAC=None,
                      PLLDelayStages =None,
                      LockWaitCycles=None, UnlockWaitCycles=None,
                      commitTransaction=None, log=None, readback=None):
        """Configure DTU"""
        # default for now
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        self.setreg_dtu_test_1(TestEN=0,
                               commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_dacs(PLLDAC=PLLDAC, DriverDAC=DriverDAC, PreDAC=PreDAC,
                             commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_pll_lock_2(LockWaitCycles=LockWaitCycles, UnlockWaitCycles=UnlockWaitCycles,
                                   commitTransaction=commitTransaction, readback=readback, log=log)
        if PLLDelayStages is None:
            VcoDelayStages = PLLDelayStages
        else:
            stageregs = {5: 0b11, 4: 0b01, 3: 0b00}
            assert PLLDelayStages in stageregs
            VcoDelayStages = stageregs[PLLDelayStages]
        self.setreg_dtu_cfg(VcoDelayStages=VcoDelayStages,
                            PllOffSignal=0,
                            commitTransaction=commitTransaction, readback=readback, log=log)

    def initialize_readout(self, PLLDAC=None, DriverDAC=None, PreDAC=None,
                           PLLDelayStages=None,
                           commitTransaction=None, log=None, readback=None):
        """Perform initialization sequence for readout"""
        self.configure_dtu(PLLDAC=PLLDAC, DriverDAC=DriverDAC, PreDAC=PreDAC,
                           PLLDelayStages=PLLDelayStages,
                           commitTransaction=commitTransaction, log=log, readback=readback)
        self.propagate_data(commitTransaction,log,readback)
        self.reset_pll()
        self.init_pixel_matrix()
        self.setreg_mode_ctrl(ChipModeSelector=1,
                              commitTransaction=commitTransaction, log=log, readback=readback)
        self.board.write_chip_opcode(Opcode.RORST)
        self.pll_check_lock()
        for i in range(10):
            self.pll_check_lock()

    def initialize_readout_slave(self,commitTransaction=None, log=None, readback=None):
        """Perform readout sequence for Slave chip"""
        self.init_pixel_matrix()
        self.setreg_mode_ctrl(ChipModeSelector=1,
                              commitTransaction=commitTransaction, log=log, readback=readback)
        self.board.write_chip_opcode(Opcode.RORST)


    def reset_pll(self):
        """Reset the pll"""
        self.logger.info('resetting pll (updating ch.LockCounter)')
        self.setreg_dtu_cfg(PLLReset=1, readback=False,commitTransaction=False)
        self.setreg_dtu_cfg(PLLReset=0, readback=False,commitTransaction=False)
        self.board.wait(100)
        self.PLLLockCounter = self.getreg_dtu_pll_lock_1()[1]['LockCounter']

    def trigger(self, commitTransaction=None, readback=None, log=None, verbose=False):
        """Send a trigger to the chip"""
        commitTransaction, log, readback = self.set_default_variables(
            commitTransaction, log, readback)
        self.write_opcode(Opcode.TRIGGER, commitTransaction, log, verbose)

    def pulse(self, commitTransaction=None, readback=None, log=None, verbose=False):
        """Send a trigger to the chip"""
        commitTransaction, log, readback = self.set_default_variables(
            commitTransaction, log, readback)
        self.write_opcode(Opcode.PULSE, commitTransaction, log, verbose)

    def clear_cmuerrors(self, commitTransaction=None, readback=None, log=None, verbose=False):
        """Send a clear_cmuerrors to the chip"""
        commitTransaction, log, readback = self.set_default_variables(
            commitTransaction, log, readback)
        self.setreg_cmd(CommandRegisterOpcode.CMUCLRERR, commitTransaction, log, verbose)



    ##########
    # REGION #
    ##########

    def _region_control_register_set_double_column(self, region, value=0xFFFF,
                                                    readback=None, log=None, commitTransaction=None):
        """Set the region control registers to 1: disable reading all the columns"""
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        assert region | 0x1F == 0x1F
        assert value | 0xFFFF == 0xFFFF
        self.write_reg(address= region<<11 | 0x300,
                       data=value,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction)

    def region_control_register_mask_all_double_columns(self, broadcast=False, readback=None, log=None, commitTransaction=None):
        """Set the region control registers to 1: disable reading all the columns"""
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        if broadcast == True:
            assert readback == False
        if broadcast == True:

            self.write_reg(address=0x0310,
                           data=0xFFFF,
                           readback=readback,
                           log=log,
                           commitTransaction=commitTransaction)
        else:
            self.logger.info("masking all columns, one by one")
            for i in range(32):
                self._region_control_register_set_double_column(region=i,
                                                                value=0xFFFF,
                                                                readback=readback,
                                                                log=log,
                                                                commitTransaction=commitTransaction)

    def region_control_register_unmask_all_double_columns(self, broadcast = True,readback=None, log=None, commitTransaction=None):
        """Set the region control registers to 0: disable reading all the columns"""
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        if broadcast == True:
            assert readback == False
        if broadcast == True:
            self.write_reg(address=0x0310,
                           data=0x0000,
                           readback=readback,
                           log=log,
                           commitTransaction=commitTransaction)
        else:
            for i in range(32):
                self._region_control_register_set_double_column(region=i,
                                                                value=0x0000,
                                                                readback=readback,
                                                                log=log,
                                                                commitTransaction=commitTransaction)

    def _setreg_region_status_register(self, region, PixelStatus=None, MemoryStatus=None,
                                       readback=None, log=None, commitTransaction=None, verbose=False):
        """sets the region status register"""
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        assert region | 0x1F == 0x1F

        dataout = {}
        if None in [
                PixelStatus,
                MemoryStatus]:
            dataout = self._getreg_region_status_register(commitTransaction, log, verbose)[1]

        if PixelStatus is None:
            PixelStatus = dataout['PixelStatus']
        if MemoryStatus is None:
            MemoryStatus = dataout['MemoryStatus']

        # Writedata generation
        datawrite = (((PixelStatus & 0X1) << 1) |
                     ((MemoryStatus & 0X1) << 2))

        self.write_reg(address= region<<11 | 0x301,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    def _getreg_region_status_register(self, region, PixelStatus=None, MemoryStatus=None,
                                       readback=None, log=None, commitTransaction=None):
        """gets the region status register"""
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        assert region | 0x1F == 0x1F

        dataread = self.read_reg(address= region<<11 | 0x301,
                                   log=log,
                                   commitTransaction=commitTransaction)

        ret = OrderedDict()
        ret["PixelStatus"] = (dataread >> 0) & 0X1
        ret["MemoryStatus"] = (dataread >> 1) & 0X1
        ret["AllColumnsDisabled"] = (dataread >> 2) & 0X1

        return (dataread, ret)

    def region_control_register_pulse_gating(self,region,enabled_doublecolumns,
                                             log=False,commitTransaction=True):
        """Set the pulse gating Control register of a region. Expects a 16 bit mask for enabling a
        double columns within a region"""
        assert region is None or region | 0x1F == 0x1F
        assert enabled_doublecolumns | 0xFF == 0xFF


        if region is None:
            region_broadcast = 1
            region = 0
        else:
            region_broadcast = 0

        sub_add = (region_broadcast << 7) | (1<<3)

        self.write_region_reg(region, 0b100, sub_add, enabled_doublecolumns, log, False)
        self.write_region_reg(region, 0b100, region_broadcast << 7, 0x00, log, commitTransaction)


    ##########
    # MATRIX #
    ##########

    def init_pixel_matrix(self,readback=None, log=None, commitTransaction=None):
        """init the matrix by unmasking and disabling pulse"""
        # A - unmask all
        self._set_all_pixel_ff(value=0, pulse_notmask=0,
                               commitTransaction=commitTransaction,log=log,readback=readback)
        # B - disable pulse for all pixels
        self._set_all_pixel_ff(value=0, pulse_notmask=1,
                               commitTransaction=commitTransaction,log=log,readback=readback)


    def mask_all_pixels(self, readback=None,log=None,commitTransaction=None):
        """masks all the pixels"""
        self._set_all_pixel_ff(value=1, pulse_notmask=0,
                               commitTransaction=commitTransaction,log=log,readback=readback)

    def unmask_all_pixels(self, readback=None,log=None,commitTransaction=None):
        """unmasks all the pixels"""
        self._set_all_pixel_ff(value=0, pulse_notmask=0,
                               commitTransaction=commitTransaction,log=log,readback=readback)

    def pulse_all_pixels_enable(self, readback=None,log=None,commitTransaction=None):
        """enable pulse for all pixels"""
        self._set_all_pixel_ff(value=1, pulse_notmask=1,
                               commitTransaction=commitTransaction,log=log,readback=readback)
    def pulse_all_pixels_disable(self, readback=None,log=None,commitTransaction=None):
        """enable pulse for all pixels"""
        self._set_all_pixel_ff(value=0, pulse_notmask=1,
                               commitTransaction=commitTransaction,log=log,readback=readback)

    def _set_all_pixel_ff(self, value, pulse_notmask, readback=None,log=None,commitTransaction=None):
        """set the pixel FF for all the pixel on the given flop (mask or pulse) to the given value)"""
        assert value | 1 == 1
        assert pulse_notmask | 1 == 1
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=pulse_notmask, PIXCNFG_DATA=value,
                              commitTransaction=commitTransaction,log=log,readback=readback)
        sub_add = (1<<7) | 0x7
        self.write_region_reg(0x0, 0b100, sub_add, 0xFFFF, readback, log, commitTransaction)
        self.write_region_reg(0x0, 0b100, sub_add, 0, readback, log, commitTransaction)

    def unmask_reg(self, reg, readback=None, log=None, commitTransaction=None):
        """unmasks the region in the given reg"""
        reglist = self._2list(reg)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=0, PIXCNFG_DATA=0,
                              readback = readback, log=log, commitTransaction=False)
        for i_reg in reglist:
            self._address_reg(i_reg,
                              readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def unmask_row(self, row, readback=None, log=None, commitTransaction=None):
        """unmasks the row in the given reg"""
        rowlist = self._2list(row)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=0, PIXCNFG_DATA=0,
                              readback = readback, log=log, commitTransaction=False)
        for i_row in rowlist:
            self._address_row(i_row,
                              readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def mask_row(self, row, readback=None, log=None, commitTransaction=None):
        """masks the row in the given reg"""
        rowlist = self._2list(row)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=0, PIXCNFG_DATA=1,
                              readback = readback, log=log, commitTransaction=False)
        for i_row in rowlist:
            self._address_row(i_row,
                              readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()


    def unmask_col(self, col, readback=None, log=None, commitTransaction=None):
        """unmasks the column in the given reg"""
        collist = self._2list(col)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=0, PIXCNFG_DATA=0,
                              readback = readback, log=log, commitTransaction=False)
        for i_col in collist:
            self._address_col(i_col,
                              readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def unmask_pixel(self, pixel_coordinates, readback=None, log=None, commitTransaction=None):
        """unmasks the given pixels"""
        pixellist = self._2listoflists(pixel_coordinates)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=0, PIXCNFG_DATA=0,
                              readback = readback, log=log, commitTransaction=False)
        for i_pixel in pixellist:
            self._address_pixel(i_pixel[0],i_pixel[1],
                                readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def pulse_pixel_enable(self, pixel_coordinates, readback=None, log=None, commitTransaction=None):
        """Enable pulse for the given pixels"""
        pixellist = self._2listoflists(pixel_coordinates)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=1, PIXCNFG_DATA=1,
                              readback = readback, log=log, commitTransaction=False)
        for i_pixel in pixellist:
            self._address_pixel(i_pixel[0],i_pixel[1],
                                readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def pulse_row_enable(self, row, readback=None, log=None, commitTransaction=None):
        """disables the pulse for the row in the given reg"""
        rowlist = self._2list(row)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=1, PIXCNFG_DATA=1,
                              readback = readback, log=log, commitTransaction=False)
        for i_row in rowlist:
            self._address_row(i_row,
                              readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def pulse_row_disable(self, row, readback=None, log=None, commitTransaction=None):
        """disables the pulse for the row in the given reg"""
        rowlist = self._2list(row)
        self.setreg_pixel_cfg(PIXCNFG_REGSEL=1, PIXCNFG_DATA=0,
                              readback = readback, log=log, commitTransaction=False)
        for i_row in rowlist:
            self._address_row(i_row,
                              readback = readback, log=log, commitTransaction=False)
        if commitTransaction == None:
            commitTransaction = self.commitTransaction
        if commitTransaction:
            self.board.dctrl.flush()

    def _2listoflists(self, datalist):
        """if it is a single list, it transform it in lists of lists"""
        if datalist.__class__ == list:
            if datalist and datalist[0].__class__ == list:
                datalistoflists = datalist
            else:
                datalistoflists = []
                for i_list in datalist:
                    datalistoflists.append(i_list)
        else:
            raise Exception("""datalist is not a list, please insert a list to continue:
            \tdatalist {0}}""".format(datalist))
        return datalistoflists

    def _2list(self, data):
        """if data is a single value, it returns a list containing it, else return data"""
        if data.__class__ == list:
            datalist = data
        else:
            datalist = []
            datalist.append(data)
        return datalist

    def _address_reg(self, reg, readback=None, log=None, commitTransaction=None):
        """addressing a signle column of pixels"""
        assert reg | 0x1F == 0x1F # bit [15:11] address

        sub_addr_col = 0b11  # bit [1:0] address
        data_col = 0xFFFF
        self.write_region_reg(reg, 0b100, sub_addr_col, data_col, readback, log, commitTransaction)

        region_row = 0 # bit [15:11] address : DONTCARE!
        data_row = 0xFFFF
        sub_addr_row = 1<<7|1<<2 # bit [2] address
        self.write_region_reg(region_row, 0b100, sub_addr_row, data_row, readback, log, commitTransaction)

        self._clear_pixel_cfg_register(readback = readback, log=log,commitTransaction=commitTransaction)

    def _address_row(self, row, readback=None, log=None, commitTransaction=None):
        """addressing a signle row of pixels"""
        assert row | 0x1FF == 0x1FF

        region_row = row>>4 & 0x1F # bit [15:11] address
        row_lsb = row & 0xF # bit index data
        data_row = 1<<row_lsb
        sub_addr_row = 1<<2 # bit [2] address
        self.write_region_reg(region_row, 0b100, sub_addr_row, data_row, readback, log, commitTransaction)

        region_col = 0 # bit [15:11] address
        sub_addr_col = (1<<7)| 3  # bit [1:0] address
        data_col = 0xFFFF
        self.write_region_reg(region_col, 0b100, sub_addr_col, data_col, readback, log, commitTransaction)

        self._clear_pixel_cfg_register(readback = readback, log=log,commitTransaction=commitTransaction)

    def _address_col(self, col, readback=None, log=None, commitTransaction=None):
        """addressing a signle column of pixels"""
        assert col | 0x3FF == 0x3FF

        region_col = col>>5 & 0x1F # bit [15:11] address
        col_high_notlow = col>>4 & 1
        col_lsb = col & 0xF # bit index data
        sub_addr_col = 1<<col_high_notlow # bit [1:0] address
        data_col = 1<<col_lsb
        self.write_region_reg(region_col, 0b100, sub_addr_col, data_col, readback, log, commitTransaction)

        region_row = 0 # bit [15:11] address
        row_lsb = 0 # bit index data
        data_row = 0xFFFF
        sub_addr_row = 1<<7|1<<2 # bit [2] address
        self.write_region_reg(region_row, 0b100, sub_addr_row, data_row, readback, log, commitTransaction)

        self._clear_pixel_cfg_register(readback = readback, log=log,commitTransaction=commitTransaction)

    def _address_pixel(self, col, row, readback=None,log=None,commitTransaction=None):
        """unmasks a single pixel of the matrix"""
        assert col | 0x3FF == 0x3FF
        assert row | 0x1FF == 0x1FF

        region_col = col>>5 & 0x1F # bit [15:11] address
        col_high_notlow = col>>4 & 1
        col_lsb = col & 0xF # bit index data
        sub_addr_col = 1<<col_high_notlow # bit [1:0] address
        data_col = 1<<col_lsb
        self.write_region_reg(region_col, 0b100, sub_addr_col, data_col, readback, log, commitTransaction)

        region_row = row>>4 & 0x1F # bit [15:11] address
        row_lsb = row & 0xF # bit index data
        data_row = 1<<row_lsb
        sub_addr_row = 1<<2 # bit [2] address
        self.write_region_reg(region_row, 0b100, sub_addr_row, data_row, readback, log, commitTransaction)

        self._clear_pixel_cfg_register(readback = readback, log=log,commitTransaction=commitTransaction)

    def _clear_pixel_cfg_register(self, readback=None,log=None,commitTransaction=None):
        """clears the pixel config register"""
        region_all = 0
        sub_addr_all = 1<<7|0x7 # bit [2:0] address
        address=region_all<<11|0b100<<8|sub_addr_all
        self.write_reg(address, 0, readback = readback, log=log,commitTransaction=commitTransaction)

    def _read_pixel_config(self, col, row, readback=None,log=None,commitTransaction=None):
        """reads back the configuration of the row/col select"""
        assert col | 0x3FF == 0x3FF
        assert row | 0x1FF == 0x1FF

        region_col = col>>5 & 0x1F # bit [15:11] address
        col_high_notlow = col>>4 & 1
        col_lsb = col & 0xF # bit index data
        sub_addr_col = 1<<col_high_notlow # bit [1:0] address
        data_col = 1<<col_lsb
        address=region_col<<11|0b100<<8|sub_addr_col
        col_reg = self.read_reg(address)

        region_row = row>>4 & 0xF # bit [15:11] address
        row_lsb = row & 0xF # bit index data
        data_row = 1<<row_lsb
        sub_addr_row = 1<<2 # bit [2] address
        address=region_row<<11|0b100<<8|sub_addr_row
        row_reg = self.read_reg(address)

        return col_reg, row_reg

    ########
    # TEST #
    ########

    def write_read_test(self, repeat, address=Addr.DTU_TEST_2, quiet=False):
        """execute multiple times the readback on the DTU_test_register2 [default]"""
        assert repeat > 0
        assert address | 0xFFFF == 0xFFFF
        original = self.read_reg(address=address, commitTransaction=True, log=False, verbose=False)
        t0 = time.time()
        err_words = 0
        for i in range(repeat):
            if i % 5 == 0:
                if not quiet:
                    self.logger.debug("pALPIDE >> write_read_test >> {0}/{1} write executed".format(i, repeat))
            r = random.randrange(0, 1 << 16)
            try:
                self.write_reg(address=address, data=r, readback=True, log=True, commitTransaction=True)
            except DataReadbackMismatchError:
                err_words += 1

        # clean output
        self.write_reg(address=address, data=original)
        print(">> Readback test on Chipid {3} >> elapsed time {0}, Errors: {1}/{2}".format(time.time() - t0, err_words,
                                                                                           repeat, self.chipid))

    def set_default_variables(self, commitTransaction, log, readback=None):
        """Set default variables for write/read operations (resolve None)"""
        if commitTransaction is None:
            commitTransaction = self.commitTransaction
        if log is None:
            log = self.log
        if readback is None:
            readback = self.readback
        return (commitTransaction, log, readback)

    def pattern30(self,pattern):
        """ Propagate 30 bit pattern """
        self.setreg_dtu_test_1(TestEN=True,IntPatternEN=False,PrbsRate=0,Bypass8b10b=True,BDIN8b10b0=pattern>>8&3,BDIN8b10b1=pattern>>18&3,BDIN8b10b2=pattern>>28&3)
        self.setreg_dtu_test_2(DIN0=pattern&255,DIN1=pattern>>10&255)
        self.setreg_dtu_test_3(DIN2=pattern>>20&255)

    def propagate_pattern(self,pattern):
        self.pattern30(pattern)


    def pattern30(self,pattern):
        """ Propagate 30 bit pattern """
        self.setreg_dtu_test_1(TestEN=True,IntPatternEN=False,PrbsRate=0,Bypass8b10b=True,BDIN8b10b0=pattern>>8&3,BDIN8b10b1=pattern>>18&3,BDIN8b10b2=pattern>>28&3)
        self.setreg_dtu_test_2(DIN0=pattern&255,DIN1=pattern>>10&255)
        self.setreg_dtu_test_3(DIN2=pattern>>20&255)

    def propagate_pattern(self,pattern):
        self.pattern30(pattern)


    def propagate_comma(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate COMMA pattern from chip (for realignment)"""
        self.setreg_dtu_test_2(DIN0=0xBC, DIN1=0xBC, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_test_3(DIN2=0xBC, ForceSetLoadEN=0, ForceUnsetLoadEN= 0, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_test_1(TestEN=1, IntPatternEN=0, TestSingleMode=0, Bypass8b10b=0, K0=1, K1=1, K2=1)

    def propagate_data(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate Data from chip"""
        self.setreg_dtu_test_3(ForceSetLoadEN=0, ForceUnsetLoadEN= 0, DIN2=0, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_test_1(TestEN=0, IntPatternEN=0, TestSingleMode=0, PrbsRate=0,
                               BDIN8b10b0=0,BDIN8b10b1=0,BDIN8b10b2=0,K0=0,K1=0,K2=0,
                               Bypass8b10b=0, commitTransaction=commitTransaction, readback=readback, log=log)

    def propagate_prbs(self, PrbsRate=None,  commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate PRBS test pattern from chip"""
        self.setreg_dtu_test_3(ForceSetLoadEN=0, ForceUnsetLoadEN= 0,DIN2=0, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_test_1(TestEN=1, IntPatternEN=1, TestSingleMode=0, PrbsRate=PrbsRate,
                               BDIN8b10b0=0,BDIN8b10b1=0,BDIN8b10b2=0,K0=0,K1=0,K2=0,
                               Bypass8b10b=1, commitTransaction=commitTransaction, readback=readback, log=log)

    def propagate_clock(self,commitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate 600 MHz clock from chip"""
        self.logger.info(self.getreg_dtu_pll_lock_1(commitTransaction=commitTransaction, log=log)[1])
        #self.setreg_dtu_test_1(TestEN=1, IntPatternEN=0)
        self.setreg_dtu_test_3(ForceSetLoadEN=0, ForceUnsetLoadEN=1)

    def set_xoff(self,XOff=1,commitTransaction=None, readback=None, log=None, verbose=False):
        """Send XOFF to the chip. 1 -> Xoff, 0 -> Xon"""
        if XOff:
            self.write_opcode(Opcode.XOFF)
        else:
            self.write_opcode(Opcode.XON)

    def dump_config(self):
        """Dump chip configuration"""
        config_str = "-- Alpide configuration of chip {0}--\n".format(self.chipid)

        # get all getreg functions
        func_list = [x for x in Alpide.__dict__.values() if callable(x) and x.__name__.startswith('getreg')]
        for func in func_list:
            name = func.__name__.replace('getreg_', '')
            result = getattr(self, func.__name__)()
            config_str += "--- Register {0}, value: {1:#4X}\n".format(name, result[0])
            for name, value in result[1].items():
                config_str += "  - {0} : {1:#X}\n".format(name, value)

        config_str += "--- Register double columns disable\n".format(name)
        for i in range(32):
            address = i <<11 |0x300
            value = self.read_reg(address)
            config_str += "  - {0} : {1:#X}\n".format(address, value)
        return config_str

    def pll_check_lock(self):
        readreg = self.getreg_dtu_pll_lock_1()[1]
        is_locked = readreg['LockStatus']
        if self.PLLLockCounter is not None:
            if readreg['LockCounter'] == 255:
                self.logger.warning("PLL lock counter is 255, it reached the maximum value")
            if readreg['LockCounter'] != self.PLLLockCounter:
                self.logger.error("PLL lost lock, counter increase from {0} to {1}".format(self.PLLLockCounter, readreg['LockCounter']))
                self.logger.info("actual value of dtu_pll_lock_1 is {0}".format(readreg))
        self.PLLLockCounter = readreg['LockCounter']
        return is_locked

    ###########################
    # AUTOGENERATED FUNCTIONS #
    ###########################

    def setreg_cmd(self,
                   Command=None,
                   commitTransaction=None,
                   log=None,
                   readback=None,
                   verbose=False):
        """ Autogenerated function for Command Register.
        Register fields
        ===============
            Command                 [15:0] :   0x0

        Orgininal docstring
        ===================
        Command Register.
        Valid opcodes:
        16’h00D2			GRST
        16’h00E4			PRST
        16’h0078			PULSE
        16’h0036			BCRST
        16’h0063			RORST
        16’h00AA			DEBUG
        16’h00B1,0055,00C9,002D		TRIGGER
        16’h009C			WROP
        16’h004E			RDOP
        16’hFF00			CMUCLRERR
        16’hFF01			FIFOTEST
        16’hFF02			LOADOBDEFCFG
        16’hFF10			XOFF
        16’hFF11			XON
        16’hFF20			ADCMEASURE

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert Command is None or Command | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [Command]:
            dataout = self.getreg_cmd(commitTransaction, log, verbose)[1]

        if Command is None:
            Command = dataout['Command']

        # Writedata generation
        datawrite = (((Command & 0XFFFF) << 0))

        self.write_reg(address=Addr.CMD,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_cmd(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Command Register.
        Register fields
        ===============
            Command                 [15:0] :   0x0

        Orgininal docstring
        ===================
        Command Register.
        Valid opcodes:
        16’h00D2			GRST
        16’h00E4			PRST
        16’h0078			PULSE
        16’h0036			BCRST
        16’h0063			RORST
        16’h00AA			DEBUG
        16’h00B1,0055,00C9,002D		TRIGGER
        16’h009C			WROP
        16’h004E			RDOP
        16’hFF00			CMUCLRERR
        16’hFF01			FIFOTEST
        16’hFF02			LOADOBDEFCFG
        16’hFF10			XOFF
        16’hFF11			XON
        16’hFF20			ADCMEASURE

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.CMD,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["Command"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_mode_ctrl(self,
                         ChipModeSelector=None,
                         EnClustering=None,
                         MatrixROSpeed=None,
                         IBSerialLinkSpeed=None,
                         EnSkewGlobalSignals=None,
                         EnSkewStartReadout=None,
                         EnReadoutClockGating=None,
                         EnReadoutFromCMU=None,
                         commitTransaction=None,
                         log=None,
                         readback=None,
                         verbose=False):
        """ Autogenerated function for Mode Control register
        Register fields
        ===============
            ChipModeSelector         [1:0] :   0x0
            EnClustering               [2] :   0x1
            MatrixROSpeed              [3] :   0x1
            IBSerialLinkSpeed        [5:4] :   0x3
            EnSkewGlobalSignals        [6] :   0x1
            EnSkewStartReadout         [7] :   0x1
            EnReadoutClockGating       [8] :   0x1
            EnReadoutFromCMU           [9] :   0x0

        Orgininal docstring
        ===================
        Mode Control register
        Chip Mode Selector values:
        0=Cfg Mode, 1=Triggered Mode, 2=Continuous Mode
        EnClustering default = 1
        MatrixROSpeed 0=10MHz, 1=20MHz (default)
        IBSeriaLinkSpeed 0=400Mbit, 1=600Mbit, 2-3=1200Mbit (default)
        EnSkewGlobalSignals default = 1
        EnsSkewStartReadout default = 1
        EnClockGating default = 1

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert ChipModeSelector is None or ChipModeSelector | 0X3 == 0X3
        assert EnClustering is None or EnClustering | 0X1 == 0X1
        assert MatrixROSpeed is None or MatrixROSpeed | 0X1 == 0X1
        assert IBSerialLinkSpeed is None or IBSerialLinkSpeed | 0X3 == 0X3
        assert EnSkewGlobalSignals is None or EnSkewGlobalSignals | 0X1 == 0X1
        assert EnSkewStartReadout is None or EnSkewStartReadout | 0X1 == 0X1
        assert EnReadoutClockGating is None or EnReadoutClockGating | 0X1 == 0X1
        assert EnReadoutFromCMU is None or EnReadoutFromCMU | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [
                ChipModeSelector,
                EnClustering,
                MatrixROSpeed,
                IBSerialLinkSpeed,
                EnSkewGlobalSignals,
                EnSkewStartReadout,
                EnReadoutClockGating,
                EnReadoutFromCMU]:
            dataout = self.getreg_mode_ctrl(commitTransaction, log, verbose)[1]

        if ChipModeSelector is None:
            ChipModeSelector = dataout['ChipModeSelector']
        if EnClustering is None:
            EnClustering = dataout['EnClustering']
        if MatrixROSpeed is None:
            MatrixROSpeed = dataout['MatrixROSpeed']
        if IBSerialLinkSpeed is None:
            IBSerialLinkSpeed = dataout['IBSerialLinkSpeed']
        if EnSkewGlobalSignals is None:
            EnSkewGlobalSignals = dataout['EnSkewGlobalSignals']
        if EnSkewStartReadout is None:
            EnSkewStartReadout = dataout['EnSkewStartReadout']
        if EnReadoutClockGating is None:
            EnReadoutClockGating = dataout['EnReadoutClockGating']
        if EnReadoutFromCMU is None:
            EnReadoutFromCMU = dataout['EnReadoutFromCMU']

        # Writedata generation
        datawrite = (((ChipModeSelector & 0X3) << 0) |
                     ((EnClustering & 0X1) << 2) |
                     ((MatrixROSpeed & 0X1) << 3) |
                     ((IBSerialLinkSpeed & 0X3) << 4) |
                     ((EnSkewGlobalSignals & 0X1) << 6) |
                     ((EnSkewStartReadout & 0X1) << 7) |
                     ((EnReadoutClockGating & 0X1) << 8) |
                     ((EnReadoutFromCMU & 0X1) << 9))

        self.write_reg(address=Addr.MODE_CTRL,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_mode_ctrl(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Mode Control register
        Register fields
        ===============
            ChipModeSelector         [1:0] :   0x0
            EnClustering               [2] :   0x1
            MatrixROSpeed              [3] :   0x1
            IBSerialLinkSpeed        [5:4] :   0x3
            EnSkewGlobalSignals        [6] :   0x1
            EnSkewStartReadout         [7] :   0x1
            EnReadoutClockGating       [8] :   0x1
            EnReadoutFromCMU           [9] :   0x0

        Orgininal docstring
        ===================
        Mode Control register
        Chip Mode Selector values:
        0=Cfg Mode, 1=Triggered Mode, 2=Continuous Mode
        EnClustering default = 1
        MatrixROSpeed 0=10MHz, 1=20MHz (default)
        IBSeriaLinkSpeed 0=400Mbit, 1=600Mbit, 2-3=1200Mbit (default)
        EnSkewGlobalSignals default = 1
        EnsSkewStartReadout default = 1
        EnClockGating default = 1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.MODE_CTRL,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["ChipModeSelector"] = (dataread >> 0) & 0X3
        ret["EnClustering"] = (dataread >> 2) & 0X1
        ret["MatrixROSpeed"] = (dataread >> 3) & 0X1
        ret["IBSerialLinkSpeed"] = (dataread >> 4) & 0X3
        ret["EnSkewGlobalSignals"] = (dataread >> 6) & 0X1
        ret["EnSkewStartReadout"] = (dataread >> 7) & 0X1
        ret["EnReadoutClockGating"] = (dataread >> 8) & 0X1
        ret["EnReadoutFromCMU"] = (dataread >> 9) & 0X1

        return (dataread, ret)

    def setreg_disable_regions_lsbs(self,
                                    RegionDisable=None,
                                    commitTransaction=None,
                                    log=None,
                                    readback=None,
                                    verbose=False):
        """ Autogenerated function for Disable of regions 0-15
        Register fields
        ===============
            RegionDisable           [15:0] :   0x0

        Orgininal docstring
        ===================
        Disable of regions 0-15

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert RegionDisable is None or RegionDisable | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [RegionDisable]:
            dataout = self.getreg_disable_regions_lsbs(commitTransaction, log, verbose)[1]

        if RegionDisable is None:
            RegionDisable = dataout['RegionDisable']

        # Writedata generation
        datawrite = (((RegionDisable & 0XFFFF) << 0))

        self.write_reg(address=Addr.DISABLE_REGIONS_LSBS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_disable_regions_lsbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Disable of regions 0-15
        Register fields
        ===============
            RegionDisable           [15:0] :   0x0

        Orgininal docstring
        ===================
        Disable of regions 0-15

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DISABLE_REGIONS_LSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["RegionDisable"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_disable_regions_msbs(self,
                                    RegionDisable=None,
                                    commitTransaction=None,
                                    log=None,
                                    readback=None,
                                    verbose=False):
        """ Autogenerated function for Disable of regions 16-31
        Register fields
        ===============
            RegionDisable           [15:0] :   0x0

        Orgininal docstring
        ===================
        Disable of regions 16-31

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert RegionDisable is None or RegionDisable | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [RegionDisable]:
            dataout = self.getreg_disable_regions_msbs(commitTransaction, log, verbose)[1]

        if RegionDisable is None:
            RegionDisable = dataout['RegionDisable']

        # Writedata generation
        datawrite = (((RegionDisable & 0XFFFF) << 0))

        self.write_reg(address=Addr.DISABLE_REGIONS_MSBS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_disable_regions_msbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Disable of regions 16-31
        Register fields
        ===============
            RegionDisable           [15:0] :   0x0

        Orgininal docstring
        ===================
        Disable of regions 16-31

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DISABLE_REGIONS_MSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["RegionDisable"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_cfg_1(self,
                           MEBMask=None,
                           EnStrobeGeneration=None,
                           EnBusyMonitoring=None,
                           PulseMode=None,
                           EnPulse2Strobe=None,
                           EnRotatePulseLines=None,
                           TriggerDelay=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for FROMU Configuration Register 1
        Register fields
        ===============
            MEBMask                  [2:0] :   0x0
            EnStrobeGeneration         [3] :   0x0
            EnBusyMonitoring           [4] :   0x1
            PulseMode                  [5] :   0x0
            EnPulse2Strobe             [6] :   0x0
            EnRotatePulseLines         [7] :   0x0
            TriggerDelay            [10:8] :   0x0

        Orgininal docstring
        ===================
        FROMU Configuration Register 1

        EnBusyMonitoring default = 1



        Trigger delay, 0-175ns

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert MEBMask is None or MEBMask | 0X7 == 0X7
        assert EnStrobeGeneration is None or EnStrobeGeneration | 0X1 == 0X1
        assert EnBusyMonitoring is None or EnBusyMonitoring | 0X1 == 0X1
        assert PulseMode is None or PulseMode | 0X1 == 0X1
        assert EnPulse2Strobe is None or EnPulse2Strobe | 0X1 == 0X1
        assert EnRotatePulseLines is None or EnRotatePulseLines | 0X1 == 0X1
        assert TriggerDelay is None or TriggerDelay | 0X7 == 0X7

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [
                MEBMask,
                EnStrobeGeneration,
                EnBusyMonitoring,
                PulseMode,
                EnPulse2Strobe,
                EnRotatePulseLines,
                TriggerDelay]:
            dataout = self.getreg_fromu_cfg_1(commitTransaction, log, verbose)[1]

        if MEBMask is None:
            MEBMask = dataout['MEBMask']
        if EnStrobeGeneration is None:
            EnStrobeGeneration = dataout['EnStrobeGeneration']
        if EnBusyMonitoring is None:
            EnBusyMonitoring = dataout['EnBusyMonitoring']
        if PulseMode is None:
            PulseMode = dataout['PulseMode']
        if EnPulse2Strobe is None:
            EnPulse2Strobe = dataout['EnPulse2Strobe']
        if EnRotatePulseLines is None:
            EnRotatePulseLines = dataout['EnRotatePulseLines']
        if TriggerDelay is None:
            TriggerDelay = dataout['TriggerDelay']

        # Writedata generation
        datawrite = (((MEBMask & 0X7) << 0) |
                     ((EnStrobeGeneration & 0X1) << 3) |
                     ((EnBusyMonitoring & 0X1) << 4) |
                     ((PulseMode & 0X1) << 5) |
                     ((EnPulse2Strobe & 0X1) << 6) |
                     ((EnRotatePulseLines & 0X1) << 7) |
                     ((TriggerDelay & 0X7) << 8))

        self.write_reg(address=Addr.FROMU_CFG_1,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fromu_cfg_1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Configuration Register 1
        Register fields
        ===============
            MEBMask                  [2:0] :   0x0
            EnStrobeGeneration         [3] :   0x0
            EnBusyMonitoring           [4] :   0x1
            PulseMode                  [5] :   0x0
            EnPulse2Strobe             [6] :   0x0
            EnRotatePulseLines         [7] :   0x0
            TriggerDelay            [10:8] :   0x0

        Orgininal docstring
        ===================
        FROMU Configuration Register 1

        EnBusyMonitoring default = 1



        Trigger delay, 0-175ns

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_CFG_1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["MEBMask"] = (dataread >> 0) & 0X7
        ret["EnStrobeGeneration"] = (dataread >> 3) & 0X1
        ret["EnBusyMonitoring"] = (dataread >> 4) & 0X1
        ret["PulseMode"] = (dataread >> 5) & 0X1
        ret["EnPulse2Strobe"] = (dataread >> 6) & 0X1
        ret["EnRotatePulseLines"] = (dataread >> 7) & 0X1
        ret["TriggerDelay"] = (dataread >> 8) & 0X7

        return (dataread, ret)

    def setreg_fromu_cfg_2(self,
                           FrameDuration=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for FROMU Configuration Register 2
        Register fields
        ===============
            FrameDuration           [15:0] :  0x14

        Orgininal docstring
        ===================
        FROMU Configuration Register 2

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert FrameDuration is None or FrameDuration | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [FrameDuration]:
            dataout = self.getreg_fromu_cfg_2(commitTransaction, log, verbose)[1]

        if FrameDuration is None:
            FrameDuration = dataout['FrameDuration']

        # Writedata generation
        datawrite = (((FrameDuration & 0XFFFF) << 0))

        self.write_reg(address=Addr.FROMU_CFG_2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fromu_cfg_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Configuration Register 2
        Register fields
        ===============
            FrameDuration           [15:0] :  0x14

        Orgininal docstring
        ===================
        FROMU Configuration Register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_CFG_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["FrameDuration"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_cfg_3(self,
                           FrameGap=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for FROMU Configuration Register 3
        Register fields
        ===============
            FrameGap                [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Configuration Register 3

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert FrameGap is None or FrameGap | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [FrameGap]:
            dataout = self.getreg_fromu_cfg_3(commitTransaction, log, verbose)[1]

        if FrameGap is None:
            FrameGap = dataout['FrameGap']

        # Writedata generation
        datawrite = (((FrameGap & 0XFFFF) << 0))

        self.write_reg(address=Addr.FROMU_CFG_3,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fromu_cfg_3(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Configuration Register 3
        Register fields
        ===============
            FrameGap                [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Configuration Register 3

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_CFG_3,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["FrameGap"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_pulsing1(self,
                              PulseDelay=None,
                              commitTransaction=None,
                              log=None,
                              readback=None,
                              verbose=False):
        """ Autogenerated function for FROMU Pulsing Register1
        Register fields
        ===============
            PulseDelay              [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Pulsing Register1

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert PulseDelay is None or PulseDelay | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [PulseDelay]:
            dataout = self.getreg_fromu_pulsing1(commitTransaction, log, verbose)[1]

        if PulseDelay is None:
            PulseDelay = dataout['PulseDelay']

        # Writedata generation
        datawrite = (((PulseDelay & 0XFFFF) << 0))

        self.write_reg(address=Addr.FROMU_PULSING1,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fromu_pulsing1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Pulsing Register1
        Register fields
        ===============
            PulseDelay              [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Pulsing Register1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_PULSING1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["PulseDelay"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_pulsing_2(self,
                               PulseDuration=None,
                               commitTransaction=None,
                               log=None,
                               readback=None,
                               verbose=False):
        """ Autogenerated function for FROMU Pulsing Register 2
        Register fields
        ===============
            PulseDuration           [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Pulsing Register 2

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert PulseDuration is None or PulseDuration | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [PulseDuration]:
            dataout = self.getreg_fromu_pulsing_2(commitTransaction, log, verbose)[1]

        if PulseDuration is None:
            PulseDuration = dataout['PulseDuration']

        # Writedata generation
        datawrite = (((PulseDuration & 0XFFFF) << 0))

        self.write_reg(address=Addr.FROMU_PULSING_2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fromu_pulsing_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Pulsing Register 2
        Register fields
        ===============
            PulseDuration           [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Pulsing Register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_PULSING_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["PulseDuration"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status Register 1
        Register fields
        ===============
            TriggerCounter          [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Status Register 1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_STATUS_1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["TriggerCounter"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status Register 2
        Register fields
        ===============
            StrobeCounter           [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Status Register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_STATUS_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["StrobeCounter"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_3(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status Register 3
        Register fields
        ===============
            ReadoutCounter          [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Status Register 3

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_STATUS_3,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["ReadoutCounter"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_4(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status Register 4
        Register fields
        ===============
            FrameCounter            [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Status Register 4

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_STATUS_4,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["FrameCounter"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_5(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status Register 5
        Register fields
        ===============
            BunchCounter            [11:0] :   0x0
            EventCounter           [14:12] :   0x0
            FrameExtended             [15] :   0x0

        Orgininal docstring
        ===================
        FROMU Status Register 5

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_STATUS_5,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["BunchCounter"] = (dataread >> 0) & 0XFFF
        ret["EventCounter"] = (dataread >> 12) & 0X7
        ret["FrameExtended"] = (dataread >> 15) & 0X1

        return (dataread, ret)

    def setreg_dac_settings_dclk_and_mclk_io_buffers(self,
                                                     DCLKReceiver=None,
                                                     DCLKDriver=None,
                                                     MCLKReceiver=None,
                                                     commitTransaction=None,
                                                     log=None,
                                                     readback=None,
                                                     verbose=False):
        """ Autogenerated function for DAC settings for DCLK and MCLK I/O buffers
        Register fields
        ===============
            DCLKReceiver             [3:0] :   0xa
            DCLKDriver               [7:4] :   0xa
            MCLKReceiver            [11:8] :   0xa

        Orgininal docstring
        ===================
        DAC settings for DCLK and MCLK I/O buffers

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert DCLKReceiver is None or DCLKReceiver | 0XF == 0XF
        assert DCLKDriver is None or DCLKDriver | 0XF == 0XF
        assert MCLKReceiver is None or MCLKReceiver | 0XF == 0XF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [DCLKReceiver, DCLKDriver, MCLKReceiver]:
            dataout = self.getreg_dac_settings_dclk_and_mclk_io_buffers(commitTransaction, log, verbose)[1]

        if DCLKReceiver is None:
            DCLKReceiver = dataout['DCLKReceiver']
        if DCLKDriver is None:
            DCLKDriver = dataout['DCLKDriver']
        if MCLKReceiver is None:
            MCLKReceiver = dataout['MCLKReceiver']

        # Writedata generation
        datawrite = (((DCLKReceiver & 0XF) << 0) |
                     ((DCLKDriver & 0XF) << 4) |
                     ((MCLKReceiver & 0XF) << 8))

        self.write_reg(address=Addr.DAC_SETTINGS_DCLK_AND_MCLK_IO_BUFFERS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dac_settings_dclk_and_mclk_io_buffers(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DAC settings for DCLK and MCLK I/O buffers
        Register fields
        ===============
            DCLKReceiver             [3:0] :   0xa
            DCLKDriver               [7:4] :   0xa
            MCLKReceiver            [11:8] :   0xa

        Orgininal docstring
        ===================
        DAC settings for DCLK and MCLK I/O buffers

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DAC_SETTINGS_DCLK_AND_MCLK_IO_BUFFERS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DCLKReceiver"] = (dataread >> 0) & 0XF
        ret["DCLKDriver"] = (dataread >> 4) & 0XF
        ret["MCLKReceiver"] = (dataread >> 8) & 0XF

        return (dataread, ret)

    def setreg_dac_settings_cmu_io_buffers(self,
                                           DCTRLReceiver=None,
                                           DCTRLDriver=None,
                                           commitTransaction=None,
                                           log=None,
                                           readback=None,
                                           verbose=False):
        """ Autogenerated function for DAC settings for CMU I/O buffers
        Register fields
        ===============
            DCTRLReceiver            [3:0] :   0xa
            DCTRLDriver              [7:4] :   0xa

        Orgininal docstring
        ===================
        DAC settings for CMU I/O buffers

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert DCTRLReceiver is None or DCTRLReceiver | 0XF == 0XF
        assert DCTRLDriver is None or DCTRLDriver | 0XF == 0XF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [DCTRLReceiver, DCTRLDriver]:
            dataout = self.getreg_dac_settings_cmu_io_buffers(commitTransaction, log, verbose)[1]

        if DCTRLReceiver is None:
            DCTRLReceiver = dataout['DCTRLReceiver']
        if DCTRLDriver is None:
            DCTRLDriver = dataout['DCTRLDriver']

        # Writedata generation
        datawrite = (((DCTRLReceiver & 0XF) << 0) |
                     ((DCTRLDriver & 0XF) << 4))

        self.write_reg(address=Addr.DAC_SETTINGS_CMU_IO_BUFFERS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dac_settings_cmu_io_buffers(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DAC settings for CMU I/O buffers
        Register fields
        ===============
            DCTRLReceiver            [3:0] :   0xa
            DCTRLDriver              [7:4] :   0xa

        Orgininal docstring
        ===================
        DAC settings for CMU I/O buffers

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DAC_SETTINGS_CMU_IO_BUFFERS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DCTRLReceiver"] = (dataread >> 0) & 0XF
        ret["DCTRLDriver"] = (dataread >> 4) & 0XF

        return (dataread, ret)

    def setreg_cmu_and_dmu_cfg(self,
                               PreviousChipID=None,
                               InitialToken=None,
                               DisableManchester=None,
                               EnableDDR=None,
                               commitTransaction=None,
                               log=None,
                               readback=None,
                               verbose=False):
        """ Autogenerated function for CMU and DMU Configuration Register
        Register fields
        ===============
            PreviousChipID           [3:0] :   0xf
            InitialToken               [4] :   0x0
            DisableManchester          [5] :   0x0
            EnableDDR                  [6] :   0x1

        Orgininal docstring
        ===================
        CMU and DMU Configuration Register

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert PreviousChipID is None or PreviousChipID | 0XF == 0XF
        assert InitialToken is None or InitialToken | 0X1 == 0X1
        assert DisableManchester is None or DisableManchester | 0X1 == 0X1
        assert EnableDDR is None or EnableDDR | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [PreviousChipID, InitialToken, DisableManchester, EnableDDR]:
            dataout = self.getreg_cmu_and_dmu_cfg(commitTransaction, log, verbose)[1]

        if PreviousChipID is None:
            PreviousChipID = dataout['PreviousChipID']
        if InitialToken is None:
            InitialToken = dataout['InitialToken']
        if DisableManchester is None:
            DisableManchester = dataout['DisableManchester']
        if EnableDDR is None:
            EnableDDR = dataout['EnableDDR']

        # Writedata generation
        datawrite = (((PreviousChipID & 0XF) << 0) |
                     ((InitialToken & 0X1) << 4) |
                     ((DisableManchester & 0X1) << 5) |
                     ((EnableDDR & 0X1) << 6))

        self.write_reg(address=Addr.CMU_AND_DMU_CFG,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_cmu_and_dmu_cfg(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for CMU and DMU Configuration Register
        Register fields
        ===============
            PreviousChipID           [3:0] :   0xf
            InitialToken               [4] :   0x0
            DisableManchester          [5] :   0x0
            EnableDDR                  [6] :   0x1

        Orgininal docstring
        ===================
        CMU and DMU Configuration Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.CMU_AND_DMU_CFG,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["PreviousChipID"] = (dataread >> 0) & 0XF
        ret["InitialToken"] = (dataread >> 4) & 0X1
        ret["DisableManchester"] = (dataread >> 5) & 0X1
        ret["EnableDDR"] = (dataread >> 6) & 0X1

        return (dataread, ret)

    # Autogenerated function
    def getreg_cmu_and_dmu_status(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for CMU and DMU Status Register
        Register fields
        ===============
            CMUErrorsCounter         [3:0] :   0x0
            CMUTimeOutCounter        [7:4] :   0x0
            CMUOpCounter            [11:8] :   0x0

        Orgininal docstring
        ===================
        CMU and DMU Status Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.CMU_AND_DMU_STATUS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["CMUErrorsCounter"] = (dataread >> 0) & 0XF
        ret["CMUTimeOutCounter"] = (dataread >> 4) & 0XF
        ret["CMUOpCounter"] = (dataread >> 8) & 0XF

        return (dataread, ret)

    # Autogenerated function
    def getreg_dmu_data_fifo_lsbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DMU Data FIFO [15:0]
        Register fields
        ===============
            DMUDataFifoLSB          [15:0] :   0x0

        Orgininal docstring
        ===================
        DMU Data FIFO [15:0]
        Accessible when EnReadoutFromCMU=1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DMU_DATA_FIFO_LSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DMUDataFifoLSB"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_dmu_data_fifo_msbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DMU Data FIFO [23:16]
        Register fields
        ===============
            DMUDataFifoMSB           [7:0] :   0x0

        Orgininal docstring
        ===================
        DMU Data FIFO [23:16]
        Read operation will pop word from FIFO
        Accessible when EnReadoutFromCMU=1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DMU_DATA_FIFO_MSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DMUDataFifoMSB"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_dtu_cfg(self,
                       VcoDelayStages=None,
                       PllBandwidthControl=None,
                       PllOffSignal=None,
                       SerPhase=None,
                       PLLReset=None,
                       LoadENStatus=None,
                       commitTransaction=None,
                       log=None,
                       readback=None,
                       verbose=False):
        """ Autogenerated function for DTU Configuration Register
        Register fields
        ===============
            VcoDelayStages           [1:0] :   0x1
            PllBandwidthControl        [2] :   0x1
            PllOffSignal               [3] :   0x1
            SerPhase                 [7:4] :   0x8
            PLLReset                   [8] :   0x0
            LoadENStatus              [12] :   0x0

        Orgininal docstring
        ===================
        DTU Configuration Register



        LoadENStatus is read-only

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VcoDelayStages is None or VcoDelayStages | 0X3 == 0X3
        assert PllBandwidthControl is None or PllBandwidthControl | 0X1 == 0X1
        assert PllOffSignal is None or PllOffSignal | 0X1 == 0X1
        assert SerPhase is None or SerPhase | 0XF == 0XF
        assert PLLReset is None or PLLReset | 0X1 == 0X1
        assert LoadENStatus is None or LoadENStatus | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VcoDelayStages, PllBandwidthControl, PllOffSignal, SerPhase, PLLReset, LoadENStatus]:
            dataout = self.getreg_dtu_cfg(commitTransaction, log, verbose)[1]

        if VcoDelayStages is None:
            VcoDelayStages = dataout['VcoDelayStages']
        if PllBandwidthControl is None:
            PllBandwidthControl = dataout['PllBandwidthControl']
        if PllOffSignal is None:
            PllOffSignal = dataout['PllOffSignal']
        if SerPhase is None:
            SerPhase = dataout['SerPhase']
        if PLLReset is None:
            PLLReset = dataout['PLLReset']
        if LoadENStatus is None:
            LoadENStatus = dataout['LoadENStatus']

        # Writedata generation
        datawrite = (((VcoDelayStages & 0X3) << 0) |
                     ((PllBandwidthControl & 0X1) << 2) |
                     ((PllOffSignal & 0X1) << 3) |
                     ((SerPhase & 0XF) << 4) |
                     ((PLLReset & 0X1) << 8) |
                     ((LoadENStatus & 0X1) << 12))

        self.write_reg(address=Addr.DTU_CFG,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dtu_cfg(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU Configuration Register
        Register fields
        ===============
            VcoDelayStages           [1:0] :   0x1
            PllBandwidthControl        [2] :   0x1
            PllOffSignal               [3] :   0x1
            SerPhase                 [7:4] :   0x8
            PLLReset                   [8] :   0x0
            LoadENStatus              [12] :   0x0

        Orgininal docstring
        ===================
        DTU Configuration Register



        LoadENStatus is read-only

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_CFG,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VcoDelayStages"] = (dataread >> 0) & 0X3
        ret["PllBandwidthControl"] = (dataread >> 2) & 0X1
        ret["PllOffSignal"] = (dataread >> 3) & 0X1
        ret["SerPhase"] = (dataread >> 4) & 0XF
        ret["PLLReset"] = (dataread >> 8) & 0X1
        ret["LoadENStatus"] = (dataread >> 12) & 0X1

        return (dataread, ret)

    def setreg_dtu_dacs(self,
                        PLLDAC=None,
                        DriverDAC=None,
                        PreDAC=None,
                        commitTransaction=None,
                        log=None,
                        readback=None,
                        verbose=False):
        """ Autogenerated function for DTU DACs Register
        Register fields
        ===============
            PLLDAC                   [3:0] :   0x8
            DriverDAC                [7:4] :   0x8
            PreDAC                  [11:8] :   0x0

        Orgininal docstring
        ===================
        DTU DACs Register

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert PLLDAC is None or PLLDAC | 0XF == 0XF
        assert DriverDAC is None or DriverDAC | 0XF == 0XF
        assert PreDAC is None or PreDAC | 0XF == 0XF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [PLLDAC, DriverDAC, PreDAC]:
            dataout = self.getreg_dtu_dacs(commitTransaction, log, verbose)[1]

        if PLLDAC is None:
            PLLDAC = dataout['PLLDAC']
        if DriverDAC is None:
            DriverDAC = dataout['DriverDAC']
        if PreDAC is None:
            PreDAC = dataout['PreDAC']

        # Writedata generation
        datawrite = (((PLLDAC & 0XF) << 0) |
                     ((DriverDAC & 0XF) << 4) |
                     ((PreDAC & 0XF) << 8))

        self.write_reg(address=Addr.DTU_DACS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dtu_dacs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU DACs Register
        Register fields
        ===============
            PLLDAC                   [3:0] :   0x8
            DriverDAC                [7:4] :   0x8
            PreDAC                  [11:8] :   0x0

        Orgininal docstring
        ===================
        DTU DACs Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_DACS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["PLLDAC"] = (dataread >> 0) & 0XF
        ret["DriverDAC"] = (dataread >> 4) & 0XF
        ret["PreDAC"] = (dataread >> 8) & 0XF

        return (dataread, ret)

    # Autogenerated function
    def getreg_dtu_pll_lock_1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU PLL Lock Register 1
        Register fields
        ===============
            LockCounter              [7:0] :   0x0
            LockFlag                   [8] :   0x0
            LockStatus                 [9] :   0x0

        Orgininal docstring
        ===================
        DTU PLL Lock Register 1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_PLL_LOCK_1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["LockCounter"] = (dataread >> 0) & 0XFF
        ret["LockFlag"] = (dataread >> 8) & 0X1
        ret["LockStatus"] = (dataread >> 9) & 0X1

        return (dataread, ret)

    def setreg_dtu_pll_lock_2(self,
                              LockWaitCycles=None,
                              UnlockWaitCycles=None,
                              commitTransaction=None,
                              log=None,
                              readback=None,
                              verbose=False):
        """ Autogenerated function for DTU PLL Lock Register 2
        Register fields
        ===============
            LockWaitCycles           [7:0] :   0x0
            UnlockWaitCycles        [15:8] :   0x0

        Orgininal docstring
        ===================
        DTU PLL Lock Register 2

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert LockWaitCycles is None or LockWaitCycles | 0XFF == 0XFF
        assert UnlockWaitCycles is None or UnlockWaitCycles | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [LockWaitCycles, UnlockWaitCycles]:
            dataout = self.getreg_dtu_pll_lock_2(commitTransaction, log, verbose)[1]

        if LockWaitCycles is None:
            LockWaitCycles = dataout['LockWaitCycles']
        if UnlockWaitCycles is None:
            UnlockWaitCycles = dataout['UnlockWaitCycles']

        # Writedata generation
        datawrite = (((LockWaitCycles & 0XFF) << 0) |
                     ((UnlockWaitCycles & 0XFF) << 8))

        self.write_reg(address=Addr.DTU_PLL_LOCK_2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dtu_pll_lock_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU PLL Lock Register 2
        Register fields
        ===============
            LockWaitCycles           [7:0] :   0x0
            UnlockWaitCycles        [15:8] :   0x0

        Orgininal docstring
        ===================
        DTU PLL Lock Register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_PLL_LOCK_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["LockWaitCycles"] = (dataread >> 0) & 0XFF
        ret["UnlockWaitCycles"] = (dataread >> 8) & 0XFF

        return (dataread, ret)

    def setreg_dtu_test_1(self,
                          TestEN=None,
                          IntPatternEN=None,
                          TestSingleMode=None,
                          PrbsRate=None,
                          Bypass8b10b=None,
                          BDIN8b10b0=None,
                          BDIN8b10b1=None,
                          BDIN8b10b2=None,
                          K0=None,
                          K1=None,
                          K2=None,
                          commitTransaction=None,
                          log=None,
                          readback=None,
                          verbose=False):
        """ Autogenerated function for DTU Test Register 1
        Register fields
        ===============
            TestEN                     [0] :   0x0
            IntPatternEN               [1] :   0x0
            TestSingleMode             [2] :   0x0
            PrbsRate                 [4:3] :   0x0
            Bypass8b10b                [5] :   0x0
            BDIN8b10b0               [7:6] :   0x0
            BDIN8b10b1               [9:8] :   0x0
            BDIN8b10b2             [11:10] :   0x0
            K0                        [12] :   0x0
            K1                        [13] :   0x0
            K2                        [14] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 1

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert TestEN is None or TestEN | 0X1 == 0X1
        assert IntPatternEN is None or IntPatternEN | 0X1 == 0X1
        assert TestSingleMode is None or TestSingleMode | 0X1 == 0X1
        assert PrbsRate is None or PrbsRate | 0X3 == 0X3
        assert Bypass8b10b is None or Bypass8b10b | 0X1 == 0X1
        assert BDIN8b10b0 is None or BDIN8b10b0 | 0X3 == 0X3
        assert BDIN8b10b1 is None or BDIN8b10b1 | 0X3 == 0X3
        assert BDIN8b10b2 is None or BDIN8b10b2 | 0X3 == 0X3
        assert K0 is None or K0 | 0X1 == 0X1
        assert K1 is None or K1 | 0X1 == 0X1
        assert K2 is None or K2 | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [
                TestEN,
                IntPatternEN,
                TestSingleMode,
                PrbsRate,
                Bypass8b10b,
                BDIN8b10b0,
                BDIN8b10b1,
                BDIN8b10b2,
                K0,
                K1,
                K2]:
            dataout = self.getreg_dtu_test_1(commitTransaction, log, verbose)[1]

        if TestEN is None:
            TestEN = dataout['TestEN']
        if IntPatternEN is None:
            IntPatternEN = dataout['IntPatternEN']
        if TestSingleMode is None:
            TestSingleMode = dataout['TestSingleMode']
        if PrbsRate is None:
            PrbsRate = dataout['PrbsRate']
        if Bypass8b10b is None:
            Bypass8b10b = dataout['Bypass8b10b']
        if BDIN8b10b0 is None:
            BDIN8b10b0 = dataout['BDIN8b10b0']
        if BDIN8b10b1 is None:
            BDIN8b10b1 = dataout['BDIN8b10b1']
        if BDIN8b10b2 is None:
            BDIN8b10b2 = dataout['BDIN8b10b2']
        if K0 is None:
            K0 = dataout['K0']
        if K1 is None:
            K1 = dataout['K1']
        if K2 is None:
            K2 = dataout['K2']

        # Writedata generation
        datawrite = (((TestEN & 0X1) << 0) |
                     ((IntPatternEN & 0X1) << 1) |
                     ((TestSingleMode & 0X1) << 2) |
                     ((PrbsRate & 0X3) << 3) |
                     ((Bypass8b10b & 0X1) << 5) |
                     ((BDIN8b10b0 & 0X3) << 6) |
                     ((BDIN8b10b1 & 0X3) << 8) |
                     ((BDIN8b10b2 & 0X3) << 10) |
                     ((K0 & 0X1) << 12) |
                     ((K1 & 0X1) << 13) |
                     ((K2 & 0X1) << 14))

        self.write_reg(address=Addr.DTU_TEST_1,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dtu_test_1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU Test Register 1
        Register fields
        ===============
            TestEN                     [0] :   0x0
            IntPatternEN               [1] :   0x0
            TestSingleMode             [2] :   0x0
            PrbsRate                 [4:3] :   0x0
            Bypass8b10b                [5] :   0x0
            BDIN8b10b0               [7:6] :   0x0
            BDIN8b10b1               [9:8] :   0x0
            BDIN8b10b2             [11:10] :   0x0
            K0                        [12] :   0x0
            K1                        [13] :   0x0
            K2                        [14] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_TEST_1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["TestEN"] = (dataread >> 0) & 0X1
        ret["IntPatternEN"] = (dataread >> 1) & 0X1
        ret["TestSingleMode"] = (dataread >> 2) & 0X1
        ret["PrbsRate"] = (dataread >> 3) & 0X3
        ret["Bypass8b10b"] = (dataread >> 5) & 0X1
        ret["BDIN8b10b0"] = (dataread >> 6) & 0X3
        ret["BDIN8b10b1"] = (dataread >> 8) & 0X3
        ret["BDIN8b10b2"] = (dataread >> 10) & 0X3
        ret["K0"] = (dataread >> 12) & 0X1
        ret["K1"] = (dataread >> 13) & 0X1
        ret["K2"] = (dataread >> 14) & 0X1

        return (dataread, ret)

    def setreg_dtu_test_2(self,
                          DIN0=None,
                          DIN1=None,
                          commitTransaction=None,
                          log=None,
                          readback=None,
                          verbose=False):
        """ Autogenerated function for DTU Test Register 2
        Register fields
        ===============
            DIN0                     [7:0] :   0x0
            DIN1                    [15:8] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 2

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert DIN0 is None or DIN0 | 0XFF == 0XFF
        assert DIN1 is None or DIN1 | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [DIN0, DIN1]:
            dataout = self.getreg_dtu_test_2(commitTransaction, log, verbose)[1]

        if DIN0 is None:
            DIN0 = dataout['DIN0']
        if DIN1 is None:
            DIN1 = dataout['DIN1']

        # Writedata generation
        datawrite = (((DIN0 & 0XFF) << 0) |
                     ((DIN1 & 0XFF) << 8))

        self.write_reg(address=Addr.DTU_TEST_2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dtu_test_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU Test Register 2
        Register fields
        ===============
            DIN0                     [7:0] :   0x0
            DIN1                    [15:8] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_TEST_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DIN0"] = (dataread >> 0) & 0XFF
        ret["DIN1"] = (dataread >> 8) & 0XFF

        return (dataread, ret)

    def setreg_dtu_test_3(self,
                          DIN2=None,
                          ForceSetLoadEN=None,
                          ForceUnsetLoadEN=None,
                          commitTransaction=None,
                          log=None,
                          readback=None,
                          verbose=False):
        """ Autogenerated function for DTU Test Register 3
        Register fields
        ===============
            DIN2                     [7:0] :   0x0
            ForceSetLoadEN             [8] :   0x0
            ForceUnsetLoadEN           [9] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 3

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert DIN2 is None or DIN2 | 0XFF == 0XFF
        assert ForceSetLoadEN is None or ForceSetLoadEN | 0X1 == 0X1
        assert ForceUnsetLoadEN is None or ForceUnsetLoadEN | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [DIN2, ForceSetLoadEN, ForceUnsetLoadEN]:
            dataout = self.getreg_dtu_test_3(commitTransaction, log, verbose)[1]

        if DIN2 is None:
            DIN2 = dataout['DIN2']
        if ForceSetLoadEN is None:
            ForceSetLoadEN = dataout['ForceSetLoadEN']
        if ForceUnsetLoadEN is None:
            ForceUnsetLoadEN = dataout['ForceUnsetLoadEN']

        # Writedata generation
        datawrite = (((DIN2 & 0XFF) << 0) |
                     ((ForceSetLoadEN & 0X1) << 8) |
                     ((ForceUnsetLoadEN & 0X1) << 9))

        self.write_reg(address=Addr.DTU_TEST_3,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_dtu_test_3(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DTU Test Register 3
        Register fields
        ===============
            DIN2                     [7:0] :   0x0
            ForceSetLoadEN             [8] :   0x0
            ForceUnsetLoadEN           [9] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 3

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DTU_TEST_3,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DIN2"] = (dataread >> 0) & 0XFF
        ret["ForceSetLoadEN"] = (dataread >> 8) & 0X1
        ret["ForceUnsetLoadEN"] = (dataread >> 9) & 0X1

        return (dataread, ret)

    def setreg_busy_min_width(self,
                              BusyMinWidth=None,
                              commitTransaction=None,
                              log=None,
                              readback=None,
                              verbose=False):
        """ Autogenerated function for BUSY min width
        Register fields
        ===============
            BusyMinWidth             [4:0] :   0x8

        Orgininal docstring
        ===================
        BUSY min width

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert BusyMinWidth is None or BusyMinWidth | 0X1F == 0X1F

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [BusyMinWidth]:
            dataout = self.getreg_busy_min_width(commitTransaction, log, verbose)[1]

        if BusyMinWidth is None:
            BusyMinWidth = dataout['BusyMinWidth']

        # Writedata generation
        datawrite = (((BusyMinWidth & 0X1F) << 0))

        self.write_reg(address=Addr.BUSY_MIN_WIDTH,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_busy_min_width(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for BUSY min width
        Register fields
        ===============
            BusyMinWidth             [4:0] :   0x8

        Orgininal docstring
        ===================
        BUSY min width

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.BUSY_MIN_WIDTH,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["BusyMinWidth"] = (dataread >> 0) & 0X1F

        return (dataread, ret)

    def setreg_pixel_cfg(self,
                         PIXCNFG_REGSEL=None,
                         PIXCNFG_DATA=None,
                         commitTransaction=None,
                         log=None,
                         readback=None,
                         verbose=False):
        """ Autogenerated function for Pixel Configuration Register
        Register fields
        ===============
            PIXCNFG_REGSEL             [0] :   0x0
            PIXCNFG_DATA               [1] :   0x0

        Orgininal docstring
        ===================
        Pixel Configuration Register
        RegSel 0 = MASK, RegSel 1 = PULSE

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert PIXCNFG_REGSEL is None or PIXCNFG_REGSEL | 0X1 == 0X1
        assert PIXCNFG_DATA is None or PIXCNFG_DATA | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [PIXCNFG_REGSEL, PIXCNFG_DATA]:
            dataout = self.getreg_pixel_cfg(commitTransaction, log, verbose)[1]

        if PIXCNFG_REGSEL is None:
            PIXCNFG_REGSEL = dataout['PIXCNFG_REGSEL']
        if PIXCNFG_DATA is None:
            PIXCNFG_DATA = dataout['PIXCNFG_DATA']

        # Writedata generation
        datawrite = (((PIXCNFG_REGSEL & 0X1) << 0) |
                     ((PIXCNFG_DATA & 0X1) << 1))

        self.write_reg(address=Addr.PIXEL_CFG,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_pixel_cfg(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Pixel Configuration Register
        Register fields
        ===============
            PIXCNFG_REGSEL             [0] :   0x0
            PIXCNFG_DATA               [1] :   0x0

        Orgininal docstring
        ===================
        Pixel Configuration Register
        RegSel 0 = MASK, RegSel 1 = PULSE

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.PIXEL_CFG,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["PIXCNFG_REGSEL"] = (dataread >> 0) & 0X1
        ret["PIXCNFG_DATA"] = (dataread >> 1) & 0X1

        return (dataread, ret)

    def setreg_analog_monitor_and_override(self,
                                           VoltageDACSel=None,
                                           CurrentDACSel=None,
                                           SWCNTL_DACMONI=None,
                                           SWCNTL_DACMONV=None,
                                           IRefBufferCurrent=None,
                                           commitTransaction=None,
                                           log=None,
                                           readback=None,
                                           verbose=False):
        """ Autogenerated function for Analog Monitor and Override Register
        Register fields
        ===============
            VoltageDACSel            [3:0] :   0x0
            CurrentDACSel            [6:4] :   0x0
            SWCNTL_DACMONI             [7] :   0x0
            SWCNTL_DACMONV             [8] :   0x0
            IRefBufferCurrent       [10:9] :   0x2

        Orgininal docstring
        ===================
        Analog Monitor and Override Register
        DACMONI current selection (ignored if ADC in Auto mode):
        0	IRESET
        1	IAUX2
        2	IBIAS
        3	IDB
        4	IREF
        5	ITHR
        6	IREFBuffer

        DACMONV voltage selection (ignored if ADC in Auto mode):
        0	VCASN
        1	VCASP
        2	VPULSEH
        3	VPULSEL
        4	VRESETP
        5	VRESETD
        6	VCASN2
        7	VCLIP
        8	VTEMP
        9	ADCDAC

        SWCNTL_DACMONV/I are ignored if ADC in Auto mode

        IRefBuffer current setting:
        0	0,25uA
        1	0,75uA
        2	1,00uA (default)
        3	1,25uA

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VoltageDACSel is None or VoltageDACSel | 0XF == 0XF
        assert CurrentDACSel is None or CurrentDACSel | 0X7 == 0X7
        assert SWCNTL_DACMONI is None or SWCNTL_DACMONI | 0X1 == 0X1
        assert SWCNTL_DACMONV is None or SWCNTL_DACMONV | 0X1 == 0X1
        assert IRefBufferCurrent is None or IRefBufferCurrent | 0X3 == 0X3

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VoltageDACSel, CurrentDACSel, SWCNTL_DACMONI, SWCNTL_DACMONV, IRefBufferCurrent]:
            dataout = self.getreg_analog_monitor_and_override(commitTransaction, log, verbose)[1]

        if VoltageDACSel is None:
            VoltageDACSel = dataout['VoltageDACSel']
        if CurrentDACSel is None:
            CurrentDACSel = dataout['CurrentDACSel']
        if SWCNTL_DACMONI is None:
            SWCNTL_DACMONI = dataout['SWCNTL_DACMONI']
        if SWCNTL_DACMONV is None:
            SWCNTL_DACMONV = dataout['SWCNTL_DACMONV']
        if IRefBufferCurrent is None:
            IRefBufferCurrent = dataout['IRefBufferCurrent']

        # Writedata generation
        datawrite = (((VoltageDACSel & 0XF) << 0) |
                     ((CurrentDACSel & 0X7) << 4) |
                     ((SWCNTL_DACMONI & 0X1) << 7) |
                     ((SWCNTL_DACMONV & 0X1) << 8) |
                     ((IRefBufferCurrent & 0X3) << 9))

        self.write_reg(address=Addr.ANALOG_MONITOR_AND_OVERRIDE,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_analog_monitor_and_override(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Analog Monitor and Override Register
        Register fields
        ===============
            VoltageDACSel            [3:0] :   0x0
            CurrentDACSel            [6:4] :   0x0
            SWCNTL_DACMONI             [7] :   0x0
            SWCNTL_DACMONV             [8] :   0x0
            IRefBufferCurrent       [10:9] :   0x2

        Orgininal docstring
        ===================
        Analog Monitor and Override Register
        DACMONI current selection (ignored if ADC in Auto mode):
        0	IRESET
        1	IAUX2
        2	IBIAS
        3	IDB
        4	IREF
        5	ITHR
        6	IREFBuffer

        DACMONV voltage selection (ignored if ADC in Auto mode):
        0	VCASN
        1	VCASP
        2	VPULSEH
        3	VPULSEL
        4	VRESETP
        5	VRESETD
        6	VCASN2
        7	VCLIP
        8	VTEMP
        9	ADCDAC

        SWCNTL_DACMONV/I are ignored if ADC in Auto mode

        IRefBuffer current setting:
        0	0,25uA
        1	0,75uA
        2	1,00uA (default)
        3	1,25uA

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ANALOG_MONITOR_AND_OVERRIDE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VoltageDACSel"] = (dataread >> 0) & 0XF
        ret["CurrentDACSel"] = (dataread >> 4) & 0X7
        ret["SWCNTL_DACMONI"] = (dataread >> 7) & 0X1
        ret["SWCNTL_DACMONV"] = (dataread >> 8) & 0X1
        ret["IRefBufferCurrent"] = (dataread >> 9) & 0X3

        return (dataread, ret)

    def setreg_VRESETP(self,
                       VRESETP=None,
                       commitTransaction=None,
                       log=None,
                       readback=None,
                       verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VRESETP                  [7:0] :  0x75

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VRESETP is None or VRESETP | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VRESETP]:
            dataout = self.getreg_VRESETP(commitTransaction, log, verbose)[1]

        if VRESETP is None:
            VRESETP = dataout['VRESETP']

        # Writedata generation
        datawrite = (((VRESETP & 0XFF) << 0))

        self.write_reg(address=Addr.VRESETP,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VRESETP(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VRESETP                  [7:0] :  0x75

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VRESETP,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VRESETP"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VRESETD(self,
                       VRESETD=None,
                       commitTransaction=None,
                       log=None,
                       readback=None,
                       verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VRESETD                  [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VRESETD is None or VRESETD | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VRESETD]:
            dataout = self.getreg_VRESETD(commitTransaction, log, verbose)[1]

        if VRESETD is None:
            VRESETD = dataout['VRESETD']

        # Writedata generation
        datawrite = (((VRESETD & 0XFF) << 0))

        self.write_reg(address=Addr.VRESETD,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VRESETD(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VRESETD                  [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VRESETD,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VRESETD"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VCASP(self,
                     VCASP=None,
                     commitTransaction=None,
                     log=None,
                     readback=None,
                     verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCASP                    [7:0] :  0x56

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VCASP is None or VCASP | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VCASP]:
            dataout = self.getreg_VCASP(commitTransaction, log, verbose)[1]

        if VCASP is None:
            VCASP = dataout['VCASP']

        # Writedata generation
        datawrite = (((VCASP & 0XFF) << 0))

        self.write_reg(address=Addr.VCASP,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VCASP(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCASP                    [7:0] :  0x56

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VCASP,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASP"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VCASN(self,
                     VCASN=None,
                     commitTransaction=None,
                     log=None,
                     readback=None,
                     verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCASN                    [7:0] :  0x39

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VCASN is None or VCASN | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VCASN]:
            dataout = self.getreg_VCASN(commitTransaction, log, verbose)[1]

        if VCASN is None:
            VCASN = dataout['VCASN']

        # Writedata generation
        datawrite = (((VCASN & 0XFF) << 0))

        self.write_reg(address=Addr.VCASN,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VCASN(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCASN                    [7:0] :  0x39

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VCASN,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASN"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VPULSEH(self,
                       VPULSEH=None,
                       commitTransaction=None,
                       log=None,
                       readback=None,
                       verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VPULSEH                  [7:0] :  0xff

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VPULSEH is None or VPULSEH | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VPULSEH]:
            dataout = self.getreg_VPULSEH(commitTransaction, log, verbose)[1]

        if VPULSEH is None:
            VPULSEH = dataout['VPULSEH']

        # Writedata generation
        datawrite = (((VPULSEH & 0XFF) << 0))

        self.write_reg(address=Addr.VPULSEH,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VPULSEH(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VPULSEH                  [7:0] :  0xff

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VPULSEH,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VPULSEH"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VPULSEL(self,
                       VPULSEL=None,
                       commitTransaction=None,
                       log=None,
                       readback=None,
                       verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VPULSEL                  [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VPULSEL is None or VPULSEL | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VPULSEL]:
            dataout = self.getreg_VPULSEL(commitTransaction, log, verbose)[1]

        if VPULSEL is None:
            VPULSEL = dataout['VPULSEL']

        # Writedata generation
        datawrite = (((VPULSEL & 0XFF) << 0))

        self.write_reg(address=Addr.VPULSEL,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VPULSEL(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VPULSEL                  [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VPULSEL,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VPULSEL"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VCASN2(self,
                      VCASN2=None,
                      commitTransaction=None,
                      log=None,
                      readback=None,
                      verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCASN2                   [7:0] :  0x40

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VCASN2 is None or VCASN2 | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VCASN2]:
            dataout = self.getreg_VCASN2(commitTransaction, log, verbose)[1]

        if VCASN2 is None:
            VCASN2 = dataout['VCASN2']

        # Writedata generation
        datawrite = (((VCASN2 & 0XFF) << 0))

        self.write_reg(address=Addr.VCASN2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VCASN2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCASN2                   [7:0] :  0x40

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VCASN2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASN2"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VCLIP(self,
                     VCLIP=None,
                     commitTransaction=None,
                     log=None,
                     readback=None,
                     verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCLIP                    [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VCLIP is None or VCLIP | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VCLIP]:
            dataout = self.getreg_VCLIP(commitTransaction, log, verbose)[1]

        if VCLIP is None:
            VCLIP = dataout['VCLIP']

        # Writedata generation
        datawrite = (((VCLIP & 0XFF) << 0))

        self.write_reg(address=Addr.VCLIP,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VCLIP(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VCLIP                    [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VCLIP,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCLIP"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_VTEMP(self,
                     VTEMP=None,
                     commitTransaction=None,
                     log=None,
                     readback=None,
                     verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VTEMP                    [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VTEMP is None or VTEMP | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [VTEMP]:
            dataout = self.getreg_VTEMP(commitTransaction, log, verbose)[1]

        if VTEMP is None:
            VTEMP = dataout['VTEMP']

        # Writedata generation
        datawrite = (((VTEMP & 0XFF) << 0))

        self.write_reg(address=Addr.VTEMP,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_VTEMP(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            VTEMP                    [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.VTEMP,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VTEMP"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_IAUX2(self,
                     IAUX2=None,
                     commitTransaction=None,
                     log=None,
                     readback=None,
                     verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IAUX2                    [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert IAUX2 is None or IAUX2 | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [IAUX2]:
            dataout = self.getreg_IAUX2(commitTransaction, log, verbose)[1]

        if IAUX2 is None:
            IAUX2 = dataout['IAUX2']

        # Writedata generation
        datawrite = (((IAUX2 & 0XFF) << 0))

        self.write_reg(address=Addr.IAUX2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_IAUX2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IAUX2                    [7:0] :   0x0

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.IAUX2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IAUX2"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_IRESET(self,
                      IRESET=None,
                      commitTransaction=None,
                      log=None,
                      readback=None,
                      verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IRESET                   [7:0] :  0x32

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert IRESET is None or IRESET | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [IRESET]:
            dataout = self.getreg_IRESET(commitTransaction, log, verbose)[1]

        if IRESET is None:
            IRESET = dataout['IRESET']

        # Writedata generation
        datawrite = (((IRESET & 0XFF) << 0))

        self.write_reg(address=Addr.IRESET,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_IRESET(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IRESET                   [7:0] :  0x32

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.IRESET,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IRESET"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_IDB(self,
                   IDB=None,
                   commitTransaction=None,
                   log=None,
                   readback=None,
                   verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IDB                      [7:0] :  0x40

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert IDB is None or IDB | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [IDB]:
            dataout = self.getreg_IDB(commitTransaction, log, verbose)[1]

        if IDB is None:
            IDB = dataout['IDB']

        # Writedata generation
        datawrite = (((IDB & 0XFF) << 0))

        self.write_reg(address=Addr.IDB,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_IDB(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IDB                      [7:0] :  0x40

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.IDB,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IDB"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_IBIAS(self,
                     IBIAS=None,
                     commitTransaction=None,
                     log=None,
                     readback=None,
                     verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IBIAS                    [7:0] :  0x40

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert IBIAS is None or IBIAS | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [IBIAS]:
            dataout = self.getreg_IBIAS(commitTransaction, log, verbose)[1]

        if IBIAS is None:
            IBIAS = dataout['IBIAS']

        # Writedata generation
        datawrite = (((IBIAS & 0XFF) << 0))

        self.write_reg(address=Addr.IBIAS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_IBIAS(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            IBIAS                    [7:0] :  0x40

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.IBIAS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IBIAS"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_ITHR(self,
                    ITHR=None,
                    commitTransaction=None,
                    log=None,
                    readback=None,
                    verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            ITHR                     [7:0] :  0x33

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert ITHR is None or ITHR | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [ITHR]:
            dataout = self.getreg_ITHR(commitTransaction, log, verbose)[1]

        if ITHR is None:
            ITHR = dataout['ITHR']

        # Writedata generation
        datawrite = (((ITHR & 0XFF) << 0))

        self.write_reg(address=Addr.ITHR,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_ITHR(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for
        Register fields
        ===============
            ITHR                     [7:0] :  0x33

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ITHR,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["ITHR"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    def setreg_buffer_bypass(self,
                             VCASNBYPASS=None,
                             VCASN2BYPASS=None,
                             VCASPBYPASS=None,
                             VCLIPBYPASS=None,
                             IRESETBYPASS=None,
                             IBIASBYPASS=None,
                             ITHRBYPASS=None,
                             IDBBYPASS=None,
                             commitTransaction=None,
                             log=None,
                             readback=None,
                             verbose=False):
        """ Autogenerated function for Buffer Bypass Register
        Register fields
        ===============
            VCASNBYPASS                [0] :   0x0
            VCASN2BYPASS               [1] :   0x0
            VCASPBYPASS                [2] :   0x0
            VCLIPBYPASS                [3] :   0x0
            IRESETBYPASS               [4] :   0x0
            IBIASBYPASS                [5] :   0x0
            ITHRBYPASS                 [6] :   0x0
            IDBBYPASS                  [7] :   0x0

        Orgininal docstring
        ===================
        Buffer Bypass Register

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert VCASNBYPASS is None or VCASNBYPASS | 0X1 == 0X1
        assert VCASN2BYPASS is None or VCASN2BYPASS | 0X1 == 0X1
        assert VCASPBYPASS is None or VCASPBYPASS | 0X1 == 0X1
        assert VCLIPBYPASS is None or VCLIPBYPASS | 0X1 == 0X1
        assert IRESETBYPASS is None or IRESETBYPASS | 0X1 == 0X1
        assert IBIASBYPASS is None or IBIASBYPASS | 0X1 == 0X1
        assert ITHRBYPASS is None or ITHRBYPASS | 0X1 == 0X1
        assert IDBBYPASS is None or IDBBYPASS | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [
                VCASNBYPASS,
                VCASN2BYPASS,
                VCASPBYPASS,
                VCLIPBYPASS,
                IRESETBYPASS,
                IBIASBYPASS,
                ITHRBYPASS,
                IDBBYPASS]:
            dataout = self.getreg_buffer_bypass(commitTransaction, log, verbose)[1]

        if VCASNBYPASS is None:
            VCASNBYPASS = dataout['VCASNBYPASS']
        if VCASN2BYPASS is None:
            VCASN2BYPASS = dataout['VCASN2BYPASS']
        if VCASPBYPASS is None:
            VCASPBYPASS = dataout['VCASPBYPASS']
        if VCLIPBYPASS is None:
            VCLIPBYPASS = dataout['VCLIPBYPASS']
        if IRESETBYPASS is None:
            IRESETBYPASS = dataout['IRESETBYPASS']
        if IBIASBYPASS is None:
            IBIASBYPASS = dataout['IBIASBYPASS']
        if ITHRBYPASS is None:
            ITHRBYPASS = dataout['ITHRBYPASS']
        if IDBBYPASS is None:
            IDBBYPASS = dataout['IDBBYPASS']

        # Writedata generation
        datawrite = (((VCASNBYPASS & 0X1) << 0) |
                     ((VCASN2BYPASS & 0X1) << 1) |
                     ((VCASPBYPASS & 0X1) << 2) |
                     ((VCLIPBYPASS & 0X1) << 3) |
                     ((IRESETBYPASS & 0X1) << 4) |
                     ((IBIASBYPASS & 0X1) << 5) |
                     ((ITHRBYPASS & 0X1) << 6) |
                     ((IDBBYPASS & 0X1) << 7))

        self.write_reg(address=Addr.BUFFER_BYPASS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_buffer_bypass(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Buffer Bypass Register
        Register fields
        ===============
            VCASNBYPASS                [0] :   0x0
            VCASN2BYPASS               [1] :   0x0
            VCASPBYPASS                [2] :   0x0
            VCLIPBYPASS                [3] :   0x0
            IRESETBYPASS               [4] :   0x0
            IBIASBYPASS                [5] :   0x0
            ITHRBYPASS                 [6] :   0x0
            IDBBYPASS                  [7] :   0x0

        Orgininal docstring
        ===================
        Buffer Bypass Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.BUFFER_BYPASS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASNBYPASS"] = (dataread >> 0) & 0X1
        ret["VCASN2BYPASS"] = (dataread >> 1) & 0X1
        ret["VCASPBYPASS"] = (dataread >> 2) & 0X1
        ret["VCLIPBYPASS"] = (dataread >> 3) & 0X1
        ret["IRESETBYPASS"] = (dataread >> 4) & 0X1
        ret["IBIASBYPASS"] = (dataread >> 5) & 0X1
        ret["ITHRBYPASS"] = (dataread >> 6) & 0X1
        ret["IDBBYPASS"] = (dataread >> 7) & 0X1

        return (dataread, ret)

    def setreg_adc_ctrl(self,
                        Mode=None,
                        SelInput=None,
                        SetIComp=None,
                        DiscriSign=None,
                        RampSpd=None,
                        HalfLSBTrim=None,
                        CompOut=None,
                        commitTransaction=None,
                        log=None,
                        readback=None,
                        verbose=False):
        """ Autogenerated function for ADC Control Register
        Register fields
        ===============
            Mode                     [1:0] :   0x0
            SelInput                 [5:2] :   0x0
            SetIComp                 [7:6] :   0x0
            DiscriSign                 [8] :   0x0
            RampSpd                 [10:9] :   0x2
            HalfLSBTrim               [11] :   0x0
            CompOut                   [15] :   0x0

        Orgininal docstring
        ===================
        ADC Control Register
        Mode:
        0	Manual
        1	Calibration
        2	Auto
        3	Super-Manual
        Sel input values for manual modes (values not listed will select AVSS):
        0	AVSS
        1	DVSS
        2	AVDD
        3	DVDD
        4	V bandgap through voltage scaling
        5	DACMONV
        6	DACMONI
        7	bandgap (direct measurement)
        8	temperature (direct measurement)
        Comparator current:
        0
        1
        2
        3

        Ramp speed:
        0	500ns
        1	1us (default)
        2	2us
        3	4us

        CompOut is read-only

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert Mode is None or Mode | 0X3 == 0X3
        assert SelInput is None or SelInput | 0XF == 0XF
        assert SetIComp is None or SetIComp | 0X3 == 0X3
        assert DiscriSign is None or DiscriSign | 0X1 == 0X1
        assert RampSpd is None or RampSpd | 0X3 == 0X3
        assert HalfLSBTrim is None or HalfLSBTrim | 0X1 == 0X1
        assert CompOut is None or CompOut | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [Mode, SelInput, SetIComp, DiscriSign, RampSpd, HalfLSBTrim, CompOut]:
            dataout = self.getreg_adc_ctrl(commitTransaction, log, verbose)[1]

        if Mode is None:
            Mode = dataout['Mode']
        if SelInput is None:
            SelInput = dataout['SelInput']
        if SetIComp is None:
            SetIComp = dataout['SetIComp']
        if DiscriSign is None:
            DiscriSign = dataout['DiscriSign']
        if RampSpd is None:
            RampSpd = dataout['RampSpd']
        if HalfLSBTrim is None:
            HalfLSBTrim = dataout['HalfLSBTrim']
        if CompOut is None:
            CompOut = dataout['CompOut']

        # Writedata generation
        datawrite = (((Mode & 0X3) << 0) |
                     ((SelInput & 0XF) << 2) |
                     ((SetIComp & 0X3) << 6) |
                     ((DiscriSign & 0X1) << 8) |
                     ((RampSpd & 0X3) << 9) |
                     ((HalfLSBTrim & 0X1) << 11) |
                     ((CompOut & 0X1) << 15))

        self.write_reg(address=Addr.ADC_CTRL,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_adc_ctrl(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC Control Register
        Register fields
        ===============
            Mode                     [1:0] :   0x0
            SelInput                 [5:2] :   0x0
            SetIComp                 [7:6] :   0x0
            DiscriSign                 [8] :   0x0
            RampSpd                 [10:9] :   0x2
            HalfLSBTrim               [11] :   0x0
            CompOut                   [15] :   0x0

        Orgininal docstring
        ===================
        ADC Control Register
        Mode:
        0	Manual
        1	Calibration
        2	Auto
        3	Super-Manual
        Sel input values for manual modes (values not listed will select AVSS):
        0	AVSS
        1	DVSS
        2	AVDD
        3	DVDD
        4	V bandgap through voltage scaling
        5	DACMONV
        6	DACMONI
        7	bandgap (direct measurement)
        8	temperature (direct measurement)
        Comparator current:
        0
        1
        2
        3

        Ramp speed:
        0	500ns
        1	1us (default)
        2	2us
        3	4us

        CompOut is read-only

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_CTRL,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["Mode"] = (dataread >> 0) & 0X3
        ret["SelInput"] = (dataread >> 2) & 0XF
        ret["SetIComp"] = (dataread >> 6) & 0X3
        ret["DiscriSign"] = (dataread >> 8) & 0X1
        ret["RampSpd"] = (dataread >> 9) & 0X3
        ret["HalfLSBTrim"] = (dataread >> 11) & 0X1
        ret["CompOut"] = (dataread >> 15) & 0X1

        return (dataread, ret)

    def setreg_adc_dac_input_value_(self,
                                    DACValue=None,
                                    commitTransaction=None,
                                    log=None,
                                    readback=None,
                                    verbose=False):
        """ Autogenerated function for ADC DAC input value (used in super-manual mode)
        Register fields
        ===============
            DACValue                [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC DAC input value (used in super-manual mode)

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert DACValue is None or DACValue | 0X7FF == 0X7FF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [DACValue]:
            dataout = self.getreg_adc_dac_input_value_(commitTransaction, log, verbose)[1]

        if DACValue is None:
            DACValue = dataout['DACValue']

        # Writedata generation
        datawrite = (((DACValue & 0X7FF) << 0))

        self.write_reg(address=Addr.ADC_DAC_INPUT_VALUE_,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_adc_dac_input_value_(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC DAC input value (used in super-manual mode)
        Register fields
        ===============
            DACValue                [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC DAC input value (used in super-manual mode)

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_DAC_INPUT_VALUE_,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DACValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_calibration_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC Calibration Value Register
        Register fields
        ===============
            CalibrationValue        [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC Calibration Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_CALIBRATION_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["CalibrationValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_avss_value_(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC AVSS Value Register (also used to store measure in manual mode)
        Register fields
        ===============
            AVSSValue                 [10] :   0x0

        Orgininal docstring
        ===================
        ADC AVSS Value Register (also used to store measure in manual mode)

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_AVSS_VALUE_,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["AVSSValue"] = (dataread >> 10) & 0X1

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_dvss_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC DVSS Value Register
        Register fields
        ===============
            DVSSValue               [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC DVSS Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_DVSS_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DVSSValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_avdd_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC AVDD Value Register
        Register fields
        ===============
            AVDDValue               [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC AVDD Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_AVDD_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["AVDDValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_dvdd_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC DVDD Value Register
        Register fields
        ===============
            DVDDValue               [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC DVDD Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_DVDD_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["DVDDValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vcasn_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VCASN Value Register
        Register fields
        ===============
            VCASNValue              [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VCASN Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VCASN_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASNValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vcasp_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VCASP Value Register
        Register fields
        ===============
            VCASPValue              [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VCASP Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VCASP_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASPValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vpulseh_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VPULSEH Value Register
        Register fields
        ===============
            VPULSEHValue            [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VPULSEH Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VPULSEH_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VPULSEHValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vpulsel_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VPULSEL Value Register
        Register fields
        ===============
            VPULSELValue            [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VPULSEL Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VPULSEL_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VPULSELValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vresetp_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VRESETP Value Register
        Register fields
        ===============
            VRESETPValue            [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VRESETP Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VRESETP_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VRESETPValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vresetd_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VRESETD Value Register
        Register fields
        ===============
            VRESETDValue            [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VRESETD Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VRESETD_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VRESETDValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vcasn2_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VCASN2 Value Register
        Register fields
        ===============
            VCASN2Value             [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VCASN2 Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VCASN2_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCASN2Value"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vclip_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VCLIP Value Register
        Register fields
        ===============
            VCLIPValue              [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VCLIP Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VCLIP_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VCLIPValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_vtemp_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC VTEMP Value Register
        Register fields
        ===============
            VTEMPValue              [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC VTEMP Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_VTEMP_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["VTEMPValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_ithr_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC ITHR Value Register
        Register fields
        ===============
            ITHRValue               [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC ITHR Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_ITHR_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["ITHRValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_iref_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC IREF Value Register
        Register fields
        ===============
            IREFValue               [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC IREF Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_IREF_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IREFValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_idb_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC IDB Value Register
        Register fields
        ===============
            IDBValue                [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC IDB Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_IDB_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IDBValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_ibias_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC IBIAS Value Register
        Register fields
        ===============
            IBIASValue              [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC IBIAS Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_IBIAS_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IBIASValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_iaux2_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC IAUX2 Value Register
        Register fields
        ===============
            IAUX2Value              [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC IAUX2 Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_IAUX2_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IAUX2Value"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_ireset_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC IRESET Value Register
        Register fields
        ===============
            IRESETValue             [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC IRESET Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_IRESET_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["IRESETValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_bg2v_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC BG2V Value Register
        Register fields
        ===============
            BG2VValue               [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC BG2V Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_BG2V_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["BG2VValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)

    # Autogenerated function
    def getreg_adc_t2v_value(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for ADC T2V Value Register
        Register fields
        ===============
            T2VValue                [10:0] :   0x0

        Orgininal docstring
        ===================
        ADC T2V Value Register

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.ADC_T2V_VALUE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = OrderedDict()
        ret["T2VValue"] = (dataread >> 0) & 0X7FF

        return (dataread, ret)
