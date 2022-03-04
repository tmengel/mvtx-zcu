////////////////////////////////////////////////////////////////////////////////
// Title        : An N-bit counter
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : cntnbit.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2017-04-16
// Last update  : 2017-04-16
////////////////////////////////////////////////////////////////////////////////
// Description: An N-bit upcounter with ovrflv flag
////////////////////////////////////////////////////////////////////////////////

// (* DONT_TOUCH = "true" *)
module cntr_nbit_ovrflv #(parameter N = 4)(
  input               clk_i,
  input               rst_i,
  input               inc_i,
  output  reg [N-1:0] cnt_o,
  output  reg         ovrflv_o
);

always @(posedge clk_i) begin
  if (rst_i) begin
    cnt_o     <= {N{1'b0}};
    ovrflv_o  <= 1'b0;
  end else if(inc_i) begin
    cnt_o     <= cnt_o + 1;
    ovrflv_o  <= (cnt_o == {N{1'b1}}) ? 1'b1 : 1'b0;
  end else begin
    cnt_o     <= cnt_o;
    ovrflv_o  <= 1'b0;
  end
end

endmodule
