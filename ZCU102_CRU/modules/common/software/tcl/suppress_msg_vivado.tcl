#
# Project creation, synthesis, linting
#

# Analyzing verilog file...
set_msg_config -suppress -id {HDL 9-2216}
# Parsing verilog file
set_msg_config -suppress -id {HDL 9-1065}
# Parsing VHDL file
set_msg_config -suppress -id {HDL 9-1061}
# back to file 
set_msg_config -suppress -id {HDL 9-3290}

# Synthesizing module
set_msg_config -suppress -id {Synth 8-638}
# Synthesizing module
set_msg_config -suppress -id {Synth 8-6157}
# binding component
set_msg_config -suppress -id {Synth 8-113}
# Detected attribute ...
set_msg_config -suppress -id {Synth 8-5534}
# Detected attribute ... on RAM 
set_msg_config -suppress -id {Synth 8-5772}
# done synthesizing module (vhdl)
set_msg_config -suppress -id {Synth 8-256}
# done synthesizing module (sv)
set_msg_config -suppress -id {Synth 8-6155}
# null assignment ignored
set_msg_config -suppress -id {Synth 8-3919}
# default block is never used
set_msg_config -suppress -id {Synth 8-226}
# module x declared at y bound at z
set_msg_config -suppress -id {Synth 8-3491}
# ROM x won't be mapped to Block RAM because address size (y) smaller than threshold (z)
set_msg_config -suppress -id {Synth 8-5544}
# ROM x won't be mapped to RAM because address size (y) is larger than maximum supported(z)
set_msg_config -suppress -id {Synth 8-5545}
# ROM X won't be mapped to RAM because it is too sparse
set_msg_config -suppress -id {Synth 8-5546}
# inferred FSM for state register
set_msg_config -suppress -id {Synth 8-802}
# Found 'rw_addr_collision' attribute set to 'no' on SDP RAM
set_msg_config -suppress -id {Synth 8-5775}
# ROM size for x is below threshold of ROM address width. It will be mapped to LUTs
set_msg_config -suppress -id {Synth 8-5587}
# Multithreading enabled for synth_design using a maximum of x processes.
set_msg_config -suppress -id {Synth 8-5580}
# The signal x is implemented as block RAM but is better mapped onto distributed LUT RAM for the following reason(s)
set_msg_config -suppress -id {Synth 8-5583}
# Implemented Block Ram Cascade chain of height x and width y for RAM z
set_msg_config -suppress -id {Synth 8-5555}



# Attempting to get a license 
set_msg_config -suppress -id {{Attempting to get a license.*\v}} -regexp
# Got license for
set_msg_config -suppress -id {Common 17-349}
# The version limit for your license ... will expire in
set_msg_config -suppress -id {Common 17-1223}
# The version limit for your license is ... and has expired for new software.
set_msg_config -suppress -id {Common 17-1540}
# Releasing license: Synthesis
set_msg_config -suppress -id {Common 17-83}
# You have specified a new message (replaces old)
set_msg_config -suppress -id {Common 17-1361}
# The checkpoint ... has been generated.
set_msg_config -suppress -id {Common 17-1381}

# Loading part
set_msg_config -suppress -id {Device 21-403}
# Loading part: 
set_msg_config -suppress -string {{Loading part: .*\v}} -regexp

# Parsing module
set_msg_config -suppress -id {HDL 9-1125}
# Parsing entity
set_msg_config -suppress -id {HDL 9-204}
# Parsing architecture
set_msg_config -suppress -id {HDL 9-1122}
# Parsing package
set_msg_config -suppress -id {HDL 9-206}
# Parsing package body
set_msg_config -suppress -id {HDL 9-207}
# back to file
set_msg_config -suppress -id {HDL 9-2895}

# The synthesis checkpoint for IP is already up-to-date
set_msg_config -suppress -id {Vivado 12-4149}

# Parameter x bound to: y - type: z 
set_msg_config -suppress -string {{\s*Parameter [a-zA-Z0-9_]* bound to: .*\v}} -regexp

# CDC tcl files
set_msg_config -suppress -string {{Sourcing Tcl File .*xpm.*\v}} -regexp
set_msg_config -suppress -string {{Finished Sourcing Tcl File .*xpm.*\v}} -regexp
#set_msg_config -suppress -string {tying undriven pin xpm_cdc_array_single_inst:src_clk to constant 0}

# Parsing XDC File
set_msg_config -suppress -string {{Parsing XDC File .*\v}} -regexp
# Finished Parsing XDC File
set_msg_config -suppress -string {{Finished Parsing XDC File .*\v}} -regexp

# Removing section for "Start RTL Component Statistics" and "Start RTL Hierarchical Component Statistics ", ~40k lines
set_msg_config -suppress -string {Detailed RTL Component Info : }
set_msg_config -suppress -string {Hierarchical RTL Component report }
set_msg_config -suppress -string {{Module [a-zA-Z0-9_-]+ \v}} -regexp
set_msg_config -suppress -string {+---Muxes : }
set_msg_config -suppress -string {+---Registers : }
set_msg_config -suppress -string {+---Adders : }
set_msg_config -suppress -string {+---XORs : }
set_msg_config -suppress -string {+---RAMs : }
set_msg_config -suppress -string {{\s*[0-9]+ Input +[0-9]+ Bit *Adders := [0-9]+ *\v}} -regexp
set_msg_config -suppress -string {{\s*[0-9]+ Input +[0-9]+ Bit *XORs := [0-9]+ *\v}} -regexp
set_msg_config -suppress -string {{\s*[0-9]+ Bit +Registers := [0-9]+ *\v}} -regexp
set_msg_config -suppress -string {{\s*[0-9]+K? Bit +RAMs := [0-9]+ *\v}} -regexp
set_msg_config -suppress -string {{\s*[0-9]+ Input +[0-9]+ Bit +Muxes := [0-9]+ *\v}} -regexp

# Remove "Report Instance Areas: " table, ~50k lines
set_msg_config -suppress -string {{\|[0-9]+ +\| *[\\a-zA-Z0-9_\[\]\.]+ +\|[a-zA-Z0-9_]+ +\| +[0-9]+\|\v}} -regexp

# Remove internal warnings from xpm files
# Input port 'value' has an internal driver
set_msg_config -suppress -string {{.*Synth 8-6104.*'value'.*xpm_fifo.sv:[0-9]+\] *\v}} -regexp
# Unused sequential element xxx was removed
set_msg_config -suppress -string {{.*Synth 8-6014.*gen_wr_a.gen_word_wide.addralsb_reg.*xpm_memory.sv:[0-9]+\] *\v}} -regexp
set_msg_config -suppress -string {{.*Synth 8-6014.*gen_rd_b.gen_doutb_pipe.enb_pipe_reg\[0\].*xpm_memory.sv:[0-9]+\] *\v}} -regexp
set_msg_config -suppress -string {{.*Synth 8-6014.*gen_rd_b.gen_rd_b_synth_template.gen_nc_wide_pipe.addrblsb_reg.*xpm_memory.sv:[0-9]+\] *\v}} -regexp
set_msg_config -suppress -string {{.*Synth 8-6014.*dest_out_bin_ff_reg.*xpm_cdc.sv:[0-9]+\] *\v}} -regexp
set_msg_config -suppress -string {{.*Synth 8-6014.*dest_pulse_ff_reg.*xpm_cdc.sv:[0-9]+\] *\v}} -regexp
set_msg_config -suppress -string {{.*Synth 8-6014.*gen_rd_b.gen_doutb_pipe.enb_pipe_reg\[0\].*xpm_memory.sv:[0-9]+\] *\v}} -regexp
# Other xpm warnings
set_msg_config -suppress -string {{.*Synth 8-3331.*design xpm_cdc_.*_single.* has unconnected port src_clk *\v}} -regexp
set_msg_config -suppress -string {{.*Synth 8-5818.*HDL ADVISOR - The operator resource <adder> is shared.*xpm_fifo.sv:[0-9]+\] *\v}} -regexp

# Remove info message "found qualifier unique on case statement: implementing as parallel_case"
set_msg_config -suppress -id {Synth 8-294}

#
# Print more of these strings, usefull for debugging, check for [Common 17-14] in the log
#

# Instance x has DONT_TOUCH and is preventing optimization
set_msg_config -id {Physopt 32-780} -limit 2000
# Input port x has an internal driver
set_msg_config -id {Synth 8-6104} -limit 2000
# design x has unconnected port
set_msg_config -id {Synth 8-3331} -limit 2000
# propagating constant x across sequential element
set_msg_config -id {Synth 8-3333} -limit 2000
# The timing for the instance x (implemented as a Block RAM) might be sub-optimal as no optional output register could be merged into the block ram. Providing additional output register may help in improving timing.
#set_msg_config -id {Synth 8-6837} -limit 2000

#
# place and route
#

# Reading design checkpoint
set_msg_config -suppress -id {Project 1-454}
# Multithreading enabled for timing update using a maximum of x CPUs
set_msg_config -suppress -id {Timing 38-191}

#
# DRC
#
# RAMB36E2_nochange_collision_advisory: Synchronous clocking is detected for BRAM (xxx) in SDP mode with NO_CHANGE write-mode. This is the preferred mode for best power characteristics. However, NO_CHANGE may exhibit address collisions if the same address appears on both read and write ports resulting in unknown or corrupted read data. It is suggested to confirm via simulation that an address collision never occurs and if so it is suggested to try and avoid this situation. If address collisions cannot be avoided, the write-mode may be set to READ_FIRST which guarantees that the read data is the prior contents of the memory at the cost of additional power in the design. See the FPGA Memory Resources User Guide for additional information.
set_msg_config -suppress -id {DRC REQP-1935}
# Same as above, but for RAMB18E2
set_msg_config -suppress -id {DRC REQP-1934}
# Running DRC with x threads
set_msg_config -suppress -id {DRC 23-27} 

#
# Promote info/warnings to errors
#
# DONT_TOUCH attributes on non-mitigated parts
#set_msg_config -string {{.*Physopt 32-780.*if_NOMITIGATION_generate.*\v}} -regexp -new_severity "ERROR"
# could not be optimized because driver could not be replicated
#set_msg_config -string {{.*Physopt 32-117.*if_NOMITIGATION_generate.*\v}} -regexp -new_severity "ERROR"

#
# Wave messages
#
# DONT_TOUCH info on majority voters
set_msg_config -suppress -string {{.*Physopt 32-780.*if_TMR_generate.*majority_voter has DONT_TOUCH and is preventing optimization *\v}} -regexp
set_msg_config -suppress -string {{.*Physopt 32-780.*if_TMR_generate.*majority_voter_packed has DONT_TOUCH and is preventing optimization *\v}} -regexp
# Constant values on pinheader
set_msg_config -suppress -string {{.*Synth 8-3917.*fabric_top.* has port PINHEADER\[[0-9]\] driven by constant 0 *\v}} -regexp

# Remove buggy warning about vhdl configuration statement which renames the ports
set_msg_config -suppress -id {Synth 8-5640} -regexp -string {.*tmr_voter_pkg.vhd.*}
