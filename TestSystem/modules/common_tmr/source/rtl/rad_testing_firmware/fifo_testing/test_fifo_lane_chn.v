// krzysztof.sielewicz@cern.ch
// test_fifo_lane_chn.v

module test_fifo_lane_chn #(parameter
  N = 32,
  K = 48,
  M = 3,
  L = 8)(
  input             clk_i,
  input             rst_i,
  
  input   [L*K-1:0] injectdbiterr_i,
  input   [L*K-1:0] injectsbiterr_i,
  
  output  [L*K-1:0] sbiterr_o,
  output  [L*K-1:0] dbiterr_o,
  
  output  [L-1:0]   pg_warn_o,
  output  [L*M-1:0] err_o
);

// generate K test_fifos
genvar i;
generate
	for(i=0; i<L; i=i+1)
    begin : fifo_lane_chn
      fifo_lane_chn #(.N(N), .K(K), .M(M)) fifo_lane_chn(
        clk_i,
        rst_i,
        injectdbiterr_i[i*K+K-1 -: K],
        injectsbiterr_i[i*K+K-1 -: K],
        sbiterr_o[i*K+K-1 -: K],
        dbiterr_o[i*K+K-1 -: K],
        pg_warn_o[i],
        err_o[i*M+M-1 -: M]
      );
    end
endgenerate

endmodule
