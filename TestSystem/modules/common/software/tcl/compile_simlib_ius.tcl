# command to compile the ies simulation libraries
compile_simlib -verbose -force -language all -directory [lindex $argv 0] -simulator ies -simulator_exec_path [lindex $argv 1] -library all -family kintexu
