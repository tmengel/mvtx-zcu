from proasic3 import ProAsic3
from proasic3_convenience import ConvenienceBase, ConvenienceInitializer
from proasic3_enums import Pa3Register, \
     XIL_ADDR, SmapCmdOpcode

NOOP = 0x20000000
EXEC = 0x80

class SelectMapSpec():
    def type1_w(self, addr, size=1):
        return 0x30000000 | (addr << 13) | size

    def type1_r(self, addr, size=1):
        return 0x28000000 | (addr << 13) | size

    def type2_r(self, nframes):
        # in manual:
        # kintex ultrascale:
        # FDRO read length = (words per frame)*(frames to read +1) +10
        # 123 * 2 + 10
        # use only ONE value
        wordcount = 123 * (nframes + 1) + 10
        return 0b01001 << 27 | wordcount

    def type2_w(self, nframes):
        # on this chip there are 49030 frames
        # equating to 6030690 words
        wordcount = (nframes + 1) * 123 + 10
        return 0b01010 << 27 | wordcount


class ProAsic3Selmap(ProAsic3, SelectMapSpec):
    """abstraction methods for the selmap interface"""
    def __init__(self, conv_init:ConvenienceInitializer):
        self.logger = conv_init.logger
        self.read_reg, self.write_reg = conv_init.read_f, conv_init.write_f

    def get_idcode(self):
        idcode = self.sm_read(XIL_ADDR.IDCODE)
        self.logger.info(f"Selectmap read of IDcode returns 0x{idcode:08X}")
        return idcode

    def read_frames(self, address_list):
        """write each frame to a list in a list"""
        data = []
        # todo check size
        for i, adr in enumerate(address_list):
            retval = self.CMRP(adr)
            data.append(retval)
        return data

    def write_frames(self, address_list, datali):
        """use this function to write (a) frame(s)"""
        # [[d1],[d2]] and [adr1, adr2]
        for adr, data in zip(address_list, datali):
            self._configuration_memory_write_procedure(data, adr)

    def _configuration_memory_write_procedure(self, framedata, address, nframes=1):
        """CMWP: Configuration Memory Write Procedure"""
        CMD = self.type1_w(XIL_ADDR['CMD'])

        steps = [0xFFFFFFFF, 0xFFFFBB11, 0xFFFFFFFF, 0xAA995566]
        steps += [CMD, 0x7]
        steps += [self.type1_w(XIL_ADDR['IDCODE']), 0x13919093]
        # DROPsteps += [0x300016001, 123] # frame length
        steps += [CMD, 0x1, NOOP]
        steps += [self.type1_w(XIL_ADDR['FAR']), address, NOOP]
        steps += [self.type1_w(XIL_ADDR['FDRI'], size=0), self.type2_w(nframes)]
        steps += framedata + [0] * (123 + 10)
        # default CRC ?
        steps += [CMD, 0x7]  # reset CRC
        steps += [CMD, 0xD, NOOP, NOOP, NOOP, NOOP]
        for item in steps:
            self.write4bytes(item)

    def sm_read(self, addr):
        """selectmap read, see page 129 in xilinx ug470
        (https://www.xilinx.com/support/documentation/user_guides/ug470_7Series_Config.pdf)"""
        sequence1 = [0xFFFFFFFF, 0xFFFFBB11,
                     0xFFFFFFFF, 0xAA995566, 0x20000000]  # launch?
        primary = 0x28000001 | (addr << 13)  # LSB IS bit pos 13. 5 bits long addr
        sequence2 = [primary, 0x20000000, 0x20000000]  # register and data
        sequence3 = [0x30008001, 0x0000000D, 0x20000000, 0x20000000]  # fini?

        for item in (sequence1 + sequence2):
            self.write4bytes(item)  # WRITE
        data = self.read4bytes()  # READ
        for item in (sequence3):
            self.write4bytes(item)
        return data

    def sm_write(self, addr, data):
        sequence1 = [0xFFFFFFFF, 0xFFFFBB11,
                     0xFFFFFFFF, 0xAA995566, 0x20000000]  # launch?
        primary = 0x30000001 | (addr << 13)  # LSB IS bit pos 13. 5 bits long addr
        secondary = data
        sequence2 = [primary, secondary, 0x20000000, 0x20000000]  # register and data
        sq1 = sequence1 + sequence2
        sequence3 = [0x30008001, 0x0000000D, 0x20000000, 0x20000000]  # fini?

        for item in (sq1):
            self.write4bytes(item)  # WRITE
        for item in (sequence3):
            self.write4bytes(item)

    def write4bytes(self, data=0x00000000):
        """map 32 bytes of the Xilinx selectmap interface to the 8 bit interface of the Pa3"""
        sequence = [(data >> i * 8) & 0xff for i in range(4)]
        sequence.reverse()
        for item in sequence:
            self.write(item)

    def read4bytes(self):
        dlist = []
        for _ in range(4):
            dlist.append(self.read())
        data = dlist[0] << 8 * 3 | dlist[1] << 8 * 2 | dlist[2] << 8 * 1 | dlist[3]
        return data

    def read(self):
        """Read from the SMAP transmit register (smap(tx) -> pa3)"""
        self.write_reg(Pa3Register.SMAP_CMD, SmapCmdOpcode.READ | EXEC)
        byte = self.read_reg(Pa3Register.SMAP_DATA_TX)  # TX register from the smap (addr 25)
        return byte

    def write(self, byte):
        """Write a byte into the SMAP Rx register (pa3 -> smap(rx)"""
        self.write_reg(Pa3Register.SMAP_DATA_RX, byte)  # 26
        self.write_reg(Pa3Register.SMAP_CMD, SmapCmdOpcode.WRITE | EXEC)

    def CMRP(self, startaddr=0, nframes=1):
        """Configuration Memory Read Procedure (SelectMAP)"""
        data = []
        CMD = self.type1_w(XIL_ADDR.CMD)
        # 1 bus detection sequence and synchro word
        steps = [0xFFFFFFFF, 0xFFFFBB11, 0xFFFFFFFF, 0xAA995566]  # removed a noop
        # 2 write shutdown (in documentation, disabled for us)
        steps += [NOOP]  # [CMD,0xB,NOOP]
        # 3 write RCRC
        # step3 = [CMD,0x7,NOOP] # reset CRC
        # 4 write 5 noop
        # step4 = [NOOP]*5
        # 5 write RFCG
        steps += [CMD, 0x4, NOOP, NOOP]
        # 6 write 1 word FAR (ADDRESS!)
        steps += [self.type1_w(XIL_ADDR.FAR), startaddr]
        # 7 readcommand
        steps += [self.type1_r(XIL_ADDR.FDRO, size=0), self.type2_r(nframes)]
        # 8 flush the packet buffer
        steps += [NOOP]  # [NOOP]*64 # flush the packet buffer

        for item in (steps):
            self.write4bytes(item)  # WRITE
        for _ in range(123 + 11):  # whaaaaaaa???
            _junk = self.read4bytes()
        for _ in range(123 * nframes):  # not sure if *nframes works.
            retval = self.read4bytes()
            data.append(retval)

        # 9 write start (in documentation, disabled for us.)
        steps1 = [NOOP]  # [NOOP, CMD, 0x5, NOOP]
        # 10 write RCRC
        steps1 += [CMD, 0x7, NOOP]
        # 11 write DESYNC
        steps1 += [CMD, 0xD, NOOP, NOOP, NOOP, NOOP]
        # last_steps = step9 + step10 + step11
        last_steps = steps1
        for item in (last_steps):
            self.write4bytes(item)  # WRITE
        return data
