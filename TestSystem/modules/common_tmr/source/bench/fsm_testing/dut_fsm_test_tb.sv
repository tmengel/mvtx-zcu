// ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_test_tb.v

`timescale 10ns/1ns
`define L 2

module dut_fsm_test_tb();

reg             clk_r, rst_r;
reg             inj_err_r = 1'b0;
wire  [`L-1:0]  err_data_w;
wire  [`L-1:0]  err_state_w;

dut_fsm_test #(.L(`L), .K(64)) dut_fsm_test(
  .clk_i        (clk_r),
  .rst_i        (rst_r),
  .inj_err_i    (inj_err_r),
  .err_data_o   (err_data_w),
  .err_state_o  (err_state_w)
);

initial begin
  clk_r <= 1'b1;
  rst_r <= 1'b1;
  
  repeat(2)
    #5 clk_r = ~clk_r;
  
  rst_r         <= 1'b0;
  
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

endmodule
