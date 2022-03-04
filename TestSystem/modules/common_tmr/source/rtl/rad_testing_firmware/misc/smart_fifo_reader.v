// krzysztof.sielewicz@cern.ch
// fifo_reader.v

(* DONT_TOUCH = "true" *) module smart_fifo_reader #(parameter
  N = 32,
  M = 3)(
  input           clk_i,
  input           rst_i,
  input           en_i,
  input           fifo_empty_i,
  input           fifo_almst_empty_i,
  output  reg     fifo_rd_o,
  input   [N-1:0] fifo_data_i,
  output  [M-1:0] err_o
);

(* DONT_TOUCH = "true" *) reg [M-1:0] err_r;
assign err_o = err_r;

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

(* DONT_TOUCH = "true" *) reg [N-1:0] fifo_data_r[M*2-1:0];

always @(posedge clk_i)
  begin : shifter
    integer j;
    if (rst_i) begin
      for(j = 0; j < M*2; j = j + 1)
        fifo_data_r[j] <= {N{1'b0}};
      err_r <= {N{1'b0}};
    end else begin
      for(j = 0; j < M; j = j + 1) begin
        fifo_data_r[j*2] <= fifo_data_i;
        fifo_data_r[j*2+1] <= fifo_data_r[j*2];
        
        if((fifo_data_r[j*2] != fifo_data_r[j*2+1] + 1'd1) & en_i)
          err_r[j] <= 1'b1;
        else
          err_r[j] <= 1'b0;
      end
  end
end

endmodule
