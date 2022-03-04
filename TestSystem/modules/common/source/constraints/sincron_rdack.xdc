set_max_delay -datapath_only -from [get_pins -filter {NAME =~ */C} -of [get_cells -hier -filter {NAME =~ *wr_enMB_T_reg}]] 8.000
set_max_delay -datapath_only -from [get_pins -filter {NAME =~ */C} -of [get_cells -hier -filter {NAME =~ *hand_fw_D_reg}]] 8.000
set_max_delay -datapath_only -from [get_pins -filter {NAME =~ */C} -of [get_cells -hier -filter {NAME =~ *regMB_reg[*]}]] 8.000
set_max_delay -datapath_only -from [get_pins -filter {NAME =~ */C} -of [get_cells -hier -filter {NAME =~ *rd_ack_T_reg}]] 8.000
