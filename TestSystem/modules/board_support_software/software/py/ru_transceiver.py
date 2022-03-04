"""Transceiver module for Xilinx GTX Transceiver functions"""
import time
import datetime
import logging
import random
import collections
import os
import traceback

from wishbone_module import WishboneModule

class GthFrontend(WishboneModule):
    """Software module for communicating with the alpide_frontend_ib_wishbone module."""
    NR_TRANSCEIVERS = 9

    ENABLE_ALIGNMENT = 0
    ALIGNMENT_STATUS = 1
    ENABLE_DATA      = 2

    DRP_READBACK_ADDRESSES = [2, 3, 4, 5, 6, 9, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 202, 203, 204, 205, 206, 207, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 355, 361]

    GTH_RESET          = 5
    GTH_STATUS         = 6
    ENABLE_PRBS_CHECK  = 7
    PRBS_COUNTER_RESET = 8


    def __init__(self,moduleid,board_obj, drp_bridge,transceivers=None):
        super(GthFrontend, self).__init__(moduleid=moduleid,board_obj=board_obj,name="GthFrontend")
        self.drp_bridge = drp_bridge
        self.transceivers = transceivers
        if self.transceivers is None:
            self.transceivers = list(range(self.NR_TRANSCEIVERS))

    def read_config(self):
        regs = ['enable_alignment','alignment_status','enable_data','gth_reset','gth_status']
        reg_idx = [0,1,2,5,6]
        for i in reg_idx:
            self.read(i,commitTransaction=False)
        results = self.read_all()

        result_dict = collections.OrderedDict()
        for reg,val in zip(regs,results):
            result_dict[reg]=val
        return result_dict

    def set_transceivers(self,transceivers):
        """Set array of transceivers to be addressed"""
        for transceiver in transceivers:
            assert transceiver < self.NR_TRANSCEIVERS, "Transceiver not in Range of Transceivers"
        self.transceivers=transceivers

    def get_transceivers(self):
        """Return board transceivers"""
        return self.transceivers

    def initialize(self,commitTransaction=True,check_reset_done=True,max_retries=10):
        """Initialise Transceiver: Reset GTH block, enable alignment"""
        self.enable_data(False,commitTransaction=commitTransaction)
        self.enable_alignment(False,commitTransaction=commitTransaction)
        self.write(self.GTH_RESET,1<<15,commitTransaction=False)
        self.firmware_wait(15,commitTransaction=False)
        self.write(self.GTH_RESET,0,commitTransaction=commitTransaction)
        if check_reset_done:
            if not commitTransaction:
                self.logger.warning("Check reset needs to read from board -> transaction will be flushed")
            self.firmware_wait(100,commitTransaction=False)
            reset_done = self.is_reset_done()
            retries = 0
            while not reset_done and retries < max_retries:
                self.firmware_wait(200,commitTransaction=True)
                time.sleep(1)
                reset_done = self.is_reset_done()
                retries += 1
        else:
            reset_done = True
        return reset_done

    def align_transceivers(self,check_aligned=True,max_retries=10):
        """Perform transceiver alignment procedure:
           * enable alignment
           * check that all transceivers are aligned
           * disable alignment
        """
        self.enable_alignment(True)
        if check_aligned:

            aligned = self.is_aligned()
            retries = 0
            while not all(aligned) and retries < max_retries:
                self.firmware_wait(100)
                aligned = self.is_aligned()
                retries += 1
            return all(aligned)
        else:
            return True

    def is_reset_done(self):
        """Return Reset status of GTH block"""
        status = self.read(self.GTH_STATUS)
        return status&(1<<15) > 0

    def is_cdr_locked(self):
        """Return cdr status for each transceiver as array"""
        status = self.read(self.GTH_STATUS)
        locked = [status&(1<<i)>0 for i in self.transceivers]
        return locked

    def is_aligned(self):
        """Return lock alignment status of each transceivers as array"""
        status = self.read(self.ALIGNMENT_STATUS)
        aligned = [status&(1<<i)>0 for i in self.transceivers]
        return aligned

    def get_gth_status(self):
        status = self.read(self.GTH_STATUS)
        value = {}
        value['reset_done'] = status&(1<<15)>0
        value['cdr_locked'] = status&0x7F
        return value

    def _get_transceiver_mask(self):
        """Return mask for addressed transceivers"""
        mask = 0
        for transceiver in self.transceivers:
            mask |= (1<<transceiver)
        return mask

    def _write_masked_reg(self,addr,flag,commitTransaction=True,readback=True):
        """Write to a register which needs to have a transceiver mask applied"""
        if(len(self.transceivers) < self.NR_TRANSCEIVERS) and readback:
            if not commitTransaction:
                self.logger.warning("Cannot have readback enabled with commitTransaction=False -> transaction will be committed")
                traceback.print_stack()
            reg = self.read(addr)
        else:
            reg = 0
        mask = self._get_transceiver_mask()

        if flag:
            reg |= mask
        else:
            reg &= ~mask
        self.write(addr,reg,commitTransaction=commitTransaction)

    def enable_alignment(self, enable=True,commitTransaction=True):
        """Enable alignment flag for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_ALIGNMENT,enable,commitTransaction)

    def enable_data(self,enable=True,commitTransaction=True):
        """Enable data flag for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_DATA,enable,commitTransaction)

    def reset_receivers(self,commitTransaction=True):
        """Reset Receivers paths for Transceivers"""
        self._write_masked_reg(self.GTH_RESET,True,commitTransaction,False)
        self.write(self.GTH_RESET,0,commitTransaction=commitTransaction)


    def enable_prbs(self, enable=True,commitTransaction=True):
        """Enable PRBS checker for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_PRBS_CHECK,enable,commitTransaction,True)

    def reset_prbs_counter(self,commitTransaction=True):
        """Reset internal Transceiver PRBS counter"""
        self._write_masked_reg(self.PRBS_COUNTER_RESET,flag=True,commitTransaction=False,readback=False)
        self.write(self.PRBS_COUNTER_RESET,0,commitTransaction)

    def read_prbs_counter(self,reset=False):
        """Read / log the total amount of Prbs errors since the last check"""
        for tr in self.transceivers:
            self.read_drp(0x15E,False,tr)
            self.read_drp(0x15F,False,tr)

        if reset:
            self.reset_prbs_counter(commitTransaction=False)

        results = self.read_all()
        prbs_errors = [results[i+1]<<15 | results[i] for i in range(0,len(results),2)]

        return prbs_errors

    def write_drp(self, address, data, commitTransaction=True,transceiver=None):
        """Write to the drp port. Set Transceiver via transceiver setting; defaults to self.transceivers[0]"""
        if transceiver is None:
            transceiver = self.transceivers[0]
        self.drp_bridge.write_drp(transceiver,address,data,commitTransaction)

    def read_drp(self, address, commitTransaction=True, transceiver=None):
        """Read from the drp port. Set Transceiver via transceiver setting; defaults to self.transceivers[0]"""
        if transceiver is None:
            transceiver = self.transceivers[0]
        return self.drp_bridge.read_drp(transceiver,address,commitTransaction)

    def readback_all_drp(self):
        """Read back all Valid DRP ports of all registered transceivers"""
        #schedule reads
        for transceiver in self.transceivers:
            for addr in self.DRP_READBACK_ADDRESSES:
                self.read_drp(address=addr,commitTransaction=False,transceiver=transceiver)

        results = self.read_all()
        drp_readback = collections.OrderedDict()
        result_idx = 0
        for transceiver in self.transceivers:
            drp_readback[transceiver] = collections.OrderedDict()
            for addr in self.DRP_READBACK_ADDRESSES:
                drp_readback[transceiver][addr] = results[result_idx]
                result_idx+=1

        return drp_readback

class GpioFrontend(WishboneModule):
    """Software module for communicating with the alpide_frontend_ob_wishbone module."""
    NR_TRANSCEIVERS = 28

    ENABLE_ALIGNMENT_L = 0
    ENABLE_ALIGNMENT_H = 1
    ALIGNMENT_STATUS_L = 2
    ALIGNMENT_STATUS_H = 3
    ENABLE_REALIGN_L = 4
    ENABLE_REALIGN_H = 5

    ENABLE_DATA_L      = 6
    ENABLE_DATA_H      = 7

    IDELAY_VALUE = 8
    IDELAY_LOAD_L = 9
    IDELAY_LOAD_H = 10

    ENABLE_PRBS_CHECK_L  = 11
    ENABLE_PRBS_CHECK_H  = 12

    PRBS_RESET_COUNTER_L = 13
    PRBS_RESET_COUNTER_H = 14

    PRBS_COUNTER_LANE_0 = 15
    LANE_CHIP_MASK_0 = 47

    def __init__(self,moduleid,board_obj,transceivers=None):
        super().__init__(moduleid=moduleid,board_obj=board_obj,name="GthFrontend")
        self.transceivers = transceivers
        if self.transceivers is None:
            self.transceivers = list(range(self.NR_TRANSCEIVERS))

    def read_config(self):
        regs = ['enable_alignment1',
                'enable_alignment2',
                'alignment_status1',
                'alignment_status2',
                'enable_realignment1',
                'enable_realignment2',
                'enable_data1',
                'enable_data2',
                ]
        regs.extend(['readout_chip_mask_lane_{0}'.format(i) for i in self.transceivers])

        reg_idx = [0,1,2,3,4,5,6,7] + [i+self.LANE_CHIP_MASK_0 for i in self.transceivers]

        for i in reg_idx:
            self.read(i,commitTransaction=False)
        results = self.read_all()

        result_dict = collections.OrderedDict()
        for reg,val in zip(regs,results):
            result_dict[reg]=val
        return result_dict


    def subset(self,transceivers):
        return GpioFrontend(self.moduleid,self.board,transceivers)

    def set_transceivers(self,transceivers):
        """Set array of transceivers to be addressed"""
        for transceiver in transceivers:
            assert transceiver < self.NR_TRANSCEIVERS, "Transceiver not in Range of Transceivers"
        self.transceivers=transceivers

    def get_transceivers(self):
        """Return board transceivers"""
        return self.transceivers

    def initialize(self,commitTransaction=True):
        """Initialise Transceiver: enable alignment"""
        self.enable_data(False,commitTransaction=commitTransaction)
        self.enable_alignment(False,commitTransaction=commitTransaction)
        return True

    def align_transceivers(self,check_aligned=True,max_retries=10):
        """Perform transceiver alignment procedure:
           * enable alignment
           * check that all transceivers are aligned
           * disable alignment
        """
        self.enable_alignment(True)
        self.enable_realign(True)
        if check_aligned:
            aligned = self.is_aligned()
            retries = 0
            while not all(aligned) and retries < max_retries:
                self.firmware_wait(100)
                aligned = self.is_aligned()
                retries += 1
            return all(aligned)
        else:
            return True


    def scan_idelays(self,stepsize=10,waittime=0.1,set_optimum=True,verbose=True):
        """Scan all Idelay values to find the best phase. Requires chips to be set up for PRBS400"""
        delays = list(range(0,512,stepsize))
        prbs_counters_all = collections.OrderedDict()

        for delay in delays:
            self.load_idelay(delay)
            self.reset_prbs_counter()
            time.sleep(waittime)
            prbs_counters = self.read_prbs_counter()
            prbs_counters_all[delay] = prbs_counters[:]
            if verbose:
                print("Delay: {0:03d}: {1}".format(delay,",".join(["{0:5d}".format(c) for c in prbs_counters])))

        # find best delay
        best_delays_start = [-1]*len(self.transceivers)
        best_delays_end = [-2]*len(self.transceivers)
        current_delays_start = [None]*len(best_delays_start)
        prev_delay = delays[0]
        for delay, values in prbs_counters_all.items():
            for i,val in enumerate(values):
                if val == 0  and delay < delays[-1]:
                    if current_delays_start[i] is None:
                        current_delays_start[i] = delay
                        #print("Tr {0:02d}: Current start: {1}".format(i,delay))
                else:
                    if current_delays_start[i] is not None:
                        current_range = prev_delay-current_delays_start[i]
                        best_range = best_delays_end[i]-best_delays_start[i]
                        #print("Tr {0:02d}: Current range: {1}, Best range: {2}".format(i,current_range,best_range))
                        if current_range > best_range:
                            #print("Tr {0:02d}: Replace".format(i))
                            best_delays_start[i] = current_delays_start[i]
                            best_delays_end[i] = prev_delay
                        current_delays_start[i] = None

            prev_delay=delay


        transceiver_optima = {}
        for idx, tr in enumerate(self.get_transceivers()):
            if best_delays_start[idx] < 0:
                self.logger.warning("Transceiver {0:02d}: No delay found".format(tr))
            else:
                start = best_delays_start[idx]
                end = best_delays_end[idx]
                mid = round((end+start)/2)
                open_range = end-start
                self.logger.info("Transceiver {0:02d}: Delay: {1:3d} ({2:3d} to {3:3d}, \"open\" range: {4:3d})"
                      .format(tr,mid,start,end,open_range))
                transceiver_optima[tr]=mid
                if set_optimum:
                    self.subset([tr]).load_idelay(mid)

        return transceiver_optima


    def _read_hl(self,high,low):
        """Read high, low part of a register and return combined"""
        self.read(high,commitTransaction=False)
        self.read(low,commitTransaction=False)
        results = self.read_all()
        assert len(results) == 2, "Unexpected result length"
        result = results[0] << 16 | results[1]
        return result

    def is_aligned(self):
        """Return lock alignment status of each transceivers as array"""
        status = self._read_hl(self.ALIGNMENT_STATUS_H,
                              self.ALIGNMENT_STATUS_L)

        aligned = [status&(1<<i)>0 for i in self.transceivers]
        return aligned

    def _get_transceiver_mask(self):
        """Return mask for addressed transceivers"""
        mask = 0
        for transceiver in self.transceivers:
            mask |= (1<<transceiver)
        return mask

    def _write_masked_reg(self,addr_h, addr_l,flag,commitTransaction=True,readback=True):
        """Write to a register which needs to have a transceiver mask applied"""
        if(len(self.transceivers) < self.NR_TRANSCEIVERS) and readback:
            if not commitTransaction:
                self.logger.warning("Cannot have readback enabled with commitTransaction=False -> transaction will be committed")
                traceback.print_stack()
            reg = self._read_hl(addr_h,addr_l)
        else:
            reg = 0
        mask = self._get_transceiver_mask()

        if flag:
            reg |= mask
        else:
            reg &= ~mask
        reg_l = reg & 0xFFFF
        reg_h = (reg >> 16) & 0xFFFF

        self.write(addr_l,reg_l,commitTransaction=False)
        self.firmware_wait(10,commitTransaction=False)
        self.write(addr_h,reg_h,commitTransaction=commitTransaction)


    def enable_alignment(self, enable=True,commitTransaction=True):
        """Enable alignment flag for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_ALIGNMENT_H,
                               self.ENABLE_ALIGNMENT_L,
                               enable,commitTransaction)

    def enable_realign(self, enable=True,commitTransaction=True):
        """Enable realign flag for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_REALIGN_H,
                               self.ENABLE_REALIGN_L,
                               enable,commitTransaction)



    def enable_data(self,enable=True,commitTransaction=True):
        """Enable data flag for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_DATA_H,
                               self.ENABLE_DATA_L,
                               enable,commitTransaction)

    def load_idelay(self,value, commitTransaction=True):
        assert value <= 0x1FF, "Idelay value must be within 0:512"
        self.write(self.IDELAY_VALUE,value,False)
        self._write_masked_reg(self.IDELAY_LOAD_H,self.IDELAY_LOAD_L,1,commitTransaction=False,readback=False)
        self.write(self.IDELAY_LOAD_L,0,commitTransaction=False)
        self.write(self.IDELAY_LOAD_H,0,commitTransaction=commitTransaction)

    def enable_prbs(self, enable=True,commitTransaction=True):
        """Enable PRBS checker for Transceivers. Does not touch transceivers not in list"""
        self._write_masked_reg(self.ENABLE_PRBS_CHECK_H,
                               self.ENABLE_PRBS_CHECK_L,
                               enable,commitTransaction,True)

    def reset_prbs_counter(self,commitTransaction=True):
        """Reset internal Transceiver PRBS counter"""
        self._write_masked_reg(self.PRBS_RESET_COUNTER_H,
                               self.PRBS_RESET_COUNTER_L,
                               flag=True,commitTransaction=False,readback=False)
        self.write(self.PRBS_RESET_COUNTER_H,0,False)
        self.write(self.PRBS_RESET_COUNTER_L,0,commitTransaction)

    def read_prbs_counter(self,reset=False):
        """Read / log the total amount of Prbs errors since the last check"""
        for tr in self.transceivers:
            self.read(self.PRBS_COUNTER_LANE_0 + tr, commitTransaction = False)

        if reset:
            self.reset_prbs_counter(commitTransaction=False)

        results = self.read_all()
        prbs_errors = results

        return prbs_errors

    def set_lane_chip_mask(self,lane,mask,commitTransaction=True):
        """Set the chip mask for lane <lane>.
        A masked lane will not be considered for generating end of event for packaging
        """
        assert lane < self.NR_TRANSCEIVERS
        self.write(self.LANE_CHIP_MASK_0+lane,mask,commitTransaction=commitTransaction)

    def get_lane_chip_mask(self,lane,commitTransaction=True):
        assert lane < self.NR_TRANSCEIVERS
        return self.read(self.LANE_CHIP_MASK_0+lane,commitTransaction=commitTransaction)
