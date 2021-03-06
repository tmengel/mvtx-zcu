#========================================================================================================================
# Copyright (c) 2017 by Bitvis AS.  All rights reserved.
# You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not,
# contact Bitvis AS <support@bitvis.no>.
#
# UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR
# OTHER DEALINGS IN UVVM.
#========================================================================================================================

# This file may be called with an argument
# arg 1: Part directory of this library/module

# Overload quietly (Modelsim specific command) to let it work in Riviera-Pro
proc quietly { args } {
  if {[llength $args] == 0} {
    puts "quietly"
  } else {
    # this works since tcl prompt only prints the last command given. list prints "".
    uplevel $args; list;
  }
}

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
} else {
  onerror {abort all}
}
#Just in case...
quietly quit -sim

# Detect simulator
if {[catch {eval "vsim -version"} message] == 0} {
  quietly set version [eval "vsim -version"]
  # puts "Version is: $version"
  if {[regexp -nocase {modelsim} $version] || [regexp -nocase {questa} $version]} {
    quietly set simulator "modelsim"
  } elseif {[regexp -nocase {aldec} $version]} {
    quietly set simulator "rivierapro"
  } else {
    puts "Unknown simulator. Attempting to use Modelsim commands."
    quietly set simulator "modelsim"
  }
} else {
    puts "vsim -version failed with the following message:\n $message"
    abort all
}

if { [string equal -nocase $simulator "modelsim"] } {
  ###########
  # Fix possible vmap bug
  do fix_vmap.tcl
  ##########
}

# Set up util_part_path and lib_name
#------------------------------------------------------
quietly set bfm_lib_name "bitvis_vip_wishbone"

quietly set part_name "dcs_canbus"

# path from mpf-file in sim
quietly set util_part_path "../../$part_name"

# (Re-)Generate library and Compile source files
#--------------------------------------------------
echo "\n\nRe-gen lib and compile $lib_name source"
if {[file exists $util_part_path/sim/$bfm_lib_name]} {
  file delete -force $util_part_path/sim/$bfm_lib_name
}

vlib $util_part_path/sim/$bfm_lib_name
vmap $bfm_lib_name $util_part_path/sim/$bfm_lib_name

if { [string equal -nocase $simulator "modelsim"] } {
  quietly set bfm_compdirectives "-suppress 1346,1236 -2008 -quiet -O5 -work $bfm_lib_name"
} elseif { [string equal -nocase $simulator "rivierapro"] } {
  set bfm_compdirectives "-2008 -nowarn COMP96_0564 -nowarn COMP96_0048 -dbg -work $bfm_lib_name"
}

echo "\n\n\n=== Compiling $bfm_lib_name source\n"


eval vcom  $bfm_compdirectives $util_part_path/source/bench/bitvis_uvvm/bitvis_vip_wishbone/src/wishbone_bfm_pkg.vhd
