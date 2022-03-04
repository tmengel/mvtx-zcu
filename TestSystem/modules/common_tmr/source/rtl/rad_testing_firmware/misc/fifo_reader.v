// krzysztof.sielewicz@cern.ch
// fifo_reader.v

(* DONT_TOUCH = "true" *) module fifo_reader #(parameter
  N = 32)(
  input           clk_i,
  input           rst_i,
  input           fifo_empty_i,
  input           fifo_almst_empty_i,
  output  reg     fifo_rd_o,
  input   [N-1:0] fifo_data_i
);

// reading from the FIFO
always @(posedge clk_i) begin
  if (rst_i) begin
    fifo_rd_o <= 1'b0;
  end else if(!fifo_almst_empty_i) begin
    fifo_rd_o <= 1'b1;
  end else begin
    fifo_rd_o <= 1'b0;
  end
end

(* DONT_TOUCH = "true" *) reg [N-1:0] fifo_temp_r; 
always @(posedge clk_i)
  if (rst_i) begin
    fifo_temp_r <= {N{1'b0}};
  end else begin
    fifo_temp_r <= fifo_data_i;
  end

endmodule
