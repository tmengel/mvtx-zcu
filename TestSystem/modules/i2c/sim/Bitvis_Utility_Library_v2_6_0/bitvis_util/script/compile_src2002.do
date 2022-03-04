#========================================================================================================================
# Copyright (c) 2015 by Bitvis AS.  All rights reserved.
#
# BITVIS UTILITY LIBRARY AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH BITVIS UTILITY LIBRARY.
#========================================================================================================================

# Compile src2002 (vhdl version 2002)
# This file may be called with an argument
# Arg : Part directory of this library/module

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
} else {
  onerror {abort all}
}


# Set up util_part_path and lib_name
#------------------------------------------------------
quietly set lib_name "bitvis_util"
quietly set part_name "bitvis_util"
# path from mpf-file in sim
quietly set util_part_path "../..//$part_name"

# argument number 1
if { [info exists 1] } {
  # path from this part to target part
  quietly set util_part_path "$1/..//$part_name"
  unset 1
}

quietly set vhdl_version "2002"
do $util_part_path/script/compile_src.do $util_part_path $vhdl_version
