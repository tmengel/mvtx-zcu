//-----------------------------------------------------------------------------
// Title         : majority_voter_assertions
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : majority_voter_assertions.svh
// Author        : Matteo Lupi  <matte.lupi@cern.ch>
// Created       : 27.02.2017
// Last modified : 27.02.2017
//-----------------------------------------------------------------------------
// Description :
// Asserion module for majority voter
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 27.02.2017 : created (ML)
//-----------------------------------------------------------------------------

module majority_voter_assertions
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter int MISMATCH_EN = 1, // if 1 warnign signal is generated
    parameter int G_MISMATCH_REGISTERED = 0 // if 1 mismatch is registered
    )
   (input  logic clk, rst,
    input logic input_i [K_MMR-1:0],
    input logic output_o, mismatch_o
    );

   import common_assertions::*;
   import mmr_general_assertions::*;

   clocking cb@(posedge clk);
      input                 rst;
      input                 input_i;
      input                 output_o, mismatch_o;
   endclocking // cb


   default clocking cb;

   // property definition
      property mismatch_triggered_on_error(int position, logic [K_MMR-1:0] input_i,
                                           logic output_o, logic mismatch_o,
                                           logic disable_signal);
         disable iff(disable_signal)
           (input_i[position] != output_o) |-> (mismatch_o==1'b1);
      endproperty

      property mismatch_registered_triggered_on_error(int position, logic [K_MMR-1:0] input_i,
                                           logic output_o, logic mismatch_o,
                                           logic disable_signal);
         disable iff(disable_signal)
           (input_i[position] != output_o) |=> (mismatch_o==1'b1);
      endproperty


   // assert
      // kmmr_is_odd_assert: assert property((K_MMR_is_odd(.K_MMR(K_MMR), .disable_signal(cb.rst))))
      //   else $error("K_MMR should be an odd value! Current K_MMR is %d", K_MMR);
      // kmmr_is_valid_assert: assert property((K_MMR_is_valid(.K_MMR(K_MMR), .disable_signal(cb.rst))))
      //   else $error("K_MMR should be an implemented value [3,5]! Current K_MMR is %d", K_MMR);

      initial begin
         kmmr_is_odd_assert: assert property (K_MMR_is_odd(.K_MMR(K_MMR), .disable_signal(~cb.rst)))
           else $error("K_MMR should be an odd value! Current K_MMR is %d", K_MMR);
         kmmr_is_valid_assert: assert property (K_MMR_is_valid(.K_MMR(K_MMR), .disable_signal(cb.rst)))
           else $error("K_MMR should be an implemented value [3,5]! Current K_MMR is %d", K_MMR);
      end

      generate
         genvar                                  i;
         for (i=0; i<K_MMR; i++) begin : error_corrected_assert_for
            if (G_MISMATCH_REGISTERED == 0)
              error_corrected_assert: assert property(mismatch_triggered_on_error(.disable_signal(cb.rst || (cb.input_i[i] == cb.output_o)),
                                                                                  .position(i),
                                                                                  .input_i(cb.input_i),
                                                                                  .output_o(cb.output_o),
                                                                                  .mismatch_o(cb.mismatch_o)))
                else $error("error on register %d has not been corrected", i);
              else
                error_corrected_assert_reg: assert property(mismatch_registered_triggered_on_error(.disable_signal(cb.rst || (cb.input_i[i] == cb.output_o)),
                                                                                                   .position(i),
                                                                                                   .input_i(cb.input_i),
                                                                                                   .output_o(cb.output_o),
                                                                                                   .mismatch_o(cb.mismatch_o)))
                  else $error("error on register %d has not been corrected", i);
         end
      endgenerate


   // coverage
      mismatch_triggered:  cover property($rose(cb.mismatch_o));
      mismatch_released:   cover property($fell(cb.mismatch_o));


      endmodule // majority_voter_assertions

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions" "../../common/assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
