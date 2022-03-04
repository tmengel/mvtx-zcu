// krzysztof.sielewicz@cern.ch
// reg_n_bit_tmr.v

(* DONT_TOUCH = "true" *) module reg_n_bit_tmr #(parameter N = 8)(
  input           clk_i,
  input           rst_i,
  input   [N-1:0] data_i,
  output  [N-1:0] data_o,
  output          warn_o
);

wire  [N-1:0] data_0_w;
wire  [N-1:0] data_1_w;
wire  [N-1:0] data_2_w;
  
reg_n_bit #(.N(N)) reg_n_bit_0(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .data_i (data_i),
  .data_o (data_0_w)
);

reg_n_bit #(.N(N)) reg_n_bit_1(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .data_i (data_i),
  .data_o (data_1_w)
);

reg_n_bit #(.N(N)) reg_n_bit_2(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .data_i (data_i),
  .data_o (data_2_w)
);

// vote the output from 3 outputs from patter generators
mvtr #(.M(3), .N(N)) mvtr(
  .vtr_i  ({data_2_w, data_1_w, data_0_w}),
  .vtr_o  (data_o),
  .warn_o (warn_o)
);

endmodule
