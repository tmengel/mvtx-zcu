// krzysztof.sielewicz@cern.ch
// test_fifo_inj_err

(* DONT_TOUCH = "true" *) module test_fifo_err_inj #(parameter
  N = 32,     // width of the datapath
  M = 3,      // redundancy level
  K = 192)(   // number of fifo_lanes
  input             clk_i,
  input             rst_i,
  input             injectsbiterr_i,
  input             injectdbiterr_i,
  output [K-1:0]    fifo_err_o,
  output [K-1:0]    pg_warn_o,
  output [M*K-1:0]  fifo_cnt_err_o
);

wire [K-1:0] fifo_err_w;
assign fifo_err_o = fifo_err_w;
wire [K-1:0] pg_warn_w;
assign pg_warn_o = pg_warn_w;
wire [M*K-1:0] fifo_cnt_err_w;
assign fifo_cnt_err_o = fifo_cnt_err_w;

// generate K test_fifos
genvar i;
generate
	for(i = 0; i < K; i = i + 1)
    begin : fifo_lane
      fifo_lane_err_inj #(.N(N), .M(M)) fifo_lane_err_inj_i(
        clk_i,
        rst_i,
        injectsbiterr_i,
        injectdbiterr_i,
        fifo_err_w[i],
        pg_warn_w[i],        
        fifo_cnt_err_w[i * 3 + 2 -: 3]
      );
    end
endgenerate

endmodule
