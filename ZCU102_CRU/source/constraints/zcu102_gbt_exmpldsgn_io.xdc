##============================================================================##
##=============== Xilinx design constraints (XDC) information ================##
##============================================================================##
##
## Company:               CERN
## Engineer:              Hampus Sandberg (hampus.sandber@cern.ch)
##
## Project Name:          GBT-FPGA
## XDC File Name:         ZCU102 - GBT Bank example design I/O
##
## Target Device:         ZCU102 (Xilinx Zynq UltraScale+ MPSoC)
## Tool version:          Vivado 2020.2
##
## Additional Comments:   PART is xczu9eg-ffvb1156-2-e
##
##============================================================================##
##============================================================================##
##------------------------------------------------------------------------------
## Asynchronous reset
##------------------------------------------------------------------------------
set_property PACKAGE_PIN AM13 [get_ports CPU_RESET]
set_property IOSTANDARD LVCMOS33 [get_ports CPU_RESET]

##------------------------------------------------------------------------------
## Clock - 125 MHz
##------------------------------------------------------------------------------
set_property IOSTANDARD LVDS_25 [get_ports CLK_125_N]
set_property PACKAGE_PIN G21 [get_ports CLK_125_P]
set_property PACKAGE_PIN F21 [get_ports CLK_125_N]
set_property IOSTANDARD LVDS_25 [get_ports CLK_125_P]

##------------------------------------------------------------------------------
## SFP Si5328 clock - 120 MHz
##------------------------------------------------------------------------------
set_property PACKAGE_PIN B9 [get_ports SFP_SI5328_OUT_C_N]
set_property PACKAGE_PIN B10 [get_ports SFP_SI5328_OUT_C_P]

##------------------------------------------------------------------------------
## SFP serial data
##------------------------------------------------------------------------------
set_property PACKAGE_PIN D2 [get_ports SFP0_RX_P]
set_property PACKAGE_PIN D1 [get_ports SFP0_RX_N]
set_property PACKAGE_PIN E4 [get_ports SFP0_TX_P]
set_property PACKAGE_PIN E3 [get_ports SFP0_TX_N]

set_property PACKAGE_PIN A12 [get_ports SFP0_TX_DISABLE_N]
set_property IOSTANDARD LVCMOS33 [get_ports SFP0_TX_DISABLE_N]

set_property PACKAGE_PIN AG14     [get_ports "GPIO_LED[0]"] ;# Bank  44 VCCO - VCC3V3   - IO_L10P_AD2P_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[0]"] ;# Bank  44 VCCO - VCC3V3   - IO_L10P_AD2P_44
set_property PACKAGE_PIN AF13     [get_ports "GPIO_LED[1]"] ;# Bank  44 VCCO - VCC3V3   - IO_L9N_AD3N_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[1]"] ;# Bank  44 VCCO - VCC3V3   - IO_L9N_AD3N_44
set_property PACKAGE_PIN AE13     [get_ports "GPIO_LED[2]"] ;# Bank  44 VCCO - VCC3V3   - IO_L9P_AD3P_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[2]"] ;# Bank  44 VCCO - VCC3V3   - IO_L9P_AD3P_44
set_property PACKAGE_PIN AJ14     [get_ports "GPIO_LED[3]"] ;# Bank  44 VCCO - VCC3V3   - IO_L8N_HDGC_AD4N_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[3]"] ;# Bank  44 VCCO - VCC3V3   - IO_L8N_HDGC_AD4N_44
set_property PACKAGE_PIN AJ15     [get_ports "GPIO_LED[4]"] ;# Bank  44 VCCO - VCC3V3   - IO_L8P_HDGC_AD4P_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[4]"] ;# Bank  44 VCCO - VCC3V3   - IO_L8P_HDGC_AD4P_44
set_property PACKAGE_PIN AH13     [get_ports "GPIO_LED[5]"] ;# Bank  44 VCCO - VCC3V3   - IO_L7N_HDGC_AD5N_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[5]"] ;# Bank  44 VCCO - VCC3V3   - IO_L7N_HDGC_AD5N_44
set_property PACKAGE_PIN AH14     [get_ports "GPIO_LED[6]"] ;# Bank  44 VCCO - VCC3V3   - IO_L7P_HDGC_AD5P_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[6]"] ;# Bank  44 VCCO - VCC3V3   - IO_L7P_HDGC_AD5P_44
set_property PACKAGE_PIN AL12     [get_ports "GPIO_LED[7]"] ;# Bank  44 VCCO - VCC3V3   - IO_L6N_HDGC_AD6N_44
set_property IOSTANDARD  LVCMOS33 [get_ports "GPIO_LED[7]"] ;# Bank  44 VCCO - VCC3V3   - IO_L6N_HDGC_AD6N_44
