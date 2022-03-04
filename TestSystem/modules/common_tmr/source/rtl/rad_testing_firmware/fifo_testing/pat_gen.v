// krzysztof.sielewicz@cern.ch
// pat_gen 32-bit, TMR-ed, pattern generator

`timescale 1 ns / 100 ps

(* DONT_TOUCH = "true" *) module pat_gen #(parameter
  N = 32,
  M = 3)(
  input           clk_i,
  input           rst_i,
  input           en_i,
  output  [N-1:0] pat_o,
  output          warn_o
);

wire [M*N-1:0] pat_w;

// generate patter generators
genvar i;
generate
	for(i = 0; i < M; i = i + 1)
	begin : cntnbit
      (* DONT_TOUCH = "true" *) cntnbit #(.N(N)) cntnbit_i(
        clk_i,
        rst_i,
        1'b0,
        en_i,
        pat_w[i * N + N - 1 -: N]
      );
	end
endgenerate

// vote the output from 3 outputs from patter generators
mvtr #(.M(3), .N(32)) mvtr(
  .vtr_i  (pat_w),
  .vtr_o  (pat_o),
  .warn_o (warn_o)
);

endmodule
