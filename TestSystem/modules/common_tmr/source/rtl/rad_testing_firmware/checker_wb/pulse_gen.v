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

module pulse_gen #(parameter N=8, START=0, STOP=16)(
  input		        clk_i,
  input		        rst_i,
  output          pls_o
  );

reg [N-1:0] cnt_r;
reg         pls_r;
assign pls_o = pls_r;

always @(posedge clk_i) begin
  if (rst_i) begin
    cnt_r <= 0;
    pls_r <= 0;
  end else begin
    cnt_r <= cnt_r + 1;
    pls_r <= (cnt_r >= START & cnt_r <= STOP) ? 1'b1 : 1'b0;
  end
end

endmodule
