"""
   Class implementing an abstraction layer for the ProAsic3
"""

import logging
import time


from gbt_sca import ScaChannel, ScaI2cSpeed
from gbt_sca import ScaGpio
from proasic3_enums import Pa3Register


import gbt_sca


class ProAsic3:
    """Class to handle PA3 transactions"""
    sca: gbt_sca.Sca

    def __init__(self, sca):
        self.name = "ProAsic3"
        self.logger = logging.getLogger(self.name)

        self.sca = sca
        self.sca_channel_used = ScaChannel.I2C0

        # to get nice python Fire interface:
        if self.__class__ == ProAsic3:
            from proasic3_convenience import ConvenienceInitializer
            from proasic3_convenience import Status, ConfigController, Clock
            from proasic3_flash import ProAsic3Flash
            from proasic3_selectmap import ProAsic3Selmap

            # only init in master, prevent recursion
            conv_init = ConvenienceInitializer(self.write_reg, self.read_reg, self.logger)
            self.config_controller = ConfigController(conv_init)
            self.start_scrubbing = self.config_controller.start_blind_scrubbing
            self.stop_scrubbing = self.config_controller.stop_blind_scrubbing
            self.program_xilinx = self.config_controller.reprogram_ultrascale
            self.cfg_is_idle = self.config_controller.is_idle

            self._Status = Status(conv_init)
            self.dump_config = self._Status.config_get
            self.get_version = self._Status.version
            self.get_githash = self._Status.githash

            self._FlashIf = ProAsic3Flash(conv_init, self.write_fifo_reg_multibyte)
            self.flash_display_page = self._FlashIf.disp_page
            self.flash_write_file_to_block = self._FlashIf.flash_write_file
            self.flash_write_all_firmware = self._FlashIf.write_all_firmware
            self.flash_update_parameter_page = self._FlashIf.update_parameter_page
            self.flash_generate_and_write_all_firmware = self._FlashIf.generate_and_write_all_firmware

            self._Clock = Clock(conv_init)
            self.set_clock_mux_source_crystal = self._Clock.set_clock_mux_source_crystal
            self.set_clock_mux_source_jitter_cleaner = self._Clock.set_clock_mux_source_jitter_cleaner

            self._SelMap = ProAsic3Selmap(conv_init)
            self.smap_write_frame = self._SelMap.write_frames
            self.smap_read_frame = self._SelMap.read_frames
            self.smap_get_idcode = self._SelMap.get_idcode

    def initialize(self):
        self.sca.initialize()
        self.sca.initialize_i2c_channel(channel=ScaChannel.I2C0)
        self.sca.set_i2c_w_ctrl_reg(channel=ScaChannel.I2C0, speed=ScaI2cSpeed.f1MHz, nbytes=1, sclmode=0)
        self.sca.initialize_i2c_channel(channel=ScaChannel.I2C5)
        self.logger.info('Done!')
        # TODO : persistence

    def set_i2c_channel(self, channel):
        """Changes the active SCA-I2C channel used"""
        channel = ScaChannel(channel)
        assert channel in [ScaChannel.I2C0, ScaChannel.I2C5]
        self.sca_channel_used = channel
        self.logger.info('Done!')

    def check_git_hash(self, expected_git_hash=None):
        """Verifies the githash against the given value"""
        assert (expected_git_hash is None) or (expected_git_hash | 0xFFFFFFFF == 0xFFFFFFFF)
        githash = self._Status.githash()
        message_hash = ">> git hash: 0x{0:08x}".format(githash)
        if expected_git_hash is not None:
            assert githash == expected_git_hash, "Git hash mismatch: Expected: {0:08X}, got: {1:08X}".format(expected_git_hash,githash)

    def write_reg(self, address, value):
        """Writes to a PA3 register using SCA-I2C single byte mode"""
        assert 0 <= address <= 0x7F, "Only 7-bit address allowed"
        assert 0 <= value <= 0xFF, "Only 8-bit data allowed"

        self.sca._write_i2c(channel=self.sca_channel_used,
                            sl_addr=address,
                            nbytes=1,
                            data0=(value << 24))

    def write_fifo_reg_multibyte(self, address, data):
        """Writes up to 16 bytes to the same PA3 address, ie. fifo mode,
        using SCA-I2C multi byte mode. Expects a bytearray as input"""
        assert address | 0x7F == 0x7F, "Only 7-bit address allowed"
        assert len(data) in range(1, 16 + 1), "Max 16 bytes per I2C transaction"

        data_words = [0, 0, 0, 0]
        data_word = 0
        word_num = 0
        byte_num = 0

        # Join 4 bytes together in a 32-bit data word,
        # and store the 32-bit words in the list data_words
        for byte in data:
            assert byte | 0xFF == 0xFF, "Only 8-bit data allowed"
            data_word = (data_word << 8) | byte
            byte_num += 1

            if byte_num == 4:
                data_words[word_num] = data_word
                data_word = 0
                byte_num = 0
                word_num += 1

        if byte_num != 0:  # Not on a 4-byte boundary, add last word
            data_words[word_num] = data_word << (8 * (4 - byte_num))

        self.sca._write_i2c(channel=self.sca_channel_used,
                            sl_addr=address,
                            nbytes=len(data),
                            data0=data_words[0],
                            data1=data_words[1],
                            data2=data_words[2],
                            data3=data_words[3])

    def read_reg(self, address):
        """Reads a PA3 register using SCA-I2C single byte mode"""
        assert 0 <= address <= 0x7F, "Only 7-bit address allowed"
        try:
            result = self.sca._read_i2c(channel=self.sca_channel_used, sl_addr=address, nbytes=1)
        except Exception as e:
            add = Pa3Register(address)
            self.logger.error("Error in I2C read from address {0} = 0x{1:02X}".format(add.name, add.value))
            raise e
        return (result[0] >> 16) & 0xFF

    def read_fifo_reg(self, address, length):
        """Reads up to 16 bytes to a the same PA3 address, ie. fifo mode,
        using SCA-I2C multi byte mode. Returns a bytearray with the data"""
        assert 0 <= address <= 0x7F, "Only 7-bit address allowed"
        assert length in range(1, 16 + 1), "Max 16 bytes per I2C transaction"

        result = self.sca._read_i2c(channel=self.sca_channel_used, sl_addr=address, nbytes=length)
        data = bytearray(0)

        for byte_num in range(0, length):
            # First entry in results is status, data starts from index 1
            # Line below extracts one byte at a time from results, in correct order
            index = int(byte_num / 4) + 1
            shift_amount = 24 - 8 * (byte_num % 4)
            data_byte = result[index] >> (shift_amount)
            data_byte = data_byte & 0xFF
            data.append(data_byte)
        return data

    def set_reset(self, value):
        """Sets the RESET pin of the PA3 FPGA to value"""
        self.sca.set_gpio(ScaGpio.PA3_RESET, value)

    def reset_pa3(self):
        """pulse reset pin."""
        self.set_reset(1)
        time.sleep(0.001)
        self.set_reset(0)

    def set_start_program(self, value):
        """Sets the START_PROGRAM pin of the PA3 FPGA to value"""
        self.sca.set_gpio(ScaGpio.PA3_START_PROGRAM, value)
