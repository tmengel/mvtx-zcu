// krzysztof.sielewicz@cern.ch
// test_fifo.v

(* DONT_TOUCH = "true" *) module test_fifo #(parameter
  N = 32,     // width of the datapath
  M = 3,      // redundancy level
  K = 192)(   // number of fifo_lanes
  input           clk_i,
  input           rst_i,
  output [K-1:0]  fifo_err_o,
  output [K-1:0]  pg_warn_o
);

wire [K-1:0] fifo_err_w;
assign fifo_err_o = fifo_err_w;
wire [K-1:0] pg_warn_w;
assign pg_warn_o = pg_warn_w;

// generate K test_fifos
genvar i;
generate
	for(i = 0; i < K; i = i + 1)
    begin : fifo_lane
      fifo_lane #(.N(N), .M(M)) fifo_lane_i(
        clk_i,
        rst_i,
        fifo_err_w[i],
        pg_warn_w[i]
      ); 
    end
endgenerate

endmodule
