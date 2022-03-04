//
// A simple register to cross clock domain
// Output consistency is not guarantied. Use it only for static or stable when used signals
//
`timescale 1ns/10ps

`include "local.inc"

module xclk_reg #(
    parameter SIZE = 512,
    parameter RESET_VALUE = 0,
    parameter DOUBLE_BUFFER = 1
  )
  (
    input                   RESET,
    input [(SIZE-1):0]      INPUT,

    input                   CLK,
    output reg [(SIZE-1):0] OUTPUT = RESET_VALUE
  );

  reg [(SIZE-1):0]         OUT_0 = RESET_VALUE;

  always @(posedge RESET or posedge CLK)
    if (RESET)
      OUT_0 <= `Tp RESET_VALUE;
    else
      OUT_0 <= `Tp INPUT;

  generate
    if (DOUBLE_BUFFER)
    begin: double_buffer_on
      always @(posedge RESET or posedge CLK)
        if (RESET)
          OUTPUT <= `Tp RESET_VALUE;
        else
          OUTPUT <= `Tp OUT_0;
    end
    else
    begin: double_buffer_off
      always @(*)
        OUTPUT <= `Tp OUT_0;
    end
  endgenerate

endmodule

