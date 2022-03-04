"""Python to Systemverilog Simulation interface"""

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

from queue import Queue, Empty  # python 3.x
from struct import unpack
from threading import Thread, Lock, Event
from xmlrpc.server import SimpleXMLRPCServer
from xmlrpc.client import ServerProxy
import socketserver

from module_includes import *

import trigger
from communication import Communication

COMM_SIM_PORT = 32223
GLOBAL_TIMEOUT = 900

rundir = os.path.dirname(os.path.realpath(__file__)) +'/../../../../sim/run/'

class SimulationServer:
    """RPC server handling communication between Python and Systemverilog"""
    stop_server = False

    def __init__(self):
        self.server = SimpleXMLRPCServer(("localhost", COMM_SIM_PORT), logRequests=False)
        self.thrd = Thread(target=self.run)
        self.server.register_function(self.send_close,"send_close")

    def run(self):
        while not self.stop_server:
            self.server.handle_request()

    def send_close(self):
        print("Send Close")
        return True

    def stop(self):
        print("Stop")
        self.stop_server = True
        ServerProxy("http://localhost:{0}".format(COMM_SIM_PORT)).send_close()

    def start(self):
        """Start RPC server"""
        self.thrd.start()

class UsbCommSim(Communication):
    """Usb Communication wrapper connecting to simulation.

    This wrapper writes read/write actions to a set of fifos, which
    will be checked by a simulation testbench and then forwarded to
    the simulation environment

    """

    def __init__(self, server):
        super(UsbCommSim, self).__init__()
        self.max_retries = 1

        self.dp0_queue = Queue()

        self.mutex = Lock()

        self.files = [None, None, None, None]
        self.open()

        self.server = server
        self.server.register_function(self.flush_dp0, "flush_dp0")
        self.server.register_function(self.clear, "clear")

    def open(self):
        """(re)open buffer files for data exchanges"""

        files_names = [
            (rundir + 'fifo_dp0.fifo', 'w'),
            (rundir + 'fifo_dp1.fifo', 'r'),
            (rundir + 'fifo_dp2.fifo', 'r'),
            (rundir + 'fifo_dp3.fifo', 'r')
        ]

        self.files = []
        for name, openmode in files_names:
            if not os.path.exists(name):
                open(name, 'w').close()
            fifo = open(name, openmode)
            fifo.seek(0, os.SEEK_END)
            self.files.append(fifo)

    def close(self):
        self.files[0].write("EXIT\n")
        self.files[0].flush()

    def flush_dp0(self):
        """Flush DP0: send data to fifo"""
        #print(">> communication >> usbcommsim >> flush_dp0 >> called!")
        msg = ""
        try:
            while True:
                line = self.dp0_queue.get_nowait()  # or q.get(timeout=.1)
                msg += line
        except Empty:
            pass  # finished
        if len(msg) == 0:
            msg = "NOP"
        self.files[0].write(msg + "\n")
        self.files[0].flush()
        return 0

    def clear(self):
        """Clear buffers: Close and reopen files"""
        #print(">> communication >> usbcommsim >> clear >> called!")
        self.mutex.acquire()
        try:
            self.files[0].close()
            self.files[1].close()
            self.files[2].close()
            self.files[3].close()
            self.open()
        finally:
            self.mutex.release()
        return 0

    def _do_write_dp0(self, data):
        string = ''.join('{:02x}'.format(x) for x in data)
        self.dp0_queue.put(string)

    def _do_read_dp1(self, size):
        return self._read_data_sim(1, size,10)

    def _do_read_dp2(self, size):
        print("read dp2")
        return self._read_data_sim(2, size,10)

    def _do_read_dp3(self, size):
        return self._read_data_sim(3, size,10)

    def _read_data_sim(self, fifo, length,max_count = 10):
        """Read data from fifo file"""

        cnt = 0
        remaining = length
        assert length % 4 == 0
        msg = b""
        last_read = False
        seconds = 0
        while (remaining > 0) and (seconds < GLOBAL_TIMEOUT):
            try:

                try:
                    self.mutex.acquire()
                    string = self.files[fifo].readline().strip()
                finally:
                    self.mutex.release()

                hex_data = binascii.unhexlify(string)
                chunk = bytearray(hex_data)
                msg += chunk
                remaining -= len(chunk)
                if remaining > 0:
                    if cnt >= max_count:
                        #print("Read {0}, remaining: {1}".format(len(msg),remaining))
                        if last_read:
                            break
                    if len(chunk) == 0:
                        #print(">> communication >> usbcommsim >> _read_data_sim >> ALIVE!, remaining: {0}".format(remaining))
                        time.sleep(1)
                        seconds += 1
                        cnt += 1
                    else:
                        cnt = 0 # Reset retry-counter
            except KeyboardInterrupt as kie:
                x = input("Interrupted for reading. y for continue, n for stop")
                last_read = x != 'y'
        if seconds == GLOBAL_TIMEOUT:
            print("\nGBT read timeout, simulation stuck, exiting")
            raise KeyboardInterrupt
        return msg

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]

class GbtxSim(object):
    """Gbt Communication wrapper connecting to simulation.

    This wrapper writes read/write actions to a set of fifos, which
    will be checked by a simulation testbench and then forwarded to
    the simulation environment
    """

    SWT_CODE = 0x3
    SOP_CODE = 0x1
    EOP_CODE = 0x2

    def __init__(self, server):
        super(GbtxSim, self).__init__()
        self.gbtx0_queue = Queue()

        self.mutex = Lock()

        self.files = [None, None]
        self.open()

        self.server = server
        self.server.register_function(self.flush_gbtx, "flush_gbtx")
        self.server.register_function(self.clear, "clear_gbtx")

        self.logger = logging.getLogger("GbtxSim")

        self.swt_queue = Queue()
        self.data_queue = Queue()

    def open(self):
        """(re)open buffer files for data exchanges"""

        files_names = [
            (rundir + 'fifo_gbtx0_fp', 'w'),
            (rundir + 'fifo_gbtx0_tp', 'r')
        ]

        self.files = []
        for name, openmode in files_names:
            if not os.path.exists(name):
                open(name, 'w').close()
            fifo = open(name, openmode)
            fifo.seek(0, os.SEEK_END)
            self.files.append(fifo)

    def close(self):
        self.files[0].write("EXIT\n")
        self.files[0].flush()

    def flush_gbtx(self):
        """Flush gbtx: send data to fifo"""
        msg = ""
        try:
            while True:
                line = self.gbtx0_queue.get_nowait()  # or q.get(timeout=.1)
                msg += line
        except Empty:
            pass  # finished
        if len(msg) == 0:
            msg = "NOP" + "\n"
        self.files[0].write(msg)
        self.files[0].flush()
        return 0

    def clear(self):
        """Clear buffers: Close and reopen files"""
        #print(">> communication >> usbcommsim >> clear >> called!")
        self.mutex.acquire()
        try:
            self.files[0].close()
            self.files[1].close()
            self.open()
        finally:
            self.mutex.release()
        return 0

    def writeToGbt(self,data):
        """Write to GBT port. Expects tuple (valid,data). Data is 10 byte bytearray"""
        valid,word = data
        assert len(word) == 10, "Data is not 80bit"

        string = ''.join('{:02x}'.format(x) for x in word)
        self.gbtx0_queue.put("{0:d} {1}\n".format(valid,string))

    def readFromGbt(self):
        """Read all data from gbt port"""
        try:
            self.mutex.acquire()
            lines_str = self.files[1].readlines()
            lines = [(line[0],line[1:]) for line in lines_str]
        finally:
            self.mutex.release()

        data = []
        try:
            for line in lines:
                hexdata = binascii.unhexlify(line[1].strip())
                data.append((int(line[0]), hexdata))
        except binascii.Error as e:
            self.logger.exception("readFromGbt failed while decoding")
            self.logger.error("Lines: %r", lines)
            raise e
        return data

    def read_sort_data(self):
        data = self.readFromGbt()
        for v,d in data:
            package_type = d[0] >> 4
            if v or package_type in [self.SOP_CODE, self.EOP_CODE]:
                self.data_queue.put((v,d))
            elif package_type == self.SWT_CODE:
                self.swt_queue.put(d)

    def get_data(self):
        """return a GBT data word (datavalid=1)"""
        if self.data_queue.empty():
            self.read_sort_data()
        try:
            return self.data_queue.get_nowait()
        except Empty:
            return None, None

    def get_swt(self):
        """return a single word transaction"""
        if self.swt_queue.empty():
            self.read_sort_data()
        try:
            return self.swt_queue.get_nowait()
        except Empty:
            return None

class GbtCruGbtxBridge(object):
    """GBT communication bridge between GBTX and GBT_CRU simulations"""
    GBT_CRU_TX = 3
    GBT_CRU_RX = 2
    GBTX_TX = 1
    GBTX_RX = 0

    def __init__(self, server):
        super(GbtCruGbtxBridge, self).__init__()
        self.gbtx0_queue = Queue()

        self.mutex = Lock()

        self.files_names = [
            (rundir + 'fifo_gbtx0_fp', 'w'),
            (rundir + 'fifo_gbtx0_tp', 'r'),
            (rundir + 'fifo_gbt_cru_fp','w'),
            (rundir + 'fifo_gbt_cru_tp','r')
        ]
        self.files = [None, None, None, None]
        self.open()

        self.server = server
        self.server.register_function(self.flush_gbtx, "flush_gbtx")
        self.server.register_function(self.clear_gbtx, "clear_gbtx")
        self.server.register_function(self.flush_gbt_cru,"flush_gbt_cru")
        self.server.register_function(self.clear_gbt_cru, "clear_gbt_cru")

    def open(self, filelist=range(4)):
        """(re)open buffer files for data exchanges"""

        for i in filelist:
            name, openmode = self.files_names[i]
            if not os.path.exists(name):
                open(name, 'w').close()
            fifo = open(name, openmode)
            fifo.seek(0, os.SEEK_END)
            self.files[i] = fifo

    def close(self):
        pass

    def flush_gbt_cru(self):
        """Flush GBT CRU - Copy from GBTX"""
        msg = self.files[self.GBTX_TX].read()
        if len(msg) == 0:
            msg = "NOP" + "\n"
        self.files[self.GBT_CRU_RX].write(msg)
        self.files[self.GBT_CRU_RX].flush()
        return 0

    def flush_gbtx(self):
        """Flush gbtx: Copy from CRU"""
        msg = self.files[self.GBT_CRU_TX].read()
        if len(msg) == 0:
            msg = "NOP" + "\n"
        self.files[self.GBTX_RX].write(msg)
        self.files[self.GBTX_RX].flush()
        return 0

    def clear_gbt_cru(self):
        """Clear buffers: Close and reopen files"""
        #print(">> communication >> usbcommsim >> clear >> called!")
        self.mutex.acquire()
        try:
            self.files[self.GBT_CRU_RX].close()
            self.files[self.GBT_CRU_TX].close()
            self.open([self.GBT_CRU_RX,self.GBT_CRU_TX])
        finally:
            self.mutex.release()
        return 0

    def clear_gbtx(self):
        """Clear buffers: Close and reopen files"""
        #print(">> communication >> usbcommsim >> clear >> called!")
        self.mutex.acquire()
        try:
            self.files[self.GBTX_RX].close()
            self.files[self.GBTX_TX].close()
            self.open([self.GBTX_RX,self.GBTX_TX])
        finally:
            self.mutex.release()
        return 0

class Wb2GbtxComm(Communication):
    """Usb Communication wrapper connecting to GbtxLink of Simulation.

    This wrapper writes read/write actions to a set of fifos, which
    will be checked by a simulation testbench and then forwarded to
    the simulation environment

    """

    def __init__(self, gbtx_sim, create_raw_data_files=True):
        super(Wb2GbtxComm, self).__init__()
        self.gbt_sim = gbtx_sim
        self.dp2_file = None
        if create_raw_data_files:
            self.dp2_file = open('raw_data_dp2.dat', 'wb')
    def __del__(self):
        if self.dp2_file:
            self.dp2_file.close()

    def send_idle(self, numToSend=1):
        gbt_word = bytearray(10)
        for _ in range(numToSend):
            self.gbt_sim.writeToGbt((0, gbt_word))

    def send_trigger(self,triggerType=0x10, bc=0xabc, orbit=0x43215678):
        """Provides trigger to the RUv1

        Inputs:
        trigger type: 12 bit
        bc:           12 bit
        orbit:        32 bit (only 31 used on the RUv0_CRU)

        TODO: update with proper documentation"""
        assert triggerType | 0xFFF == 0xFFF
        assert bc | 0xFFF == 0xFFF
        assert orbit | 0xFFFFFFFF  == 0xFFFFFFFF
        trigger_data = binascii.unhexlify("{0:08x}{1:04x}{2:08x}".format(orbit, bc, triggerType))
        self.gbt_sim.writeToGbt((1,trigger_data))

    def _do_write_dp0(self, data):
        for chunk in chunks(data,4):
            chunk = chunk[::-1] # Reverse on write
            gbt_word = bytearray(10)
            gbt_word[6:10] = chunk
            #gbt_word[2:6] = chunk # uncomment for DWC
            gbt_word[0] = (self.gbt_sim.SWT_CODE << 4)|(gbt_word[0]&0x0F)

            self.gbt_sim.writeToGbt((0,gbt_word))

    def _do_read_dp1(self, size):
        result = bytearray()
        reads_remaining = size/4
        seconds = 0
        while (reads_remaining > 0) and (seconds < GLOBAL_TIMEOUT):
            data = self.gbt_sim.get_swt()
            if data is not None:
                reads_remaining -= 1
                result += data[6:10][::-1] # Reverse on read
            else:
                time.sleep(1)
                seconds += 1
        if seconds == GLOBAL_TIMEOUT:
            print("\nGBT read timeout, simulation stuck, exiting")
            raise KeyboardInterrupt
        return result

    def _do_read_dp2(self, size):
        """Implementation of reading from DP2. Read from GBTx datavalid"""
        result = bytearray()
        seconds = 0
        while (len(result) < size) and (seconds < GLOBAL_TIMEOUT):
            gbt_datavalid, gbt_word = self.gbt_sim.get_data()
            if gbt_word is not None:
                # Split packet
                word0 = bytearray(b'\x00\x00') + gbt_word[0:2]
                if gbt_datavalid:
                    word0[0]=0x80
                word1 = gbt_word[2:6]
                word2 = gbt_word[6:10]

                result += word0[::-1]
                result += word1[::-1]
                result += word2[::-1]
            else:
                time.sleep(1)
                seconds += 1
        if self.dp2_file:
            self.dp2_file.write(result)
            self.dp2_file.flush()
        if seconds == GLOBAL_TIMEOUT:
            print("\nGBT read timeout, simulation stuck, exiting")
            raise KeyboardInterrupt
        return result

    def _do_read_dp3(self, size):
        """Implementation of reading from DP3"""
        raise NotImplementedError

    def discardall_dp1(self,maxReads=10):
        return True
    def discardall_dp2(self,maxReads=10):
        return True
    def discardall_dp3(self,maxReads=10):
        return True
