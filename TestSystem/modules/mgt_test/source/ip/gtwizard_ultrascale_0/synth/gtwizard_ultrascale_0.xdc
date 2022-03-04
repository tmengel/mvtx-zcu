#------------------------------------------------------------------------------
#  (c) Copyright 2013-2018 Xilinx, Inc. All rights reserved.
#
#  This file contains confidential and proprietary information
#  of Xilinx, Inc. and is protected under U.S. and
#  international copyright and other intellectual property
#  laws.
#
#  DISCLAIMER
#  This disclaimer is not a license and does not grant any
#  rights to the materials distributed herewith. Except as
#  otherwise provided in a valid license issued to you by
#  Xilinx, and to the maximum extent permitted by applicable
#  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
#  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
#  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
#  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
#  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
#  (2) Xilinx shall not be liable (whether in contract or tort,
#  including negligence, or under any other theory of
#  liability) for any loss or damage of any kind or nature
#  related to, arising under or in connection with these
#  materials, including for any direct, or any indirect,
#  special, incidental, or consequential loss or damage
#  (including loss of data, profits, goodwill, or any type of
#  loss or damage suffered as a result of any action brought
#  by a third party) even if such damage or loss was
#  reasonably foreseeable or Xilinx had been advised of the
#  possibility of the same.
#
#  CRITICAL APPLICATIONS
#  Xilinx products are not designed or intended to be fail-
#  safe, or for use in any application requiring fail-safe
#  performance, such as life-support or safety devices or
#  systems, Class III medical devices, nuclear facilities,
#  applications related to the deployment of airbags, or any
#  other applications that could lead to death, personal
#  injury, or severe property or environmental damage
#  (individually and collectively, "Critical
#  Applications"). Customer assumes the sole risk and
#  liability of any use of Xilinx products in Critical
#  Applications, subject only to applicable laws and
#  regulations governing limitations on product liability.
#
#  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
#  PART OF THIS FILE AT ALL TIMES.
#------------------------------------------------------------------------------


# UltraScale FPGAs Transceivers Wizard IP core-level XDC file
# ----------------------------------------------------------------------------------------------------------------------

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y12
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y12 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[3].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin R34 [get_ports gthrxn_in[0]]
#set_property package_pin R33 [get_ports gthrxp_in[0]]
#set_property package_pin T32 [get_ports gthtxn_out[0]]
#set_property package_pin T31 [get_ports gthtxp_out[0]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y13
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y13 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[3].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin N34 [get_ports gthrxn_in[1]]
#set_property package_pin N33 [get_ports gthrxp_in[1]]
#set_property package_pin P32 [get_ports gthtxn_out[1]]
#set_property package_pin P31 [get_ports gthtxp_out[1]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y14
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y14 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[3].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin L34 [get_ports gthrxn_in[2]]
#set_property package_pin L33 [get_ports gthrxp_in[2]]
#set_property package_pin M32 [get_ports gthtxn_out[2]]
#set_property package_pin M31 [get_ports gthtxp_out[2]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y15
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y15 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[3].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin J34 [get_ports gthrxn_in[3]]
#set_property package_pin J33 [get_ports gthrxp_in[3]]
#set_property package_pin K32 [get_ports gthtxn_out[3]]
#set_property package_pin K31 [get_ports gthtxp_out[3]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y16
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y16 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin G34 [get_ports gthrxn_in[4]]
#set_property package_pin G33 [get_ports gthrxp_in[4]]
#set_property package_pin H32 [get_ports gthtxn_out[4]]
#set_property package_pin H31 [get_ports gthtxp_out[4]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y17
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y17 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin F32 [get_ports gthrxn_in[5]]
#set_property package_pin F31 [get_ports gthrxp_in[5]]
#set_property package_pin G30 [get_ports gthtxn_out[5]]
#set_property package_pin G29 [get_ports gthtxp_out[5]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y18
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y18 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin E34 [get_ports gthrxn_in[6]]
#set_property package_pin E33 [get_ports gthrxp_in[6]]
#set_property package_pin D32 [get_ports gthtxn_out[6]]
#set_property package_pin D31 [get_ports gthtxp_out[6]]

# Commands for enabled transceiver GTHE3_CHANNEL_X0Y19
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X0Y19 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin C34 [get_ports gthrxn_in[7]]
#set_property package_pin C33 [get_ports gthrxp_in[7]]
#set_property package_pin B32 [get_ports gthtxn_out[7]]
#set_property package_pin B31 [get_ports gthtxp_out[7]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y0
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y0 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[24].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AP1 [get_ports gthrxn_in[8]]
#set_property package_pin AP2 [get_ports gthrxp_in[8]]
#set_property package_pin AN3 [get_ports gthtxn_out[8]]
#set_property package_pin AN4 [get_ports gthtxp_out[8]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y1
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y1 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[24].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AM1 [get_ports gthrxn_in[9]]
#set_property package_pin AM2 [get_ports gthrxp_in[9]]
#set_property package_pin AM5 [get_ports gthtxn_out[9]]
#set_property package_pin AM6 [get_ports gthtxp_out[9]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y2
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y2 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[24].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AK1 [get_ports gthrxn_in[10]]
#set_property package_pin AK2 [get_ports gthrxp_in[10]]
#set_property package_pin AL3 [get_ports gthtxn_out[10]]
#set_property package_pin AL4 [get_ports gthtxp_out[10]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y3
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y3 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[24].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AJ3 [get_ports gthrxn_in[11]]
#set_property package_pin AJ4 [get_ports gthrxp_in[11]]
#set_property package_pin AK5 [get_ports gthtxn_out[11]]
#set_property package_pin AK6 [get_ports gthtxp_out[11]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y4
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y4 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[25].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AH1 [get_ports gthrxn_in[12]]
#set_property package_pin AH2 [get_ports gthrxp_in[12]]
#set_property package_pin AH5 [get_ports gthtxn_out[12]]
#set_property package_pin AH6 [get_ports gthtxp_out[12]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y5
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y5 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[25].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AF1 [get_ports gthrxn_in[13]]
#set_property package_pin AF2 [get_ports gthrxp_in[13]]
#set_property package_pin AG3 [get_ports gthtxn_out[13]]
#set_property package_pin AG4 [get_ports gthtxp_out[13]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y6
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y6 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[25].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AD1 [get_ports gthrxn_in[14]]
#set_property package_pin AD2 [get_ports gthrxp_in[14]]
#set_property package_pin AE3 [get_ports gthtxn_out[14]]
#set_property package_pin AE4 [get_ports gthtxp_out[14]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y7
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y7 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[25].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin AB1 [get_ports gthrxn_in[15]]
#set_property package_pin AB2 [get_ports gthrxp_in[15]]
#set_property package_pin AC3 [get_ports gthtxn_out[15]]
#set_property package_pin AC4 [get_ports gthtxp_out[15]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y8
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y8 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[26].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin Y1 [get_ports gthrxn_in[16]]
#set_property package_pin Y2 [get_ports gthrxp_in[16]]
#set_property package_pin AA3 [get_ports gthtxn_out[16]]
#set_property package_pin AA4 [get_ports gthtxp_out[16]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y9
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y9 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[26].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin V1 [get_ports gthrxn_in[17]]
#set_property package_pin V2 [get_ports gthrxp_in[17]]
#set_property package_pin W3 [get_ports gthtxn_out[17]]
#set_property package_pin W4 [get_ports gthtxp_out[17]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y10
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y10 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[26].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin T1 [get_ports gthrxn_in[18]]
#set_property package_pin T2 [get_ports gthrxp_in[18]]
#set_property package_pin U3 [get_ports gthtxn_out[18]]
#set_property package_pin U4 [get_ports gthtxp_out[18]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y11
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y11 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[26].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin P1 [get_ports gthrxn_in[19]]
#set_property package_pin P2 [get_ports gthrxp_in[19]]
#set_property package_pin R3 [get_ports gthtxn_out[19]]
#set_property package_pin R4 [get_ports gthtxp_out[19]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y12
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y12 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[27].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin M1 [get_ports gthrxn_in[20]]
#set_property package_pin M2 [get_ports gthrxp_in[20]]
#set_property package_pin N3 [get_ports gthtxn_out[20]]
#set_property package_pin N4 [get_ports gthtxp_out[20]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y13
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y13 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[27].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin K1 [get_ports gthrxn_in[21]]
#set_property package_pin K2 [get_ports gthrxp_in[21]]
#set_property package_pin L3 [get_ports gthtxn_out[21]]
#set_property package_pin L4 [get_ports gthtxp_out[21]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y14
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y14 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[27].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin H1 [get_ports gthrxn_in[22]]
#set_property package_pin H2 [get_ports gthrxp_in[22]]
#set_property package_pin J3 [get_ports gthtxn_out[22]]
#set_property package_pin J4 [get_ports gthtxp_out[22]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y15
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y15 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[27].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin F1 [get_ports gthrxn_in[23]]
#set_property package_pin F2 [get_ports gthrxp_in[23]]
#set_property package_pin G3 [get_ports gthtxn_out[23]]
#set_property package_pin G4 [get_ports gthtxp_out[23]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y16
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y16 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[28].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin E3 [get_ports gthrxn_in[24]]
#set_property package_pin E4 [get_ports gthrxp_in[24]]
#set_property package_pin F5 [get_ports gthtxn_out[24]]
#set_property package_pin F6 [get_ports gthtxp_out[24]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y17
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y17 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[28].*gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin D1 [get_ports gthrxn_in[25]]
#set_property package_pin D2 [get_ports gthrxp_in[25]]
#set_property package_pin D5 [get_ports gthtxn_out[25]]
#set_property package_pin D6 [get_ports gthtxp_out[25]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y18
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y18 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[28].*gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin B1 [get_ports gthrxn_in[26]]
#set_property package_pin B2 [get_ports gthrxp_in[26]]
#set_property package_pin C3 [get_ports gthtxn_out[26]]
#set_property package_pin C4 [get_ports gthtxp_out[26]]

# Commands for enabled transceiver GTHE3_CHANNEL_X1Y19
# ----------------------------------------------------------------------------------------------------------------------

# Channel primitive location constraint
set_property LOC GTHE3_CHANNEL_X1Y19 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[28].*gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# Channel primitive serial data pin location constraints
# (Provided as comments for your reference. The channel primitive location constraint is sufficient.)
#set_property package_pin A3 [get_ports gthrxn_in[27]]
#set_property package_pin A4 [get_ports gthrxp_in[27]]
#set_property package_pin B5 [get_ports gthtxn_out[27]]
#set_property package_pin B6 [get_ports gthtxp_out[27]]


# False path constraints
# ----------------------------------------------------------------------------------------------------------------------

set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}] -quiet

##set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out*}]] -quiet

