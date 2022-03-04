startgroup
set_property config_mode S_SELECTMAP [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

# system monitor
#set_property BITSTREAM.GENERAL.SYSMONPOWERDOWN ENABLE [current_design]
#set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

set_property BITSTREAM.CONFIG.PERSIST YES [current_design]
endgroup

