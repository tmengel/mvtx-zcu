// warn_cntr.v
module warn_cntr #(parameter TB_ARR = 256, CNT_REG_SIZE = 16)(
  input                   clk_i,
  input                   rst_i,
  input   [TB_ARR-1:0]    warn_i,
  output  [TB_ARR*16-1:0] warnCnt_o
);

wire [TB_ARR-1:0] cntInc_w;

genvar i;
generate
	for(i = 0; i < TB_ARR; i = i + 1)
    begin : edge_det
      edge_det edge_det_i(
        .rst_i      (rst_i),
        .clk_i      (clk_i),
        .sig_i      (warn_i[i]),
        .edge_det_o (cntInc_w[i])
      );
    end
endgenerate

generate
	for(i = 0; i < TB_ARR; i = i + 1)
    begin : cntnbit
      cntnbit #(.N(CNT_REG_SIZE)) cntnbit_i(
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .clr_i  (1'b0),
        .inc_i  (cntInc_w[i]),
        .cnt_o  (warnCnt_o[i * 16 + 15 -: 16])
      );
    end
endgenerate

endmodule
