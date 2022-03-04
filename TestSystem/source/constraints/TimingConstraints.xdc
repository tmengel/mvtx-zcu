# Clock constraints for clocks provided as inputs to the core
# Note: the IP core-level XDC constrains clocks produced by the core, which drive user clocks via helper blocks
# ----------------------------------------------------------------------------------------------------------------------
set T_LHC_CLK 24.952
set T_LHC_CLK_div2 [expr $T_LHC_CLK/2]
set T_LHC_160 [expr $T_LHC_CLK/4]
set T_LHC_160_div2 [expr $T_LHC_160/2]

create_clock -name clk_freerun -period 6.25 [get_ports LOCAL_CLK_dp[2]]
create_clock -name clk_mgtrefclk1_x0y4_p -period 6.25 [get_ports LOCAL_CLK_dp[1]]
create_clock -name clk_mgtrefclk1_x1y2_p -period 6.25 [get_ports LOCAL_CLK_dp[0]]

# GBTx DCLKs: 40MHz
create_clock -period $T_LHC_CLK -name GBTX0_DCLK0 [get_ports {GBTX0_DCLK_dp[0]}]
create_clock -period $T_LHC_160 -name GBTX0_DCLK1 [get_ports {GBTX0_DCLK_dp[1]}]
create_clock -period $T_LHC_CLK -name GBTX2_DCLK0 [get_ports {GBTX2_DCLK_dp[0]}]
create_clock -period $T_LHC_160 -name GBTX2_DCLK1 [get_ports {GBTX2_DCLK_dp[1]}]

# False path constraints
# ----------------------------------------------------------------------------------------------------------------------
set_false_path -to [get_cells -hierarchical -filter {NAME =~ "*bit_synchronizer*inst/i_in_meta_reg"}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ "*reset_synchronizer*inst/rst_in_*_reg"}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ "*gtwiz_userclk_tx_inst/*gtwiz_userclk_tx_active_*_reg"}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ "*gtwiz_userclk_rx_inst/*gtwiz_userclk_rx_active_*_reg"}]

###############################
##### FX3 #####################
###############################
# FX3 PCLK coming out of ODDR:
create_generated_clock -name CLKFX3 -source [get_pins INST_fabric_top/INST_usb_if/ODDR_inst/C] \
 		       -invert -multiply_by 1 [get_port FX3_PCLK];

set destination_clock CLKFX3;		# Name of destination clock
set tsu               2.000;            # Destination device setup time requirement
set thd               0.500;            # Destination device hold time requirement
set trce_dly_max      0.000;            # Maximum board trace delay
set trce_dly_min      0.000;            # Minimum board trace delay
set output_ports      {FX3_DQ[*] FX3_CTL[*]};   # List of output ports

# # Output Delay Constraint
set_output_delay -clock $destination_clock -max [expr $trce_dly_max + $tsu] [get_ports $output_ports];
set_output_delay -clock $destination_clock -min [expr $trce_dly_min - $thd] [get_ports $output_ports];

# # Report Timing Template
# # report_timing -to [get_ports $output_ports] -max_paths 20 -nworst 1 -delay_type min_max \
# # -name sys_sync_rise_out -file sys_sync_rise_out.txt;

# ### Inputs ###

create_generated_clock -name CLK100       [get_pins INST_clock_generator/INST_mmcm_adv1/CLKOUT2]
# #set input_clock     INST_mmcm_adv1_n_8;   # Name of input clock
set input_clock     CLK100;         # Name of input clock
set tco_max         5.000;          # Maximum clock to out delay (external device)
set tco_min         2.000;          # Minimum clock to out delay (external device)
set trce_dly_max    0.000;          # Maximum board trace delay
set trce_dly_min    0.000;          # Minimum board trace delay
set input_ports     {FX3_DQ[*] FX3_CTL[4] FX3_CTL[5] \
     FX3_CTL[6] FX3_CTL[8]};  # List of input ports

# # Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $tco_max + $trce_dly_max] [get_ports $input_ports];
set_input_delay -clock $input_clock -min [expr $tco_min + $trce_dly_min] [get_ports $input_ports];

#############################################################################
# Report Timing Template
# report_timing -from [get_ports $input_ports] -max_paths 20 -nworst 1 -delay_type min_max \
# -name sys_sync_rise_in  -file sys_sync_rise_in.txt;

################
### GBTx #######
################
# clock groups:
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {GBTX0_DCLK0 GBTX0_DCLK1}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {GBTX2_DCLK0 GBTX2_DCLK1}]

# Clock group constraint to ensure correct clock skew for ISERDES
set_property CLOCK_DELAY_GROUP ioclockGroup_rx0 [get_nets "INST_fabric_top/INST_gbtx_controller_01/*macros/CLK_DIV*"]
set_property CLOCK_DELAY_GROUP ioclockGroup_rx2 [get_nets "INST_fabric_top/INST_gbtx_controller_2/*macros/CLK_DIV*"]


##################
### GBTx PORTs ###
##################

# GBTx0
create_clock -period $T_LHC_160_div2 -name VIRTUAL_GBTX0_DCLK
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -max 2.5 [get_ports {GBTX0_DOUT_dp[*]}]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -min 2.0 [get_ports {GBTX0_DOUT_dp[*]}]
set_output_delay -clock [get_clocks VIRTUAL_GBTX0_DCLK] -max -4.5 [get_ports {GBTX0_DIN_dp[*]}]
set_output_delay -clock [get_clocks VIRTUAL_GBTX0_DCLK] -min -3.5 [get_ports {GBTX0_DIN_dp[*]}]

set_output_delay -clock [get_clocks GBTX0_DCLK0] -min -add_delay -3.0 [get_ports GBTX0_TXDATAVALID_A]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -max -add_delay  3.0 [get_ports GBTX0_TXDATAVALID_A]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -min -add_delay -3.0 [get_ports GBTX0_TXDATAVALID_B]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -max -add_delay  3.0 [get_ports GBTX0_TXDATAVALID_B]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -min -add_delay -3.0 [get_ports GBTX0_TXDATAVALID_C]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -max -add_delay  3.0 [get_ports GBTX0_TXDATAVALID_C]

set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -max 2.5 [get_ports GBTX0_RXDATAVALID_A]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -min 2.0 [get_ports GBTX0_RXDATAVALID_A]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -max 2.5 [get_ports GBTX0_RXDATAVALID_B]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -min 2.0 [get_ports GBTX0_RXDATAVALID_B]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -max 2.5 [get_ports GBTX0_RXDATAVALID_C]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX0_DCLK] -min 2.0 [get_ports GBTX0_RXDATAVALID_C]

# GBTx1
create_clock -period $T_LHC_160_div2 -name VIRTUAL_GBTX1_DCLK
set_output_delay -clock [get_clocks VIRTUAL_GBTX1_DCLK] -max -4.5 [get_ports {GBTX1_DIN_dp[*]}]
set_output_delay -clock [get_clocks VIRTUAL_GBTX1_DCLK] -min -3.5 [get_ports {GBTX1_DIN_dp[*]}]

set_output_delay -clock [get_clocks GBTX0_DCLK0] -min -add_delay -3.0 [get_ports GBTX1_TXDATAVALID_A]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -max -add_delay  3.0 [get_ports GBTX1_TXDATAVALID_A]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -min -add_delay -3.0 [get_ports GBTX1_TXDATAVALID_B]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -max -add_delay  3.0 [get_ports GBTX1_TXDATAVALID_B]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -min -add_delay -3.0 [get_ports GBTX1_TXDATAVALID_C]
set_output_delay -clock [get_clocks GBTX0_DCLK0] -max -add_delay  3.0 [get_ports GBTX1_TXDATAVALID_C]

# GBTx2
create_clock -period $T_LHC_160_div2 -name VIRTUAL_GBTX2_DCLK
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -max 2.5 [get_ports {GBTX2_DOUT_dp[*]}]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -min 2.0 [get_ports {GBTX2_DOUT_dp[*]}]
set_output_delay -clock [get_clocks VIRTUAL_GBTX2_DCLK] -max -4.5 [get_ports {GBTX2_DIN_dp[*]}]
set_output_delay -clock [get_clocks VIRTUAL_GBTX2_DCLK] -min -2.5 [get_ports {GBTX2_DIN_dp[*]}]

set_output_delay -clock [get_clocks GBTX2_DCLK0] -min -add_delay -3.0 [get_ports GBTX2_TXDATAVALID_A]
set_output_delay -clock [get_clocks GBTX2_DCLK0] -max -add_delay  3.0 [get_ports GBTX2_TXDATAVALID_A]
set_output_delay -clock [get_clocks GBTX2_DCLK0] -min -add_delay -3.0 [get_ports GBTX2_TXDATAVALID_B]
set_output_delay -clock [get_clocks GBTX2_DCLK0] -max -add_delay  3.0 [get_ports GBTX2_TXDATAVALID_B]
set_output_delay -clock [get_clocks GBTX2_DCLK0] -min -add_delay -3.0 [get_ports GBTX2_TXDATAVALID_C]
set_output_delay -clock [get_clocks GBTX2_DCLK0] -max -add_delay  3.0 [get_ports GBTX2_TXDATAVALID_C]

set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -max 2.5 [get_ports GBTX2_RXDATAVALID_A]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -min 2.0 [get_ports GBTX2_RXDATAVALID_A]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -max 2.5 [get_ports GBTX2_RXDATAVALID_B]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -min 2.0 [get_ports GBTX2_RXDATAVALID_B]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -max 2.5 [get_ports GBTX2_RXDATAVALID_C]
set_input_delay  -clock [get_clocks VIRTUAL_GBTX2_DCLK] -min 2.0 [get_ports GBTX2_RXDATAVALID_C]
