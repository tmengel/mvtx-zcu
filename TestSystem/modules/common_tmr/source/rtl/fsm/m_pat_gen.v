// ksielewi
// krzysztof.sielewicz@cern.ch
// m_pat_gen.v

`timescale 1ns/100ps
// if DEBUG is defined then an additional signal
// inj_err_i is added to enable error injection
`define DEBUG

(* DONT_TOUCH = "true" *) module m_pat_gen #(parameter
  IO_SIZE_G=4,
  M=3,
  LIM=14)(
  input           clk_i,
  input           rst_i,
  input           inc_i,
`ifdef DEBUG
  input           inj_err_i,
`endif
  output  [IO_SIZE_G-1:0] cnt_o,
  output          warn_o
);

wire [IO_SIZE_G*M-1:0] cnt_w;

// generate M pattern generators
genvar i;
generate
  for(i=0; i<M; i=i+1)
    begin : pat_gen
      (* DONT_TOUCH = "true" *) pat_gen #(.IO_SIZE_G(IO_SIZE_G)) pat_gen(
        clk_i,
        rst_i,
        inc_i,
`ifdef DEBUG
        inj_err_i,
`endif
        cnt_w[i*IO_SIZE_G+IO_SIZE_G-1 -: IO_SIZE_G]
      );
    end
endgenerate

// voter
(* DONT_TOUCH = "true" *) mvtr #(.M(M), .N(IO_SIZE_G)) mvtr(
  .vtr_i  (cnt_w),
  .vtr_o  (cnt_o),
  .warn_o (warn_o)
);

endmodule
