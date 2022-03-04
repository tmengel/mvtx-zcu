// ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_tb.sv

`timescale 10ns/1ns

module dut_fsm_tb();

reg         clk_r, rst_r;
reg         pat_gen_inc_r = 1'b0;
reg         inj_err_r = 1'b0;
wire  [3:0] data_gen_w;
wire  [3:0] data_nxt_fsm[1:0];

m_pat_gen #(.N(4), .LIM(14)) m_pat_gen(
  .clk_i      (clk_r),
  .rst_i      (rst_r),
  .inc_i      (pat_gen_inc_r),
  .inj_err_i  (inj_err_r),
  .cnt_o      (data_gen_w),
  .warn_o     ()
);

dut_fsm dut_fsm_0(
  .clk_i  (clk_r),
  .rst_i  (rst_r),
  .data_i (data_gen_w),
  .data_o (data_nxt_fsm[0])
);

dut_fsm dut_fsm_1(
  .clk_i  (clk_r),
  .rst_i  (rst_r),
  .data_i (data_nxt_fsm[0]),
  .data_o (data_nxt_fsm[1])
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
  wait(data_nxt_fsm[1] == 4'd15);
  $display("%d:\t%b", $stime, data_nxt_fsm[1]);
end

//task write_data (input reg [3:0] data_r, delay);
//task write_data (input reg [3:0] data_r);
/*  automatic reg [7:0] a;
  if (count > 5) begin
    $display ("@%g Returning from task", $time);
    return;
  end
  #(delay) $display ("@%g Value passed is %d", $time, count);*/
  
  //#20
  //@(posedge clk_r);
//  data_r <= 4'd1;  
//endtask

endmodule
