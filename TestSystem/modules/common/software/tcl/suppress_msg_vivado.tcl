# Analyzing verilog file...
set_msg_config -id {HDL 9-2216} -suppress
# Parsing verilog file
set_msg_config -id {HDL 9-1065} -suppress
# Parsing VHDL file
set_msg_config -id {HDL 9-1061} -suppress

# Synthesizing module
set_msg_config -suppress -id {Synth 8-638} 
# binding component
set_msg_config -suppress -id {Synth 8-113} 
# Detected attribute mark_debug
set_msg_config -suppress -id {Synth 8-5534} 
# Detected attribute rw_addr_collision
set_msg_config -suppress -id {Synth 8-5772} 
# done synthesizing
set_msg_config -suppress -id {Synth 8-256} 
# module x declared at y bound at z
set_msg_config -suppress -id {Synth 8-3491} 

# Got license for
set_msg_config -suppress -id {Common 17-349} 
# The version limit for your license ... will expire in
set_msg_config -suppress -id {Common 17-1223} 
# You have specified a new message (replaces old)
set_msg_config -suppress -id {Common 17-1361}
# Loading part
set_msg_config -suppress -id {Device 21-403} 

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
#set_msg_config -suppress -string {[ \t]*Parameter .* bound to: .*type: .*$} -regexp
set_msg_config -suppress -string {Parameter }

# CDC tcl files
#set_msg_config -suppress -string {Sourcing Tcl File .*xpm.*$} -regexp
set_msg_config -suppress -string {Sourcing Tcl File}
#set_msg_config -suppress -string {Finished Sourcing Tcl File .*xpm.*$} -regexp
set_msg_config -suppress -string {Finished Sourcing Tcl File}
set_msg_config -suppress -string {tying undriven pin xpm_cdc_array_single_inst:src_clk to constant 0}

# Parsing XDC File
set_msg_config -suppress -string {Parsing XDC File}
# Finished Parsing XDC File
set_msg_config -suppress -string {Finished Parsing XDC File}

#
# Hardcore
#
set_msg_config -suppress -string {xpm_}
set_msg_config -suppress -string {set_property}
