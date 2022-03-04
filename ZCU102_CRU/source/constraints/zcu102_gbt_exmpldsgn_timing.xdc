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

##------------------------------------------------------------------------------
## Clock - 125 MHz
##------------------------------------------------------------------------------
create_clock -period 8.000 -name CLK_125 [get_ports CLK_125_P]
set_clock_groups -asynchronous -group CLK_125


##------------------------------------------------------------------------------
## SFP Si5328 clock - 120 MHz
##------------------------------------------------------------------------------
create_clock -period 8.333 -name SFP_SI5328_CLOCK [get_ports SFP_SI5328_OUT_C_P]
set_clock_groups -asynchronous -group SFP_SI5328_CLOCK
