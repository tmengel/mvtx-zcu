module db_buff_n #(parameter WIDTH = 32)(
  input                   clk_i,
  input                   rst_i,
	input		[WIDTH - 1: 0]  sig_i,
	output	[WIDTH - 1: 0]  sig_o
);

(* ASYNC_REG = "TRUE" *) reg	[WIDTH - 1: 0]	sig_r;
(* ASYNC_REG = "TRUE" *) reg	[WIDTH - 1: 0]	sig_rr;

assign	sig_o = sig_rr;

always @(posedge clk_i) begin
  if(rst_i) begin
    sig_r   <= {WIDTH{1'b0}};
    sig_rr  <= {WIDTH{1'b0}};
  end else begin
    sig_r		<= sig_i;
    sig_rr	<= sig_r;
  end 
end

endmodule
