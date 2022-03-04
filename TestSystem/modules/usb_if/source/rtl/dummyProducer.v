// @ksielewi
// N-bit dummy producer
module dummyProducer #(parameter N = 32)(
  input           clk_i,
  input           rst_i,
  input           en_i,
  input           fifo_full_i,
  input           fifo_almst_full_i,
  output reg      fifo_wr_o,
  output  [N-1:0] cnt_o
);

reg [N-1:0] cnt_r;
assign cnt_o = cnt_r;

always @(posedge clk_i) begin
  if (rst_i) begin
    cnt_r     <= 0;
    fifo_wr_o <= 1'b0;
  end else if(en_i & !fifo_almst_full_i) begin
    cnt_r     <= cnt_r + 1;
    fifo_wr_o <= 1'b1;
  end else begin
    cnt_r     <= cnt_r;
    fifo_wr_o <= 1'b0;
  end
end

endmodule
