# Command to compile the simulation library
compile_simlib -force -language all -dir [lindex $argv 0] -simulator [lindex $argv 1] -simulator_exec_path [lindex $argv 2] -verbose  -library all -family  all
