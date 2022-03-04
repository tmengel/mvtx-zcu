//-----------------------------------------------------------------------------
// Title         : h3_correct_tb.sv
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : h3_correct_tb.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 28.03.2017
// Last modified : 28.03.2017
//-----------------------------------------------------------------------------
// Description     : testbench for the h3_correct_n_k.sv
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module testbench
  #(
    parameter int n = -1,
    parameter int k = -1
    )(
      input logic clk,
      output logic [n-1:0] data_o,
      input logic [n-1:0] data_i,
      input logic sec_i);

   clocking cb@(posedge clk);
      output          data_o;
   endclocking // cb

   // import the encode_f function
   `include "../../../source/rtl/hamming/includes/hamming_definitions.sv"

   initial
     begin
        int i, j;
        cb.data_o <= 0;

        $display("Starting test using correct sequences");
        for (i = 0; i<2**k; i++) begin
           $display("encoded sequence of %b is %b", i[k-1:0], encode_f(i));
           @cb
                 cb.data_o <= encode_f(i);
           @cb
             assert (data_i == encode_f(i))
               else $error("mismatch in data received: data_sent %b, data_received %b", encode_f(i), data_i);
           @cb
             assert (sec_i == 1'b0)
               else $error("mismatch in sec: expected 1'b0, received %b", sec_i);
        end


        $display("Starting test using incorrect sequences");
        for (i = 0; i<2**k; i++) begin
           $display("encoded sequence of %b is %b", i[k-1:0], encode_f(i));
           for (j =0; j<n; j++) begin
              @cb
                   cb.data_o <= encode_f(i);
              @cb
                   cb.data_o[j] <= ~cb.data_o[j];
              @cb
                assert (data_i == encode_f(i))
                  else $error("mismatch in data received: data_sent %b, data_received %b", encode_f(i), data_i);
              @cb
                assert (sec_i == 1'b1)
                  else $error("mismatch in sec: expected 1'b1, received %b", sec_i);
           end // for (j =0; j<n; j++)
        end // for (i = 0; i<2**k; i++)

        @ cb
          $finish;
     end // initial begin

   assign data_o = cb.data_o;

endmodule

module top ();

   localparam int n = 15;
   localparam int k = 11;
   bit   clk, rst, sec;
   bit [n-1:0] data_tb, data_corr;

   clocking cb@(posedge clk);
      output rst;
   endclocking // cb

   always
     #6ns assign clk = !clk;

   testbench #(.n(n), .k(k))
     testbench_inst(.clk(clk),
               .data_o(data_tb),
               .data_i(data_corr),
               .sec_i(sec));

   h3_correct_n_k #(.n(n), .k(k))
   DUT(.hamming_i(data_tb),
                  .hamming_corrected_o(data_corr),
                  .sec_o(sec));


endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../../rtl/hamming/." "../../rtl/hamming/assertions/")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// eval:(verilog-read-includes)
// End:
