// edge_det.v
module edge_det(
	input		rst_i,
	input		clk_i,
	input		sig_i,
	output	edge_det_o
);

reg			edge_det_r;
assign edge_det_o = edge_det_r;
reg	[1:0]	edge_det_tab_r;

always @(posedge clk_i, posedge rst_i) begin
	if(rst_i) begin
		edge_det_r      <= 1'b0;
		edge_det_tab_r  <= 2'd0;
	end else begin
		edge_det_tab_r[0] <= sig_i;
		edge_det_tab_r[1]	<= edge_det_tab_r[0];
		edge_det_r        <= (edge_det_tab_r == 2'b01) ? 1'b1 : 1'b0;
	end
end

endmodule
