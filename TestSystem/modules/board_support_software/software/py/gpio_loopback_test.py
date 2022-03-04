"""Class to implement MGT Test wishbone slave abstraction layer"""

from wishbone_module import WishboneModule
from enum import IntEnum

class WsLoopbackAddress(IntEnum):
    """memory mapping for the ws_status got from ws_status_pkg.vhd"""
    clearError          = 0x00
    injectError         = 0x01
    loopbackCTRL        = 0x02
    SMAJ21J22Error      = 0x03
    headerJ13_0Error    = 0x04
    PA3headerJ14_0Error = 0x09
    pa3_0Error          = 0x0E
    DCTRL_0Error        = 0x18
    DCLKB_0Error        = 0x1D
    DCLKC_0Error        = 0x22
    aux_0Error          = 0x27
    pu_0Error           = 0x2B

class GpioLoopbackTest(WishboneModule):
    """GPIO Loopback Test wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(GpioLoopbackTest, self).__init__(moduleid=moduleid, name="GPIO Loopback Test", board_obj=board_obj)

    def get_SMAJ21J22Error(self):
        """Gets SMAJ21J22Error"""
        smaJ21J22Error = self.read(WsLoopbackAddress.SMAJ21J22Error)
        return smaJ21J22Error

    def get_headerJ13_Error(self, num):
        assert (num <= 4), "num must be between 0 and 4"
        return(self.read(WsLoopbackAddress.headerJ13_0Error + num))

    def get_Pa3headerJ14_Error(self, num):
        assert (num <= 4), "num must be between 0 and 4"
        return(self.read(WsLoopbackAddress.PA3headerJ14_0Error + num))

    def get_pa3_Error(self, num):
        assert (num <= 11), "num must be between 0 and 11"
        return(self.read(WsLoopbackAddress.pa3_0Error + num))

    def get_DCTRL_Error(self, num):
        assert (num <= 4), "num must be between 0 and 4"
        return(self.read(WsLoopbackAddress.DCTRL_0Error + num))

    def get_DCLKB_Error(self, num):
        assert (num <= 4), "num must be between 0 and 4"
        return(self.read(WsLoopbackAddress.DCLKB_0Error + num))

    def get_DCLKC_Error(self, num):
        assert (num <= 4), "num must be between 0 and 4"
        return(self.read(WsLoopbackAddress.DCLKC_0Error + num))

    def get_aux_Error(self, num):
        assert (num <= 4), "num must be between 0 and 4"
        return(self.read(WsLoopbackAddress.aux_0Error + num))

    def get_pu_Error(self, num):
        assert (num <= 7), "num must be between 0 and 7"
        return(self.read(WsLoopbackAddress.pu_0Error + num))

    def injectError(self, value):
        """Write "value" to error inject register"""
        self.write(1, value)

    def clearError(self, value):
        """Clear GPIO loopback error count registers"""
        self.write(0, value)

    def resetAllGPIOprbs(self):
        """Clear GPIO loopback error count registers"""
        self.write(0, 0x1000)

    def disableDCLK(self):
        """Disable DCLK MLVDS buffer, enable the DCTRL buffer"""
        self.write(2, 0x01)

    def enableDCLK(self):
        """Enable DCLK MLVDS buffer, disable the DCTRL buffer"""
        self.write(2, 0x00)
