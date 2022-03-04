#!/usr/bin/env python3
"""SCA test routines"""

import logging
import os
import errno
import time

import testbench

# instantiate a testbench object and initialize it
tb = testbench.Testbench()
tb.setup_standalone()
tb.rdo.comm.discardall_dp1(20)

# setup logging
logdir = os.path.join(os.getcwd(), 'results')
try:
    os.makedirs(logdir)
except OSError as e:
    if e.errno != errno.EEXIST:
        raise

serial_nr = input("Enter RU serial number:")
logfile_name = "results_" + serial_nr[-4:] + ".log"

log_file = os.path.join(logdir, logfile_name)

fh = logging.FileHandler(log_file)
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

fh.setFormatter(formatter)

# add this as a log handler for the testbench object
tb.logger.addHandler(fh)

tb.logger.info("Start testSCA")
tb.logger.info("Board serial number = {}".format(serial_nr))
tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)

tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
time.sleep(0.5)
lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
if lock_status == 15:
    tb.logger.info("GBTx0 locked to CRU")
else:
    tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))

tb.cru.sca.initialize()
adc_vals = tb.cru.read_adcs_conv()

tb.logger.info("Now testing SCA-I2C  lines to Xilinx")
I2Cerrors = 0
for i in range(256):
    tb.cru.sca.write_us_i2c(i)
    i2cread = tb.cru.sca.read_us_i2c()
    if i != i2cread:
        tb.logger.error("Expected = {}, received = {}".format(i, i2cread))
        I2Cerrors += 1
    elif (i + 1) % 64 == 0:
        tb.logger.info("Expected = {}, received = {}".format(i, i2cread))

tb.logger.info("Now testing SCA-GPIO lines to Xilinx")
tb.cru.sca.set_gpio_direction(0xF03F)
gpio_errors = 0
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00000):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00000, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.cru.sca.write_gpio(0x1)
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00041):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00041, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.cru.sca.write_gpio(0x2)
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00082):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00082, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.cru.sca.write_gpio(0x4)
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00104):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00104, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.cru.sca.write_gpio(0x8)
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00208):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00208, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.cru.sca.write_gpio(0x10)
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00410):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00410, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.cru.sca.write_gpio(0x20)
gpio_read = tb.cru.sca.read_gpio()
if ((gpio_read | 0xfff00000) == 0xfff00820):
    tb.logger.info("read = {}".format(hex(gpio_read)))
else:
    tb.logger.error("expected=0xXXX00820, read = {}".format(hex(gpio_read)))
    gpio_errors += 1

tb.logger.info("Now testing SCA-GPIO lines to PA3")
for i in range(16):
    tb.cru.sca.write_gpio(i << 12)
    varo = (tb.cru.sca.read_gpio() >> 16) & 0xF
    if (varo == i):
        tb.logger.info("read = {}".format(varo))
    else:
        tb.logger.error("expected={}, read = {}".format(i, varo))
        gpio_errors += 1

tb.logger.info("Now reading Ultrascale IDCODE via SCA JTAG")

jtag_error = False
expected_US_idcode = 0x3919093
idcode = tb.cru.sca.do_jtag_idcode_chained()
tb.logger.info("IDCODE = {}".format(hex(idcode)))
# Bits 31:28 are "don't care"" according to Kintex Ultrascale Configuration Userguide"
if (idcode & 0x0fffffff) != expected_US_idcode:
    tb.logger.error("Expected {} for Kintex Ultrascale, got {}".format(
        hex(expected_US_idcode), hex(idcode)))
    jtag_error = True

for adc_name, adc_val in adc_vals.items():
    tb.logger.info("{} = {}".format(adc_name, adc_val))

if not (4.8 < adc_vals['V_IN '] < 12.0):
    tb.logger.error("V_IN out of range!!!")

if not (3.26 < adc_vals['V_3V3'] < 3.34):
    tb.logger.error("3.3V out of range!!!")
if not (2.46 < adc_vals['V_2V5'] < 2.51):
    tb.logger.error("2.5V out of range!!!")
if not (1.77 < adc_vals['V_1V8'] < 1.81):
    tb.logger.error("1.8V out of range!!!")
if not (1.5 < adc_vals['V_1V5'] < 1.53):
    tb.logger.error("1.5V out of range!!!")
if not (1.197 < adc_vals['V_1V2'] < 1.22):
    tb.logger.error("1.2V out of range!!!")
if not (1.0 < adc_vals['V_MGT'] < 1.03):
    tb.logger.error("V_MGT out of range!!!")
if not (0.945 < adc_vals['V_INT'] < 0.965):
    tb.logger.error("V_INT out of range!!!")

if not (1.0 < adc_vals['I_IN '] < 3.3):
    tb.logger.error("I_IN out of range!!!")

if not (0.41 < adc_vals['I_3V3'] < 0.55):
    tb.logger.error("I_3.3V out of range!!!")
if not (0.67 < adc_vals['I_2V5'] < 0.76):
    tb.logger.error("I_2.5V out of range!!!")
if not (0.80 < adc_vals['I_1V8'] < 1.00):
    tb.logger.error("I_1.8V out of range!!!")
if not (1.41 < adc_vals['I_1V5'] < 2.3):
    tb.logger.error("I_1.5V out of range!!!")
if not (1.3 < adc_vals['I_1V2'] < 1.5):
    tb.logger.error("I_1.2V out of range!!!")
if not (2.0 < adc_vals['I_MGT'] < 2.45):
    tb.logger.error("I_MGT out of range!!!")
if not (0.60 < adc_vals['I_INT'] < 1.52):
    tb.logger.error("I_INT out of range!!!")

if not (170.0 < adc_vals['I_VTRx1'] < 300.0):
    tb.logger.error("I_VTRx1 out of range!!!")
if not (10 < adc_vals['I_VTRx2'] < 260):  # JS: changed range
    tb.logger.error("I_VTRx2 out of range!!!")

if not (2.0 < adc_vals['T1   '] < 60.0):
    tb.logger.error("T1 out of range!!!")
if not (-1.0 < adc_vals['T2   '] < 60.0):
    tb.logger.error("T2 out of range!!!")

if jtag_error:
    tb.logger.error("JTAG ID read failed, did you check that the JTAG programmer(s) were disconnected?")

if not (gpio_errors == 0):
    tb.logger.error("i number of SCA GPIO ERRORS = {}".format(gpio_errors))

if not (I2Cerrors == 0):
    tb.logger.error("i number of SCA I2C  ERRORS = {}".format(I2Cerrors))
