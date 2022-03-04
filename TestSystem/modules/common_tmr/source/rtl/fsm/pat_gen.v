// ksielewi
// krzysztof.sielewicz@cern.ch
// pat_gen.v

`timescale 1ns/100ps
// if DEBUG is defined then an additional signal
// inj_err_i is added to enable error injection
`define DEBUG

module pat_gen #(parameter IO_SIZE_G=4, LIM=14)(
  input               clk_i,
  input               rst_i,
  input               inc_i,
`ifdef DEBUG
  input               inj_err_i,
`endif
  output reg  [IO_SIZE_G-1:0] cnt_o
);

always @(posedge clk_i) begin
  if (rst_i) begin
    cnt_o <= 0;
  end else if(inc_i) begin
    if(cnt_o == LIM)
      cnt_o <= {IO_SIZE_G{1'b0}};
`ifdef DEBUG
    else if(inj_err_i)
      cnt_o <= 4'd15;
`endif
    else
      cnt_o <= cnt_o + 1;
  end else begin
    cnt_o <= cnt_o;
  end
end

endmodule
