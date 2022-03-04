///////////////////////////////////////////////////////////////////////////////
// Title        : oddr_fabric
// Project      : RUv0a
////////////////////////////////////////////////////////////////////////////////
// File         : oddr_fabric.sv
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2017-07-12
// Last update  : 2017-07-12
// Platform     : Xilinx Vivado 2016.1
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: Fabric ODDR used to allow timing optimization for design
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-07-12  1.0      ML            Created
//-----------------------------------------------------------------------------

`timescale 1ns/10ps

module oddr_fabric #(
                  parameter logic DfResetValue_c = 1'b0,
                  parameter logic DrResetValue_c = 1'b0
                  )
   (
    input  rst_i, // sync reset
    input  clk_i, // clock

    input  dr_i, // data launched by the rising edge clock
    input  df_i, // data launched on the falling edge of the clock

    output q_o // DDR output
    );

   logic                         s_dr_d1, s_df_d1;

   // posedge flop
   always @(posedge clk_i) begin
      if (rst_i)
        s_dr_d1 <= DrResetValue_c;
      else begin
         s_dr_d1 <= dr_i;
      end
   end

   // negedge flop
   always @(negedge clk_i) begin
      if (rst_i)
        s_df_d1 <= DfResetValue_c;
      else begin
         s_df_d1 <= df_i;
      end
   end

   // mux
   assign q_o = (clk_i) ? s_df_d1 : s_dr_d1;

endmodule // oddr_fabric
