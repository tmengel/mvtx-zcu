#echo "\n\nCompile Xilinx libs..."
#do 01-compile_unisim.do
echo "\n\nCompile bitvis uvvm..."
do 01-compile_bitvis_uvvm.do
echo "\n\nCompile osvvm..."
do 02-compile_osvvm.do
echo "\n\nCompile Wishbone BFM..."
do 03-compile_wishbone_bfm.do
echo "\n\nCompile OpenCores CAN controller sources..."
do 04-compile_can_ctrl_src.do
echo "\n\nCompile CAN bus UVVM BFM sources..."
do 05-compile_can_uvvm_bfm_src.do
echo "\n\nCompile CAN bus UVVM BFM test bench..."
do 06-compile_can_uvvm_bfm_tb.do
echo "\n\nRun simulation..."
do 00-sim_can_uvvm_bfm.do
