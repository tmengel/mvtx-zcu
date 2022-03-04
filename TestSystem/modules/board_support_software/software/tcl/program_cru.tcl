set TARGET_DEVICE xc7k325t_0
set TARGET_FW_FOLDER /home/mbonora/
#set TARGET_FW ${TARGET_FW_FOLDER}RUv0a_CRU_top_171003_0952_526fb32_uncommittedSources
set TARGET_FW ${TARGET_FW_FOLDER}RUv0a_CRU_top_171020_0518_52a371b
set HW_TARGET */xilinx_tcf/Xilinx/000013b38e8c01
#set SERVER_NAME localhost
set SERVER_NAME pcitsnuc
set SERVER_PORT 3121

open_hw
connect_hw_server -url $SERVER_NAME:$SERVER_PORT
current_hw_target [get_hw_targets $HW_TARGET]
set_property PARAM.FREQUENCY 6000000 [get_hw_targets $HW_TARGET]
open_hw_target
current_hw_device [lindex [get_hw_devices ${TARGET_DEVICE}] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${TARGET_DEVICE}] 0]
set_property PROBES.FILE $TARGET_FW.ltx [lindex [get_hw_devices ${TARGET_DEVICE}] 0]
set_property PROGRAM.FILE $TARGET_FW.bit [lindex [get_hw_devices ${TARGET_DEVICE}] 0]
program_hw_devices [lindex [get_hw_devices ${TARGET_DEVICE}] 0]
refresh_hw_device [lindex [get_hw_devices ${TARGET_DEVICE}] 0]
display_hw_ila_data [ get_hw_ila_data hw_ila_data_1 -of_objects [get_hw_ilas -of_objects [get_hw_devices ${TARGET_DEVICE}] -filter {CELL_NAME=~"u_ila_0"}]]
exit
