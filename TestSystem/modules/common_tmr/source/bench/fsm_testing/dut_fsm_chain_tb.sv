// ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_chain_tb.v

`timescale 10ns/1ns

module dut_fsm_chain_tb();

reg         clk_r, rst_r;
reg         pat_gen_inc_r = 1'b0;
reg         inj_err_r = 1'b0;
wire  [3:0] data_gen_w;
wire  [3:0] data_chkr_w;
wire        err_data_w;
wire        err_state_w;

m_pat_gen #(.N(4), .LIM(14)) m_pat_gen(
  .clk_i      (clk_r),
  .rst_i      (rst_r),
  .inc_i      (pat_gen_inc_r),
  .inj_err_i  (inj_err_r),
  .cnt_o      (data_gen_w),
  .warn_o     ()
);

dut_fsm_chain #(.N(4), .K(32)) dut_fsm_chain(
  .clk_i  (clk_r),
  .rst_i  (rst_r),
  .data_i (data_gen_w),
  .data_o (data_chkr_w)
);

dut_fsm_checker #(.N(4)) dut_fsm_checker(
  .clk_i        (clk_r),
  .rst_i        (rst_r),
  .data_i       (data_chkr_w),
  .err_data_o   (err_data_w),
  .err_state_o  (err_state_w)
);

initial begin
  clk_r <= 1'b1;
  rst_r <= 1'b1;
  
  repeat(2)
    #5 clk_r = ~clk_r;
  
  rst_r         <= 1'b0;
  pat_gen_inc_r <= 1'b1;
  
  repeat(500)
    #5 clk_r = ~clk_r;
  
  $finish;
end

initial begin
  #500
  @(posedge clk_r);
  inj_err_r <= 1'b1;
  
  #10
  @(posedge clk_r);
  inj_err_r <= 1'b0;  
end

initial begin
  wait(data_chkr_w == 4'd15);
  $display("%d:\t%b", $stime, data_chkr_w);
end

endmodule
