// dataShifter.v

module dataShifter #(parameter N = 8192, M = 32)(
  input               clk_i,
  input               rst_i,
  input               load_i,
  input               sh_data_i,
  input       [N-1:0] data_i,
  output      [M-1:0] data_o
  );

reg [N-1:0] data_r;
assign data_o = data_r[31:0];

always @(posedge clk_i) begin
  if(rst_i) begin
    data_r  <= 'b0;
  end else if(load_i) begin
    data_r  <= data_i;
  end else if(sh_data_i) begin
    data_r  <= data_r >> M;
  end else begin
    data_r  <= data_r;
  end
end

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
