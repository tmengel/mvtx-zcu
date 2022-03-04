"""Readout unit implementation of the Board interface."""

import logging
import time
from collections import OrderedDict

#from drp_bridge import DrpBridge
from ws_master_monitor import WsMasterMonitor
from ws_i2c_gbtx import WsI2cGbtx
from ws_status import WsStatus
from ws_usb_if import WsUsbif
from mgt_test import MgtTest
from drp_wb_bridge import WsDrpCtrl
from gpio_loopback_test import GpioLoopbackTest

from wishbone_wait import WishboneWait
from sca_ru import Sca_RU
import proasic3
import trigger



from power_supplies import DummyPowerSupply

USE_RUv1 = False

class ConfigurationMemoryMapping(object):
    """configuration register mapping"""
    alpide_vdd_on = 0

class ReadoutBoard:
    def __init__(self, comm):
        self.comm = comm

    def initialize(self):
        pass

    # Wishbone access functions
    def write(self, mod, addr, data, commitTransaction=True):
        """Write to specific register on the board"""
        self.comm.register_write(mod, addr, data)
        if commitTransaction:
            self.comm.flush()

    def read(self, mod, addr, commitTransaction=True):
        """Read from specific register on the board"""
        self.comm.register_read(mod, addr)
        if commitTransaction:
            self.comm.flush()
            ret = self.comm.read_results()
            if len(ret) != 1:
                print("Unexpected length of result: {0}, expected length 1; ignore further results".format(
                    len(ret)))
            if len(ret) == 0:
                data = None
            else:
                data = ret[0][1]
            return data
        else:
            return None

    def flush(self):
        """Flush communication buffer."""
        self.comm.flush()

    def read_all(self):
        """Read all pending results."""
        self.flush()
        ret = self.comm.read_results()
        data = []
        for item in ret:
            data.append(item[1])
        return data

class RUv1(ReadoutBoard):
    """Board implementation for Readout unit"""
    MASTER_MONITOR_MODULE    = 0
    STATUS_MODULE            = 1
    I2C_GBT_MODULE           = 2
    WAIT_MODULE              = 3
    USB_IF                   = 4
    MGT_TEST_MODULE          = 5
    DRP_CTRL                 = 6
    LOOPBACK_TEST            = 7

    def __init__(self, comm):
        super(RUv1, self).__init__(comm)
        self.logger = logging.getLogger("RUv1")

        self.comm = comm
        self.status = WsStatus(moduleid=self.STATUS_MODULE, board_obj=self)
        self.master_monitor = WsMasterMonitor(moduleid=self.MASTER_MONITOR_MODULE, board_obj=self)
        self.wait_module = WishboneWait(moduleid=self.WAIT_MODULE, board_obj=self)
        self.i2c_gbtx = WsI2cGbtx(board_obj=self, moduleid=self.I2C_GBT_MODULE)
        self.usb_if = WsUsbif(moduleid=self.USB_IF, board_obj=self)
        self.mgt_test = MgtTest(moduleid=self.MGT_TEST_MODULE, board_obj=self)
        self.drp_ctrl = WsDrpCtrl(moduleid=self.DRP_CTRL, board_obj=self)
        self.gpio_loopback_test = GpioLoopbackTest(moduleid=self.LOOPBACK_TEST, board_obj=self)

    def initialize(self):
        # Only on RUv1 with wrong delay (12 instead of 8/9)
        #self.gbtx0_update_delay()
        pass

    def wait(self, wait_value, commitTransaction=True):
        """Implements the wait function of the dctrl wishbone slave"""
        self.wait_module.wait(wait_value, commitTransaction=commitTransaction)

    def dump_config(self):
        config_str = "-- RUv1 configuration --\n"
        config_str += "-- Module {0} --\n".format(self.MASTER_MONITOR_MODULE)
        config_str += self.master_monitor.dump_config()

        config_str += "-- Module {0} --\n".format(self.STATUS_MODULE)
        config_str += self.status.dump_config()

        config_str += "-- Module {0} --\n".format(self.I2C_GBT_MODULE)
        config_str += self.i2c_gbtx.dump_config()

        config_str += "-- Module {0} --\n".format(self.ALPIDE_MODULE)
        config_str += self.dctrl.dump_config()

        config_str += "-- Module {0} --\n".format(self.SYSMON_MODULE)
        config_str += self.sysmon.dump_config()

        for i in range(self.HSDATA.__len__()):
            config_str += "-- Module {0} --\n".format(self.HSDATA[i])
            config_str += self.transceiver_array[i].dump_config()

        return config_str

    def check_git_hash_and_date(self, expected_git_hash=None):
        """gets git hash and fw date"""
        self.status.check_git_hash_and_date(expected_git_hash)

    def get_dna_value(self):
        """Gets the FPGA DNA value"""
        return self.status.get_dna_value()


class RUv0_CRU(ReadoutBoard):
    """Board implementation for Readout unit"""
    CRU_OFFSET = 0x40

    MASTER_MONITOR_MODULE =  CRU_OFFSET + 0
    STATUS_MODULE         =  CRU_OFFSET + 1
    SCA_MODULE            =  CRU_OFFSET + 2
    GBT_FPGA_MODULE       =  CRU_OFFSET + 3
    WAIT_MODULE           =  CRU_OFFSET + 4

    if USE_RUv1:
        SCA_ADC_COUNTERS = [
            (0x00,"I_MGT"),
            (0x01,"I_INT"),
            (0x02,"I_1V2"),
            (0x03,"I_1V5"),
            (0x04,"I_1V8"),
            (0x05,"I_2V5"),
            (0x06,"I_3V3"),
            (0x07,"I_IN "),
            (0x08,"V_MGT"),
            (0x09,"V_INT"),
            (0x0A,"V_1V2"),
            (0x0B,"V_1V5"),
            (0x0C,"V_1V8"),
            (0x0D,"V_2V5"),
            (0x0E,"V_3V3"),
            (0x0F,"V_IN "),
            (0x10,"I_VTRx1"),
            (0x11,"I_VTRx2"),
            (0x17,"T1   "),
            (0x18,"T2   ")
        ]
    else:
        SCA_ADC_COUNTERS = [
            (0x00,"I_INT"),
            (0x01,"I_MGT"),
            (0x02,"I_1V2"),
            (0x03,"I_1V5"),
            (0x04,"I_1V8"),
            (0x05,"I_2V5"),
            (0x06,"I_3V3"),
            (0x07,"I_IN "),
            (0x08,"V_INT"),
            (0x09,"V_MGT"),
            (0x0A,"V_1V2"),
            (0x0B,"V_1V5"),
            (0x0C,"V_1V8"),
            (0x0D,"V_2V5"),
            (0x0E,"V_3V3"),
            (0x0F,"V_IN "),
            (0x10,"I_VTRx1"),
            (0x11,"I_VTRx2"),
            (0x17,"T1   "),
            (0x18,"T2   "),
            (0x1f,"T_INT")
        ]

    def __init__(self, comm):
        super(RUv0_CRU, self).__init__(comm)
        self.logger = logging.getLogger("RUv0 CRU")

        self.comm = comm
        self.wait_module = WishboneWait(moduleid=self.WAIT_MODULE, board_obj=self)
        self.status = WsStatus(moduleid=self.STATUS_MODULE, board_obj=self)
        self.master_monitor = WsMasterMonitor(moduleid=self.MASTER_MONITOR_MODULE, board_obj=self)
        self.sca = Sca_RU(moduleid=self.SCA_MODULE, board_obj=self)
        self.pa3 = proasic3.ProAsic3(sca=self.sca)
        #self.Pa3_FlashIF = proasic3_flash.ProAsic3Flash(sca=self.sca)
        #self.Pa3_SelmapIF = proasic3_selectmap.ProAsic3Selmap(sca=self.sca)

    def initialize(self):
        # activate GBTX transmission
        self.set_gbtx_forward_to_usb(0)
        self.initialize_gbtx()
        self.sca.initialize()
        self.set_gbtx_forward_to_usb(1)
        self.reset_counters()

    def initialize_gbtx(self, commitTransaction=True):
        NR_RETRIES = 100
        # set pattern mode 0
        self.write(self.GBT_FPGA_MODULE, 2, 0, commitTransaction=False)
        # reset GBT_FPGA
        self.write(self.GBT_FPGA_MODULE, 0, 0x1, commitTransaction=True)
        # set correct FIFO mode and reset error flags
        self.write(self.GBT_FPGA_MODULE, 0, 0x78, commitTransaction=commitTransaction)

        rx_ready = False
        for _ in range(NR_RETRIES):
            rx_ready = self.is_gbt_rx_ready()
            if rx_ready:
                break
            else:
                time.sleep(0.25)
        if not rx_ready:
            msg = "GBT_FPGA could not reset GBT_FPGA (RX_READY is False)"
            self.logger.error(msg)
            raise Exception(msg)

    def is_gbt_rx_ready(self):
        read = self.read(self.GBT_FPGA_MODULE, 0)

        return (read & (1<< 3)) > 0

    def send_gbtx_data_frame(self, data, commitTransaction=True):
        self.write(self.GBT_FPGA_MODULE, 11, data & 0xFFFF, commitTransaction=False)
        self.write(self.GBT_FPGA_MODULE, 12, data>>16, commitTransaction=False)
        self.write(self.GBT_FPGA_MODULE, 15, 0x8000, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def send_trigger(self, triggerType=0x10, bc=0xabc, orbit=0x43215678, commitTransaction=True):
        """Sends a trigger to the RUv1 through the GBTx

        NOTE: orbit is 32 bit in ITS upgrade but is limited to 31 bits for the CRU design"""
        assert triggerType | 0xFFF == 0xFFF
        assert bc | 0xFFF == 0xFFF
        assert orbit | 0x7FFFFFFF  == 0x7FFFFFFF
        self.write(self.GBT_FPGA_MODULE,11, (triggerType & 0xFFFF),commitTransaction=False)
        self.write(self.GBT_FPGA_MODULE,12, ((triggerType>>16)&0xFFFF),commitTransaction=False)
        self.write(self.GBT_FPGA_MODULE,13, (bc&0xFFF),commitTransaction=False)
        self.write(self.GBT_FPGA_MODULE,14, (orbit&0xFFFF),commitTransaction=False)
        self.write(self.GBT_FPGA_MODULE,15, (0x8000 | ((orbit>>16)&0x7FFF)),commitTransaction=commitTransaction)

    def send_start_of_triggered(self, bc=0xabc, orbit=0x43215678, commitTransaction=True):
        """Sends a SOT trigger"""
        triggerType = 1 << trigger.BitMap.SOT
        self.send_trigger(triggerType=triggerType, bc=bc, orbit=orbit,commitTransaction=commitTransaction)

    def send_end_of_triggered(self, bc=0xabc, orbit=0x43215678, commitTransaction=True):
        """Sends a EOT trigger"""
        triggerType = 1 << trigger.BitMap.EOT
        self.send_trigger(triggerType=triggerType, bc=bc, orbit=orbit,commitTransaction=commitTransaction)

    def send_start_of_continuous(self, bc=0xabc, orbit=0x43215678, commitTransaction=True):
        """Sends a SOC trigger"""
        triggerType = 1 << trigger.BitMap.SOC
        self.send_trigger(triggerType=triggerType, bc=bc, orbit=orbit,commitTransaction=commitTransaction)

    def send_heartbeat(self, bc=0xabc, orbit=0x43215678, commitTransaction=True):
        """Sends a SOC trigger"""
        triggerType = 1 << trigger.BitMap.HBa
        self.send_trigger(triggerType=triggerType, bc=bc, orbit=orbit,commitTransaction=commitTransaction)

    def send_end_of_continuous(self, bc=0xabc, orbit=0x43215678, commitTransaction=True):
        """Sends a EOC trigger"""
        triggerType = 1 << trigger.BitMap.EOC
        self.send_trigger(triggerType=triggerType, bc=bc, orbit=orbit,commitTransaction=commitTransaction)

    def write_gbtx(self, module, address, data, commitTransaction=True):
        """Writes to the gbtx interface on the RDO board"""
        assert module < 64
        self.write(mod=module, addr=address, data=data, commitTransaction=commitTransaction)

    def read_gbtx(self, module, address, commitTransaction=True):
        assert module < 64
        return self.read(mod=module, addr=address, commitTransaction=commitTransaction)

    def read_gbtx_data_from_usb(self,size, rawoutfile=None):
        """size is expressed in gbt packages"""
        results = []
        data = self.comm.read_dp2(size*3*4)
        if rawoutfile:
            rawoutfile.write(data)
        retries = 0
        max_retries = 10
        # GBT usb data is defined as multiple of 3 words (12 bytes), read more bytes
        while len(data) % 3 != 0 and retries < max_retries:
            data += self.comm.read_dp2(4)
            retries += 1
        #print(["{0:08X}".format(d) for d in data])
        if len(data) % 3 != 0:
            self.logger.error("RUv0_CRU.read_gbtx_datapath_from_usb: Could not read multiple of 3 words: Data loss?")
        for i in range(0,len(data),3):
            idx_data3 = i+0
            idx_data2 = i+1
            idx_data1 = i+2

            datavalid = data[idx_data3]>>31 == 1
            channel_data = bytearray(10)
            channel_data[0] = int((data[idx_data3] >>8)&0xFF)
            channel_data[1] = data[idx_data3]&0xFF
            for j in range(4):
                channel_data[5-j] = (data[idx_data2] >> (j*8))&0xFF
                channel_data[9-j] = (data[idx_data1] >> (j*8))&0xFF
            results.append((datavalid, channel_data))
        return results


    def wait(self, wait_value, commitTransaction=True):
        """Implements the wait function of the dctrl wishbone slave"""
        self.wait_module.wait(wait_value, commitTransaction=commitTransaction)

    def read_counters(self):
        for i in range(9,29):
            self.read(self.GBT_FPGA_MODULE,i,commitTransaction=False)
        self.flush()
        results = self.read_all()

        gbt_wr_counter = results[0] | (results[1]<<16)
        gbt_sop_counter = results[2] | (results[3]<<16)
        gbt_eop_counter = results[4] | (results[5]<<16)
        gbt_swt_counter = results[6] | (results[7]<<16)
        gbt_wr_swt_counter = results[8] | (results[9]<<16)
        gbt_data_valid_counter = results[10] | (results[11]<<16)
        gbt_swt_mismatch_counter0 = results[12] | (results[13]<<16)
        gbt_swt_mismatch_counter1 = results[14] | (results[15]<<16)
        gbt_swt_mismatch_counter2 = results[16] | (results[17]<<16)
        gbt_swt_mismatch_counter3 = results[18] | (results[19]<<16)
        counters = OrderedDict([
            ("gbt_wr_counter", gbt_wr_counter),
            ("gbt_sop_counter", gbt_sop_counter),
            ("gbt_eop_counter", gbt_eop_counter),
            ("gbt_swt_counter", gbt_swt_counter),
            ("gbt_wr_swt_counter", gbt_wr_swt_counter),
            ("gbt_data_valid_counter", gbt_data_valid_counter), # Gbt Write DV counter (nr Triggers)
            ("gbt_swt_mismatch_counter0", gbt_swt_mismatch_counter0),
            ("gbt_swt_mismatch_counter1", gbt_swt_mismatch_counter1),
            ("gbt_swt_mismatch_counter2", gbt_swt_mismatch_counter2),
            ("gbt_swt_mismatch_counter3", gbt_swt_mismatch_counter3)
        ])

        self.logger.debug("CRU write counter: {0}, sop counter: {1}, eop counter: {2}, swt counter: {3}".format)
        return counters

    def reset_counters(self):
        self.write(self.GBT_FPGA_MODULE, 3, 0xFFFF)

    def set_gbtx_forward_to_usb(self, value, commitTransaction=True):
        assert value in range(2)
        self.write(self.GBT_FPGA_MODULE, 4, value, commitTransaction=commitTransaction)

    def get_gbtx_forward_to_usb(self):
        return self.read(self.GBT_FPGA_MODULE, 4)

    def get_adc_names(self):
        return [name for ch,name in self.SCA_ADC_COUNTERS]

    def read_adcs(self):
        results = OrderedDict()
        for ch,name in self.SCA_ADC_COUNTERS:
            results[name] = self.sca.read_adc_channel(ch)
        return results

    def read_adcs_conv(self):
        results = OrderedDict()
        for ch,name in self.SCA_ADC_COUNTERS:
            if ch == 15:
                results[name] = 21.0 * self.sca.read_adc_channel(ch) / 4095.0
            elif ch == 31:
                results[name] = (716 - 1000 * self.sca.read_adc_channel(ch) / 4095.0) / 1.829
            elif ch == 23 or ch == 24:
                results[name] = 0.634286 * self.sca.read_adc_channel(ch) - 259.74
            elif ch == 16 or ch == 17:
                results[name] = 532.0 - 0.163 * self.sca.read_adc_channel(ch)
            elif ch < 13 and ch > 7:
                results[name] = 2.0 * self.sca.read_adc_channel(ch) / 4095.0
            else:
                results[name] = 5.0 * self.sca.read_adc_channel(ch) / 4095.0
        return results

    def dump_config(self):
        config_str = "-- RUv0_CRU configuration --\n"
        config_str += "-- Module {0} --\n".format(self.MASTER_MONITOR_MODULE)
        config_str += self.master_monitor.dump_config()

        config_str += "-- Module {0} --\n".format(self.STATUS_MODULE)
        config_str += self.status.dump_config()

        config_str += "-- Module {0} --\n".format(self.USB_IF_MODULE)
        config_str += self.usb_if.dump_config()

        return config_str

    def check_git_hash_and_date(self, expected_git_hash=None):
        """gets git hash and fw date"""
        self.status.check_git_hash_and_date(expected_git_hash)

    def get_dna_value(self, verbose):
        """Gets the FPGA DNA value"""
        self.status.get_dna_value(verbose)

    def get_microprocessor_counters(self, reg_num, reg_wid=32):
        """Gets the register values from SPI"""
        values = [0] * reg_num

        self.sca._write_spi(0x01, 0x00, reg_wid, 0)

        for i in range(reg_num-1):
            values[i] = self.sca._write_spi(0x01, 0x00, reg_wid, i+1)

        values[reg_num-1] = self.sca._write_spi(0x01, 0x00, reg_wid, 0)

        return values

    def set_test_pattern(self, value, commitTransaction=True):
        """Set the Tx/Rx test pattern"""
        assert (value | 0x7) == 0x7, "pattern value must be between 0 and 7"
        self.write(self.GBT_FPGA_MODULE, 2, value, commitTransaction=commitTransaction)

    def get_test_pattern(self):
        """Read test pattern value"""
        return(self.read(self.GBT_FPGA_MODULE, 2))

    def reset_gbt_fpga(self):
        "General Reset of the GBT_FPGA IP"
        self.write(self.GBT_FPGA_MODULE, 0, 0x1, commitTransaction=True)

    def reset_error_flags(self, commitTransaction=True):
        """Reset Latch Flags for DataErrorSeen and GBT ReadyLost"""
        self.write(self.GBT_FPGA_MODULE, 0, 0x18, commitTransaction=commitTransaction)

    def get_status_flags(self):
        """Read status and error flags for GBT_FPGA IP"""
        status_flags = self.read(self.GBT_FPGA_MODULE, 0)
        ret = OrderedDict([
            ("MGTLinkReady", status_flags & 0x1),
            ("RxWordClockReady", (status_flags >> 1) & 0x1),
            ("RxFrameClockReady", (status_flags >> 2) & 0x1),
            ("GbtRxReady", (status_flags >> 3) & 0x1),
            ("RxIsData", (status_flags >> 4) & 0x1),
            ("GbtRxReadyLostFlag", (status_flags >> 5) & 0x1),
            ("GbtRxDataErrorseenFlag", (status_flags >> 6) & 0x1)
        ])
        return ret

    def get_data_error_counter(self):
        self.read(self.GBT_FPGA_MODULE, 3, commitTransaction=False)
        self.read(self.GBT_FPGA_MODULE, 4, commitTransaction=False)
        self.flush()
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def get_link_error_counter(self):
        self.read(self.GBT_FPGA_MODULE, 5, commitTransaction=False)
        self.read(self.GBT_FPGA_MODULE, 6, commitTransaction=False)
        self.flush()
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def get_link_error_counter_dis(self):
        self.read(self.GBT_FPGA_MODULE, 7, commitTransaction=False)
        self.read(self.GBT_FPGA_MODULE, 8, commitTransaction=False)
        self.flush()
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def get_fec_counter(self):
        self.read(self.GBT_FPGA_MODULE, 29, commitTransaction=False)
        self.read(self.GBT_FPGA_MODULE, 30, commitTransaction=False)
        self.flush()
        results = self.read_all()
        return results[0] | (results[1] << 16)

    def get_bitsmodified_counter(self):
        self.read(self.GBT_FPGA_MODULE, 31, commitTransaction=False)
        self.read(self.GBT_FPGA_MODULE, 32, commitTransaction=False)
        self.flush()
        results = self.read_all()
        return results[0] | (results[1] << 16)
