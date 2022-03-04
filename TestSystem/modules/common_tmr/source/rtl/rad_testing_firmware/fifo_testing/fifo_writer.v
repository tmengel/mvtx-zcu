// krzysztof.sielewicz@cern.ch
// fifo_writer.v

(* DONT_TOUCH = "true" *) module fifo_writer #(parameter
  N = 32,
  M = 3)(
  input           clk_i,
  input           rst_i,
  input           fifo_full_i,
  input           fifo_almst_full_i,
  output reg      fifo_wr_o,
  output [N-1:0]  fifo_data_o,
  output          pg_warn_o
);

reg en_pat_gen_r;

// TMR-ed pattern generator
pat_gen #(.N(N), .M(M)) pat_gen(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .en_i   (en_pat_gen_r),
  .pat_o  (fifo_data_o),
  .warn_o (pg_warn_o)
);

// control writing to the FIFO
always @(posedge clk_i) begin
  if (rst_i) begin
    fifo_wr_o     <= 1'b0;
    en_pat_gen_r  <= 1'b0;
  end else if(!fifo_almst_full_i) begin
    fifo_wr_o <= 1'b1;
    en_pat_gen_r  <= 1'b1;
  end else begin
    fifo_wr_o <= 1'b0;
    en_pat_gen_r  <= 1'b0;
  end
end

endmodule
