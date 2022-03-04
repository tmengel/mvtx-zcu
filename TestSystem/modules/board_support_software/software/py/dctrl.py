"""Class to implement the latest capabilities of the dctrl/ctrl block relative to
trigger commands with busy management"""

from wishbone_module import WishboneModule
from userdefinedexceptions import ChipidMismatchError
from userdefinedexceptions import DataReadbackMismatchError
from enum import IntEnum

class WsDctrlAddress(IntEnum):
    """memory mapping for dctrl/ctrl module"""
    WRITE_CTRL                       = 0x00
    WRITE_ADDRESS                    = 0x01
    WRITE_DATA                       = 0x02
    PHASE_FORCE                      = 0x03
    READ_STATUS                      = 0x04
    READ_DATA                        = 0x05
    LATCH_CTRL_CNTRS                 = 0x06
    RST_CTRL_CNTRS                   = 0x07
    READ_BROADCAST_CNTR              = 0x08
    READ_WRITE_CNTR                  = 0x09
    READ_READ_CNTR                   = 0x0A
    READ_OPCODE_CNTR_LSB             = 0x0B
    READ_TRIGGER_SENT_CNTR_LSB       = 0x0C
    READ_TRIGGER_NOT_SENT_CNTR       = 0x0D
    MASK_BUSY_REG                    = 0x0E
    BUSY_TRANSCEIVER_MASK_LSB        = 0x0F
    READ_BUSY_TRANSCEIVER_STATUS_LSB = 0x10
    SET_DCTRL_INPUT                  = 0x11
    SET_DCTRL_TX_MASK                = 0x12
    BUSY_TRANSCEIVER_MASK_MSB        = 0x13
    READ_BUSY_TRANSCEIVER_STATUS_MSB = 0x14
    SET_DCLK_TX_MASK                 = 0x15
    MANCHESTER_TX_EN                 = 0x16
    SET_IDELAY_VALUE0                = 0x17
    SET_IDELAY_VALUE1                = 0x18
    SET_IDELAY_VALUE2                = 0x19
    SET_IDELAY_VALUE3                = 0x1A
    SET_IDELAY_VALUE4                = 0x1B
    GET_IDELAY_VALUE0                = 0x1C
    GET_IDELAY_VALUE1                = 0x1D
    GET_IDELAY_VALUE2                = 0x1E
    GET_IDELAY_VALUE3                = 0x1F
    GET_IDELAY_VALUE4                = 0x20
    AUTO_PHASE_OFFSET                = 0x21
    SET_DCLK_PARALLEL_0              = 0x22
    SET_DCLK_PARALLEL_1              = 0x23
    SET_DCLK_PARALLEL_2              = 0x24
    SET_DCLK_PARALLEL_3              = 0x25
    SET_DCLK_PARALLEL_4              = 0x26
    WAIT_CYCLES                      = 0x27
    MANCHESTER_RX_DETECTED           = 0x28
    READ_PULSE_SENT_CNTR_LSB         = 0x29
    READ_PULSE_SENT_CNTR_MSB         = 0x2A
    READ_OPCODE_REJECTED_CNTR_LSB    = 0x2B
    READ_OPCODE_REJECTED_CNTR_MSB    = 0x2C
    READ_OPCODE_CNTR_MSB             = 0x2D
    READ_TRIGGER_SENT_CNTR_MSB       = 0x2E
    MISMATCH                         = 0x2F
    NUM_REG                          = 0x30

class Dctrl(WishboneModule):
    """dctrl/cltr wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(Dctrl, self).__init__(moduleid=moduleid, name="DCTRL", board_obj=board_obj)
        self.verbose = False
        self.connector_used = None
        self.phase_dict = {0:   0b11110000,
                           45:  0b11100001,
                           90:  0b11000011,
                           135: 0b10000111,
                           180: 0b00001111,
                           225: 0b00011110,
                           270: 0b00111100,
                           315: 0b01111000}
        self.phase_dict_inv = {v: k for k, v in self.phase_dict.items()}


    def force_phase(self, phase, commitTransaction=True):
        """Forces offset sampling phase for DCTRL"""
        assert phase | 0x7 == 0x7
        self.write(WsDctrlAddress.PHASE_FORCE, 1<<3|phase, commitTransaction)

    def release_phase_force(self, commitTransaction=True):
        """Release the force on offset sampling phase for DCTRL"""
        phase = self.read(WsDctrlAddress.PHASE_FORCE, True)&0x7
        self.write(WsDctrlAddress.PHASE_FORCE, phase, commitTransaction)

    def get_phase_force(self, commitTransaction=True):
        return self.read(WsDctrlAddress.PHASE_FORCE, commitTransaction)>>3 & 0x1

    def get_phase(self, commitTransaction=True):
        """Get offset sampling phase for DCTRL"""
        return self.read(WsDctrlAddress.PHASE_FORCE, commitTransaction)&0x7

    def set_auto_phase_offset(self, offset, commitTransaction=True):
        """sets the phase offset for the automatic phase detection"""
        assert offset | 0x7 == 0x7
        self.write(WsDctrlAddress.AUTO_PHASE_OFFSET, offset, commitTransaction=commitTransaction)

    def get_auto_phase_offset(self, commitTransaction=True):
        """gets the phase offset for the automatic phase detection"""
        return self.read(WsDctrlAddress.AUTO_PHASE_OFFSET, commitTransaction=commitTransaction)

    def write_chip_reg(self, address, data, chipid, commitTransaction=True, readback=False):
        """Write to a specific register on the chip. commitTransaction
        flushes all pending write operations and sends it to the
        board.
        """
        assert chipid|0x7F == 0x7F
        assert address|0xFFFF == 0xFFFF
        assert data|0xFFFF == 0xFFFF
        self.write(WsDctrlAddress.WRITE_ADDRESS, address, commitTransaction=False)
        self.write(WsDctrlAddress.WRITE_DATA, data, commitTransaction=False)
        self.write(WsDctrlAddress.WRITE_CTRL, 0x9C<<8|chipid, commitTransaction=False)
        self.logger.debug("Write chip register: ChipId: %#2X Addr: %#4X, Data: %04X, commit: %s",
                         chipid, address, data, commitTransaction)
        if readback:
            self.flush()
            self.board.wait(1000, False)
            dataread = self.board.read_chip_reg(address=address, chipid=chipid, commitTransaction=True)
            if dataread != data:
                message = "data read is {1:#04X} while {0:#04X} was expected"
                msg_log = message.format(data, dataread)
                self.logger.error(msg_log)
                raise DataReadbackMismatchError(message, data, dataread)
        if commitTransaction:
            self.flush()

    def read_chip_reg(self, address, chipid, commitTransaction=True):
        """Read from a specific chip Register.  commitTransaction flushes all
        pending write operations and sends it to the board.
        """
        assert self.connector_used is not None, "Input connector is not set"
        read_done = False
        max_repeat = 1
        repeat = 0
        while repeat < max_repeat:
            assert chipid|0x7F == 0x7F
            assert address|0xFFFF == 0xFFFF
            self.write(WsDctrlAddress.WRITE_ADDRESS, address, commitTransaction=False)
            self.write(WsDctrlAddress.WRITE_CTRL, 0x4E<<8|chipid, commitTransaction=False)
            self.read(WsDctrlAddress.READ_STATUS, commitTransaction=False)
            self.read(WsDctrlAddress.READ_DATA, commitTransaction=False)
            if commitTransaction:
                # TODO: think on how to implement is without commitTransaction
                self.flush()
            output_stream = self.read_all()
            read_done = True
#            print(output_stream)
            status = output_stream[0]
            data = output_stream[1]
            chipid_read = status & 0x7F
            state = status>>7 & 0x3F
            selected_phase = status>>13

            self.logger.debug( ("Read chip register: ChipId: %#2X Addr: %#4X, Data read: %04X, "
                               "chipid read: %#02X, status: %#02X commit: %s, "
                                "phase_selected: %d"),
                               chipid, address, data, chipid_read, state,
                               commitTransaction, selected_phase)

            if state != 0x3F:
                # TODO: define ax exception for this kind of error
                self.logger.error("status read is %#X while 0x3F was expected. status %#04X. data %#04X. "
                                  "Connector %r, Phase %d",
                                  state, status, data, self.connector_used, selected_phase)
                read_done = False
            if chipid_read != chipid:
                message = "chipid read is 0b{0:07b} while 0b{1:07b} was expected"
                msg_log = message.format(chipid_read, chipid,self.connector_used)
                self.logger.error(msg_log)
                self.logger.error("Connector {0}, Phase {1}".format(self.connector_used, selected_phase))
                if repeat == max_repeat-1:
                    raise ChipidMismatchError(message, chipid, chipid_read)
                read_done = False
            repeat += 1
            self.logger.debug("dctrl read_chip_reg: repeat = %d, read_done %s", repeat, read_done)
            if read_done:
                break
        return data

    def write_chip_opcode(self, opcode, commitTransaction=True):
        """Write a specific opcode to the chip. commitTransaction
        flushes all pending write operations and sends it to the
        board.
        """
        self.write(WsDctrlAddress.WRITE_CTRL, opcode<<8|0, commitTransaction=commitTransaction)
        self.logger.debug("Write chip opcode: %#02X, commitTransaction: %s",
                         opcode, commitTransaction)

    def on_poweron_chip(self,avdd,dvdd,pvdd,backbias):
        self.logger.debug("Power on chip with AVDD=%2.2f, DVDD=%2.2f, PVDD=%s, BB=%s",
                         avdd,dvdd,pvdd,backbias)

    def on_poweroff_chip(self):
        self.logger.debug("Power off chip")

    def busy_force(self, force_value):
        """forces the busy logic to the given value
        Note that the force is not applied to the chip and this force is olny
        relative to the logic steering the trigger generation isnide the
        ctrl/dctrl block"""
        assert force_value|0x1 == 0x1
        self.write(WsDctrlAddress.MASK_BUSY_REG, force_value<<1|1<<0)

    def busy_force_release(self):
        """releases the force on busy logic"""
        self.write(WsDctrlAddress.MASK_BUSY_REG, 0)

    def _latch_ctrl_cntrs(self, commitTransaction=True):
        """latches all the counters inside the ctrl block"""
        self.write(WsDctrlAddress.LATCH_CTRL_CNTRS, 0xFF, commitTransaction=commitTransaction)

    def rst_ctrl_cntrs(self, commitTransaction=True):
        self.reset_counters(commitTransaction=commitTransaction)

    def reset_counters(self, commitTransaction=True):
        """resets all the counters"""
        self.write(WsDctrlAddress.RST_CTRL_CNTRS, 0xFF, False)
        self.write(WsDctrlAddress.RST_CTRL_CNTRS, 0, False)
        if commitTransaction:
            self.flush()

    def _read_counters(self, reset_after=False, commitTransaction=True):
        """gets the value of all the counters and returns them into a dictionary"""
        self.read(WsDctrlAddress.READ_BROADCAST_CNTR,commitTransaction=False)
        self.read(WsDctrlAddress.READ_WRITE_CNTR,commitTransaction=False)
        self.read(WsDctrlAddress.READ_READ_CNTR,commitTransaction=False)

        self.read(WsDctrlAddress.READ_OPCODE_CNTR_MSB,commitTransaction=False)
        self.read(WsDctrlAddress.READ_OPCODE_CNTR_LSB,commitTransaction=False)
        self.read(WsDctrlAddress.READ_TRIGGER_SENT_CNTR_MSB,commitTransaction=False)

        self.read(WsDctrlAddress.READ_TRIGGER_SENT_CNTR_LSB,commitTransaction=False)
        self.read(WsDctrlAddress.READ_TRIGGER_NOT_SENT_CNTR,commitTransaction=False)
        self.read(WsDctrlAddress.READ_PULSE_SENT_CNTR_MSB,commitTransaction=False)

        self.read(WsDctrlAddress.READ_PULSE_SENT_CNTR_LSB,commitTransaction=False)
        self.read(WsDctrlAddress.READ_OPCODE_REJECTED_CNTR_MSB,commitTransaction=False)
        self.read(WsDctrlAddress.READ_OPCODE_REJECTED_CNTR_LSB,commitTransaction=False)
        if reset_after:
            self.reset_counters(commitTransaction=False)
        if commitTransaction:
            self.comm.flush()
            results = self.comm.read_results()
            assert len(results) == 12, "len not correct {0}/12".format(len(results))
            ret = {}
            ret['broadcast'] = results[0][1]
            ret['write'] = results[1][1]
            ret['read'] = results[2][1]
            ret['opcode'] = results[3][1]<<16 | results[4][1]
            ret['trigger_sent'] = results[5][1]<<16 | results[6][1]
            ret['trigger_not_sent'] = results[7][1]
            ret['pulse_sent'] = results[8][1]<<16 | results[9][1]
            ret['opcode_rejected'] = results[10][1]<<16 | results[11][1]
            return ret

    def get_counters(self, reset_after=False, commitTransaction=True):
        """latches and reads all the counters"""
        self._latch_ctrl_cntrs(commitTransaction=False)
        return self._read_counters(reset_after=reset_after, commitTransaction=commitTransaction)

    def get_busy_transceiver_mask(self):
        """gets the actual value of the busy transceiver mask"""
        LSB = self.read(WsDctrlAddress.BUSY_TRANSCEIVER_MASK_LSB)
        MSB = self.read(WsDctrlAddress.BUSY_TRANSCEIVER_MASK_MSB)
        return MSB << 16| LSB

    def set_busy_transceiver_mask(self, mask):
        """sets the busy transceiver mask"""
        assert mask | 0xFFFFFFFF == 0xFFFFFFFF
        mask_lsb = mask >> 0  & 0xFFFF
        mask_msb = mask >> 16 & 0xFFFF
        self.write(WsDctrlAddress.BUSY_TRANSCEIVER_MASK_LSB, mask_lsb)
        self.write(WsDctrlAddress.BUSY_TRANSCEIVER_MASK_MSB, mask_msb)

    def get_busy_transceiver_status(self):
        """gets the status of the busy flag for the transceivers"""
        LSB = self.read(WsDctrlAddress.READ_BUSY_TRANSCEIVER_STATUS_LSB)
        MSB = self.read(WsDctrlAddress.READ_BUSY_TRANSCEIVER_STATUS_MSB)
        return MSB << 16 | LSB

    def set_input(self, dctrl_input=0, force=False, commitTransaction=True):
        """Sets which DCTRL line is used to receive chip replies"""
        assert dctrl_input in range(5)
        if force or dctrl_input != self.connector_used:
            self.write(WsDctrlAddress.SET_DCTRL_INPUT, dctrl_input, commitTransaction=commitTransaction)
            self.connector_used = dctrl_input

    def get_input(self):
        """Read on which line the dctrl receives replies """
        return self.read(WsDctrlAddress.SET_DCTRL_INPUT)

    def set_dctrl_mask(self, mask):
        """sets a 1-hot mask for transmission on DCTRL"""
        assert mask | 0x1F == 0x1F
        self.write(WsDctrlAddress.SET_DCTRL_TX_MASK, mask)

    def get_dctrl_mask(self):
        """gets a 1-hot mask for transmission on DCTRL"""
        return self.read(WsDctrlAddress.SET_DCTRL_TX_MASK)

    def set_dclk_mask(self, mask):
        """sets a 1-hot mask for transmission on DCTRL"""
        assert mask | 0x1F == 0x1F
        self.write(WsDctrlAddress.SET_DCLK_TX_MASK, mask)

    def get_dclk_mask(self):
        """gets a 1-hot mask for transmission of DCLK"""
        return self.read(WsDctrlAddress.SET_DCLK_TX_MASK)

    def enable_manchester_tx(self, commitTransaction=True):
        """Enables the manchester encoding in transmission"""
        self.write(WsDctrlAddress.MANCHESTER_TX_EN, 1, commitTransaction=commitTransaction)

    def disable_manchester_tx(self, commitTransaction=True):
        """Disables the manchester encoding in transmission"""
        self.write(WsDctrlAddress.MANCHESTER_TX_EN, 0, commitTransaction=commitTransaction)

    def get_manchester_tx(self):
        """check if the manchester encoding in transmission is enabled"""
        return self.read(WsDctrlAddress.MANCHESTER_TX_EN)

    def _set_idelay(self, index=None, idelay=None, commitTransaction=True):
        """sets the input delay for ports index"""
        assert idelay | 0x1FF == 0x1FF
        assert index in range(5)
        self.write(WsDctrlAddress.SET_IDELAY_VALUE0 + index, idelay, commitTransaction=commitTransaction)

    def _get_idelay(self, index=None):
        """gets the idelay value for index"""
        assert index in list(range(5))

        return self.read(WsDctrlAddress.SET_IDELAY_VALUE0 + index) & 0x1FF

    def _get_idelay_read(self, index=None):
        """gets the idelay value for index"""
        assert index in list(range(5))
        return self.read(WsDctrlAddress.GET_IDELAY_VALUE0 + index) & 0x1FF

    def set_idelays(self, idelays=None, idelay_all=None, commitTransaction=True):
        """sets the input delay of all the dctrl ports, in they are not None"""
        if idelay_all is not None:
            assert idelays == None, "Only one of the two input can be given"
            idelays = [idelay_all]*5
        assert isinstance(idelays, list), "{0} should be a list".format(idelays)
        for i in range(5):
            self._set_idelay(idelay=idelays[i], index=i, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def get_idelays(self):
        """gets the idelay values and check if values are consistent,
        returns a tuple with the idelays 0 to 4"""
        idelays = []
        idelays_read = []
        for i in range(5):
            idelays.append(self._get_idelay(index=i))
            idelays_read.append(self._get_idelay_read(index=i))
        assert idelays==idelays_read, "idelays value set is not consisistend with read value: SET {0} GET {1}".format(idelays,
                                                                                                                      idelays_read)
        return idelays_read

    def get_mismatch(self):
        """returns the instantaneous value of the mismatch register"""
        return self.read(WsDctrlAddress.MISMATCH)

    def set_dclk_parallel(self, phase, index, commitTransaction=True):
        """sets the dclk parallel with the given phase [0:45:360-45]"""
        index = 4 - index # FIXME
        assert index in range(5)
        assert phase in range(0,360,45)
        self.write(WsDctrlAddress.SET_DCLK_PARALLEL_0+index, self.phase_dict[phase], commitTransaction=commitTransaction)

    def get_dclk_parallel(self, index, commitTransaction=True):
        """gets the dclk parallel phase [0:45:360-45]"""
        index = 4 - index # FIXME
        assert index in range(5)
        return self.phase_dict_inv[self.read(WsDctrlAddress.SET_DCLK_PARALLEL_0+index,
                                             commitTransaction=commitTransaction)]

    def set_wait_cycles(self, value, commitTransaction=True):
        """sets the wait cycles for the automatic phase detection"""
        assert value | 0xF == 0xF
        self.write(WsDctrlAddress.WAIT_CYCLES, value, commitTransaction=commitTransaction)

    def get_wait_cycles(self, commitTransaction=True):
        """gets the wait cycles for the automatic phase detection"""
        return self.read(WsDctrlAddress.WAIT_CYCLES, commitTransaction=commitTransaction)

    def get_manchester_rx_detected(self, commitTransaction=True):
        """Returns 1 if manchester has been detected"""
        return self.read(WsDctrlAddress.MANCHESTER_RX_DETECTED, commitTransaction=commitTransaction) & 0x1

    def dump_config(self):
        config_str = "--- ALPIDE DCTRL module ---\n"

        config_str += "  - Write phase register:\n"
        self.board.comm.disable_rderr_exception()
        for address in WsDctrlAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str
        self.board.comm.enable_rderr_exception()

    def readreg_write_phase(self):
        """Read the Write phase register"""
        assert NotImplementedError("Obsolete function")
