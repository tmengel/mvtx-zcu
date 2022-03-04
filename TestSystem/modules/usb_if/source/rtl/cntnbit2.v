////////////////////////////////////////////////////////////////////////////////
// Title        : An N-bit counter
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : cntnbit.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-11-30
// Last update  : 2015-11-30
// Platform     : Xilinx Vivado 2015.2
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: An N-bit counter
////////////////////////////////////////////////////////////////////////////////

module cntnbit2 #(parameter N = 8)(
  input               clk_i,
  input               rst_i,
  input               inc_i,
  output      [N-1:0] cnt_o
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
