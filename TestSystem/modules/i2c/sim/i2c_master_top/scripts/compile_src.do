#========================================================================================================================
# Copyright (c) 2015 by Bitvis AS.  All rights reserved.
#
# BITVIS UTILITY LIBRARY AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH BITVIS UTILITY LIBRARY.
#========================================================================================================================

# This file may be called with an argument
# arg 1: Part directory of this library/module

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
} else {
  onerror {abort all}
}
quit -sim   #Just in case...

# Set up tb_src_path and lib_name
#------------------------------------------------------
quietly set lib_name "i2c_master_top"

# (Re-)Generate library and Compile source files
#--------------------------------------------------
echo "\n\nRe-gen lib and compile $lib_name source\n"
if {[file exists ./$lib_name]} {
  file delete -force ./$lib_name
}

vlib ./$lib_name
vmap $lib_name ./$lib_name

set comp_vhdl_directives "-2008 -lint -work $lib_name"
set comp_vlog_directives "-lint -incr -warning 1957 -override_timescale \"1 ps / 10 fs\" -work $lib_name"

#eval vlog  $comp_vlog_directives -f ../scripts/vlog_sources_sim.txt
eval vcom  $comp_vhdl_directives -f ../scripts/vhdl_sources.txt

