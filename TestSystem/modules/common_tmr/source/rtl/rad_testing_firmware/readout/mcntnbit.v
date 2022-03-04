// krzysztof.sielewicz@cern.ch
// mcntnbit.v

(* DONT_TOUCH = "true" *) module mcntnbit #(parameter
  N = 8,
  M = 3)(
  input           clk_i,
  input           rst_i,
  input           inc_i,
  output  [N-1:0] cnt_o
);

// generate M N-bit counters
wire [N*M-1:0] cnt_w;
genvar i;
generate
	for(i = 0; i < M; i = i + 1)
	begin : cntnbit
      (* DONT_TOUCH = "true" *) cntnbit2 #(.N(N)) cntnbit2_i(
        clk_i,
        rst_i,
        inc_i,
        cnt_w[i*N + N-1 -: N]
      );
	end
endgenerate

// vote the output from 3 outputs from the counters
mvtr #(.M(M), .N(N)) mvtr(
  .vtr_i  (cnt_w),
  .vtr_o  (cnt_o),
  .warn_o ()
);

endmodule
