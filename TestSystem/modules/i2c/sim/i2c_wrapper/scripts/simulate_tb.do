#========================================================================================================================
# Copyright (c) 2015 by Bitvis AS.  All rights reserved.
#
# BITVIS UTILITY LIBRARY AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH BITVIS UTILITY LIBRARY.
#========================================================================================================================

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
  onbreak {abort all; exit -f}
} else {
  onerror {abort all}
}

quiet set SIM_FLAGS "-fsmdebug"
quiet set LIBS "-L unisims_ver -L unimacro_ver -L secureip -L xpm -L fifo_generator_v13_1_3"

eval vsim  $SIM_FLAGS $LIBS i2c.i2c_wrapper_tb

if {[batch_mode] == 0} {
  add log -r /*
  source ../scripts/wave.do
}

run -all

