// krzysztof.sielewicz@cern.ch
// reg_n_bit.v

(* DONT_TOUCH = "true" *) module reg_n_bit #(parameter N = 32)(
  input               clk_i,
  input               rst_i,
  input       [N-1:0] data_i,
  output  reg [N-1:0] data_o
);
  
always @(posedge clk_i) begin
  if (rst_i)
    data_o <= {N{1'b0}};
  else
    data_o <= data_i;
end

endmodule
