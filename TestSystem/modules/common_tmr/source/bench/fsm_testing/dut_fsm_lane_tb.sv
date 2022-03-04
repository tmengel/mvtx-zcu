// ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_lane_tb.v

`timescale 10ns/1ns

module dut_fsm_lane_tb();

reg         clk_r, rst_r;
reg         inj_err_r = 1'b0;
wire        err_data_w;
wire        err_state_w;

dut_fsm_lane #(.N(4), .K(32)) dut_fsm_lane(
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

initial begin
  wait(err_state_w == 1'b1);
  $display("%d:\t%b", $stime, err_state_w);
end

endmodule
