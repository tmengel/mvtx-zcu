set vivado_libs $::env(SIMLIB_MODELSIM_PATH)
quietly set XILINX_LIBS {
                        unisim
                        xpm
                        }

quietly set LIBS ""
foreach lib $XILINX_LIBS {
    append LIBS " -L " $lib
    vmap $lib $vivado_libs/$lib
    }

if { [info exists 1] } {
  if {[string compare $1 "--ci"] == 0 } {
    onerror { quit -force -code 1 }
    onElabError { quit -force -code 1 }
  }
}
echo "\n\nCompile bitvis uvvm..."
do 01-compile_bitvis_uvvm.do
echo "\n\nCompile osvvm..."
do 02-compile_osvvm.do
echo "\n\nCompile Wishbone BFM..."
do 03-compile_wishbone_bfm.do
echo "\n\nCompile OpenCores CAN controller sources..."
do 04-compile_can_ctrl_src.do
echo "\n\nCompile CAN HLP sources..."
do 05-compile_can_hlp_src.do
echo "\n\nCompile CAN HLP test bench..."
do 06-compile_can_hlp_tb.do
echo "\n\nRun CAN HLP simulation..."
if { [info exists 1] } {
  if {[string compare $1 "--ci"] == 0 } {
    eval vsim $LIBS -fsmdebug -quiet -no_autoacc -t 1ps -do ci_do.tcl can_hlp_uvvm_tb
  }
} else {
  do 00-sim_can_hlp.do
}
