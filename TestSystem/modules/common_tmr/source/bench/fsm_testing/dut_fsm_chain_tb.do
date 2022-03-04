vsim work.dut_fsm_chain_tb

# General
add wave -noupdate -divider -height 17 General
add wave -position end  sim:/dut_fsm_chain_tb/clk_r
add wave -position end  sim:/dut_fsm_chain_tb/rst_r
add wave -position end  sim:/dut_fsm_chain_tb/pat_gen_inc_r
add wave -position end  sim:/dut_fsm_chain_tb/inj_err_r
add wave -position end  sim:/dut_fsm_chain_tb/data_gen_w
property wave -radix unsigned /dut_fsm_chain_tb/data_gen_w
add wave -position end  sim:/dut_fsm_chain_tb/data_chkr_w
property wave -radix unsigned /dut_fsm_chain_tb/data_chkr_w
add wave -position end  sim:/dut_fsm_chain_tb/err_data_w
add wave -position end  sim:/dut_fsm_chain_tb/err_state_w

# m_pat_gen
add wave -noupdate -divider -height 17 m_pat_gen
add wave -position end  sim:/dut_fsm_chain_tb/m_pat_gen/inc_i
add wave -position end  sim:/dut_fsm_chain_tb/m_pat_gen/inj_err_i
add wave -position end  sim:/dut_fsm_chain_tb/m_pat_gen/cnt_o
property wave -radix unsigned /dut_fsm_chain_tb/m_pat_gen/cnt_o
add wave -position end  sim:/dut_fsm_chain_tb/m_pat_gen/warn_o

# dut_fsm_chain
add wave -noupdate -divider -height 17 dut_fsm_chain
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_chain/data_i
property wave -radix unsigned /dut_fsm_chain_tb/dut_fsm_chain/data_i
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_chain/data_o
property wave -radix unsigned /dut_fsm_chain_tb/dut_fsm_chain/data_o
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_chain/data_fsm_w
property wave -radix unsigned /dut_fsm_chain_tb/dut_fsm_chain/data_fsm_w


# dut_fsm_checker
add wave -noupdate -divider -height 17 dut_fsm_checker
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_checker/data_i
property wave -radix unsigned /dut_fsm_chain_tb/dut_fsm_checker/data_i
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_checker/err_data_o
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_checker/err_state_o
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_checker/data_marker_r
add wave -position end  sim:/dut_fsm_chain_tb/dut_fsm_checker/ovrflv_w

# toggle leaf names
config wave -signalnamewidth 1

run -all
