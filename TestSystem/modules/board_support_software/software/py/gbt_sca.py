""" Generic SCA module

"""

import logging
from enum import IntEnum
from enum import IntFlag

class ScaGpio(IntEnum):
    XCKU_TMR_RESET       = 0
    XCKU_TMR_RESERVED1   = 1
    XCKU_TMR_RESERVED2   = 2
    XCKU_TMR_RESERVED3   = 3
    XCKU_RESERVED4       = 4
    XCKU_RESERVED5       = 5
    XCKU_RESERVED6       = 6
    XCKU_RESERVED7       = 7
    XCKU_RESERVED8       = 8
    XCKU_RESERVED9       = 9
    XCKU_RESERVED10      = 10
    XCKU_RESERVED11      = 11
    PA3_START_PROGRAM    = 12
    PA3_PROGRAM_DONE     = 13
    PA3_RESET            = 14
    PA3_ALIVE_COUNTER_b0 = 15
    PA3_ALIVE_COUNTER_b1 = 16
    PA3_ALIVE_COUNTER_b2 = 17
    PA3_ALIVE_COUNTER_b3 = 18
    PA3_ALIVE_COUNTER_b4 = 19
    SCA_GPIO_NUM         = 20

class ScaChannel(IntEnum):
    """Copied from p17 of the GBT-SCA-UserManual.pdf v8.2
    (https://espace.cern.ch/GBT-Project/GBT-SCA/Manuals/Forms/AllItems.aspx)"""
    CTRL = 0x00  # SCA configuration registers
    SPI  = 0x01  # Serial Peripheral master Interface
    GPIO = 0x02  # Parallel I/O interface
    I2C0 = 0x03  # I2C Serial interface - master 0 (PA3)
    I2C1 = 0x04  # I2C Serial interface - master 1
    I2C2 = 0x05  # I2C Serial interface - master 2
    I2C3 = 0x06  # I2C Serial interface - master 3
    I2C4 = 0x07  # I2C Serial interface - master 4 (US)
    I2C5 = 0x08  # I2C Serial interface - master 5 (PA3)
    I2C6 = 0x09  # I2C Serial interface - master 6
    I2C7 = 0x0A  # I2C Serial interface - master 7 (GBTX)
    I2C8 = 0x0B  # I2C Serial interface - master 8
    I2C9 = 0x0C  # I2C Serial interface - master 9
    I2CA = 0x0D  # I2C Serial interface - master 10
    I2CB = 0x0E  # I2C Serial interface - master 11
    I2CC = 0x0F  # I2C Serial interface - master 12
    I2CD = 0x10  # I2C Serial interface - master 13
    I2CE = 0x11  # I2C Serial interface - master 14
    I2CF = 0x12  # I2C Serial interface - master 15
    JTAG = 0x13  # JTAG serial master interface
    ADC  = 0x14  # Analog to digital converter
    DAC  = 0x15  # Digital to analog converter

class ScaErrorFlag(IntFlag):
    """Sca error flag bit mapping"""
    GENERIC_ERROR_FLAG          = 0
    INVALID_CHANNEL_REQUEST     = 1
    INVALID_COMMAND_REQUEST     = 2
    INVALID_TRANSACTION_REQUEST = 3
    INVALID_LENGTH              = 4
    CHANNEL_NOT_ENABLED         = 5
    CHANNEL_CURRENTLY_BUSY      = 6
    COMMAND_IN_TREATMENT        = 7
    NUM_BITS                    = 8

class ScaBadErrorFlagError(Exception):
    """basic class to define an SCA error flag exception"""

    def __init__(self, status=None):
        super(ScaBadErrorFlagError, self).__init__()
        self.logger = logging.getLogger("SCA")
        self.status=status
        self.error_message = ""
        self.get_error_message()
        self.log_info()

    def __sts__(self):
        return repr(self.status)

    def __srt__(self):
        return repr(self.error_message)

    def get_error_message(self):
        for i in range(ScaErrorFlag.NUM_BITS):
            # isolates individual errors
            if self.status>>i & 0x1 == 0x1:
                self.error_message += "\t\t\t\t\t{0}\n".format(ScaErrorFlag(i).name)

    def log_info(self):
        """returns the args of the exception"""
        self.logger.error("SCA Error Return:\t0x{0:02X}".format(self.status))
        self.logger.error("Errors Identified:\n{0}".format(self.error_message))

class ScaI2cStatusFlag(IntFlag):
    """SCA I2C status bit mapping"""
    RESERVED0 = 0
    RESERVED1 = 1
    SUCC      = 2
    LEVERR    = 3
    EMPTY4    = 4
    INVCOM    = 5
    NOACK     = 6
    EMPTY7    = 7
    NUM_BITS  = 8

class ScaI2cCmd(IntEnum):
    I2C_W_CTRL  = 0x30 # Write CONTROL register
    I2C_R_CTRL  = 0x31 # Read CONTROL register
    I2C_R_STR   = 0x11 # Read STATUS register
    I2C_W_MSK   = 0x20 # Write MASK register
    I2C_R_MSK   = 0x21 # Read MASK register
    I2C_W_DATA0 = 0x40 # Write data register bytes 0,1,2,3
    I2C_R_DATA0 = 0x41 # Read data register bytes 0,1,2,3
    I2C_W_DATA1 = 0x50 # Write data register bytes 4,5,6,7
    I2C_R_DATA1 = 0x51 # Write data register bytes 4,5,6,7
    I2C_W_DATA2 = 0x60 # Write data register bytes 8,9,10,11
    I2C_R_DATA2 = 0x61 # Write data register bytes 8,9,10,11
    I2C_W_DATA3 = 0x70 # Write data register bytes 12,13,14,15
    I2C_R_DATA3 = 0x71 # Write data register bytes 12,13,14,15
    I2C_S_7B_W  = 0x82 # Start I2C single byte write (7-bit addr)
    I2C_S_7B_R  = 0x86 # Start I2C single byte read (7-bit addr)
    I2C_S_10B_W = 0x8A # Start I2C single byte write (10-bit addr)
    I2C_S_10B_R = 0x8E # Start I2C single byte read (10-bit addr)
    I2C_M_7B_W  = 0xDA # Start I2C multi byte write (7-bit addr)
    I2C_M_7B_R  = 0xDE # Start I2C multi byte read (7-bit addr)
    I2C_M_10B_W = 0xE2 # Start I2C multi byte write (10-bit addr)
    I2C_M_10B_R = 0xE6 # Start I2C multi byte read (10-bit addr)
    #I2C_RMW_AND = # Address not specified in SCA manual??
    I2C_RMW_OR  = 0xC6 # Start I2C read-modify-write transaction with OR mask
    I2C_RMW_XOR = 0xCA # Start I2C read-modify-write transaction with XOR mask

class ScaI2cSpeed(IntEnum):
    f100kHz = 0
    f200kHz = 1
    f400kHz = 2
    f1MHz   = 3

class ScaI2cBadStatusError(Exception):
    """basic class to define an SCA I2C read error exception"""

    def __init__(self, status=None):
        super(ScaI2cBadStatusError, self).__init__()
        self.logger = logging.getLogger("SCA")
        self.status = status
        self.error_message = ""
        self.get_error_message()
        self.log_info()

    def __sts__(self):
        return repr(self.status)

    def __srt__(self):
        return repr(self.error_message)

    def get_error_message(self):
        for i in range(ScaI2cStatusFlag.NUM_BITS):
            # isolates individual errors
            if self.status>>i & 0x1 == 0x1:
                self.error_message += "\t\t\t\t\t{0}\n".format(ScaI2cStatusFlag(i).name)

    def log_info(self):
        """returns the args of the exception"""
        self.logger.error("SCA I2C bad status return:\t0x{0:02X}".format(self.status))
        self.logger.error("Errors Identified:\n{0}".format(self.error_message))

class Sca(object):
    """Class to handle SCA transactions"""

    def __init__(self, use_adc=True, use_gpio=True, use_pa3_i2c=True, use_pa3_i2c_2=True, use_us_i2c=True, use_jtag=True):
        #super().__init__()
        self.use_adc = use_adc
        self.use_gpio = use_gpio
        self.use_pa3_i2c = use_pa3_i2c
        self.use_pa3_i2c_2 = use_pa3_i2c_2
        self.use_us_i2c = use_us_i2c
        self.use_jtag = use_jtag

    def initialize(self):
        self.init_communication()
        self.enable_channel(ADC=self.use_adc, GPIO=self.use_gpio, I2C_PA3_1=self.use_pa3_i2c,
                            I2C_PA3_2=self.use_pa3_i2c_2, I2C_US=self.use_us_i2c, JTAG=self.use_jtag)
        self.initialize_adc_channel()
        self.initialize_gpio_channel()

    def initialize_gpio_channel(self):
        DIRECTION = 0x5001 # 14, 12, 0 are output, rest are input
        self.set_gpio_direction(DIRECTION)


    def _sca_write(self, channel, length, command, scadata, trid=0x12, commitTransaction=True, wait=400):
        """Implementation of writing to SCA"""
        raise NotImplementedError

    def _sca_read(self):
        """Implementation of reading from SCA"""
        raise NotImplementedError

    def init_communication(self):
        """Implementation to initialize communication with SCA"""
        raise NotImplementedError

    def enable_channel(self, SPI=0, GPIO=0, I2C_PA3_1=0, I2C_PA3_2=0,
                       I2C_VTTX1=0, I2C_VTTX2=0, I2C_VTRX2=0,
                       I2C_US=0, I2C_GBTX=0, JTAG=0, ADC=0):
        CRB = (SPI<<1) | (GPIO<<2) | (I2C_PA3_1<<3) | (I2C_VTTX1<<4) | \
              (I2C_VTTX2<<5) | (I2C_VTRX2<<6) | (I2C_US<<7)
        CRC = (I2C_PA3_2) | (I2C_GBTX<<2)
        CRD = (JTAG<<3) | (ADC<<4)

        CRB = CRB<<24
        CRC = CRC<<24
        CRD = CRD<<24

        self._sca_write(channel=ScaChannel.CTRL, length=1, command=0x02, scadata=CRB)
        self._sca_write(channel=ScaChannel.CTRL, length=1, command=0x04, scadata=CRC)
        self._sca_write(channel=ScaChannel.CTRL, length=1, command=0x06, scadata=CRD)

    def initialize_i2c_channel(self, channel, speed=ScaI2cSpeed.f1MHz):
        """
        Sets the I2C transactions speed to 1MHz,
        with no multi byte operation and
        no scl mode
        """
        self.set_i2c_w_ctrl_reg(channel=channel, speed=speed, nbytes=0, sclmode=0)

    def set_i2c_w_ctrl_reg(self, channel, speed, nbytes, sclmode):
        """GBT sca manual page 23 v8.2"""
        speed =  ScaI2cSpeed(speed) # Assert if not in value
        assert nbytes in range(17)
        assert sclmode in range(2)
        assert channel not in [ScaChannel.CTRL, ScaChannel.SPI, ScaChannel.GPIO, ScaChannel.ADC, ScaChannel.DAC], "Only writing to I2C channels allowed with this function"

        data = sclmode<<7|nbytes<<2|speed.value
        data = data<<24 # uses uppermost bits

        self._sca_write(channel=channel, length=1, command=ScaI2cCmd.I2C_W_CTRL, scadata=data, wait=400)

    def initialize_adc_channel(self):
        self._sca_write(channel=ScaChannel.ADC, length=4, command=0x60, scadata=0x01800000)

    def set_adc_channel(self, channel, commitTransaction=True):
        """Sets the adc channel to the correct MUX channel"""
        assert channel in range(32), " Channel must be between 0 and 31"
        self._sca_write(channel=ScaChannel.ADC, length=4, command=0x50, scadata=channel, commitTransaction=commitTransaction)

    def read_adc_channel(self, channel):
        """Expected wait time for ADC read: 9000 cycles"""
        self.set_adc_channel(channel, commitTransaction=True)
        self._sca_write(channel=ScaChannel.ADC, length=4, command=0x02, scadata=1, commitTransaction=True, wait=20000) # ADC go command
        return self._sca_read()

    def read_gpio(self):
        self._sca_write(channel=ScaChannel.GPIO, length=1, command=0x01, scadata=0) # GPIO_R_DATAIN
        return self._sca_read()

    def write_gpio(self, value):
        """Writes GPIOs set to output"""
        self._sca_write(channel=ScaChannel.GPIO, length=4, command=0x10, scadata=value)

    def set_gpio_direction(self, value):
        """Sets the direction for the GPIO pin of the SCA.
        value is a one-hot bit array with position n indicating GPIO n
        if the bit is set to 1, the pin is an output,
        if the bit is set to 0, the pin is an input"""
        assert value | 0xFFFFF == 0xFFFFF
        self._sca_write(channel=ScaChannel.GPIO, length=4, command=0x20, scadata=value)

    def set_gpio(self, index, value):
        """overwrites the value in the index with the value in the SCA gpio"""
        assert value in range(2)
        assert index in range(ScaGpio.SCA_GPIO_NUM)
        actual_value = self.read_gpio()
        if value == 0:
            altered_value = ~(1 << index) & actual_value
        else:
            altered_value = (1 << index) | actual_value
        print("Got SCA GPIO {0:#06X} and set to {1:#06X}".format(actual_value, altered_value))
        self.write_gpio(altered_value)

    def set_xcku_reset(self, value):
        """XCKU reset via SCA"""
        assert value in range(2)
        self.set_gpio(index=ScaGpio.XCKU_TMR_RESET, value=value)

    def _write_spi(self, slave_select, nbits, data0=0, data1=0, data2=0, data3=0):
        """Perform a SPI write of "nbits" on SCA channel "channel" with slave_select as SPI slave select (8bit)
        Up to 16 bytes can be sent, to be filled into data0 - data3 as follows:
        """

        data = 19
        self._sca_write(channel=ScaChannel.SPI, length=6, command=0x50, scadata=data, wait=400)

        assert nbits in range(128+1), "Max 128 bits allowed"

        if nbits > 96:
            self._sca_write(channel=ScaChannel.SPI, length=6, command=0x30, scadata=data3)
        if nbits > 64:
            self._sca_write(channel=ScaChannel.SPI, length=6, command=0x20, scadata=data2, wait=400)
        if nbits > 32:
            self._sca_write(channel=ScaChannel.SPI, length=6, command=0x10, scadata=data1, wait=400)
        if nbits > 0:
            self._sca_write(channel=ScaChannel.SPI, length=6, command=0x00, scadata=data0, wait=400)

        # write control register
        data = (nbits & 0x00ff) | (0x30 << 8)
        self._sca_write(channel=ScaChannel.SPI, length=6, command=0x40, scadata=data, wait=400)

        # enable targeted slave select
        data = ((1 << slave_select) & 0xff)
        self._sca_write(channel=ScaChannel.SPI, length=6, command=0x60, scadata=data, wait=400)

        # start write
        self._sca_write(channel=ScaChannel.SPI, length=2, command=0x72, scadata=data, wait=400)

        status = self._sca_read()
        return status

    def _read_spi(self, slave_select, nbits):
        """Perform a SPI read of "nbits" on SCA channel "channel" with slave_select as SPI slave select (8bit)
        For all other nbyte values, the return is a tuple of up to five 32bit unsigned integers as follows:
        """
        assert nbits in range(128+1), "Max 128 bits allowed"
        results = []
        # write control register
        data = (nbits & 0x00ff) | (0x30 << 8)
        self._sca_write(channel=ScaChannel.SPI, length=6, command=0x40, scadata=data, wait=400)

        # enable targeted slave select
        data = ((1 << slave_select) & 0xff)
        self._sca_write(channel=ScaChannel.SPI, length=6, command=0x60, scadata=data, wait=400)

        # start read
        self._sca_write(channel=ScaChannel.SPI, length=2, command=0x72, scadata=data, wait=400)

        # return read value is status in upper 8 bits
        results.append(self._sca_read())
        if nbits > 0:
            self._sca_write(channel=ScaChannel.SPI, length=2, command=0x01, scadata=0, wait=10000)
            results.append(self._sca_read())
        if nbits > 4:
            self._sca_write(channel=ScaChannel.SPI, length=2, command=0x11, scadata=0, wait=10000)
            results.append(self._sca_read())
        if nbits > 8:
            self._sca_write(channel=ScaChannel.SPI, length=2, command=0x21, scadata=0, wait=10000)
            results.append(self._sca_read())
        if nbits > 12:
            self._sca_write(channel=ScaChannel.SPI, length=2, command=0x31, scadata=0, wait=10000)
            results.append(self._sca_read())

        return(results)

    def _write_i2c(self, channel, sl_addr, nbytes, data0=0, data1=0, data2=0, data3=0):
        """Perform a I2C write of "nbytes" on SCA channel "channel" to I2C slave address "sl_addr" (7bit)
        Up to 16 bytes can be sent, to be filled into data0 - data3 as follows:
        data0 = byte0<<24  | byte1<<16  | byte2<<8  | byte3
        data1 = byte4<<24  | byte5<<16  | byte6<<8  | byte7
        data2 = byte8<<24  | byte9<<16  | byte10<<8 | byte11
        data3 = byte12<<24 | byte13<<16 | byte14<<8 | byte15
        """
        assert channel not in [ScaChannel.CTRL, ScaChannel.SPI, ScaChannel.GPIO, ScaChannel.ADC, ScaChannel.DAC], "Only writing to I2C channels allowed with this function"
        assert nbytes | 0xFFFF == 0xFFFF, "Max 16 bytes allowed"
        if nbytes == 1 :
            data = ((sl_addr & 0x7f)<<24) | ((data0 & 0xff000000)>>8)
            # I2C_S_7B_W needs 20 us (3200) wait to be executed @ 1 MHz
            self._sca_write(channel=channel, length=2, command=ScaI2cCmd.I2C_S_7B_W, scadata=data, wait=40000)
            status = self._sca_read()
            if (status & 0xff000000) != 0x04000000:
                raise ScaI2cBadStatusError(status>>24)
            return

        if nbytes > 12:
            self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_W_DATA3, scadata=data3, wait=800)
        if nbytes > 8:
            self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_W_DATA2, scadata=data2, wait=800)
        if nbytes > 4:
            self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_W_DATA1, scadata=data1, wait=800)
        if nbytes > 0:
            self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_W_DATA0, scadata=data0, wait=800)

        # Update control register for multi byte write
        self.set_i2c_w_ctrl_reg(channel=channel, speed=ScaI2cSpeed.f1MHz, nbytes=nbytes, sclmode=0)

        # Start multibyte write
        data = ((sl_addr & 0x7f)<<24)
        self._sca_write(channel=channel, length=1, command=ScaI2cCmd.I2C_M_7B_W, scadata=data, wait=40000)

        status = self._sca_read()
        if (status & 0xff000000) != 0x04000000:
            raise ScaI2cBadStatusError(status>>24)

    def _read_i2c(self, channel, sl_addr, nbytes):
        """Perform a I2C read of "nbytes" on SCA channel "channel" from I2C slave address "sl_addr" (7bit)
        If nbytes==1 the value returned contains (status<<24 | byte0<<16)
        For all other nbyte values, the return is a tuple of up to five 32bit unsigned integers as follows:
        data0 = status<<24
        data1 = byte0<<24  | byte1<<16  | byte2<<8  | byte3
        data2 = byte4<<24  | byte5<<16  | byte6<<8  | byte7
        data3 = byte8<<24  | byte9<<16  | byte10<<8 | byte11
        data4 = byte12<<24 | byte13<<16 | byte14<<8 | byte15
        """
        assert channel not in [ScaChannel.CTRL, ScaChannel.SPI, ScaChannel.GPIO, ScaChannel.ADC, ScaChannel.DAC], "Only writing to I2C channels allowed with this function"
        assert nbytes | 0xFFFF == 0xFFFF, "Max 16 bytes allowed"
        results = []
        if nbytes == 1:
            data = ((sl_addr & 0x7f)<<24)
            self._sca_write(channel=channel, length=1, command=ScaI2cCmd.I2C_S_7B_R, scadata=data, wait=40000)
            results.append(self._sca_read())
            status = results[0]
            if (status & 0xff000000) != 0x04000000:
                raise ScaI2cBadStatusError(status>>24)
            return(results)
        else:
            #print("Reading {0} bytes from I2C".format(nbytes))

            # Update control register for multi byte write
            self.set_i2c_w_ctrl_reg(channel=channel, speed=ScaI2cSpeed.f1MHz, nbytes=nbytes, sclmode=0)
            # Start multibyte read
            data = (sl_addr & 0x7f)<<24
            self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_M_7B_R, scadata=data, wait=40000)
            # return read value is status in upper 8 bits
            results.append(self._sca_read())
            if nbytes > 0:
                self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_R_DATA3, scadata=0, wait=800)
                results.append(self._sca_read())
            if nbytes > 4:
                self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_R_DATA2, scadata=0, wait=800)
                results.append(self._sca_read())
            if nbytes > 8:
                self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_R_DATA1, scadata=0, wait=800)
                results.append(self._sca_read())
            if nbytes > 12:
                self._sca_write(channel=channel, length=4, command=ScaI2cCmd.I2C_R_DATA0, scadata=0, wait=800)
                results.append(self._sca_read())

        return(results)

    def read_gbtx_register(self, register, gbtx=0):
        """Read GBTx register "register" from GBTx "gbtx" """
        assert gbtx in range(3)
        sl_addr = gbtx*2+1
        data0 = ((register&0xff)<<24) | ((register&0xff00)<<8)
        self._write_i2c(channel=ScaChannel.I2C7, sl_addr=sl_addr, nbytes=2,
                        data0=data0)
        result = self._read_i2c(channel=ScaChannel.I2C7, sl_addr=sl_addr, nbytes=1)
        return((result[0]>>16)&0xff)

    def write_gbtx_register(self, register, value, gbtx=0):
        """Write "value" (8bit) to register "register" of GBTx "gbtx" """
        assert gbtx in range(3)
        sl_addr = gbtx*2+1
        data0 = ((register&0xff)<<24) | ((register&0xff00)<<8) | ((value&0xff)<<8)
        self._write_i2c(channel=ScaChannel.I2C7, sl_addr=sl_addr, nbytes=3, data0=data0)

    def read_us_i2c(self):
        """Read 1 byte from Ultrascale I2C channel at the test slave address 0101000"""
        result = self._read_i2c(channel=ScaChannel.I2C4, sl_addr=0x28, nbytes=1)
        return((result[0] >> 16) & 0xff)

    def write_us_i2c(self, val):
        """Write 1 byte to Ultrascale I2C channel at the test slave address 0101000"""
        data0 = (val & 0xff) << 24
        self._write_i2c(channel=ScaChannel.I2C4, sl_addr=0x28, nbytes=1, data0=data0)

    def do_jtag_idcode(self):
        # JTAG procedure as outlined in J. Schambach's OneNote page:

        # JTAG_W_CTRL command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x80, scadata=0x35)
        # JTAG_W_FREQ command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x90, scadata=0x01)
        # JTAG_W_TMS0 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x40, scadata=0x000381bf)
        # JTAG_W_TMS1 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x50, scadata=0x00180000)
        # JTAG_W_TDO0 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x00, scadata=0x00009000)
        # JTAG_W_TDO1 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x10, scadata=0x00000000)

        # JTAG_GO command
        self._sca_write(channel=ScaChannel.JTAG, length=1, command=0xa2, scadata=0x00000000, wait=40000)

        # JTAG_R_TDI0 command
        self._sca_write(channel=ScaChannel.JTAG, length=2, command=0x01, scadata=0)
        read_lsb = self._sca_read()

        # JTAG_R_TDI1 command
        self._sca_write(channel=ScaChannel.JTAG, length=2, command=0x11, scadata=0)
        read_msb = self._sca_read()

        # construct the ID code read from the two TDI registers
        id_code = (read_lsb >> 20) | (read_msb << 12)

        return(id_code)

    def do_jtag_idcode_chained(self):
        # JTAG procedure as outlined in J. Schambach's OneNote page:

        # JTAG_W_CTRL command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x80, scadata=0x3e)
        # JTAG_W_FREQ command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x90, scadata=0x01)
        # JTAG_W_TMS0 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x40, scadata=0x038001bf)
        # JTAG_W_TMS1 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x50, scadata=0x30000000)
        # JTAG_W_TDO0 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x00, scadata=0x00ff9000)
        # JTAG_W_TDO1 command
        self._sca_write(channel=ScaChannel.JTAG, length=4, command=0x10, scadata=0x00000000)

        # JTAG_GO command
        self._sca_write(channel=ScaChannel.JTAG, length=1, command=0xa2, scadata=0x00000000, wait=40000)

        # JTAG_R_TDI0 command
        self._sca_write(channel=ScaChannel.JTAG, length=2, command=0x01, scadata=0)
        read_lsb = self._sca_read()

        # JTAG_R_TDI1 command
        self._sca_write(channel=ScaChannel.JTAG, length=2, command=0x11, scadata=0)
        read_msb = self._sca_read()

        # construct the ID code read from the two TDI registers
        id_code = (read_lsb >> 28) | (read_msb << 4)

        return(id_code)
