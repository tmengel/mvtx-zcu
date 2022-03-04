import time
import datetime
import logging
import random
import collections
import os

from wishbone_module import WishboneModule

class WishboneToFifo(WishboneModule):
    """Send data to wishbone fifo slave"""
    def __init__(self, moduleid, board_obj):
        super(WishboneToFifo, self).__init__(moduleid=moduleid,board_obj=board_obj,name="WishboneToFifo")

    def page_write(self,data):
        assert len(data) >= 4096, "Page size must be 4096"
        status = self.read_fifo_status()
        if (status & 0x01) != 0x01:
            for idx in range(0,4096,2):
                word = (data[idx+1]<<8) | data[idx]
                self.write(0,word,False)
            self.flush()
            return True
        else:
            return False

    def write_bitfile(self, filename, timeout_count = 100):
        assert os.path.isfile(filename), "Did not find file"
        bytes_written = 0
        page_size = 4096 # write in chunks of 4096 bytes
        buf = bytearray([0xff]*page_size)
        filesize = os.path.getsize(filename)
        buf[0] = 1
        buf[1] = buf[2] = buf[3] = 0
        buf[4] = filesize & 0xff
        buf[5] = (filesize >> 8) & 0xff
        buf[6] = (filesize >> 16) & 0xff
        buf[7] = (filesize >> 24) & 0xff
        timeout = 0
        while((not self.page_write(buf)) and (timeout < timeout_count)):
            timeout += 1
            time.sleep(0.01)
        if timeout == timeout_count:
            return (-bytes_written)

        bytes_written += 4096
        with open(filename, 'rb') as f:
            while True:
                n = f.readinto(buf)
                if n == 0:
                    break
                if n < page_size:
                    for idx in range(n, 4096):
                        buf[idx] = 0xff
                timeout = 0
                while((not self.page_write(buf)) and (timeout < timeout_count)):
                    timeout += 1
                    time.sleep(0.01)
                if timeout == timeout_count:
                    return (-bytes_written)
                bytes_written += 4096
        return bytes_written


    def bulk_write(self,data,chunks=256*10):
        assert len(data) % 3 == 0, "Data send must be multiple of 3"
        data_written_before = self.read_write_counter()
        for idx in range(0,len(data),3):
            addr = data[idx]
            word = (data[idx+1]<<8) | data[idx+2]
            self.write(addr,word,False)
            if idx%chunks == chunks-1:
                self.flush()
        self.flush()
        data_written_after = self.read_write_counter()

        data_written = data_written_after - data_written_before
        if (data_written)*3 != len(data):
            self.logger.error("Data write mismatch: Written: %d, expected: %d",data_written,len(data))


    def counter_test(self,max_val,chunks=256*10):
        # reset counter to 0 -> next value should be one
        self.write(0,0)
        errors_before = self.read_validate_read_counter()
        writes_before = self.read_write_counter()

        assert max_val < 1<<24, "Counter can only run up to  with 24 bit width"

        data = bytearray()
        for i in range(1,max_val+1):
            data += (i).to_bytes(3,byteorder='big')
            if len(data) >= chunks:
                self.bulk_write(data,chunks)
                data = bytearray()
        self.bulk_write(data,chunks)

        errors = self.read_validate_read_counter() - errors_before
        writes = self.read_write_counter() - writes_before

        if errors > 0:
            self.logger.error("Validation errors encountered during counter test: %d errors",errors)
        if writes != max_val:
            self.logger.error("Invalid number of writes encountered. Expected: %d, received: %d",max_val,writes)
        return writes,errors

    def read_write_counter(self):
        self.read(0,False)
        self.read(1,False)
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def read_read_counter(self):
        self.read(2,False)
        self.read(3,False)
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def read_overflow_counter(self):
        self.read(4,False)
        self.read(5,False)
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def read_validate_read_counter(self):
        self.read(6,False)
        self.read(7,False)
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def read_fifo_status(self):
        return self.read(8,True)
