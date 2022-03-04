module db_buff(
  input   clk_i,
	input		sig_i,
	output	sig_o
);

(* ASYNC_REG = "TRUE" *) reg sig_r;
(* ASYNC_REG = "TRUE" *) reg sig_rr;

assign	sig_o = sig_rr;

always @(posedge clk_i) begin
  sig_r		<= sig_i;
  sig_rr	<= sig_r;
end

endmodule
