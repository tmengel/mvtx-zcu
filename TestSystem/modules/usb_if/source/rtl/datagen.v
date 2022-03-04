module datagen #(parameter N = 32)(
  input           clk_i,
  input           rst_i,
  input           inc_i,
  output  [N-1:0] cnt_o
  );

reg [N-1:0] cnt_r;
assign cnt_o = cnt_r;

always @(posedge clk_i) begin
  if (rst_i) begin
    cnt_r <= 0;
  end else if(inc_i) begin
    cnt_r <= cnt_r + 1;
  end else begin
    cnt_r <= cnt_r;
  end
end

endmodule
