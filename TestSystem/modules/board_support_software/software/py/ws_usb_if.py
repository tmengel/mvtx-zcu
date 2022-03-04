"""file implementing the control for the ws_usbif wishbone slave"""

from enum import IntEnum
from wishbone_module import WishboneModule


class WsUsbifAddress(IntEnum):
    """memory mapping for the ws_usbif got from ws_usbif_pkg.vhd"""
    DP23_CMD                     = 0x00
    READ_DP23_STS_DP2_WRDS_MSB   = 0x01
    READ_DP23_STS_DP2_WRDS_LSB   = 0x02
    READ_DP23_STS_DP2_OVFL       = 0x03
    READ_DP23_STS_DP3_WRDS_MSB   = 0x04
    READ_DP23_STS_DP3_WRDS_LSB   = 0x05
    READ_DP23_STS_DP3_OVFL       = 0x06
    CFG_DP23_PRODUCER_ADDRESS    = 0x07
    READ_DP23_STS_DP2_RDWRDS_MSB = 0x08
    READ_DP23_STS_DP2_RDWRDS_LSB = 0x09
    READ_DP23_STS_DP2_FULL       = 0x0A
    READ_DP23_STS_DP3_RDWRDS_MSB = 0x0B
    READ_DP23_STS_DP3_RDWRDS_LSB = 0x0C
    READ_DP23_STS_DP3_FULL       = 0x0D

class WsUsbif(WishboneModule):
    """wishbone slave instatiated inside the usb_if executing the control over
    the DP2, DP3 fifos and the DP1, DP0 errors"""

    def __init__(self, moduleid, board_obj):
        """init"""
        super(WsUsbif, self).__init__(moduleid=moduleid, board_obj=board_obj, name="Wishbone usbif")
        self.transceiver = []
        self.dp_map = {}
        self._generate_transceiver_map()

    def _generate_transceiver_map(self):
        """at __init__ regenerates the transceiver mapping"""
        self.dp_map[2] = {}
        self.dp_map[3] = {}

        for i in range(13):
            self.transceiver.append((2,i))
            self.transceiver.append((3,i))


        self.transceiver.append((2,15))
        self.transceiver.append((3,15))

        for i,value in enumerate(self.transceiver):
            self.dp_map[value[0]][value[1]] = i

    def dp23_monitor_latch_counters(self):
        """latches all the counters in the dp23 fifos monitor"""
        data = 1 << 15 | 1 << 14 | 1 << 11 | 1 << 10 | 1 << 7 | 1 << 6 | 1 << 3 | 1 << 2
        self.write(WsUsbifAddress.DP23_CMD, data)

    def dp23_monitor_rst_counters(self):
        """resets all the counters in the dp23 fifos monitor"""
        data = 1 << 13 | 1 << 12 | 1 << 9 | 1 << 8 | 1 << 5 | 1 << 4 | 1 << 1 | 1 << 0
        self.write(WsUsbifAddress.DP23_CMD, data)

    def read_dp23_status(self):
        dp2_ovfl, dp2_full, dp2_words, dp2_rdwords, dp3_ovfl, dp3_full, dp3_words, dp3_rdwords = self.dp23_monitor_get_register()

        ret = {"dp2_overflow" : dp2_ovfl,
               "dp2_full" : dp2_full,
               "dp2_words" : dp2_words,
               "dp2_rdwords" : dp2_rdwords,
               "dp3_overflow" : dp3_ovfl,
               "dp3_full" : dp3_full,
               "dp3_words" : dp3_words,
               "dp3_rdwords" : dp3_rdwords}
        return ret

    def dp23_monitor_get_register(self, verbose=True):
        """gets all the registers in the dp23 monitor registers.
        Note that a fetch command is required before executing this command"""

        self.dp23_monitor_latch_counters()

        self.read(WsUsbifAddress.READ_DP23_STS_DP2_OVFL, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP3_OVFL, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP2_FULL, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP3_FULL, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP2_WRDS_MSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP2_WRDS_LSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP3_WRDS_MSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP3_WRDS_LSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP2_RDWRDS_MSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP2_RDWRDS_LSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP3_RDWRDS_MSB, commitTransaction=False)
        self.read(WsUsbifAddress.READ_DP23_STS_DP3_RDWRDS_LSB, commitTransaction=False)
        self.comm.flush()
        results = self.comm.read_results()
        dp2_ovfl    = results[0][1]
        dp3_ovfl    = results[1][1]
        dp2_full    = results[2][1]
        dp3_full    = results[3][1]
        dp2_words   = (results[4][1] & 0xFFFF)  << 16 | results[5][1]  & 0xFFFF
        dp3_words   = (results[6][1] & 0xFFFF)  << 16 | results[7][1]  & 0xFFFF
        dp2_rdwords = (results[8][1] & 0xFFFF)  << 16 | results[9][1]  & 0xFFFF
        dp3_rdwords = (results[10][1] & 0xFFFF) << 16 | results[11][1] & 0xFFFF
        if verbose:
            self.logger.info("DP2 overflow counter: \t%#04X", dp2_ovfl)
            self.logger.info("DP2 full counter: \t%#04X", dp2_full)
            self.logger.info("DP2 words counter: \t%#08X", dp2_words)
            self.logger.info("DP2 rdwords counter: \t%#08X", dp2_rdwords)
            self.logger.info("DP3 overflow counter: \t%#04X", dp3_ovfl)
            self.logger.info("DP3 full counter: \t%#04X", dp3_full)
            self.logger.info("DP3 words counter: \t%#08X", dp3_words)
            self.logger.info("DP3 rdwords counter: \t%#08X", dp3_rdwords)
        return dp2_ovfl, dp2_full, dp2_words, dp2_rdwords, dp3_ovfl, dp3_full, dp3_words, dp3_rdwords

    def get_dp_data_producer(self, verbose=True):
        """returns the data producer address for the DP2 and DP3"""
        datard = self.read(WsUsbifAddress.CFG_DP23_PRODUCER_ADDRESS)
        dp2 = datard>>0 & 0x7
        dp3 = datard>>8 & 0x7
        if verbose:
            self.logger.info("DP2 producer is {0}, DP3 producer is {1}".format(self.dp_map[2][dp2], self.dp_map[3][dp3]))
        return self.dp_map[2][dp2], self.dp_map[3][dp3]

    def set_dp_data_producer(self, DP2=None, DP3=None, verbose=True,commitTransaction=True):
        """selects the DP2 and DP3 transceivers to be used"""

        assert DP2 is None or DP2 in self.dp_map[2].values(), "transceiver %d is not connected to DP2" % DP2
        assert DP3 is None or DP3 in self.dp_map[3].values(), "transceiver %d is not connected to DP3" % DP3

        dp2_port = None
        dp3_port = None
        if DP2 is None or DP3 is None:
            dp2, dp3 = self.get_dp_data_producer(verbose=verbose)
            if DP2 is None:
                DP2 = dp2
            if DP3 is None:
                DP3 = dp3

        for port,transceiver in self.dp_map[2].items():
            if DP2 == transceiver:
                dp2_port = port
        for port,transceiver in self.dp_map[3].items():
            if DP3 == transceiver:
                dp3_port = port

        assert dp2_port is not None, "Transceiver lookup failed on DP2, transceiver number: {0}".format(DP2)
        assert dp3_port is not None, "Transceiver lookup failed on DP3, transceiver number: {0}".format(DP3)


        datawr = (dp3_port& 0xF) <<8 | (dp2_port & 0xF) <<0
        self.logger.info("DP2: %s, DP3: %s, datawr: %x",DP2,DP3,datawr)

        self.write(WsUsbifAddress.CFG_DP23_PRODUCER_ADDRESS, datawr,commitTransaction)

    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        config_str = "--- USBIF CONFIG module ---\n"
        config_str += "  - Write phase register:\n"
        for address in WsUsbifAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#06X}\n".format(name, value)
        return config_str
