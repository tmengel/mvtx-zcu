#-- Code to extract the git hash and pass it to the top level VHDL code
#-- as a GENERIC
#
# set some defaults
set scriptDir [file dirname [info script]]
source $scriptDir/set_defaults.tcl
#
set curr_dir [pwd]
# set this to where the top git working dir is
cd $git_dir
# get the git hash of the latest commit in short format
set git_hash [exec git log -1 --pretty=%h]
# Set the generics
#set_property generic "HASH_CODE=32'h$git_hash" [current_fileset]
#

# Current date, time, and seconds since epoch
# 0 = 4-digit year
# 1 = 2-digit year
# 2 = 2-digit month
# 3 = 2-digit day
# 4 = 2-digit hour
# 5 = 2-digit minute
# 6 = 2-digit second
# 7 = Epoch (seconds since 1970-01-01_00:00:00)
# Array index                                            0  1  2  3  4  5  6  7
#set datetime_arr [clock format [clock seconds] -format {%Y %y %m %d %H %M %S %s}]
# Array index                                            1  2  3  4
# Solves issue with date changing seed for synth
#set DATECODE [clock format [clock seconds] -format {%y%m%d%H%M%S}]
set DATECODE [exec date -d @[exec git log -1 --format=%ct] +%Y%m%d%H%M%S]

parray tcl_platform

if { ${tcl_platform(platform)} == "windows" } {
    set OS 0
} elseif { ${tcl_platform(platform)} == "unix" } {
    set OS 1
} else {
    set OS 2
}

puts $OS
# Get the datecode in the yy-mm-dd-HH format
#set datecode [lindex $datetime_arr 1][lindex $datetime_arr 2][lindex $datetime_arr 3][lindex $datetime_arr 4]
# Show this in the log
puts $DATECODE
set_property generic "DATE=48'h$DATECODE HASH_CODE=32'h$git_hash OS=16'h$OS" [current_fileset]

cd $curr_dir
