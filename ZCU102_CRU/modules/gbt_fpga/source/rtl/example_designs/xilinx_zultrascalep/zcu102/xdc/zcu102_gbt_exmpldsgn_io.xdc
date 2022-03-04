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
set_false_path -through [get_nets CPU_RESET]
set_property PACKAGE_PIN AM13 [get_ports CPU_RESET]
set_property IOSTANDARD LVCMOS33 [get_ports CPU_RESET]

##------------------------------------------------------------------------------
## Clock - 125 MHz
##------------------------------------------------------------------------------
set_property IOSTANDARD LVDS_25 [get_ports CLK_125_N]
set_property PACKAGE_PIN G21 [get_ports CLK_125_P]
set_property PACKAGE_PIN F21 [get_ports CLK_125_N]
set_property IOSTANDARD LVDS_25 [get_ports CLK_125_P]

create_clock -period 8.000 -name CLK_125 [get_ports CLK_125_P]
set_clock_groups -asynchronous -group CLK_125


##------------------------------------------------------------------------------
## SFP Si5328 clock - 120 MHz
##------------------------------------------------------------------------------
set_property PACKAGE_PIN B9 [get_ports SFP_SI5328_OUT_C_N]
set_property PACKAGE_PIN B10 [get_ports SFP_SI5328_OUT_C_P]

create_clock -period 8.333 -name SFP_SI5328_CLOCK [get_ports SFP_SI5328_OUT_C_P]
set_clock_groups -asynchronous -group SFP_SI5328_CLOCK

##------------------------------------------------------------------------------
## SFP serial data
##------------------------------------------------------------------------------
set_property PACKAGE_PIN D2 [get_ports SFP0_RX_P]
set_property PACKAGE_PIN D1 [get_ports SFP0_RX_N]
set_property PACKAGE_PIN E4 [get_ports SFP0_TX_P]
set_property PACKAGE_PIN E3 [get_ports SFP0_TX_N]

set_property PACKAGE_PIN A12 [get_ports SFP0_TX_DISABLE_N]
set_property IOSTANDARD LVCMOS33 [get_ports SFP0_TX_DISABLE_N]


