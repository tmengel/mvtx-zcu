"""Class to implement MGT Test wishbone slave abstraction layer"""

from wishbone_module import WishboneModule
from enum import IntEnum

class WsMgtTestAddress(IntEnum):
    """memory mapping for mgt test module"""
    PRBS_SEL00 =        0
    PRBS_SEL01 =        1
    PRBS_SEL02 =        2
    PRBS_SEL03 =        3
    PRBS_SEL04 =        4
    PRBS_SEL05 =        5
    PRBS_SEL06 =        6
    PRBS_SEL07 =        7
    PRBS_SEL08 =        8
    PRBS_SEL09 =        9
    PRBS_SEL10 =        10
    PRBS_SEL11 =        11
    PRBS_SEL12 =        12
    PRBS_SEL13 =        13
    PRBS_SEL14 =        14
    PRBS_SEL15 =        15
    PRBS_SEL16 =        16
    PRBS_SEL17 =        17
    PRBS_SEL18 =        18
    PRBS_SEL19 =        19
    PRBS_SEL20 =        20
    PRBS_SEL21 =        21
    PRBS_SEL22 =        22
    PRBS_SEL23 =        23
    PRBS_SEL24 =        24
    PRBS_SEL25 =        25
    PRBS_SEL26 =        26
    PRBS_SEL27 =        27
    RESET =             28
    PRBS_CTR_RST_LSB =  29
    PRBS_CTR_RST_MSB =  30
    STATUS =            31
    INIT_RTRY_CTR =     32
    POWERGOOD_LSB =     33
    POWERGOOD_MSB =     34
    PMARST_DONE_LSB =   35
    PMARST_DONE_MSB =   36
    PRBS_ERR_LSB =      37
    PRBS_ERR_MSB =      38
    PRBS_LOCKED_LSB =   39
    PRBS_LOCKED_MSB =   40
    ENABLE_ERRORS   =   41

class WsMgtResetBits(IntEnum):
    """Reset bit definitions"""
    Reset_All = 0x0001
    Reset_Pll_and_Datapath = 0x0002
    Reset_Datapath = 0x0004
    Reset_Linkdown_Latch = 0x0008
    Force_Error = 0x0010

class MgtTest(WishboneModule):
    """MGT test wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(MgtTest, self).__init__(moduleid=moduleid, name="MGT Test", board_obj=board_obj)

    def reset_all(self, commitTransaction=True):
        self.write(WsMgtTestAddress.RESET, WsMgtResetBits.Reset_All, commitTransaction=commitTransaction)

    def reset_pll_and_datapath(self, commitTransaction=True):
        self.write(WsMgtTestAddress.RESET, WsMgtResetBits.Reset_Pll_and_Datapath, commitTransaction=commitTransaction)

    def reset_datapath(self, commitTransaction=True):
        self.write(WsMgtTestAddress.RESET, WsMgtResetBits.Reset_Datapath, commitTransaction=commitTransaction)

    def reset_linkdown_latch(self, commitTransaction=True):
        self.write(WsMgtTestAddress.RESET, WsMgtResetBits.Reset_Linkdown_Latch, commitTransaction=commitTransaction)

    def force_error(self, commitTransaction=True):
        self.write(WsMgtTestAddress.RESET, WsMgtResetBits.Force_Error, commitTransaction=commitTransaction)

    def reset_prbs_ctrs(self, commitTransaction=True):
        self.write(WsMgtTestAddress.PRBS_CTR_RST_LSB, 0xffff, commitTransaction=commitTransaction )
        self.write(WsMgtTestAddress.PRBS_CTR_RST_MSB, 0x0fff, commitTransaction=commitTransaction )

    def read_status(self, commitTransaction=True):
        ret = self.read(WsMgtTestAddress.STATUS, commitTransaction)
        retdict = {}
        retdict['init_done'] = ret & 0x1
        retdict['reset_rx_done'] = ret>>1 & 1
        retdict['link_status'] = ret>>2 & 1
        retdict['link_down_latched'] = ret>>3 & 1
        return ret, retdict

    def read_pmarst_done(self, commitTransaction=True):
        self.read(WsMgtTestAddress.PMARST_DONE_LSB, commitTransaction=False)
        self.read(WsMgtTestAddress.PMARST_DONE_MSB, commitTransaction=False)
        ret = self.read_all()
        return ((ret[1]<<16) | ret[0])

    def read_prbs_locked(self, commitTransaction=True):
        self.read(WsMgtTestAddress.PRBS_LOCKED_LSB, commitTransaction=False)
        self.read(WsMgtTestAddress.PRBS_LOCKED_MSB, commitTransaction=False)
        ret = self.read_all()
        return ((ret[1]<<16) | ret[0])

    def read_prbs_err(self, commitTransaction=True):
        self.read(WsMgtTestAddress.PRBS_ERR_LSB, commitTransaction=False)
        self.read(WsMgtTestAddress.PRBS_ERR_MSB, commitTransaction=False)
        ret = self.read_all()
        return ((ret[1]<<16) | ret[0])

    def set_prbs_sel(self, ch, val, commitTransaction=True):
        assert ch < 28, "Channel must be between 0 and 27"
        self.write(WsMgtTestAddress.PRBS_SEL00+ch, val, commitTransaction)

    def enable_errors(self, commitTransaction=True):
        self.write(WsMgtTestAddress.ENABLE_ERRORS, 1, commitTransaction)

    def disable_errors(self, commitTransaction=True):
        self.write(WsMgtTestAddress.ENABLE_ERRORS, 0, commitTransaction)

    def get_errors_enabled(self, commitTransaction=True):
        ret = self.read(WsMgtTestAddress.ENABLE_ERRORS, commitTransaction)
        return (ret & 1)
