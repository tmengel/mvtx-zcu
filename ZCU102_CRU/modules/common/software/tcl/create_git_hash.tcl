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
set git_hash [exec git log -1 --pretty=%h --abbrev=8]
# get git commit date in unix time
set git_date [exec git log -1 --format=%ct]

# Convert unix to normal time in yymmddHHMMss
set DATECODE [clock format $git_date -format %y%m%d%H%M%S -gmt True]

# Set OS version
if { ${tcl_platform(platform)} == "windows" } {
    set OS 0
} elseif { ${tcl_platform(platform)} == "unix" } {
    set OS 1
} else {
    set OS 2
}

# Show values in the log
puts "OS: $OS"
puts "DATECODE: $DATECODE"
puts "HASH: $git_hash"

set_property generic "DATE=48'h$DATECODE HASH_CODE=32'h$git_hash OS=16'h$OS" [current_fileset]

cd $curr_dir
