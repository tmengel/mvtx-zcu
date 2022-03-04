echo "\n\nCompile bitvis uvvm..."
do 01-compile_bitvis_uvvm.do
echo "\n\nCompile osvvm..."
do 02-compile_osvvm.do
echo "\n\nCompile Wishbone BFM..."
do 03-compile_wishbone_bfm.do
echo "\n\nCompile OpenCores CAN controller sources..."
do 04-compile_can_ctrl_src.do
echo "\n\nCompile CAN controller test bench..."
do 06-compile_can_ctrl_tb.do
echo "\n\nRun simulation..."
do 00-sim_can_ctrl.do
