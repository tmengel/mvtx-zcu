#!/usr/bin/env python
import socket
import random
import sys
from struct import unpack

PORT_CONTROL = 30000
PORT_DATA0 = 30001
PORT_DATA1 = 30002
HOSTNAME = 'localhost'

class DAQ:
    def __init__(self, ctlOnly = False):
        self.socketControl = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socketControl.connect((HOSTNAME,PORT_CONTROL))
        if ctlOnly:
            self.socketData0 = None
            self.socketData1 = None
        else:
            self.socketData0 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socketData0.connect((HOSTNAME,PORT_DATA0))
            self.socketData1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socketData1.connect((HOSTNAME,PORT_DATA1))
        
    def __del__(self):
        self.closeConnections()

    def closeConnections(self):
        try:
            for sock in (self.socketControl,self.socketData0,self.socketData1):
                if sock is not None:
                    sock.shutdown(socket.SHUT_RDWR)
                    sock.close()
        except:
            print ("Error while shutting down sockets")
    
        
    def write_reg(self,mod_addr,sub_addr,data):
        assert mod_addr|0x0F==0xF
        assert sub_addr|0xFF==0xFF

        write = bytearray([data>>0&0xFF, data>>8&0xFF, sub_addr, mod_addr|0x80])
        assert self.socketControl.sendall(write) is None

    def read_reg(self,mod_addr,sub_addr):
        assert mod_addr|0x0F==0xF
        assert sub_addr|0xFF==0xFF

        write = bytearray([0x00, 0x00, sub_addr, mod_addr])
        assert self.socketControl.sendall(write) is None
        data = self.socketControl.recv(4)
        ret = bytearray(data)

        #assert len(ret)==4
        #assert ret[3]==0 and ret[2]==0
        return ret[0]|ret[1]<<8

    def read_data(self,socket,length):
        remaining = length
        assert length % 4 == 0
        msg = b""
        while remaining > 0:
            chunk = socket.recv(remaining)
            msg += chunk                
            remaining -= len(chunk)

            
        intarr = unpack('i'*int(length/4),msg)

        return intarr

    def read_data0(self,length):
        return self.read_data(self.socketData0,length)

    def read_data1(self,length):
        return self.read_data(self.socketData1,length)

class DaqTest:

    def __init__(self, ctlOnly = False):
        self.daq = DAQ(ctlOnly)
        
    def write_read(self,mod_addr,sub_addr,data):
        self.daq.write_reg(mod_addr,sub_addr,data)
        ret = self.daq.read_reg(mod_addr,sub_addr);
        assert data == ret;

    def write_read_all(self,data):
        cnt = 0
        for mod in range(0,2):
            for addr in range(0,8):
                self.daq.write_reg(mod,addr,data);
        for mod in range(0,2):
            for addr in range(0,8):
                ret = self.daq.read_reg(mod,addr)
                if ret != data:
                    print("Data write/read mismatch(%x | %x)" % data,ret)
                    cnt = cnt + 1
        return cnt

    def write_read_all_loop(self,count):
        errors = 0
        for i in range(0,count):
            errors += self.write_read_all(i)
    
    def check_data(self,socket,length):
        intarr = self.daq.read_data(socket,length)
    
        cnt = 0

        for i in intarr:
            if(cnt != i):
                print("Output cnt error (length: {2}) (expect, found): {0} | {1}"
                      .format(cnt,i,length))
                return False;
            cnt += 1
        return True;

    
    def read_until(self,socket,data):
        read = -1
        cnt = 0
        while read != data:
            read = unpack('B',socket.recv(1))[0]
            cnt = cnt + 1
        # synchronize: read 3 more bytes
        socket.recv(3)
        cnt = cnt + 3
        return cnt
    
    def test_data(self,socket,count,delim, resync = False):
        if resync:
            print("Resync starting point");
            self.read_until(socket,delim)
        errorCnt = 0
        for i in range(0,count):
            if not self.check_data(socket,256):
                errorCnt = errorCnt + 1
            if not self.check_data(socket,1024):
                errorCnt = errorCnt + 1
        return errorCnt;

    def test_data0(self,count,resync = False,delim=0xFF):
        return self.test_data(self.daq.socketData0,count,delim,resync)

    def test_data1(self,count,resync = False,delim=0xFF):
        return self.test_data(self.daq.socketData1,count,delim,resync)

    def test_bulk_control(self,packets):
        data = b'\0'*1024*packets
        self.daq.socketControl.sendall(data)
        ret = len(self.daq.read_data(self.daq.socketControl,len(data))) * 4
        return ret == len(data)
    
    #define test scenario
    def full_test_run(self,cnt, resync = False):
        data = random.randint(0,30000)
        run = 1

        resyncD0 = resync
        resyncD1 = resync

        while(run <= cnt or cnt == -1):
            errCnt = self.write_read_all(data)

            errCntD0 = self.test_data0(100,resyncD0)
            errCntD1 = self.test_data1(100,resyncD1)

            resyncD0 = errCntD0 > 0
            resyncD1 = errCntD1 > 0

            if errCnt + errCntD0 + errCntD1 > 0:
                print("Run Nr. {0} Error counts: Control:{1}, Data0:{2},Data1{3}"
                      .format(run,errCnt,errCntD0,errCntD1))
            elif run % 100 == 0:
                print("Run {0}".format(run))
            run += 1
                  
def main():
    #nrRuns = 1
    #if len(sys.argv) > 1 :
    #    nrRuns = sys.argv[1]
    #daqTest = DaqTest()
    #daqTest.full_test_run(int(nrRuns),True)
    daq = DAQ(True);
    daq.write_reg(1,0,1)
    daq.write_reg(1,0,0)
	            
                
if __name__ == "__main__":
    main()
