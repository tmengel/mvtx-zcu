set_max_delay -to [get_pins -filter {NAME =~ */D} -of [get_cells -hier -filter {NAME =~ *OUT_0_reg[*]}]] 10.000
set_false_path -hold -to [get_pins -filter {NAME =~ */D} -of [get_cells -hier -filter {NAME =~ *OUT_0_reg[*]}]]






