"""file implementing the control for the ws_status wishbone slave"""

from enum import IntEnum
from wishbone_module import WishboneModule


class WsStatusAddress(IntEnum):
    """memory mapping for the ws_status got from ws_status_pkg.vhd"""
    GITHASH_LSB       = 0x00
    GITHASH_MSB       = 0x01
    DATE_LSB          = 0x02
    DATE_CSB          = 0x03
    DATE_MSB          = 0x04
    FREQ_CTR          = 0x05
    DIPSWITCH_VAL     = 0x06
    DNA_DO_READ       = 0x07
    DNA_CHUNK_0       = 0x08
    DNA_CHUNK_1       = 0x09
    DNA_CHUNK_2       = 0x0A
    DNA_CHUNK_3       = 0x0B
    DNA_CHUNK_4       = 0x0C
    DNA_CHUNK_5       = 0x0D
    PUSHBUTTON_VAL    = 0x0E

class WsStatus(WishboneModule):
    """wishbone slave used to identify the firmware and the FPGA"""

    def __init__(self, moduleid, board_obj):
        """init"""
        super(WsStatus, self).__init__(moduleid=moduleid, board_obj=board_obj,
                                       name="Wishbone status")

    def get_git_hash(self):
        """Gets git hash"""
        lsb = self.read(WsStatusAddress.GITHASH_LSB)
        msb = self.read(WsStatusAddress.GITHASH_MSB)
        githash = (msb << 16) | lsb
        return githash

    def get_date(self):
        """Returns the git date"""
        lsb = self.read(WsStatusAddress.DATE_LSB)
        csb = self.read(WsStatusAddress.DATE_CSB)
        msb = self.read(WsStatusAddress.DATE_MSB)
        year = (msb >> 8) & 0xFF
        month = msb & 0xFF
        day = (csb >> 8) & 0xFF
        hh = csb & 0xFF
        mm = (lsb >> 8) & 0xFF
        ss = lsb & 0xFF
        date = "20{0:02x}/{1:02x}/{2:02x} {3:02x}:{4:02x}:{5:02x}".format(year,
                                                                          month,
                                                                          day,
                                                                          hh,
                                                                          mm,
                                                                          ss)
        return date

    def get_freq_ctr(self):
        """Returns the frequency counter value"""
        ctr = self.read(WsStatusAddress.FREQ_CTR)
        return ctr

    def get_dipswitch(self):
        """Returns value of RU DIPSWITCH"""
        dipval = self.read(WsStatusAddress.DIPSWITCH_VAL)
        assert (dipval | 0x3ff) == 0x3ff, "DIPSWITCH value out of range"
        return dipval

    def get_pushbutton(self):
        """Returns state of the RU Push Buttons"""
        pbval = self.read(WsStatusAddress.PUSHBUTTON_VAL)
        return pbval

    def get_dna_value(self):
        """Returns the unique DNA value of the FPGA, in simulation it returns 0x76543210FEDCBA9876543210"""
        self.write(WsStatusAddress.DNA_DO_READ, 0x1, commitTransaction=False)
        self.firmware_wait(wait_value=97, commitTransaction=True)
        dna = self.read(WsStatusAddress.DNA_CHUNK_0)
        dna = dna | self.read(WsStatusAddress.DNA_CHUNK_1) << 16
        dna = dna | self.read(WsStatusAddress.DNA_CHUNK_2) << 32
        dna = dna | self.read(WsStatusAddress.DNA_CHUNK_3) << 48
        dna = dna | self.read(WsStatusAddress.DNA_CHUNK_4) << 64
        dna = dna | self.read(WsStatusAddress.DNA_CHUNK_5) << 80
        assert dna > 0, "DNA value is zero"
        assert dna < 0xfffffffffffffffffffffffd, "DNA value is out of range"
        return dna

    def check_git_hash_and_date(self, expected_git_hash=None):
        """gets git hash and git date"""
        assert (expected_git_hash is None) or (expected_git_hash | 0xFFFFFFFF == 0xFFFFFFFF)
        githash = self.get_git_hash()
        message_hash = ">> git hash: 0x{0:08x}".format(githash)
        self.logger.info(message_hash)
        # prints before assert to have additional information on failure
        gitdate = self.get_date()
        message_date = ">> git date: {0}".format(gitdate)
        self.logger.info(message_date)
        if expected_git_hash is not None:
            assert githash == expected_git_hash, "Git hash mismatch: Expected: {0:08X}, got: {1:08X}".format(expected_git_hash,githash)

    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        config_str = "--- STATUS CONFIG module ---\n"
        for address in WsStatusAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#06X}\n".format(name, value)
        return config_str
