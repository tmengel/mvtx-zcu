# I2C Interface module

The module in this directory interfaces up to 8 I2C devices to the wishbone bus.
The core of the firmware is based on the wishbone slave I2C-master core from
Richard Herveille from opencores. This interface is coded in the files "i2c_master_top.vhd" (top entity),
"i2c_master_byte_ctrl.vhd", and "i2c_master_bit_ctrl.vhd", and is described in the document "RUv0a/doc/I2C_specs.doc"
The wishbone slave of the top entity is then wrapped in the module "i2c_wrapper.vhd" to provide a wishbone
slave interface for full I2C transactions of a few of the I2C devices at various wishbone slave addresses.

The currently implemented I2C transactions at the various wishbone addresses are (see the PowerUnit User guide for details of the
functionality of the various PowerUnit devices):

 * 0x00:	(r/w) GBTx register address (indirect addressing)
 * 0x01:	(r/w) GBTx register pointed to by address in 0x00. The address auto-increments after each read/write
 * 0x02:	(r/w) PowerUnit I/O module
 * 0x03 - 0x07:	(w) PowerUnit Current threshold DAC. 0x03 sets all 4 channels, 0x04-0x07 sets the individual channels 0 - 3
 * 0x08 - 0x0b:	(w) PowerUnit Output Voltage Potentiometer channels 0 - 3
 * 0x0c:	(w) Store/recall PowerUnit Voltage Potentiometer values (see PowerUnit User guide for data values to use)
 * 0x0d:	(w) PowerUnit Bias Voltage Potentiometer
 * 0x10 - 0x17:	(r/w) Write to any address configures ADC (see UserGuide); read ADC value for channels 0 - 7

 All other I2C devices are currently not implemented.


 ## Dependencies

 - core
 - wishbone
