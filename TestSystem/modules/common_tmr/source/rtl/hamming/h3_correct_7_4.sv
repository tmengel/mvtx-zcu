// Filename        : h3_correct_7_4.sv
// Description     : Hamming error correction block.
//                   Used for (n, k, t)-Hamming code with
//                   n: encoded vector size               = 7
//                   k: information bits                  = 4
//                   t: correction capability of the code = 1
//                   The block is completely combinatorial
// Author          : Matteo Lupi
// Created On      : Mon Mar 27 14:53:38 2017
// Last Modified By: Matteo Lupi
// Last Modified On: Mon Mar 27 14:53:38 2017
// Update Count    : 0
// Status          : Unknown, Use with caution!


module h3_correct_7_4
  #(parameter int n = 7, // size of the input array
    parameter int k = 4 // size of the information array
    )
  (input logic [n-1:0] hamming_i, // input vector
   output logic [n-1:0] hamming_corrected_o, // output corrected vector
   output logic sec_o // output bit asserted if an error has been corrected (sec)
   );

   localparam int r = (n-k); // size of the redundant array

   integer        error_position;
   logic [r-1:0]  syndrome_s;
   logic [n:1]    hamming_s, hamming_corrected_s;

   always @(hamming_i) begin
      hamming_s[n:1] = hamming_i[n-1:0];

      syndrome_s[0] = ^{hamming_s[7], hamming_s[5], hamming_s[3], hamming_s[1]};
      syndrome_s[1] = ^{hamming_s[7], hamming_s[6], hamming_s[3], hamming_s[2]};
      syndrome_s[2] = ^{hamming_s[7], hamming_s[6], hamming_s[5], hamming_s[4]};

      hamming_corrected_o = hamming_s;
      assign error_position = syndrome_s;

      if (error_position == 0)
         warning_o = 1'b0;
      else begin
         warning_o = 1'b1;
         hamming_corrected_o[error_position] = ~hamming_s[error_position];
      end
   end // always @ (hamming_i)

   assign hamming_corrected_o[n-1:0] = hamming_corrected_s[n:1];

endmodule // h3_correct_7_4

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
