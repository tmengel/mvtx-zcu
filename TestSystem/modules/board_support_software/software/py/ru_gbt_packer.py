"""Trigger handler class for RU"""

import collections
from collections import OrderedDict

from wishbone_module import WishboneModule

class GbtPackerMonitor(WishboneModule):
    wb_register_mapping = [
        "TRIGGER_RD_LOW",
        "TRIGGER_RD_HIGH",
        "SEND_SOP_LOW",
        "SEND_SOP_HIGH",
        "SEND_EOP_LOW",
        "SEND_EOP_HIGH",
        "PACKET_DONE_LOW",
        "PACKET_DONE_HIGH",
        "PACKET_TIMEOUT",
        "STATE_MISMATCH",
        "FIFO_FULL",
        "FIFO_OVERFLOW",
        "EMPTY_PACKET"
    ]
    nr_counter_regs = len(wb_register_mapping)

    """Monitor for Datapath status counters"""
    def __init__(self, moduleid,board_obj):
        super(GbtPackerMonitor, self).__init__(moduleid=moduleid,board_obj=board_obj,name="GbtPackerMonitor")

        self.REG_LATCH = 0
        self.REG_RESET = 1

        self.nr_regs = self.nr_counter_regs

        self.counter_mapping = [
            "TRIGGER_RD",
            "SEND_SOP",
            "SEND_EOP",
            "PACKET_DONE",
            "PACKET_TIMEOUT",
            "STATE_MISMATCH",
            "FIFO_FULL",
            "FIFO_OVERFLOW",
            "EMPTY_PACKET"
        ]

        self.multi_counter_order = {
            "TRIGGER_RD" : ("TRIGGER_RD_LOW", "TRIGGER_RD_HIGH"),
            "SEND_SOP" : ("SEND_SOP_LOW", "SEND_SOP_HIGH"),
            "SEND_EOP" : ("SEND_EOP_LOW", "SEND_EOP_HIGH"),
            "PACKET_DONE": ("PACKET_DONE_LOW", "PACKET_DONE_HIGH")
        }

    def _to_register_mapping(self,counters):
        mapped = []
        for c in counters:
            assert c in self.counter_mapping, "Counter {0} not in counter mapping".format(c)
            if c in self.multi_counter_order:
                mapped.extend(self.multi_counter_order[c])
            else:
                mapped.append(c)
        return mapped

    def _combine_counters(self,counters):
        counters_combined = OrderedDict()
        for cmc in self.counter_mapping:
            if cmc in self.multi_counter_order and all(cnt in counters for cnt in self.multi_counter_order[cmc]):
                part_cnt = self.multi_counter_order[cmc]
                counters_combined[cmc] = counters[part_cnt[1]] << 16 | counters[part_cnt[0]]
            elif cmc in counters:
                counters_combined[cmc] = counters[cmc]
        return counters_combined

    def reset_counters(self,commitTransaction=True):
        """Reset all counters"""
        self.write(self.REG_RESET,0xFFFF,commitTransaction=commitTransaction)

    def latch_counters(self,commitTransaction=False):
        """Latches values into counters"""
        self.write(self.REG_LATCH,0xFFFF,commitTransaction=commitTransaction)

    def read_counters(self,counters=None):
        """Read Counters(array) from lanes(array)"""
        if counters is None:
            counters = self.counter_mapping
        if not isinstance(counters,collections.Iterable):
            counters = [ counters ]
        result = None
        self.latch_counters()
        registers = self._to_register_mapping(counters)
        offsets = [self.wb_register_mapping.index(reg) + 2 for reg in registers]
        for offset in offsets:
            self.read(offset, False)
        values = self.read_all()
        read_regs = collections.OrderedDict()
        for reg_idx,reg in enumerate(registers):
            read_regs[reg] = values[reg_idx]
        results = self._combine_counters(read_regs)
        return results

class GbtPacker(WishboneModule):
    """Trigger Handler Interface"""
    ADD_FEE_ID              = 0
    ADD_GBT_PRIORITY        = 1
    ADD_MAX_WORD_COUNT      = 2
    ADD_MAX_PACKET_COUNT    = 3
    ADD_WAIT_DATA_TIMEOUT   = 4
    ADD_SEND_DATA_TIMEOUT   = 5
    ADD_LANE_TIMEOUT        = 6
    ADD_MASK_DATALANE_L     = 7
    ADD_MASK_DATALANE_H     = 8
    ADD_GBT_PACKER_SETTINGS = 9

    def __init__(self, moduleid, board_obj):
        super(GbtPacker, self).__init__(moduleid=moduleid,board_obj=board_obj,name="GbtPacker")


    def read_config(self):
        regs = ['fee_id',
                'gbt_priority',
                'max_word_count',
                'max_packet_count',
                'wait_data_timeout',
                'send_data_timeout',
                'lane_timeout',
                'mask_datalane_l',
                'mask_datalane_h',
                'gbt_packer_settings'
                ]

        reg_idx = list(range(10))

        for i in reg_idx:
            self.read(i,commitTransaction=False)
        results = self.read_all()

        result_dict = OrderedDict()
        for reg,val in zip(regs,results):
            result_dict[reg]=val
        return result_dict

    def dump_config(self):
        print("--- GBT Packer Module ---")
        config = self.read_config();
        for key, val in config:
            print("{0}:\t\t: {1}".format(key,val))

    def initialize(self,enable_data_forward=0,commitTransaction=True):
        """Initialize trigger handler"""
        self.set_settings(enable_data_forward,commitTransaction=commitTransaction)

    def set_settings(self,enable_data_forward=0, commitTransaction=True):
        data = (enable_data_forward&1) << 0
        self.write(self.ADD_GBT_PACKER_SETTINGS,data,commitTransaction)

    def get_settings(self,commitTransaction=True):
        data = self.read(self.ADD_GBT_PACKER_SETTINGS,commitTransaction=commitTransaction)
        if commitTransaction:
            results = OrderedDict()
            results['ENABLE_DATA_FORWARD'] = (data)&1
            return results
        else:
            return None

    def update_masks(self,lanes,commitTransaction=True):
        """Mask out all transceivers not in [lanes]"""
        mask = 0xFFFFFFFF
        for lane in lanes:
            mask &= ~(1<<lane)
        self.set_datalane_mask(mask,commitTransaction)

    def set_datalane_mask(self,mask=0x0,commitTransaction=True):
        data_l = mask&0xFFFF
        data_h = (mask>>16)&0xFFFF

        self.write(self.ADD_MASK_DATALANE_L,data_l,commitTransaction=False)
        self.write(self.ADD_MASK_DATALANE_H,data_h,commitTransaction=commitTransaction)

    def get_datalane_mask(self,commitTransaction=True):
        self.read(self.ADD_MASK_DATALANE_L,commitTransaction=False)
        self.read(self.ADD_MASK_DATALANE_H,commitTransaction=False)
        if commitTransaction:
            results = self.read_all()
            data = results[0]&0xFFFF | (results[1]&0xFFFF)<<16
            return data
        return None

    def set_fee_id(self,fee_id,commitTransaction=True):
        self.write(self.ADD_FEE_ID,fee_id,commitTransaction=commitTransaction)

    def get_fee_id(self,commitTransaction=True):
        return self.read(self.ADD_FEE_ID,commitTransaction=commitTransaction)

    def set_gbt_priority(self,gbt_priority,commitTransaction=True):
        self.write(self.ADD_GBT_PRIORITY,gbt_priority,commitTransaction=commitTransaction)

    def get_gbt_priority(self,commitTransaction=True):
        return self.read(self.ADD_GBT_PRIORITY,commitTransaction=commitTransaction)

    def set_max_word_count(self,max_word_count,commitTransaction=True):
        self.write(self.ADD_MAX_WORD_COUNT,max_word_count,commitTransaction=commitTransaction)

    def get_max_word_count(self,commitTransaction=True):
        return self.read(self.ADD_MAX_WORD_COUNT,commitTransaction=commitTransaction)

    def set_max_packet_count(self,max_packet_count,commitTransaction=True):
        self.write(self.ADD_MAX_PACKET_COUNT,max_packet_count,commitTransaction=commitTransaction)

    def get_max_packet_count(self,commitTransaction=True):
        return self.read(self.ADD_MAX_PACKET_COUNT,commitTransaction=commitTransaction)

    def set_wait_data_timeout(self,wait_data_timeout,commitTransaction=True):
        self.write(self.ADD_WAIT_DATA_TIMEOUT,wait_data_timeout,commitTransaction=commitTransaction)

    def get_wait_data_timeout(self,commitTransaction=True):
        return self.read(self.ADD_WAIT_DATA_TIMEOUT,commitTransaction=commitTransaction)

    def set_send_data_timeout(self,send_data_timeout,commitTransaction=True):
        self.write(self.ADD_SEND_DATA_TIMEOUT,send_data_timeout,commitTransaction=commitTransaction)

    def get_send_data_timeout(self,commitTransaction=True):
        return self.read(self.ADD_SEND_DATA_TIMEOUT,commitTransaction=commitTransaction)

    def set_lane_timeout(self,lane_timeout,commitTransaction=True):
        self.write(self.ADD_LANE_TIMEOUT,lane_timeout,commitTransaction=commitTransaction)

    def get_lane_timeout(self,commitTransaction=True):
        return self.read(self.ADD_LANE_TIMEOUT,commitTransaction=commitTransaction)
