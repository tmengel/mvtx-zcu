// krzysztof.sielewicz@cern.ch
// fifo_glue_logic.v

module fifo_glue_logic(
  input           clk_i,
  input           rst_i,
  
  output reg      fifoA_rd_o,
  input           fifoA_almst_empty_i,
  
  input           fifoB_almst_full_i,
  output reg      fifoB_wr_o
);

reg fifoB_wr_1_r, fifoB_wr_2_r;

// control writing to the FIFO
always @(posedge clk_i) begin
  if (rst_i) begin
    fifoA_rd_o    <= 1'b0;
    fifoB_wr_1_r  <= 1'b0;
    fifoB_wr_2_r  <= 1'b0;
    fifoB_wr_o    <= 1'b0;
  end else if(!fifoA_almst_empty_i & !fifoB_almst_full_i) begin
    fifoA_rd_o    <= 1'b1;
    fifoB_wr_1_r  <= 1'b1;
    fifoB_wr_2_r  <= fifoB_wr_1_r;
    fifoB_wr_o    <= fifoB_wr_2_r;
  end else begin
    fifoA_rd_o    <= 1'b0;
    fifoB_wr_1_r  <= 1'b0;
    fifoB_wr_2_r  <= 1'b0;
    fifoB_wr_o    <= 1'b0;
  end
end

endmodule
