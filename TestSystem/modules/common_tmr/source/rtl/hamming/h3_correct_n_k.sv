//-----------------------------------------------------------------------------
// Title         : h3_correct_n_k.sv
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : h3_correct_n_k.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 27.03.2017
// Last modified : 27.03.2017
//-----------------------------------------------------------------------------
// Description    : Hamming error correction block.
//                  Used for (n, k, t)-Hamming code with
//                  n: encoded vector size               = 15,7
//                  k: information bits                  = 11,4
//                  t: correction capability of the code = 1
//                  The block is completely combinatorial
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module h3_correct_n_k
  #(parameter int n = 15, // size of the input array
    parameter int k = 11 // size of the information array
    )
  (input logic [n-1:0] hamming_i, // input vector
   output logic [n-1:0] hamming_corrected_o, // output corrected vector
   output logic sec_o // output bit asserted if an error has been corrected (SEC)
   );

   localparam int r = (n-k); // size of the redundant array

   logic [r-1:0]  syndrome_s;
   integer        error_position;
   logic [n:1]    hamming_s, hamming_corrected_s;

   function logic [n-1:0] syndrome_f(input logic [n:1] hamming_s = 0);
      begin
         logic [r-1:0]  syndrome_v;
         if (n == 7) begin
            syndrome_v[0] = ^{hamming_s[7], hamming_s[5], hamming_s[3], hamming_s[1]};
            syndrome_v[1] = ^{hamming_s[7], hamming_s[6], hamming_s[3], hamming_s[2]};
            syndrome_v[2] = ^{hamming_s[7], hamming_s[6], hamming_s[5], hamming_s[4]};
         end else if (n == 15) begin
            syndrome_v[0] = ^{hamming_s[15], hamming_s[13], hamming_s[11], hamming_s[9],  hamming_s[7],  hamming_s[5],  hamming_s[3], hamming_s[1]};
            syndrome_v[1] = ^{hamming_s[15], hamming_s[14], hamming_s[11], hamming_s[10], hamming_s[7],  hamming_s[6],  hamming_s[3], hamming_s[2]};
            syndrome_v[2] = ^{hamming_s[15], hamming_s[14], hamming_s[13], hamming_s[12], hamming_s[7],  hamming_s[6],  hamming_s[5], hamming_s[4]};
            syndrome_v[3] = ^{hamming_s[15], hamming_s[14], hamming_s[13], hamming_s[12], hamming_s[11], hamming_s[10], hamming_s[9], hamming_s[8]};
         end
         return syndrome_v;
      end
   endfunction

   always @(hamming_i) begin
      hamming_s[n:1] = hamming_i[n-1:0];

      syndrome_s = syndrome_f(.hamming_s(hamming_s));

      hamming_corrected_s = hamming_s;
      error_position = syndrome_s;

      if (error_position == 0)
         sec_o = 1'b0;
      else begin
         sec_o = 1'b1;
         hamming_corrected_s[error_position] = ~hamming_s[error_position];
      end
   end // always @ (hamming_i)

   assign hamming_corrected_o[n-1:0] = hamming_corrected_s[n:1];

   // assertions block
   // synthesis translate_off
   h3_correct_n_k_assertions
     #(// Parameters
       .n                               (n),
       .k                               (k),
       .r                               (r)
       /*AUTOinstparam*/)
   h3_correct_n_k_assertions_inst
   (// Inputs
    .hamming_i                          (hamming_i),
    .hamming_corrected_o                (hamming_corrected_o),
    .sec_o                              (sec_o),
    .syndrome_s                         (syndrome_s)
    /*AUTOinst*/);
   // synthesis translate_on

endmodule // h3_correct_n_k

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
