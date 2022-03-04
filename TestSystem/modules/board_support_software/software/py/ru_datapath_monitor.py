"""Datapath monitor module for Reading out Lane counters"""

import time
import datetime
import logging
import random
import collections
import os
import traceback

from wishbone_module import WishboneModule

class DatapathMonitor(WishboneModule):
    wb_register_mapping = [
        "EVENT_COUNT_LOW",
        "EVENT_COUNT_HIGH",
        "DECODE_ERROR_COUNT",
        "EVENT_ERROR_COUNT",
        "BUSY_COUNT",
        "DOUBLE_BUSY_ON_COUNT",
        "IDLE_WORD_COUNT",
        "CPLL_LOCK_LOSS_COUNT",
        "CDR_LOCK_LOSS_COUNT",
        "ALIGNED_LOSS_COUNT",
        "ELASTIC_BUF_OVERFLOW_COUNT",
        "LANE_FIFO_FULL_COUNT",
        "LANE_PACKAGER_LANE_TIMEOUT_COUNT",
        "GBT_PACKER_LANE_STOPS_COUNT",
        "LANE_PACKAGER_STOP_COUNT",
        "LANE_PACKAGER_START_COUNT",
        "GBT_PACKER_LANE_START_VIOLATION_COUNT"
    ]
    nr_counter_regs = len(wb_register_mapping)

    """Monitor for Datapath status counters"""
    def __init__(self, moduleid,board_obj, lanes, offset=0):
        super(DatapathMonitor, self).__init__(moduleid=moduleid,board_obj=board_obj,name="DatapathMonitor")

        self.REG_LATCH = 0
        self.REG_RESET = 1
        self.COUNTER_OFFSET = 2

        self.lanes = lanes
        self.default_lanes = lanes[:]
        self.offset = offset

        self.nr_regs = self.nr_counter_regs * len(self.default_lanes)

        self.counter_mapping = [
            "EVENT_COUNT",
            "DECODE_ERROR_COUNT",
            "EVENT_ERROR_COUNT",
            "EMPTY_REGION_COUNT",
            "BUSY_COUNT",
            "BUSY_VIOLATION_COUNT",
            "DOUBLE_BUSY_ON_COUNT",
            "DOUBLE_BUSY_OFF_COUNT",
            "IDLE_WORD_COUNT",
            "CPLL_LOCK_LOSS_COUNT",
            "REALIGNED_COUNT",
            "CDR_LOCK_LOSS_COUNT",
            "LANE_FIFO_FULL_COUNT",
            "LANE_FIFO_OVERFLOW_COUNT",
            "ALIGNED_LOSS_COUNT",
            "ELASTIC_BUF_OVERFLOW_COUNT",
            "ELASTIC_BUF_UNDERFLOW_COUNT",
            "LANE_PACKAGER_LANE_TIMEOUT_COUNT",
            "GBT_PACKER_LANE_TIMEOUT_COUNT",
            "GBT_PACKER_LANE_STOPS_COUNT",
            "LANE_PACKAGER_STOP_COUNT",
            "LANE_PACKAGER_START_COUNT",
            "GBT_PACKER_LANE_START_VIOLATION_COUNT"
        ]

        self.counter_order = {
            "EVENT_COUNT" : ["EVENT_COUNT_LOW", "EVENT_COUNT_HIGH"],
            "EMPTY_REGION_COUNT" : ["EVENT_ERROR_COUNT"],
            "BUSY_VIOLATION_COUNT" : ["BUSY_COUNT"],
            "DOUBLE_BUSY_OFF_COUNT" : ["DOUBLE_BUSY_ON_COUNT"],
            "REALIGNED_COUNT" : ["CPLL_LOCK_LOSS_COUNT"],
            "ELASTIC_BUF_UNDERFLOW_COUNT" : ["ELASTIC_BUF_OVERFLOW_COUNT"],
            "LANE_FIFO_OVERFLOW_COUNT":["LANE_FIFO_FULL_COUNT"],
            "GBT_PACKER_LANE_TIMEOUT_COUNT" : ["LANE_PACKAGER_LANE_TIMEOUT_COUNT"]
        }

        self.counter_transform = {
            "EVENT_COUNT" : (lambda wb_regs: wb_regs["EVENT_COUNT_HIGH"] << 16 | wb_regs["EVENT_COUNT_LOW"]),
            "EVENT_ERROR_COUNT" : (lambda wb_regs: wb_regs["EVENT_ERROR_COUNT"] & 0xFF),
            "EMPTY_REGION_COUNT": (lambda wb_regs: (wb_regs["EVENT_ERROR_COUNT"]>>8) & 0xFF),
            "BUSY_COUNT" : (lambda wb_regs: wb_regs["BUSY_COUNT"] & 0xFF),
            "BUSY_VIOLATION_COUNT": (lambda wb_regs: (wb_regs["BUSY_COUNT"]>>8) & 0xFF),
            "DOUBLE_BUSY_ON_COUNT" : (lambda wb_regs: wb_regs["DOUBLE_BUSY_ON_COUNT"] & 0xFF),
            "DOUBLE_BUSY_OFF_COUNT": (lambda wb_regs: (wb_regs["DOUBLE_BUSY_ON_COUNT"]>>8) & 0xFF),
            "IDLE_WORD_COUNT" : (lambda wb_regs: wb_regs["IDLE_WORD_COUNT"] << 8),
            "CPLL_LOCK_LOSS_COUNT" : (lambda wb_regs: wb_regs["CPLL_LOCK_LOSS_COUNT"] & 0xFF),
            "REALIGNED_COUNT": (lambda wb_regs: (wb_regs["CPLL_LOCK_LOSS_COUNT"]>>8) & 0xFF),
            "ELASTIC_BUF_OVERFLOW_COUNT" : (lambda wb_regs: wb_regs["ELASTIC_BUF_OVERFLOW_COUNT"] & 0xFF),
            "ELASTIC_BUF_UNDERFLOW_COUNT": (lambda wb_regs: (wb_regs["ELASTIC_BUF_OVERFLOW_COUNT"]>>8) & 0xFF),
            "LANE_FIFO_FULL_COUNT" : (lambda wb_regs: (wb_regs["LANE_FIFO_FULL_COUNT"] & 0xFF) << 8),
            "LANE_FIFO_OVERFLOW_COUNT": (lambda wb_regs: ((wb_regs["LANE_FIFO_FULL_COUNT"]>>8) & 0xFF) << 8),
            "LANE_PACKAGER_LANE_TIMEOUT_COUNT" : (lambda wb_regs: wb_regs["LANE_PACKAGER_LANE_TIMEOUT_COUNT"] & 0xFF),
            "GBT_PACKER_LANE_TIMEOUT_COUNT": (lambda wb_regs: (wb_regs["LANE_PACKAGER_LANE_TIMEOUT_COUNT"]>>8) & 0xFF),
            "GBT_PACKER_LANE_STOPS_COUNT" : (lambda wb_regs: wb_regs["GBT_PACKER_LANE_STOPS_COUNT"] << 8),
            "LANE_PACKAGER_STOP_COUNT" : (lambda wb_regs: wb_regs["LANE_PACKAGER_STOP_COUNT"] << 8),
            "LANE_PACKAGER_START_COUNT" : (lambda wb_regs: wb_regs["LANE_PACKAGER_START_COUNT"] << 8),
            "GBT_PACKER_LANE_START_VIOLATION_COUNT" : (lambda wb_regs: wb_regs["GBT_PACKER_LANE_START_VIOLATION_COUNT"])
        }


    def set_lanes(self,lanes):
        self.lanes = lanes

    def get_lanes(self):
        return self.lanes

    def get_default_lanes(self):
        return self.default_lanes

    def _to_register_mapping(self,counters):
        mapped = []
        for c in counters:
            assert c in self.counter_mapping, "Counter {0} not in counter mapping".format(c)
            if c in self.counter_order:
                for sc in self.counter_order[c]:
                    if sc not in mapped:
                        mapped.append(sc)
            else:
                mapped.append(c)
        return mapped

    def _process_counters(self,wb_regs,counters):
        counters_combined = collections.OrderedDict()
        for c in counters:
            if c in self.counter_transform:
                counters_combined[c] = self.counter_transform[c](wb_regs)
            else:
                counters_combined[c] = wb_regs[c]
        return counters_combined

    def reset_counters(self,commitTransaction=True):
        """Reset all counters"""
        self.write(self.REG_RESET,0xFFFF,commitTransaction=commitTransaction)

    def latch_counters(self,commitTransaction=False):
        """Latches values into counters"""
        self.write(self.REG_LATCH,0xFFFF,commitTransaction=commitTransaction)

    def get_lane_idx(self,lane):
        return lane - self.offset


    def reset_lane_counters(self,lane,commitTransaction=True):
        """Reset all counters for lane i"""
        assert lane in self.lanes , "Lane not in range"
        for i in range(self.nr_counter_regs*self.get_lane_idx(lane) + self.COUNTER_OFFSET,
                       self.nr_counter_regs*self.get_lane_idx(lane)+self.nr_counter_regs + self.COUNTER_OFFSET):
            reset_cmd = 0xF000|(i&0xFF)
            self.write(self.REG_RESET,reset_cmd,commitTransaction=False)
        if commitTransaction:
            self.flush()

    def read_counters(self,lanes=None,counters=None):
        """Read Counters(array) from lanes(array)"""
        if lanes is None:
            lanes = self.lanes
        if not isinstance(lanes,collections.Iterable):
            lanes = [ lanes ]
        if counters is None:
            counters = self.counter_mapping
        if not isinstance(counters,collections.Iterable):
            counters = [ counters ]
        result = None
        self.latch_counters(commitTransaction=False)
        registers = self._to_register_mapping(counters)
        offsets = [self.wb_register_mapping.index(reg) for reg in registers]
        for lane in lanes:
            lane_idx = self.nr_counter_regs * self.get_lane_idx(lane) + self.COUNTER_OFFSET
            for offset in offsets:
                self.read(lane_idx + offset, False)
        values = self.read_all()

        results = []
        nr_registers = len(registers)
        for idx,lane in enumerate(lanes):
            lane_regs = collections.OrderedDict()
            for reg_idx,reg in enumerate(registers):
                lane_regs[reg] = values[idx*nr_registers + reg_idx]
            results.append(self._process_counters(lane_regs,counters))

        return results

    def read_counter(self,lanes,counter):
        result = None
        results = self.read_counters(lanes,[counter])
        results_reduced = [l[counter] for l in results]
        if(len(results_reduced) == 1):
            return results_reduced[0]
        else:
            return results_reduced

    def read_all_counters(self):
        """Read all counters of monitor"""
        return self.read_counters()

class DatapathMonitorDual():
    """Monitor for Datapath status counters"""
    def __init__(self, datapath_mon1,datapath_mon2):

        self.datapath_mon1 = datapath_mon1
        self.datapath_mon2 = datapath_mon2
        self.lanes = datapath_mon1.get_lanes() + datapath_mon2.get_lanes()

        self.counter_mapping = self.datapath_mon1.counter_mapping

    def set_lanes(self,lanes):
        for dpmon,lanes_split in self._split_lane_access(lanes).items():
            dpmon.set_lanes(lanes_split)
        self.lanes = lanes

    def get_lanes(self):
        return self.lanes

    def reset_counters(self,commitTransaction=True):
        """Reset all counters"""
        self.datapath_mon1.reset_counters(False)
        self.datapath_mon2.reset_counters(commitTransaction)

    def latch_counters(self,commitTransaction=False):
        """Latches values into counters"""
        self.datapath_mon1.latch_counters(False)
        self.datapath_mon2.latch_counters(commitTransaction)

    def _split_lane_access(self,lanes):
        parts = {self.datapath_mon1:list(),
                 self.datapath_mon2:list()}
        for lane in lanes:
            if lane in self.datapath_mon1.get_default_lanes():
                parts[self.datapath_mon1].append(lane)
            else:
                parts[self.datapath_mon2].append(lane)
        return parts

    def reset_lane_counters(self,lane,commitTransaction=True):
        """Reset all counters for lane i"""
        assert lane in self.lanes, "Lane not in range"
        parts = self._split_lane_access([lane])
        for mon,lanes in parts.items():
            for lane_idx in lanes:
                for i in range(mon.nr_counter_regs*lane_idx,mon.nr_counter_regs*lane_idx+mon.nr_counter_regs):
                    mon.write(i,1,commitTransaction=False)
        if commitTransaction:
            self.datapath_mon1.flush()

    def read_counters(self,lanes=None,counters=None):
        """Read Counters(array) from lanes(array)"""
        if lanes is None:
            lanes = self.lanes
        if not isinstance(lanes,collections.Iterable):
            lanes = [ lanes ]

        parts = self._split_lane_access(lanes)
        results = []
        for mon,lane_parts in parts.items():
            results.extend(mon.read_counters(lane_parts,counters))

        return results

    def read_counter(self,lanes=None,counter='EVENT_COUNT'):
        if lanes is None:
            lanes = self.lanes
        if not isinstance(lanes,collections.Iterable):
            lanes = [ lanes ]
        result = None
        results = self.read_counters(lanes,[counter])
        results_reduced = [l[counter] for l in results]
        if(len(results_reduced) == 1):
            return results_reduced[0]
        else:
            return results_reduced

    def read_all_counters(self):
        """Read all counters of monitor"""
        return self.read_counters()
