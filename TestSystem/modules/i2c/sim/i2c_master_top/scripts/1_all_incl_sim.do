#========================================================================================================================
# Copyright (c) 2015 by Bitvis AS.  All rights reserved.
#
# BITVIS UTILITY LIBRARY AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH BITVIS UTILITY LIBRARY.
#========================================================================================================================

# JS: modified for I2C testbench

# - Compile dependencies (ieee_proposed)
# - Compile src
# - Compile testbench dependencies (Bitvis Utility Library, vhdl 93 version)
# - Compile and simulate I2C testbench

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
  onbreak {abort all; exit -f}
} else {
  onerror {abort all}
}

quit -sim

quietly set vhdl_version "2002"

quietly set bv_part_path ../../Bitvis_Utility_Library_v2_6_0/bitvis_util

do ./compile_dep.do $bv_part_path 
do ./compile_src.do
do ./compile_tb_dep.do $bv_part_path $vhdl_version
do ./compile_tb.do
do ./simulate_tb.do


