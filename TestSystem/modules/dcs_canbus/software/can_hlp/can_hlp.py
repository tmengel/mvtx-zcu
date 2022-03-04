"""CANbus High Level Protocol.
Includes CanHlp class for communicating with Readout Unit via CAN bus, and
relevant exceptions, and a small set of wishbone registers found in the
CAN HLP module in the Ultrascale (as well as githash registers).

Should be integrated into the larger framework at some point."""

import can
import binascii
from enum import IntEnum

class UsRegisters(IntEnum):
    GITHASH_LSB            = 0x0100
    GITHASH_MSB            = 0x0101
    DATE_LSB               = 0x0102
    DATE_CSB               = 0x0103
    DATE_MSB               = 0x0104
    CAN_RX_MSG_COUNT       = 0x0900
    CAN_TX_MSG_COUNT       = 0x0901
    CAN_READ_COUNT         = 0x0902
    CAN_WRITE_COUNT        = 0x0903
    CAN_STATUS_ALERT_COUNT = 0x0904
    CAN_UNKNOWN_COUNT      = 0x0905
    CAN_TEST               = 0x0906
    CAN_CLK_PRESCALE       = 0x0907

class CanHlpCmd(IntEnum):
    DATA = 1
    WRITE_CMD = 2
    WRITE_RESP = 3
    READ_CMD = 4
    READ_RESP = 5
    STATUS_ALERT = 7

class CanHlpTimeout(Exception):
    pass

class CanHlpWrongId(Exception):
    pass

class CanHlpWrongReponse(Exception):
    pass

class CanHlp(object):
    """CANbus High Level Protocol

    Args:
        can_if (str): Name of SocketCAN interface to use, e.g. can0.
    """

    channel = ''
    bus_type = 'socketcan'

    C_DATA = 1
    C_WRITE_CMD = 2
    C_WRITE_RESP = 3
    C_READ_CMD = 4
    C_READ_RESP = 5
    C_STATUS_ALERT = 7

    C_BROADCAST_ID = 0x7F

    bus = None


    def __init__(self, can_if):
        channel = can_if
        self.bus = can.interface.Bus(channel=channel, bustype=self.bus_type)

    def readHLP(self, dev_id, addr, timeout_ms=1000):
        """Read from wishbone address from Readout Unit using CAN bus HLP.

        A HLP read request is sent to the RU using CAN bus, where the 11-bit
        CAN bus ID contains the RU node ID (dev_id) and read request command ID.
            Arbitration ID(10:3) : dev_id
            Arbitration ID(2:0)  : CMD ID

        If dev_id = 0x7F (broadcast ID), any RU that hears the request will respond.

        Todo:
            Currently only one 16-bit value is returned, even for broadcast (last RU to respond).
            This could be changed to a list of values to support broadcast properly.

        Args:
            dev_id (uint): 8-bit Node ID of Readout Unit to access. ID 0x7F is reserved for broadcast
            addr (uint): 15-bit Wishbone address of register to read
            timeout_ms (uint): Timeout in milliseconds

        Raises:
            CanHlpTimeout: If no reply was received before timeout
            CanHlpWrongId: If a reply was received with the wrong ID (and dev_id was not 0x7F broadcast)
            CanHlpWrongReponse: If something else than a read response was received for this request

        Return:
            16-bit register data
        """
        can_arb_id = dev_id << 3
        can_arb_id = can_arb_id | CanHlpCmd.READ_CMD

        data_out = bytearray([(addr >> 8) & 0xFF, addr & 0xFF])
        msg_out = can.Message(extended_id=False, arbitration_id=can_arb_id,
                              data=data_out)
        self.bus.send(msg_out)

        if dev_id != self.C_BROADCAST_ID:
            msg_in = self.bus.recv(timeout_ms/1000.0)  # Timeout in seconds.

            if msg_in is None:
                raise CanHlpTimeout("CAN HLP read timed out")

            # Mask out 3 LSBs, those are the cmd bits in arbitration id
            cmd = msg_in.arbitration_id & 0x0007

            if cmd != CanHlpCmd.READ_RESP:
                raise CanHlpWrongReponse('Expected read response, got {:02x}'.format(cmd))

            dev_id_in = msg_in.arbitration_id >> 3
            if dev_id_in != dev_id and dev_id != self.C_BROADCAST_ID:
                raise CanHlpWrongId("Wrong ID received for read response, got {:02x}".format(cmd))

            data_recvd = (msg_in.data[2] << 8) | msg_in.data[3]
        else:
            done = False
            while done == False:
                msg_in = self.bus.recv(timeout_ms/1000.0)

                if msg_in == None:
                    done = True
                    continue

                # Mask out 3 LSBs, those are the cmd bits in arbitration id
                cmd = msg_in.arbitration_id & 0x0007

                if cmd != CanHlpCmd.READ_RESP:
                    raise CanHlpWrongReponse('Expected read response, got {:02x}'.format(cmd))

                data_recvd = (msg_in.data[2] << 8) | msg_in.data[3]

                dev_id_in = msg_in.arbitration_id >> 3
                if dev_id_in != dev_id and dev_id != self.C_BROADCAST_ID:
                    raise CanHlpWrongId("Wrong ID received for read response, got {:02x}".format(cmd))

                if dev_id_in == self.C_BROADCAST_ID:
                    raise CanHlpWrongId("Sent broadcast read, got read response with broadcast ID")
                else:
                    print("Got read response from {:02x}, data {:04x}".format(dev_id_in, data_recvd))

        return data_recvd

    def writeHLP(self, dev_id, addr, data, timeout_ms=1000):
        """Write to wishbone address from Readout Unit using CAN bus HLP.

        A HLP write request is sent to the RU using CAN bus, where the 11-bit
        CAN bus ID contains the RU node ID (dev_id) and read request command ID.
            Arbitration ID(10:3) : dev_id
            Arbitration ID(2:0)  : CMD ID

        If dev_id = 0x7F (broadcast ID), the value will be written to the register in
        any RU that hears the request, and each RU will respond with a write response.

        Todo:
            Return a list or something of IDs that responded

        Args:
            dev_id (uint): 8-bit Node ID of Readout Unit to access. ID 0x7F is reserved for broadcast
            addr (uint): 15-bit Wishbone address of register to read
            data (uint): 16-bit data to write
            timeout_ms (uint): Timeout in milliseconds

        Raises:
            CanHlpTimeout: If no reply was received before timeout
            CanHlpWrongId: If a reply was received with the wrong ID (and dev_id was not 0x7F broadcast)
            CanHlpWrongReponse: If something else than a write response was received for this request

        Return:
            None
        """
        can_arb_id = dev_id << 3
        can_arb_id = can_arb_id | CanHlpCmd.WRITE_CMD
        data_out = bytearray([(addr >> 8) & 0xFF, addr & 0xFF])
        data_out.append((data >> 8) & 0xFF)
        data_out.append(data & 0xFF)

        msg_out = can.Message(extended_id=False, arbitration_id=can_arb_id,
                              data=data_out)

        if dev_id != self.C_BROADCAST_ID:
            self.bus.send(msg_out)
            msg_in = self.bus.recv(timeout_ms/1000.0)  # Timeout in seconds.

            if msg_in is None:
                raise CanHlpTimeout("CAN HLP write timed out")

            # Mask out 3 LSBs, those are the cmd bits in arbitration id
            cmd = msg_in.arbitration_id & 0x0007

            if cmd != CanHlpCmd.WRITE_RESP:
                raise CanHlpWrongReponse('Expected write response, got {:02x}'.format(cmd))

            dev_id_in = msg_in.arbitration_id >> 3
            if dev_id_in != dev_id and dev_id != self.C_BROADCAST_ID:
                raise CanHlpWrongId("Wrong ID received for write response, got {:02x}".format(cmd))
        else:
            done = False
            while done == False:
                msg_in = self.bus.recv(timeout_ms/1000.0)

                if msg_in == None:
                    done = True
                    continue

                # Mask out 3 LSBs, those are the cmd bits in arbitration id
                cmd = msg_in.arbitration_id & 0x0007

                if cmd != CanHlpCmd.WRITE_RESP:
                    raise CanHlpWrongReponse('Expected write response, got {:02x}'.format(cmd))

                dev_id_in = msg_in.arbitration_id >> 3
                if dev_id_in == self.C_BROADCAST_ID:
                    raise CanHlpWrongId("Sent broadcast write, got write response with broadcast ID")
                else:
                    print("Got write response from {:02x}".format(dev_id_in))
