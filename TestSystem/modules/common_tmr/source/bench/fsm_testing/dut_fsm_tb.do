vsim work.dut_fsm_tb

add wave -noupdate -divider -height 17 General
add wave -position end  sim:/dut_fsm_tb/clk_r
add wave -position end  sim:/dut_fsm_tb/rst_r

add wave -position end  sim:/dut_fsm_tb/m_pat_gen/inc_i
add wave -position end  sim:/dut_fsm_tb/m_pat_gen/cnt_o
property wave -radix unsigned /dut_fsm_tb/m_pat_gen/cnt_o
add wave -position end  sim:/dut_fsm_tb/m_pat_gen/inj_err_i

add wave -position end  sim:/dut_fsm_tb/data_nxt_fsm
property wave -radix unsigned /dut_fsm_tb/data_nxt_fsm

add wave -noupdate -divider -height 17 FSM#0
add wave -position end  sim:/dut_fsm_tb/dutu_fsm_0/data_i
property wave -radix unsigned /dut_fsm_tb/dutu_fsm_0/data_i
add wave -position end  sim:/dut_fsm_tb/dutu_fsm_0/state_r
property wave -radix unsigned /dut_fsm_tb/dutu_fsm_0/state_r
add wave -position end  sim:/dut_fsm_tb/dutu_fsm_0/data_o
property wave -radix unsigned /dut_fsm_tb/dutu_fsm_0/data_o

add wave -noupdate -divider -height 17 FSM#1
add wave -position end  sim:/dut_fsm_tb/dutu_fsm_1/data_i
property wave -radix unsigned /dut_fsm_tb/dutu_fsm_1/data_i
add wave -position end  sim:/dut_fsm_tb/dutu_fsm_1/state_r
property wave -radix unsigned /dut_fsm_tb/dutu_fsm_1/state_r
add wave -position end  sim:/dut_fsm_tb/dutu_fsm_1/data_o
property wave -radix unsigned /dut_fsm_tb/dutu_fsm_1/data_o

run -all
