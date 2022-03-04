"""Communication classes, used to communicate with a board, using the
FX3 chip and usb_if firmware.

The provided communication classes are either direct via libusb, over
the usb_comm server, or via simulation. They all share the common base
class Communication

"""




import binascii
import logging
import os
import select
import signal
import socket
import subprocess
import sys
import time
import traceback
import usb

from collections import defaultdict
from queue import Queue, Empty  # python 3.x
from struct import unpack
from threading import Thread, Lock, Event

class WishboneReadError(Exception):
    """basic class to define a wishbone read error exception"""

    def __init__(self, value="", data=0, address=0, rderr_flag=0):
        super(WishboneReadError, self).__init__()
        self.value = value.format(data, address, rderr_flag)
        self.data = data
        self.address = address
        self.rderr_flag = rderr_flag

    def __str__(self):
        return repr(self.value)

    def __data__(self):
        return repr(self.data)

    def __address__(self):
        return repr(self.address)

    def __rderr_flag__(self):
        return repr(self.rderr_flag)

    def print_info(self):
        """returns the args of the exception"""
        print("rderr_flag: {0}".format(self.rderr_flag))
        print("data: {0}".format(self.data))
        print("address: {0}".format(self.address))

class AddressMismatchError(Exception):
    """basic class to define an error mismatch between the address requested by
    the read command and the one received in the packafe read from the board"""
    def __init__(self, value="", requested_address=0, rd_address=0, rderr_flag=0):
        super(AddressMismatchError, self).__init__()
        self.value = value.format(requested_address, rd_address, rderr_flag)
        self.requested_address = requested_address
        self.rd_address = rd_address
        self.rderr_flag = rderr_flag

    def __str__(self):
        return repr(self.value)

    def __requested_address__(self):
        return repr(self.requested_address)

    def __rd_address__(self):
        return repr(self.rd_address)

    def __rderr_flag__(self):
        return repr(self.rderr_flag)


class NetUsbTimeoutException(Exception):
    """basic class to handle netusbcomm timeout exception"""
    def __init__(self, signum=0):
        super(NetUsbTimeoutException, self).__init__()
        self.signum = signum

    def __signum__(self):
        return repr(self.signum)

def sig_alarm_handler(signum, frame):
    #print('received signal %s'%signum)
    raise NetUsbTimeoutException(signum)

def _get_wb_reads(data):
    """ Returns a byte array to a tuple list [(addr,data)] """
    assert len(data) % 4 == 0
    vals = unpack('HH' * int(len(data) / 4), data)
    addr = vals[1::2]
    dats = vals[0::2]
    return list(zip(addr, dats))


def _as_int_array(data):
    """Return data byte stream as list of unsigned integers"""
    assert len(data) % 4 == 0
    return unpack('I' * int(len(data) / 4), data)


class Communication(object):
    """Basic Communication class between Host and Device.

    This abstract class provides the basic communication blocks used
    to write and read data between chip and host.

    Access to Wishbone is possible via single_write() or single_read()
    To send a batch of commands, the functions register_write(),
    register_read(), flush() and read_results() are used. In both
    cases, results are written as a 2-tuple in the form (addr,data).


    Access to data ports is given via read_DP2() and read_DP3(). The
    result is given as array of 4 byte ints.

    This is an abstract class, and is NOT intended to be used
    directly. Instead, use the actual implementations PyUsbComm,
    NetUsbComm, UsbCommSim or Wb2GbtxComm.

    """

    def __init__(self, enable_rderr_exception=False):
        self._buffer = bytearray()
        self._read_bytes = 0
        self._enable_rderr_exception = enable_rderr_exception
        self.logger = logging.getLogger("Communication")
        self.log = True
        self.max_retries = 10

    def enable_log(self):
        """enables the exception throw when receiving a wishbone read error flag"""
        self.log = True

    def disable_log(self):
        """disables the exception throw when receiving a wishbone read error flag"""
        self.log = False

    def enable_rderr_exception(self):
        """enables the exception throw when receiving a wishbone read error flag"""
        self._enable_rderr_exception = True

    def disable_rderr_exception(self):
        """disables the exception throw when receiving a wishbone read error flag"""
        self._enable_rderr_exception = False

    def stop(self):
        """Perform any operation on close"""
        pass

    def single_write(self, module, address, data):
        """A Single write operation.

        Perform a single write operation to a given module and
        address. This sends the command directly to the
        device. Previously registered commands are not sent.

        """
        tmp_buffer = self._buffer
        self._buffer = bytearray()
        self.register_write(module, address, data)
        self.flush()
        self._buffer = tmp_buffer

    def single_read(self, module, address, log=None):
        """A Single read operation.

        Perform a single read operation to a given module and
        address. This sends the command directly to the device and
        reads back the result. Previously registered commands are not
        sent.

        """
        if log is None:
            log = self.log

        tmp_buffer = self._buffer
        tmp_read_bytes = self._read_bytes
        self._buffer = bytearray()
        self._read_bytes = 0
        self.register_read(module, address)
        self.flush()

        val = _get_wb_reads(self._read_all_bytes())

        self._buffer = tmp_buffer
        self._read_bytes = tmp_read_bytes

        rd_data = val[0][1]
        complete_read_address = val[0][0] & 0x7FFF
        rderr_flag = (val[0][0] >> 15) & 1
        # rderr_flag validation
        if rderr_flag:
            message = ("The WbMstr reported a read error! data {0:04X}, "
                       "address {1:04X}, rderr_flag {2}")
            if log:
                logmessage = message.format(
                    rd_data, complete_read_address, rderr_flag)
                self.logger.warning(logmessage)
            if self._enable_rderr_exception:
                raise WishboneReadError(
                    message, rd_data, complete_read_address, rderr_flag)
            else:
                self.logger.error("communication.communication.read_reg >> returned read error from usb_if."
                      "raw data \t rderr_flag {0}, \t address {1:04X},"
                      " \t data {2:04X}".format(rderr_flag, complete_read_address, rd_data))

        complete_address = module << 8 | address
        if complete_address != complete_read_address:
            message = ("The address read is different than the one requested! complete_address {0:04X},"
                       "complete_read_address {1:04X}, rderr_flag {2}")
            if log:
                logmessage = message.format(
                    complete_address, complete_read_address, rderr_flag)
                self.logger.warning(logmessage)
            raise AddressMismatchError(
                message, complete_address, complete_read_address, rderr_flag)

        if len(val) > 0:
            return val[0][1]
        else:
            return None

    def write_reg(self, module, address, data):
        """DEPRECATED! used for Probecard while waiting to modify local implementation"""
        raise DeprecationWarning("This function is deprecated, please use self.single write instead")
        self.single_write(module, address, data)

    def read_reg(self, module, address):
        """DEPRECATED! used for Probecard while waiting to modify local implementation"""
        raise DeprecationWarning("This function is deprecated, please use self.single read instead")
        return self.single_read(module, address)

    def register_write(self, module, address, data):
        """ Register a write register command in the buffer """
        assert module | 0x7F == 0x7F
        assert address | 0xFF == 0xFF
        data_low = data >> 0 & 0xFF
        data_high = data >> 8 & 0xFF

        self._buffer += bytearray([data_low, data_high,
                                   address, module | 0x80])

    def register_read(self, module, address):
        """ Register a read register command in the buffer """
        assert module | 0x7F == 0x7F
        assert address | 0xFF == 0xFF

        self._buffer += bytearray([0x00, 0x00, address, module])
        self._read_bytes += 4

    def flush(self):
        """Flush the buffer.

        This function sends all previously registered commands to the
        device.

        """
        self._do_write_dp0(self._buffer)
        self._buffer = bytearray()

    def _read_all_bytes(self,log=None):
        """Try to read all bytes of self._read_bytes"""
        if log == None:
            log = self.log

        retries = 0
        ret = bytearray()
        remaining = self._read_bytes
        while len(ret) < self._read_bytes and retries < self.max_retries:
            ret += self._do_read_dp1(remaining)
            remaining = self._read_bytes - len(ret)
            if len(ret) != self._read_bytes:
                if log:
                    msg = "Result size mismatch. Expected %d bytes, read %d bytes. retry"
                    if retries > self.max_retries / 2:
                        self.logger.warning(msg, self._read_bytes,len(ret))
                    else:
                        self.logger.debug(msg, self._read_bytes,len(ret))

            retries += 1
        if log and len(ret) < self._read_bytes:
            self.logger.warning("Result size mismatch. Expected %d bytes, read %d bytes. Max number of retries reached",
                                self._read_bytes,len(ret))
        self._read_bytes = 0
        return ret

    def _check_result(self,val,log=None):
        """Check result of a _get_wb_reads list"""
        rd_data = val[1]
        complete_read_address = val[0] & 0x7FFF
        rderr_flag = (val[0] >> 15) & 1
        # rderr_flag validation
        if rderr_flag:
            message = ("The WbMstr reported a read error! data {0:04X}, "
                       "address {1:04X}, rderr_flag {2}")
            if log:
                logmessage = message.format(
                    rd_data, complete_read_address, rderr_flag)
                self.logger.warning(logmessage)
            if self._enable_rderr_exception:
                raise WishboneReadError(
                    message, rd_data, complete_read_address, rderr_flag)
            else:
                self.logger.error("communication.communication.read_reg >> returned read error from usb_if."
                      "raw data \t rderr_flag {0}, \t address {1:04X},"
                      " \t data {2:04X}".format(rderr_flag, complete_read_address, rd_data))

    def read_results(self, log=None):
        """Read results from communication.

        This function reads the results from a previously flushed
        communication. The function expects 1 result per read command
        registered.

        Returns a List of data tuples in the form
        [(addr0,data0),(addr1,data1),...,(addrN,dataN)]

        """
        if log == None:
            log = self.log

        ret = self._read_all_bytes(log)
        results = _get_wb_reads(ret)

        for val in results:
            self._check_result(val,log)

        return results

    def diagnose_read_results(self, log=None):
        """Read results for debugging and diagnose.

        This function reads results from a previously flushed communication.
        In comparison to read_results, this function does not check the results for read errors,
        but returns rderrorflag as part of the tuple.
        The return value is [(rderr0,addr0,data0),...,(rderrN,addrN,dataN)]
        """
        if log == None:
            log = self.log

        ret = self._read_all_bytes(log)
        results = _get_wb_reads(ret)

        results_diag = []
        for val in results:
            rd_data = val[1]
            rd_address = val[0] & 0x7FFF
            rderr_flag = (val[0] >> 15) & 1
            results_diag.append( (rderr_flag,rd_address,rd_data) )

        return results_diag


    def _discardall(self,read_dp_func,maxReads=10):
        reads = 0
        nrbytes = len(read_dp_func(10240))
        total_bytes = nrbytes
        while reads < maxReads and nrbytes > 0:
            nrbytes = len(read_dp_func(102400))
            total_bytes += nrbytes
            reads += 1
        if total_bytes > 0:
            self.logger.info("Discarded %d bytes for dp_function %r", total_bytes, read_dp_func.__name__)
        return nrbytes == 0

    def discardall_dp1(self,maxReads=10):
        return self._discardall(self._do_read_dp1,maxReads)
    def discardall_dp2(self,maxReads=10):
        return self._discardall(self._do_read_dp2,maxReads)
    def discardall_dp3(self,maxReads=10):
        return self._discardall(self._do_read_dp3,maxReads)

    def read_dp2(self, size):
        """ Reads <size> bytes of data from DP2.
        Returns a list of integers.
        """
        return _as_int_array(self._do_read_dp2(size))

    def read_dp3(self, size):
        """ Reads <size> bytes of data from DP3.
        Returns a list of integers.
        """
        return _as_int_array(self._do_read_dp3(size))

    def _do_write_dp0(self, data):
        """Implementation of writing to DP0"""
        raise NotImplementedError

    def _do_read_dp1(self, size):
        """Implementation of reading from DP1"""
        raise NotImplementedError

    def _do_read_dp2(self, size):
        """Implementation of reading from DP2"""
        raise NotImplementedError

    def _do_read_dp3(self, size):
        """Implementation of reading from DP3"""
        raise NotImplementedError

class PrefetchCommunication(Communication):
    """Prefetch Communication controller.

    Optimized communication control which provides functions to
    record a set of wishbone transactions, and later prefetch the same
    set of wishbone transactions in a single usb packet.
    """
    def __init__(self, comm,enable_rderr_exception=False):
        """Initialize with given comm object as actual communication controller"""
        super(PrefetchCommunication, self).__init__(enable_rderr_exception)
        self.comm = comm
        self.logger = logging.getLogger("PrefetchCommunication")
        self.recording = True
        self.prefetch_mode = False
        self.sequence = bytearray()
        # prefetched commands in form {Addr: [1,0,0,1]} where 1=Write, 0=Read
        self.prefetched_commands = defaultdict(list)
        # prefetched results in form {Addr: [d0,d1,d2,...]}
        self.prefetched_results = defaultdict(list)
        self.prefetch_read_buffer = bytearray()

    def stop(self):
        self.comm.stop()

    def discardall_dp1(self,maxReads=10):
        return self.comm.discardall_dp1(maxReads)

    def discardall_dp2(self,maxReads=10):
        return self.comm.discardall_dp2(maxReads)

    def discardall_dp3(self,maxReads=10):
        return self.comm.discardall_dp3(maxReads)

    def start_recording(self):
        """Start recording wishbone access commands"""
        self.recording = True
        self.sequence = bytearray()

    def stop_recording(self):
        """Finish recording wishbone access commands. Return the sequence of commands generated so far"""
        self.recording = False
        return self.sequence

    def prefetch(self):
        """Prefetch mode. Load sequence of commands, send to usb, store results"""
        # Check that prefetched values are empty
        self._prefetch_empty_buffer(True)
        nrReads = 0
        for i in range(0,len(self.sequence),4):
            write_cmd = (self.sequence[i+3]>>7)&1
            if not write_cmd:
                nrReads += 1
            address = ((self.sequence[i+3]&0x7F) << 8) | self.sequence[i+2]
            self.prefetched_commands[address].append(write_cmd)
        # prefetch send command
        self.comm._do_write_dp0(self.sequence)
        # prefetch receive results
        results = self.comm._do_read_dp1(nrReads*4)
        for i in range(0,len(results),4):
            addr = results[i+2] | ((results[i+3] &0x7F)<<8)
            self.prefetched_results[addr].append(results[i:i+4])

        self.prefetch_mode = True

    def load_sequence(self,sequence):
        """Load given sequence of commands to communication (no call to usb yet)"""
        self.sequence = sequence
        self.recording = False

    def stop_prefetch_mode(self, checkEmpty=True):
        self.prefetch_mode = False
        self._prefetch_empty_buffer(checkEmpty)

    def get_sequence(self):
        """Return the current sequence of commands"""
        return self.sequence

    def _prefetch_empty_buffer(self,checkEmpty=True):
        if checkEmpty:
            for addr,cmds in self.prefetched_commands.items():
                if len(cmds) > 0:
                    self.logger.warning("Prefetch_empty_buffer: Address %04X}: There are %d unsent commands",addr,len(cmds))
            for addr,dat in self.prefetched_results.items():
                if len(dat) > 0:
                    self.logger.warning("Prefetch_empty_buffer: Address %04X: There are %d unread results",addr,len(dat))

        self.prefetched_commands = defaultdict(list)
        self.prefetched_results = defaultdict(list)
        self.prefetched_read_buffer = bytearray()

    def _prefetch_handle_error(self):
        self._prefetch_empty_buffer(False)
        self.logger.debug("Prefetch mode failed, back to normal mode. Sequence: %r",self.sequence)
        self.prefetch_mode = False

    def _prefetch_write_dp0(self,data):
        for i in range(0,len(data),4):
            write_cmd = data[i+3]>>7 &1
            address = ((data[i+3]&0x7F) << 8) | data[i+2]
            if self.prefetched_commands[address]:
                rw = self.prefetched_commands[address].pop(0)
                if rw != write_cmd:
                    self.logger.error("Prefetch: Next command is Write=%d, while Write=%d was expected . Command: 0x%s",
                                      rw,write_cmd, ["{0:02X}".format(x) for x in data[i:i+4][::-1]])
                    self._prefetch_handle_error()
                if not write_cmd:
                    if self.prefetched_results[address]:
                        self.prefetched_read_buffer += self.prefetched_results[address].pop(0)
                    else:
                        self.logger.error("Prefetch: wishbone read command has no corresponding readback value Address: %04X . Command: 0x%s",
                                          address, ["{0:02X}".format(x) for x in data[i:i+4][::-1]])
                        self._prefetch_handle_error()


            else:
                self.logger.error("Prefetch: wishbone command not registered in prefetch. Command: 0x%s",
                                  ["{0:02X}".format(x) for x in data[i:i+4][::-1]])
                self._prefetch_handle_error()


    def _prefetch_read_dp1(self,size):
        if len(self.prefetched_read_buffer) != size:
            self.logger.error("Prefetch: Read results has unexpected length: Requested: %d, In Buffer: %d",
                              size,len(self.prefetched_read_buffer))
            self._prefetch_handle_error()

        result = self.prefetched_read_buffer
        self.prefetched_read_buffer = bytearray()
        return result


    def _do_write_dp0(self, data):
        if self.prefetch_mode:
            self._prefetch_write_dp0(data)
        # in case prefetch fails, it turns off prefetch_mode: write normally to wishbone
        if not self.prefetch_mode:
            # forward to comm
            if self.recording:
                self.sequence += data
            self.comm._do_write_dp0(data)

    def _do_read_dp1(self, size):
        if self.prefetch_mode:
            return self._prefetch_read_dp1(size)
        else:
            return self.comm._do_read_dp1(size)

    def _do_read_dp2(self, size):
        return self.comm._do_read_dp2(size)

    def _do_read_dp3(self, size):
        return self.comm._do_read_dp3(size)

    def send_trigger(self, triggerType=0x10, bc=0xabc, orbit=0x43215678):
        self.comm.send_trigger(triggerType, bc, orbit)

    def send_idle(self, numToSend=1):
        self.comm.send_idle(numToSend)



def _cmp_serial(device, serialNr):
    """Compare the serial number of a device with the given serial number"""
    serial_str = usb.util.get_string(device, device.iSerialNumber)
    return serial_str[:-1] == serialNr


class PyUsbComm(Communication):
    """Implementation of Communication class.

    This implements the communication class by establishing a direct
    Connection to the usb port via PyUsb.

    """
    _TIMEOUT_ERRNO = 110

    def __init__(self,
                 VID=0x04b4,
                 PID=0x0008,
                 IF=2,
                 PacketSize=1024,
                 serialNr=None,
                 enable_rderr_exception=False):

        super(PyUsbComm, self).__init__()
        if serialNr is not None:
            self.dev = usb.core.find(
                idVendor=VID, idProduct=PID, custom_match=lambda d: _cmp_serial(d, serialNr))
        else:
            self.dev = usb.core.find(idVendor=VID, idProduct=PID)

        if self.dev is None:
            raise Exception("no USB device found")

        cfg = self.dev.get_active_configuration()
        itf = cfg[(IF, 0)]
        self.epo = itf[0]  # endpoint towards the FX3 (in)
        self.epi = itf[1]  # endpoint from the FX3 (out) - DP1
        self.dp2 = itf[2]  # endpoint from the FX3 (out) - DP2
        self.dp3 = itf[3]  # endpoint from the FX3 (out) - DP3

        self._PacketSize = PacketSize

    def _do_write_dp0(self, data):
        written = self.epo.write(data)
        assert written == len(data), "Data mismatch: Bytes written: {0}, Data length: {1}".format(written,len(data))

    def _do_read_dp1(self, size):
        return self._read_data(self.epi, size)

    def _do_read_dp2(self, size):
        return self._read_data(self.dp2, size)

    def _do_read_dp3(self, size):
        return self._read_data(self.dp3, size)

    def _read_data(self, endpoint, length):
        """Read at least <length> bytes of data from the Endpoint.

        Tries to read <length> bytes from the endpoint, with a
        granularity of _PacketSize. This is due to the restrictions of
        the libusb implementation, which requires a readout size as
        multiple of the packet size to prevent data loss.

        Returns when at least <length> bytes have been read, or if a
        Timeout occurs.

        """
        remaining = length
        assert length % 4 == 0
        msg = bytearray()
        try:
            while remaining > 0:
                chunk = endpoint.read(self._round_to_packet_size(remaining))
                msg.extend(chunk)
                remaining -= len(chunk)
        except usb.core.USBError as e_usb:
            if e_usb.errno != PyUsbComm._TIMEOUT_ERRNO:
                raise

        return msg

    def _round_to_packet_size(self, num):
        """Round given read size to minimum packet size of usb transaction"""
        return num - num % - self._PacketSize


def enqueue_output(out, queue):
    """Add message to message_queue"""
    for line in iter(out.readline, b''):
        queue.put(line)

ON_POSIX = 'posix' in sys.builtin_module_names


class UsbCommServer:
    """ Run usb_comm Server in subprocess.

    Convenience class to start / stop the usb_comm software from python
    """

    def __init__(self, executable='../usb_comm/build/usb_comm', serial=None):
        self.executable = executable
        self.process = None
        self.message_queue = None
        self.message_thread = None
        self.logger = logging.getLogger("UsbCommServer")
        self.serial=serial

    def start(self):
        """Start the USB Comm Server program"""
        exe_args = [self.executable]
        if self.serial is not None:
            exe_args = [self.executable,
                        "--serial_number",
                        "{0}".format(self.serial)]
        self.process = subprocess.Popen(exe_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE, close_fds=ON_POSIX)
        self.message_queue = Queue()
        self.message_thread = Thread(target=enqueue_output, args=(
            self.process.stdout, self.message_queue))
        self.message_thread.start()

    def stop(self):
        """Send stop signal to USB Comm Server program"""
        self.process.stdin.write(b'quit\n')
        self.process.stdin.flush()

    def is_stopped(self):
        """Check if the server is stopped or still running"""
        stopped = False
        if self.process:
            poll = self.process.poll()
            if poll is not None:
                stopped = True
                if poll < 0:
                    self.logger.warning("UsbCommServer terminated with signal %d",-poll)
        return stopped

    def read_messages(self):
        """Read all messages sent by the usb comm server program."""
        msg = ""
        try:
            while True:
                line = self.message_queue.get_nowait()  # or q.get(timeout=.1)
                msg += line.decode("utf-8")
        except Empty:
            pass  # finished
        return msg

def _create_connection_nonblock(host,port):
    """Create a non-blocking connection via socket"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setblocking(0)
    try:
        sock.connect((host,port))
    except BlockingIOError as be:
        if be.errno == 115:
            pass
        else:
            raise be
    return sock

class NetUsbComm(Communication):
    """Network usb communication class.

    This class implements the Communication class by implementing a
    network communication with the UsbComm C++ program.

    """

    def __init__(self,
                 ctlOnly=False,
                 HOSTNAME='127.0.0.1', #'localhost'
                 PORT_CONTROL=30000,
                 PORT_DATA0=30001,
                 PORT_DATA1=30002,
                 Timeout=None,
                 enable_rderr_exception=False):
        super(NetUsbComm, self).__init__()

        self.socketControl = None
        self.socketData0 = None
        self.socketData1 = None

        self.timeout = Timeout
        self.hostname = HOSTNAME
        self.port_control = PORT_CONTROL
        self.port_data0 = PORT_DATA0
        self.port_data1 = PORT_DATA1

        self.ctlOnly = ctlOnly
        self.open_connection(ctlOnly)

        self.write_retries = 10
        self.server = None

        signal.signal(signal.SIGALRM, sig_alarm_handler)

    def stop(self):
        self.close_connections()

    def _read_data(self, sock, length):
        """read data from socket"""
        remaining = length
        assert length % 4 == 0
        msg = b""
        try:
            while remaining > 0:
                signal.alarm(int(10*self.timeout))
                chunk = sock.recv(remaining)
                msg += chunk
                remaining -= len(chunk)
        except NetUsbTimeoutException as e:
            #self.logger.warning(traceback.format_exc())
            pass
        except socket.timeout:
            #self.logger.warning(traceback.format_exc())
            pass
        except BlockingIOError as be:
            #self.logger.warning(traceback.format_exc())
            pass
        finally:
            signal.alarm(0)
        return msg

    def set_server(self, server):
        self.server = server

    def open_connection(self,ctlOnly=False):
        self.ctlOnly = ctlOnly
        signal.alarm(int(10*self.timeout))
        try:

            self.socketControl = socket.create_connection(
                (self.hostname, self.port_control), self.timeout)
    #        self.socketControl = _create_connection_nonblock(self.hostname,self.port_control)
            if ctlOnly:
                self.socketData0 = None
                self.socketData1 = None
            else:
               self.socketData0 = socket.create_connection(
                    (self.hostname, self.port_data0), self.timeout)
               self.socketData1 = socket.create_connection(
                    (self.hostname, self.port_data1), self.timeout)
               #self.socketData0 =_create_connection_nonblock(self.hostname,self.port_data0)
               #self.socketData1 =_create_connection_nonblock(self.hostname,self.port_data1)
            time.sleep(0.1)
        except:
            raise
        finally:
            signal.alarm(0)

    def _reconnect_attempt(self):
        """Try to reconnect to server"""

        #check if server is running
        if self.server and self.server.is_stopped():
            self.server.start()
#        else:
#            try:
#                self.server.stop()
#            except Exception as e:
#                self.logger.exception("Error while reconnect: shutdown server")
#            time.sleep(0.5)
#            self.server.start()

        time.sleep(0.5)
        self.logger.info("Attempt to reconnect to server")
        self.close_connections()
        time.sleep(0.5)
        self.open_connection(ctlOnly = self.ctlOnly)
        time.sleep(0.5)


    def close_connections(self):
        """Close all open sockets"""
        for sock in (self.socketControl,
                     self.socketData0,
                     self.socketData1):
            try:
                if sock is not None:
                    sock.shutdown(socket.SHUT_RDWR)
                    sock.close()
            except:
                self.logger.exception("Error while shutting down socket {0}".format(sock))
        self.socketControl = None
        self.socketData0 = None
        self.socketData1 = None


    def _do_write_dp0(self, data):
        try:
            signal.alarm(15)
            self.socketControl.sendall(data)
            signal.alarm(0)
        except NetUsbTimeoutException as e:
            self.logger.exception("error while sendall(data), timeout run with %s",e)
            self.logger.error("Data may have been lost due to %s",e)
            self._reconnect_attempt()
        except:
            self.logger.exception("error while sendall(data)")
            self._reconnect_attempt()

    def _do_read_dp1(self, size):
        return self._read_data(self.socketControl, size)

    def _do_read_dp2(self, size):
        if self.socketData0 is None:
            raise Exception(
                "Communication module was started with Control only")
        return self._read_data(self.socketData0, size)

    def _do_read_dp3(self, size):
        if self.socketData1 is None:
            raise Exception(
                "Communication module was started with Control only")
        return self._read_data(self.socketData1, size)
