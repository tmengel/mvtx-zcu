# coding: utf-8

# coding: utf-8

"""file containing the ALPIDE class"""
# Imports
import logging
import collections
from collections import OrderedDict

from chip import Chip

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
    CMUCLRERR = 0xFF00
    FIFOTEST = 0xFF01
    LOADOBDEFCFG = 0xFF02
    XOFF = 0xFF10
    XON = 0xFF11
    ADCMEASURE = 0xFF20


class Addr(object):
    """Addresses supported by ALPIDE (NOTE that only region indipendent addresses are supported here)"""
    CMD = (0 << 8) | 0
    PERIPHERY_CTRL = (0 << 8) | 1
    DISABLE_REGIONS_LSBS = (0 << 8) | 2
    DISABLEOF_REGIONS_MSBS = (0 << 8) | 3
    FROMU_CFG_1 = (0 << 8) | 4
    FROMU_CFG_2 = (0 << 8) | 5
    FROMU_PULSING1 = (0 << 8) | 6
    FROMU_PULSING_2 = (0 << 8) | 7
    FROMU_STATUS_1 = (0 << 8) | 8
    FROMU_STATUS_2 = (0 << 8) | 9
    DAC_SETTINGS_DCLK_AND_MCLK_IO_BUFFERS = (0 << 8) | 10
    DAC_SETTINGS_CMU_IO_BUFFERS = (0 << 8) | 11
    CMU_AND_DMU_CFG = (0 << 8) | 12
    CMU_ERRORS_COUNTER = (0 << 8) | 13
    DTU_CFG = (0 << 8) | 14
    DTU_DACS = (0 << 8) | 15
    DTU_PLL_LOCK_1 = (0 << 8) | 16
    DTU_PLL_LOCK_2 = (0 << 8) | 17
    DTU_TEST_1 = (0 << 8) | 18
    DTU_TEST_2 = (0 << 8) | 19
    DTU_TEST_3 = (0 << 8) | 20
    BUSY_MIN_WIDTH = (0 << 8) | 21
    FUSES_WRITE_LSBS = (0 << 8) | 22
    FUSES_WRITE_MSBS = (0 << 8) | 23
    FUSES_READ_LSBS = (0 << 8) | 24
    FUSES_READ_MSBS = (0 << 8) | 25
    TEMPERATURE_SENSOR = (0 << 8) | 26
    DMU_AND_TRU_STATE = (4 << 8) | 0
    PIXEL_CFG_1 = (5 << 8) | 0
    PIXEL_CFG_2 = (5 << 8) | 1
    PIXEL_CFG_3 = (5 << 8) | 2
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


class PAlpide3(Chip):
    """pALPIDE3 chip

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
                 commitTransaction=True):
        super(PAlpide3, self).__init__(board=board, chipid=chipid,
                                       readback=readback, log=log,
                                       modulename="pALPIDE3_{0}",
                                       commitTransaction=commitTransaction)
        self.modulename = self.modulename.format(self.chipid)
        self.logger = logging.getLogger(self.modulename)
        self.PLLLockCounter = None

    # User functions

    # Higher level user functions
    def reset(self):
        self.write_opcode(Opcode.GRST)
        self.write_opcode(Opcode.PRST)

    def initialize(self, disable_manchester=1, grst=True):
        """Perform chip initialization procedure ([grst], manchester, RORST)"""
        assert disable_manchester | 1 == 1
        if grst:
            self.board.write_chip_opcode(Opcode.GRST)
        self.setreg_cmu_and_dmu_cfg(DisableManchester=disable_manchester, InitialToken=1,
                                    EnableDDR=1, PreviousChipID=(self.chipid & 0xF))
        self.board.write_chip_opcode(Opcode.RORST)
        self.logger.info("initializing chip")
        self.board.log_currents()

    def configure_dtu(self,
                      PLLDAC=None, DriverDAC=None, PreDAC=None,
                      PLLDelayStages =None, PllBandwidthControl=None,
                      LockWaitCycles=None, UnlockWaitCycles=None,
                      commitTransaction=None, log=None, readback=None):
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
        self.setreg_dtu_cfg(VcoDelayStages=VcoDelayStages, PllBandwidthControl=PllBandwidthControl,
                            PllOffSignal=0,
                            commitTransaction=commitTransaction, readback=readback, log=log)

    def initialize_readout(self,  PLLDAC=None, DriverDAC=None, PreDAC=None,
                           PLLDelayStages=None, PllBandwidthControl=None,
                           commitTransaction=None, log=None, readback=None):
        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)
        self.configure_dtu(PLLDAC=PLLDAC, DriverDAC=DriverDAC, PreDAC=PreDAC,
                           PLLDelayStages=PLLDelayStages, PllBandwidthControl=PllBandwidthControl,
                           commitTransaction=commitTransaction, log=log, readback=readback)
        self.propagate_data(commitTransaction,log,readback)
        self.reset_pll()
        self.init_pixel_matrix()
        self.setreg_periphery_ctrl(ChipModeSelector=1,
                              commitTransaction=commitTransaction, log=log, readback=readback)
        self.board.write_chip_opcode(Opcode.RORST)
        self.pll_check_lock()
        for i in range(10):
            self.pll_check_lock()

    def reset_pll(self, commitTransaction=None, readback=None, log=None, verbose=False):
        self.logger.info('resetting pll (updating ch.LockCounter)')
        self.setreg_dtu_cfg(PLLReset=1, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_cfg(PLLReset=0, commitTransaction=commitTransaction, readback=readback, log=log)
        self.PLLLockCounter = self.getreg_dtu_pll_lock_1()[1]['LockCounter']

    def pll_check_lock(self):
        readreg = self.getreg_dtu_pll_lock_1()[1]
        is_locked = readreg['LockStatus']
        if self.PLLLockCounter is not None:
            if readreg['LockCounter'] != self.PLLLockCounter:
                self.logger.error("PLL lost lock, counter increase from {0} to {1}".format(self.PLLLockCounter, readreg['LockCounter']))
                self.logger.info("actual value of dtu_pll_lock_1 is {0}".format(readreg))
        self.PLLLockCounter = readreg['LockCounter']
        return is_locked

    def trigger(self, commitTransaction=None, readback=None, log=None, verbose=False):
        commitTransaction, log, readback = self.set_default_variables(
            commitTransaction, log, readback)
        self.write_opcode(Opcode.TRIGGER, commitTransaction, log, verbose)

    def propagate_comma(self, commitTransaction=None, readback=None, log=None, verbose=False):
        self.setreg_dtu_test_2(DIN0=0xBC, DIN1=0xBC, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_test_3(DIN2=0xBC, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_dtu_test_1(TestEN=1, IntPatternEN=0, K0=1, K1=1, K2=1, ForceSetLoadEN=0, ForceUnsetLoadEN=0)

    def propagate_data(self, commitTransaction=None, readback=None, log=None, verbose=False):
        self.setreg_dtu_test_1(TestEN=0, ForceSetLoadEN=0, ForceUnsetLoadEN=0)

    def propagate_prbs(self, commitTransaction=None, readback=None, log=None, verbose=False):
        self.setreg_dtu_test_1(TestEN=1, IntPatternEN=1, PrbsEN=1, ForceSetLoadEN=1)

    def propagate_clock(self,acommitTransaction=None, readback=None, log=None, verbose=False):
        """Propagate 600 MHz clock from chip"""
        self.setreg_dtu_test_1(TestEN=1, IntPatternEN=0, ForceSetLoadEN=0, ForceUnsetLoadEN=1)

    def set_xoff(self, XOff=1, commitTransaction=None, readback=None, log=None, verbose=False):
        self.setreg_cmu_and_dmu_cfg(DMUXOff=XOff, commitTransaction=commitTransaction, readback=readback, log=log)

    def dump_config(self):
        """Dump chip configuration"""
        config_str = "-- pALPIDE3 configuration --\n"

        # get all getreg functions
        func_list = [x for x in PAlpide3.__dict__.values() if callable(x) and x.__name__.startswith('getreg')]
        for func in func_list:
            name = func.__name__.replace('getreg_', '')
            result = getattr(self, func.__name__)()
            config_str += "--- Register {0}, value: {1:#4X}\n".format(name, result[0])
            for name, value in result[1].items():
                config_str += "  - {0} : {1:#X}\n".format(name, value)

        return config_str


    ##########
    # MATRIX #
    ##########

    def init_pixel_matrix(self,readback=None, log=None, commitTransaction=None):
        """init the matrix by unmasking and disabling pulse"""
        # Configure pulse and pixels
        # A - unmask all
        self.setreg_pixel_cfg_1(SetsAllRows=1, PIXCNFG_REGSEL=0, PIXCNFG_DATA=0,
                                commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_pixel_cfg_2(SetsAllColumns=1, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_pixel_cfg_3(MatrixLatchEn=1, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_pixel_cfg_3(MatrixLatchEn=0, commitTransaction=commitTransaction, readback=readback, log=log)
        # B - disable pulse for all pixels
        self.setreg_pixel_cfg_1(SetsAllRows=1, PIXCNFG_REGSEL=1, PIXCNFG_DATA=0,
                                commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_pixel_cfg_2(SetsAllColumns=1, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_pixel_cfg_3(MatrixLatchEn=1, commitTransaction=commitTransaction, readback=readback, log=log)
        self.setreg_pixel_cfg_3(MatrixLatchEn=0, commitTransaction=commitTransaction, readback=readback, log=log)

    def set_default_variables(self, commitTransaction, log, readback=None):
        """Set default values for commitTransaction, log and readback. If
        values are set, the function values are used, if not, the class
        default is used"""
        if commitTransaction is None:
            commitTransaction = self.commitTransaction
        if log is None:
            log = self.log
        if readback is None:
            readback = self.readback
        return (commitTransaction, log, readback)

    # Autogenerated functions, Do not touch

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
        16’hFF00			CMUCLRERR
        16’h00D2			GRST
        16’h00E4			PRST
        16’h0078			PULSE
        16’h0036			BCRST
        16’h0063			RORST
        16’h00B1,0055,00C9,002D	TRIGGER
        16’h009C			WROP
        16’h004E			RDOP

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
        16’hFF00			CMUCLRERR
        16’h00D2			GRST
        16’h00E4			PRST
        16’h0078			PULSE
        16’h0036			BCRST
        16’h0063			RORST
        16’h00B1,0055,00C9,002D	TRIGGER
        16’h009C			WROP
        16’h004E			RDOP

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.CMD,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["Command"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_periphery_ctrl(self,
                              ChipModeSelector=None,
                              ClusteringEnabled=None,
                              StartMemSelfTest=None,
                              MatrixROSpeed=None,
                              ForceBusy=None,
                              ForceBusyValue=None,
                              commitTransaction=None,
                              log=None,
                              readback=None,
                              verbose=False):
        """ Autogenerated function for Periphery Control register
        Register fields
        ===============
            ChipModeSelector         [1:0] :   0x0
            ClusteringEnabled          [2] :   0x0
            StartMemSelfTest           [3] :   0x0
            MatrixROSpeed              [5] :   0x1
            ForceBusy                  [6] :   0x0
            ForceBusyValue             [7] :   0x0

        Orgininal docstring
        ===================
        Periphery Control register
        Chip Mode Selector values:
        0	Cfg Mode
        1	Readout Triggered Mode
        2	Readout Continuous Mode
        MatrixROSpeed 0=10MHz, 1=20MHz (default)

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert ChipModeSelector is None or ChipModeSelector | 0X3 == 0X3
        assert ClusteringEnabled is None or ClusteringEnabled | 0X1 == 0X1
        assert StartMemSelfTest is None or StartMemSelfTest | 0X1 == 0X1
        assert MatrixROSpeed is None or MatrixROSpeed | 0X1 == 0X1
        assert ForceBusy is None or ForceBusy | 0X1 == 0X1
        assert ForceBusyValue is None or ForceBusyValue | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [ChipModeSelector, ClusteringEnabled, StartMemSelfTest, MatrixROSpeed, ForceBusy, ForceBusyValue]:
            dataout = self.getreg_periphery_ctrl(commitTransaction, log, verbose)[1]

        if ChipModeSelector is None:
            ChipModeSelector = dataout['ChipModeSelector']
        if ClusteringEnabled is None:
            ClusteringEnabled = dataout['ClusteringEnabled']
        if StartMemSelfTest is None:
            StartMemSelfTest = dataout['StartMemSelfTest']
        if MatrixROSpeed is None:
            MatrixROSpeed = dataout['MatrixROSpeed']
        if ForceBusy is None:
            ForceBusy = dataout['ForceBusy']
        if ForceBusyValue is None:
            ForceBusyValue = dataout['ForceBusyValue']

        # Writedata generation
        datawrite = (((ChipModeSelector & 0X3) << 0) |
                     ((ClusteringEnabled & 0X1) << 2) |
                     ((StartMemSelfTest & 0X1) << 3) |
                     ((MatrixROSpeed & 0X1) << 5) |
                     ((ForceBusy & 0X1) << 6) |
                     ((ForceBusyValue & 0X1) << 7))

        self.write_reg(address=Addr.PERIPHERY_CTRL,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_periphery_ctrl(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Periphery Control register
        Register fields
        ===============
            ChipModeSelector         [1:0] :   0x0
            ClusteringEnabled          [2] :   0x0
            StartMemSelfTest           [3] :   0x0
            MatrixROSpeed              [5] :   0x1
            ForceBusy                  [6] :   0x0
            ForceBusyValue             [7] :   0x0

        Orgininal docstring
        ===================
        Periphery Control register
        Chip Mode Selector values:
        0	Cfg Mode
        1	Readout Triggered Mode
        2	Readout Continuous Mode
        MatrixROSpeed 0=10MHz, 1=20MHz (default)

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.PERIPHERY_CTRL,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["ChipModeSelector"] = (dataread >> 0) & 0X3
        ret["ClusteringEnabled"] = (dataread >> 2) & 0X1
        ret["StartMemSelfTest"] = (dataread >> 3) & 0X1
        ret["MatrixROSpeed"] = (dataread >> 5) & 0X1
        ret["ForceBusy"] = (dataread >> 6) & 0X1
        ret["ForceBusyValue"] = (dataread >> 7) & 0X1

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
        ret = {}
        ret["RegionDisable"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_disableof_regions_msbs(self,
                                      RegionDisable=None,
                                      commitTransaction=None,
                                      log=None,
                                      readback=None,
                                      verbose=False):
        """ Autogenerated function for Disableof regions 16-31
        Register fields
        ===============
            RegionDisable           [15:0] :   0x0

        Orgininal docstring
        ===================
        Disableof regions 16-31

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert RegionDisable is None or RegionDisable | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [RegionDisable]:
            dataout = self.getreg_disableof_regions_msbs(commitTransaction, log, verbose)[1]

        if RegionDisable is None:
            RegionDisable = dataout['RegionDisable']

        # Writedata generation
        datawrite = (((RegionDisable & 0XFFFF) << 0))

        self.write_reg(address=Addr.DISABLEOF_REGIONS_MSBS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_disableof_regions_msbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Disableof regions 16-31
        Register fields
        ===============
            RegionDisable           [15:0] :   0x0

        Orgininal docstring
        ===================
        Disableof regions 16-31

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DISABLEOF_REGIONS_MSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["RegionDisable"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_cfg_1(self,
                           MEBMask=None,
                           EnInternalGeneration=None,
                           EnBusyMonitoring=None,
                           TPulseMode=None,
                           EnTestStrobe=None,
                           SMState=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for FROMU Configuration Register 1
        Register fields
        ===============
            MEBMask                  [2:0] :   0x0
            EnInternalGeneration       [3] :   0x0
            EnBusyMonitoring           [4] :   0x1
            TPulseMode                 [5] :   0x0
            EnTestStrobe               [6] :   0x0
            SMState                 [12:8] :   0x0

        Orgininal docstring
        ===================
        FROMU Configuration Register 1

        EnBusyMonitoring default = 1



        SMState is Read only

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert MEBMask is None or MEBMask | 0X7 == 0X7
        assert EnInternalGeneration is None or EnInternalGeneration | 0X1 == 0X1
        assert EnBusyMonitoring is None or EnBusyMonitoring | 0X1 == 0X1
        assert TPulseMode is None or TPulseMode | 0X1 == 0X1
        assert EnTestStrobe is None or EnTestStrobe | 0X1 == 0X1
        assert SMState is None or SMState | 0X1F == 0X1F

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [MEBMask, EnInternalGeneration, EnBusyMonitoring, TPulseMode, EnTestStrobe, SMState]:
            dataout = self.getreg_fromu_cfg_1(commitTransaction, log, verbose)[1]

        if MEBMask is None:
            MEBMask = dataout['MEBMask']
        if EnInternalGeneration is None:
            EnInternalGeneration = dataout['EnInternalGeneration']
        if EnBusyMonitoring is None:
            EnBusyMonitoring = dataout['EnBusyMonitoring']
        if TPulseMode is None:
            TPulseMode = dataout['TPulseMode']
        if EnTestStrobe is None:
            EnTestStrobe = dataout['EnTestStrobe']
        if SMState is None:
            SMState = dataout['SMState']

        # Writedata generation
        datawrite = (((MEBMask & 0X7) << 0) |
                     ((EnInternalGeneration & 0X1) << 3) |
                     ((EnBusyMonitoring & 0X1) << 4) |
                     ((TPulseMode & 0X1) << 5) |
                     ((EnTestStrobe & 0X1) << 6) |
                     ((SMState & 0X1F) << 8))

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
            EnInternalGeneration       [3] :   0x0
            EnBusyMonitoring           [4] :   0x1
            TPulseMode                 [5] :   0x0
            EnTestStrobe               [6] :   0x0
            SMState                 [12:8] :   0x0

        Orgininal docstring
        ===================
        FROMU Configuration Register 1

        EnBusyMonitoring default = 1



        SMState is Read only

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_CFG_1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["MEBMask"] = (dataread >> 0) & 0X7
        ret["EnInternalGeneration"] = (dataread >> 3) & 0X1
        ret["EnBusyMonitoring"] = (dataread >> 4) & 0X1
        ret["TPulseMode"] = (dataread >> 5) & 0X1
        ret["EnTestStrobe"] = (dataread >> 6) & 0X1
        ret["SMState"] = (dataread >> 8) & 0X1F

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
            FrameDuration           [15:0] :   0x0

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
            FrameDuration           [15:0] :   0x0

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
        ret = {}
        ret["FrameDuration"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_pulsing1(self,
                              TPulseDelay=None,
                              commitTransaction=None,
                              log=None,
                              readback=None,
                              verbose=False):
        """ Autogenerated function for FROMU Pulsing Register1
        Register fields
        ===============
            TPulseDelay             [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Pulsing Register1

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert TPulseDelay is None or TPulseDelay | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [TPulseDelay]:
            dataout = self.getreg_fromu_pulsing1(commitTransaction, log, verbose)[1]

        if TPulseDelay is None:
            TPulseDelay = dataout['TPulseDelay']

        # Writedata generation
        datawrite = (((TPulseDelay & 0XFFFF) << 0))

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
            TPulseDelay             [15:0] :   0x0

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
        ret = {}
        ret["TPulseDelay"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fromu_pulsing_2(self,
                               TPulseDuration=None,
                               commitTransaction=None,
                               log=None,
                               readback=None,
                               verbose=False):
        """ Autogenerated function for FROMU Pulsing Register 2
        Register fields
        ===============
            TPulseDuration          [15:0] :   0x0

        Orgininal docstring
        ===================
        FROMU Pulsing Register 2

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert TPulseDuration is None or TPulseDuration | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [TPulseDuration]:
            dataout = self.getreg_fromu_pulsing_2(commitTransaction, log, verbose)[1]

        if TPulseDuration is None:
            TPulseDuration = dataout['TPulseDuration']

        # Writedata generation
        datawrite = (((TPulseDuration & 0XFFFF) << 0))

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
            TPulseDuration          [15:0] :   0x0

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
        ret = {}
        ret["TPulseDuration"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status Register 1
        Register fields
        ===============
            StrobeCounter           [15:0] :   0x0

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
        ret = {}
        ret["StrobeCounter"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fromu_status_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for FROMU Status register 2
        Register fields
        ===============
            BunchCounter            [11:0] :   0x0
            EventCounter           [13:12] :   0x0

        Orgininal docstring
        ===================
        FROMU Status register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FROMU_STATUS_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["BunchCounter"] = (dataread >> 0) & 0XFFF
        ret["EventCounter"] = (dataread >> 12) & 0X3

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
        ret = {}
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
        ret = {}
        ret["DCTRLReceiver"] = (dataread >> 0) & 0XF
        ret["DCTRLDriver"] = (dataread >> 4) & 0XF

        return (dataread, ret)

    def setreg_cmu_and_dmu_cfg(self,
                               PreviousChipID=None,
                               DMUXOff=None,
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
            DMUXOff                    [4] :   0x0
            InitialToken               [5] :   0x0
            DisableManchester          [6] :   0x0
            EnableDDR                  [7] :   0x1

        Orgininal docstring
        ===================
        CMU and DMU Configuration Register

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert PreviousChipID is None or PreviousChipID | 0XF == 0XF
        assert DMUXOff is None or DMUXOff | 0X1 == 0X1
        assert InitialToken is None or InitialToken | 0X1 == 0X1
        assert DisableManchester is None or DisableManchester | 0X1 == 0X1
        assert EnableDDR is None or EnableDDR | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [PreviousChipID, DMUXOff, InitialToken, DisableManchester, EnableDDR]:
            dataout = self.getreg_cmu_and_dmu_cfg(commitTransaction, log, verbose)[1]

        if PreviousChipID is None:
            PreviousChipID = dataout['PreviousChipID']
        if DMUXOff is None:
            DMUXOff = dataout['DMUXOff']
        if InitialToken is None:
            InitialToken = dataout['InitialToken']
        if DisableManchester is None:
            DisableManchester = dataout['DisableManchester']
        if EnableDDR is None:
            EnableDDR = dataout['EnableDDR']

        # Writedata generation
        datawrite = (((PreviousChipID & 0XF) << 0) |
                     ((DMUXOff & 0X1) << 4) |
                     ((InitialToken & 0X1) << 5) |
                     ((DisableManchester & 0X1) << 6) |
                     ((EnableDDR & 0X1) << 7))

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
            DMUXOff                    [4] :   0x0
            InitialToken               [5] :   0x0
            DisableManchester          [6] :   0x0
            EnableDDR                  [7] :   0x1

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
        ret = {}
        ret["PreviousChipID"] = (dataread >> 0) & 0XF
        ret["DMUXOff"] = (dataread >> 4) & 0X1
        ret["InitialToken"] = (dataread >> 5) & 0X1
        ret["DisableManchester"] = (dataread >> 6) & 0X1
        ret["EnableDDR"] = (dataread >> 7) & 0X1

        return (dataread, ret)

    # Autogenerated function
    def getreg_cmu_errors_counter(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for CMU Errors Counter
        Register fields
        ===============
            CMUErrorsCounter        [11:0] :   0x0

        Orgininal docstring
        ===================
        CMU Errors Counter

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.CMU_ERRORS_COUNTER,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["CMUErrorsCounter"] = (dataread >> 0) & 0XFFF

        return (dataread, ret)

    def setreg_dtu_cfg(self,
                       VcoDelayStages = None,
                       PllBandwidthControl = None,
                       PllOffSignal = None,
                       SerPhase = None,
                       PLLReset = None,
                       LoadENStatus = None,
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
        if None in [VcoDelayStages,PllBandwidthControl,PllOffSignal,SerPhase,PLLReset,LoadENStatus]:
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
        datawrite = (((VcoDelayStages & 0X3) << 0)|
                    ((PllBandwidthControl & 0X1) << 2)|
                    ((PllOffSignal & 0X1) << 3)|
                    ((SerPhase & 0XF) << 4)|
                    ((PLLReset & 0X1) << 8)|
                    ((LoadENStatus & 0X1) << 12))

        self.write_reg(address=Addr.DTU_CFG,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    #Autogenerated function
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
        ret = {}
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
        ret = {}
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
        ret = {}
        ret["LockWaitCycles"] = (dataread >> 0) & 0XFF
        ret["UnlockWaitCycles"] = (dataread >> 8) & 0XFF

        return (dataread, ret)

    def setreg_dtu_test_1(self,
                          TestEN=None,
                          IntPatternEN=None,
                          PrbsEN=None,
                          Bypass8b10b=None,
                          BDIN8b10b0=None,
                          BDIN8b10b1=None,
                          BDIN8b10b2=None,
                          K0=None,
                          K1=None,
                          K2=None,
                          ForceSetLoadEN=None,
                          ForceUnsetLoadEN=None,
                          commitTransaction=None,
                          log=None,
                          readback=None,
                          verbose=False):
        """ Autogenerated function for DTU Test Register 1
        Register fields
        ===============
            TestEN                     [0] :   0x0
            IntPatternEN               [1] :   0x0
            PrbsEN                     [2] :   0x0
            Bypass8b10b                [3] :   0x0
            BDIN8b10b0               [5:4] :   0x0
            BDIN8b10b1               [7:6] :   0x0
            BDIN8b10b2               [9:8] :   0x0
            K0                        [10] :   0x0
            K1                        [11] :   0x0
            K2                        [12] :   0x0
            ForceSetLoadEN            [13] :   0x0
            ForceUnsetLoadEN          [14] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 1

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert TestEN is None or TestEN | 0X1 == 0X1
        assert IntPatternEN is None or IntPatternEN | 0X1 == 0X1
        assert PrbsEN is None or PrbsEN | 0X1 == 0X1
        assert Bypass8b10b is None or Bypass8b10b | 0X1 == 0X1
        assert BDIN8b10b0 is None or BDIN8b10b0 | 0X3 == 0X3
        assert BDIN8b10b1 is None or BDIN8b10b1 | 0X3 == 0X3
        assert BDIN8b10b2 is None or BDIN8b10b2 | 0X3 == 0X3
        assert K0 is None or K0 | 0X1 == 0X1
        assert K1 is None or K1 | 0X1 == 0X1
        assert K2 is None or K2 | 0X1 == 0X1
        assert ForceSetLoadEN is None or ForceSetLoadEN | 0X1 == 0X1
        assert ForceUnsetLoadEN is None or ForceUnsetLoadEN | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [
                TestEN,
                IntPatternEN,
                PrbsEN,
                Bypass8b10b,
                BDIN8b10b0,
                BDIN8b10b1,
                BDIN8b10b2,
                K0,
                K1,
                K2,
                ForceSetLoadEN,
                ForceUnsetLoadEN]:
            dataout = self.getreg_dtu_test_1(commitTransaction, log, verbose)[1]

        if TestEN is None:
            TestEN = dataout['TestEN']
        if IntPatternEN is None:
            IntPatternEN = dataout['IntPatternEN']
        if PrbsEN is None:
            PrbsEN = dataout['PrbsEN']
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
        if ForceSetLoadEN is None:
            ForceSetLoadEN = dataout['ForceSetLoadEN']
        if ForceUnsetLoadEN is None:
            ForceUnsetLoadEN = dataout['ForceUnsetLoadEN']

        # Writedata generation
        datawrite = (((TestEN & 0X1) << 0) |
                     ((IntPatternEN & 0X1) << 1) |
                     ((PrbsEN & 0X1) << 2) |
                     ((Bypass8b10b & 0X1) << 3) |
                     ((BDIN8b10b0 & 0X3) << 4) |
                     ((BDIN8b10b1 & 0X3) << 6) |
                     ((BDIN8b10b2 & 0X3) << 8) |
                     ((K0 & 0X1) << 10) |
                     ((K1 & 0X1) << 11) |
                     ((K2 & 0X1) << 12) |
                     ((ForceSetLoadEN & 0X1) << 13) |
                     ((ForceUnsetLoadEN & 0X1) << 14))

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
            PrbsEN                     [2] :   0x0
            Bypass8b10b                [3] :   0x0
            BDIN8b10b0               [5:4] :   0x0
            BDIN8b10b1               [7:6] :   0x0
            BDIN8b10b2               [9:8] :   0x0
            K0                        [10] :   0x0
            K1                        [11] :   0x0
            K2                        [12] :   0x0
            ForceSetLoadEN            [13] :   0x0
            ForceUnsetLoadEN          [14] :   0x0

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
        ret = {}
        ret["TestEN"] = (dataread >> 0) & 0X1
        ret["IntPatternEN"] = (dataread >> 1) & 0X1
        ret["PrbsEN"] = (dataread >> 2) & 0X1
        ret["Bypass8b10b"] = (dataread >> 3) & 0X1
        ret["BDIN8b10b0"] = (dataread >> 4) & 0X3
        ret["BDIN8b10b1"] = (dataread >> 6) & 0X3
        ret["BDIN8b10b2"] = (dataread >> 8) & 0X3
        ret["K0"] = (dataread >> 10) & 0X1
        ret["K1"] = (dataread >> 11) & 0X1
        ret["K2"] = (dataread >> 12) & 0X1
        ret["ForceSetLoadEN"] = (dataread >> 13) & 0X1
        ret["ForceUnsetLoadEN"] = (dataread >> 14) & 0X1

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
        ret = {}
        ret["DIN0"] = (dataread >> 0) & 0XFF
        ret["DIN1"] = (dataread >> 8) & 0XFF

        return (dataread, ret)

    def setreg_dtu_test_3(self,
                          DIN2=None,
                          commitTransaction=None,
                          log=None,
                          readback=None,
                          verbose=False):
        """ Autogenerated function for DTU Test Register 3
        Register fields
        ===============
            DIN2                     [7:0] :   0x0

        Orgininal docstring
        ===================
        DTU Test Register 3

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert DIN2 is None or DIN2 | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [DIN2]:
            dataout = self.getreg_dtu_test_3(commitTransaction, log, verbose)[1]

        if DIN2 is None:
            DIN2 = dataout['DIN2']

        # Writedata generation
        datawrite = (((DIN2 & 0XFF) << 0))

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
        ret = {}
        ret["DIN2"] = (dataread >> 0) & 0XFF

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
        ret = {}
        ret["BusyMinWidth"] = (dataread >> 0) & 0X1F

        return (dataread, ret)

    def setreg_fuses_write_lsbs(self,
                                FusesWriteLSBs=None,
                                commitTransaction=None,
                                log=None,
                                readback=None,
                                verbose=False):
        """ Autogenerated function for Fuses Write LSBs
        Register fields
        ===============
            FusesWriteLSBs          [15:0] :   0x0

        Orgininal docstring
        ===================
        Fuses Write LSBs

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert FusesWriteLSBs is None or FusesWriteLSBs | 0XFFFF == 0XFFFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [FusesWriteLSBs]:
            dataout = self.getreg_fuses_write_lsbs(commitTransaction, log, verbose)[1]

        if FusesWriteLSBs is None:
            FusesWriteLSBs = dataout['FusesWriteLSBs']

        # Writedata generation
        datawrite = (((FusesWriteLSBs & 0XFFFF) << 0))

        self.write_reg(address=Addr.FUSES_WRITE_LSBS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fuses_write_lsbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Fuses Write LSBs
        Register fields
        ===============
            FusesWriteLSBs          [15:0] :   0x0

        Orgininal docstring
        ===================
        Fuses Write LSBs

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FUSES_WRITE_LSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["FusesWriteLSBs"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    def setreg_fuses_write_msbs(self,
                                FusesWriteMSBs=None,
                                commitTransaction=None,
                                log=None,
                                readback=None,
                                verbose=False):
        """ Autogenerated function for Fuses Write MSBs
        Register fields
        ===============
            FusesWriteMSBs           [7:0] :   0x0

        Orgininal docstring
        ===================
        Fuses Write MSBs

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert FusesWriteMSBs is None or FusesWriteMSBs | 0XFF == 0XFF

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [FusesWriteMSBs]:
            dataout = self.getreg_fuses_write_msbs(commitTransaction, log, verbose)[1]

        if FusesWriteMSBs is None:
            FusesWriteMSBs = dataout['FusesWriteMSBs']

        # Writedata generation
        datawrite = (((FusesWriteMSBs & 0XFF) << 0))

        self.write_reg(address=Addr.FUSES_WRITE_MSBS,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_fuses_write_msbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Fuses Write MSBs
        Register fields
        ===============
            FusesWriteMSBs           [7:0] :   0x0

        Orgininal docstring
        ===================
        Fuses Write MSBs

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FUSES_WRITE_MSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["FusesWriteMSBs"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fuses_read_lsbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Fuses Read LSBs
        Register fields
        ===============
            FusesReadLSBs           [15:0] :   0x0

        Orgininal docstring
        ===================
        Fuses Read LSBs

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FUSES_READ_LSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["FusesReadLSBs"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_fuses_read_msbs(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Fuses Read MSBs
        Register fields
        ===============
            FusesReadMSBs            [7:0] :   0x0

        Orgininal docstring
        ===================
        Fuses Read MSBs

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.FUSES_READ_MSBS,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["FusesReadMSBs"] = (dataread >> 0) & 0XFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_temperature_sensor(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Temperature Sensor
        Register fields
        ===============
            TempSensor              [15:0] :   0x0

        Orgininal docstring
        ===================
        Temperature Sensor

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.TEMPERATURE_SENSOR,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["TempSensor"] = (dataread >> 0) & 0XFFFF

        return (dataread, ret)

    # Autogenerated function
    def getreg_dmu_and_tru_state(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for DMU and TRU State
        Register fields
        ===============
            TRUSMState               [2:0] :   0x0
            DMUSMState               [5:3] :   0x0
            BusyMismatchError          [6] :   0x0
            BusyFifoFullError          [7] :   0x0

        Orgininal docstring
        ===================
        DMU and TRU State

        Reset on GRST or RORST
        Reset on GRST or RORST

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.DMU_AND_TRU_STATE,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["TRUSMState"] = (dataread >> 0) & 0X7
        ret["DMUSMState"] = (dataread >> 3) & 0X7
        ret["BusyMismatchError"] = (dataread >> 6) & 0X1
        ret["BusyFifoFullError"] = (dataread >> 7) & 0X1

        return (dataread, ret)

    def setreg_pixel_cfg_1(self,
                           RowSel=None,
                           SetsAllRows=None,
                           PIXCNFG_REGSEL=None,
                           PIXCNFG_DATA=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for Pixel CFG Register 1
        Register fields
        ===============
            RowSel                   [8:0] :   0x0
            SetsAllRows                [9] :   0x0
            PIXCNFG_REGSEL            [10] :   0x0
            PIXCNFG_DATA              [11] :   0x0

        Orgininal docstring
        ===================
        Pixel CFG Register 1

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert RowSel is None or RowSel | 0X1FF == 0X1FF
        assert SetsAllRows is None or SetsAllRows | 0X1 == 0X1
        assert PIXCNFG_REGSEL is None or PIXCNFG_REGSEL | 0X1 == 0X1
        assert PIXCNFG_DATA is None or PIXCNFG_DATA | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [RowSel, SetsAllRows, PIXCNFG_REGSEL, PIXCNFG_DATA]:
            dataout = self.getreg_pixel_cfg_1(commitTransaction, log, verbose)[1]

        if RowSel is None:
            RowSel = dataout['RowSel']
        if SetsAllRows is None:
            SetsAllRows = dataout['SetsAllRows']
        if PIXCNFG_REGSEL is None:
            PIXCNFG_REGSEL = dataout['PIXCNFG_REGSEL']
        if PIXCNFG_DATA is None:
            PIXCNFG_DATA = dataout['PIXCNFG_DATA']

        # Writedata generation
        datawrite = (((RowSel & 0X1FF) << 0) |
                     ((SetsAllRows & 0X1) << 9) |
                     ((PIXCNFG_REGSEL & 0X1) << 10) |
                     ((PIXCNFG_DATA & 0X1) << 11))

        self.write_reg(address=Addr.PIXEL_CFG_1,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_pixel_cfg_1(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Pixel CFG Register 1
        Register fields
        ===============
            RowSel                   [8:0] :   0x0
            SetsAllRows                [9] :   0x0
            PIXCNFG_REGSEL            [10] :   0x0
            PIXCNFG_DATA              [11] :   0x0

        Orgininal docstring
        ===================
        Pixel CFG Register 1

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.PIXEL_CFG_1,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["RowSel"] = (dataread >> 0) & 0X1FF
        ret["SetsAllRows"] = (dataread >> 9) & 0X1
        ret["PIXCNFG_REGSEL"] = (dataread >> 10) & 0X1
        ret["PIXCNFG_DATA"] = (dataread >> 11) & 0X1

        return (dataread, ret)

    def setreg_pixel_cfg_2(self,
                           ColSel=None,
                           SetsAllColumns=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for Pixel CFG Register 2
        Register fields
        ===============
            ColSel                   [9:0] :   0x0
            SetsAllColumns            [10] :   0x0

        Orgininal docstring
        ===================
        Pixel CFG Register 2

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert ColSel is None or ColSel | 0X3FF == 0X3FF
        assert SetsAllColumns is None or SetsAllColumns | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [ColSel, SetsAllColumns]:
            dataout = self.getreg_pixel_cfg_2(commitTransaction, log, verbose)[1]

        if ColSel is None:
            ColSel = dataout['ColSel']
        if SetsAllColumns is None:
            SetsAllColumns = dataout['SetsAllColumns']

        # Writedata generation
        datawrite = (((ColSel & 0X3FF) << 0) |
                     ((SetsAllColumns & 0X1) << 10))

        self.write_reg(address=Addr.PIXEL_CFG_2,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_pixel_cfg_2(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Pixel CFG Register 2
        Register fields
        ===============
            ColSel                   [9:0] :   0x0
            SetsAllColumns            [10] :   0x0

        Orgininal docstring
        ===================
        Pixel CFG Register 2

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.PIXEL_CFG_2,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["ColSel"] = (dataread >> 0) & 0X3FF
        ret["SetsAllColumns"] = (dataread >> 10) & 0X1

        return (dataread, ret)

    def setreg_pixel_cfg_3(self,
                           MatrixLatchEn=None,
                           commitTransaction=None,
                           log=None,
                           readback=None,
                           verbose=False):
        """ Autogenerated function for Pixel CFG Register 3
        Register fields
        ===============
            MatrixLatchEn              [0] :   0x0

        Orgininal docstring
        ===================
        Pixel CFG Register 3

        This is an autogenerated function. Do not modify directly.
        """
        # Assertions
        assert MatrixLatchEn is None or MatrixLatchEn | 0X1 == 0X1

        commitTransaction, log, readback = self.set_default_variables(commitTransaction, log, readback)

        dataout = {}
        if None in [MatrixLatchEn]:
            dataout = self.getreg_pixel_cfg_3(commitTransaction, log, verbose)[1]

        if MatrixLatchEn is None:
            MatrixLatchEn = dataout['MatrixLatchEn']

        # Writedata generation
        datawrite = (((MatrixLatchEn & 0X1) << 0))

        self.write_reg(address=Addr.PIXEL_CFG_3,
                       data=datawrite,
                       readback=readback,
                       log=log,
                       commitTransaction=commitTransaction,
                       verbose=verbose)

    # Autogenerated function
    def getreg_pixel_cfg_3(self, commitTransaction=None, log=None, verbose=False):
        """ Autogenerated function for Pixel CFG Register 3
        Register fields
        ===============
            MatrixLatchEn              [0] :   0x0

        Orgininal docstring
        ===================
        Pixel CFG Register 3

        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_reg(address=Addr.PIXEL_CFG_3,
                                 log=log,
                                 commitTransaction=commitTransaction,
                                 verbose=verbose)
        ret = {}
        ret["MatrixLatchEn"] = (dataread >> 0) & 0X1

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
        DACMONI current selection:
        0	IRESET
        1	IAUX2
        2	IBIAS
        3	IDB
        4	IREF
        5	ITHR
        6	IREFBuffer
        DACMONV voltage selection:
        0	VCASN
        1	VCASP
        2	VPULSEH
        3	VPULSEL
        4	VRESETP
        5	VRESETD
        6	VCASN2
        7	VCLIP
        8	VTEMP
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
        DACMONI current selection:
        0	IRESET
        1	IAUX2
        2	IBIAS
        3	IDB
        4	IREF
        5	ITHR
        6	IREFBuffer
        DACMONV voltage selection:
        0	VCASN
        1	VCASP
        2	VPULSEH
        3	VPULSEL
        4	VRESETP
        5	VRESETD
        6	VCASN2
        7	VCLIP
        8	VTEMP
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
        ret = {}
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
            ITHR                     7:0 :  0x33

        Orgininal docstring
        ===================


        This is an autogenerated function. Do not modify directly.
        """

        commitTransaction, log, _ = self.set_default_variables(commitTransaction, log)

        dataread = self.read_re(address=Addr.ITHR,
                                log=log,
                                commitTransaction=commitTransaction,
                                verbose=verbose)
        ret = {}
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
        ret = {}
        ret["VCASNBYPASS"] = (dataread >> 0) & 0X1
        ret["VCASN2BYPASS"] = (dataread >> 1) & 0X1
        ret["VCASPBYPASS"] = (dataread >> 2) & 0X1
        ret["VCLIPBYPASS"] = (dataread >> 3) & 0X1
        ret["IRESETBYPASS"] = (dataread >> 4) & 0X1
        ret["IBIASBYPASS"] = (dataread >> 5) & 0X1
        ret["ITHRBYPASS"] = (dataread >> 6) & 0X1
        ret["IDBBYPASS"] = (dataread >> 7) & 0X1

        return (dataread, ret)

        dataout = {}
        if None in [LockWaitCycles, UnlockWaitCycles]:
            dataout = self.getreg_dtu_pll_lock_2(
                commitTransaction, log, verbose)[1]

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
