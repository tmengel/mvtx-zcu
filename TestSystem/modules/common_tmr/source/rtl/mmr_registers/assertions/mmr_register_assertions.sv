//-----------------------------------------------------------------------------
// Title         : mmr_register_assertions
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : mmr_register_assertions.svh
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
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

module mmr_register_assertions
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter int K_MMR_CLOCK = 1, // size of the clock input: if 1 then a single clock is provided to all the flop, if equal to K_MMR then multiple clocks are provided
    parameter int MISMATCH_EN = 1, // if 1 warnign signal is generated
    parameter int RESET_VALUE = 0,
    parameter int VOTING_SCHEME = -1 // voting scheme used in the register
    )
   (input bit clk, rst,
    input bit D_i [K_MMR-1:0],
    input bit Q_o [K_MMR-1:0],
    input bit mismatch_o
    );

   import common_assertions::*;
   import mmr_general_assertions::*;

      function logic to_packed_array(logic unpacked_array [K_MMR-1:0]);
         begin
            logic [K_MMR-1:0]   packed_array;
            for (int i =0; i<K_MMR;i++)
              packed_array[i] = unpacked_array[i];
            return packed_array;
         end
      endfunction // to_packed_array

   logic [K_MMR-1:0]            D_i_packed, Q_o_packed;
   //assign D_i_packed = to_packed_array(D_i);
   //assign Q_o_packed = to_packed_array(Q_o);
   assign D_i_packed = {>>{D_i}};
   assign Q_o_packed = {>>{Q_o}};

   clocking cb@(posedge clk);
      input                 rst;
      input                 D_i_packed;
      input                 Q_o_packed, mismatch_o;
   endclocking // cb
   default clocking cb;

      function bit no_upset(logic [K_MMR-1:0] data);
         begin
            return (data=={K_MMR{1'b1}} || data=={K_MMR{1'b0}} || data=={K_MMR{1'bX}});
         end
      endfunction // no_upset

      function bit upset(logic [K_MMR-1:0] data);
         begin
            return (data!={K_MMR{1'b1}} && data!={K_MMR{1'b0}});
         end
      endfunction // upset

      function bit majority(logic [K_MMR-1:0] data);
         begin
            if (K_MMR==3)
              return ((data[0]==data[1] && data[0]==1'b1) || (data[0]==data[2] && data[0]==1'b1) || (data[1]==data[2] && data[1]==1'b1));
            else if (K_MMR==5)
              return ((data[0]==data[1] && data[0]==data[2] && data[0]==1'b1) || (data[0]==data[1] && data[0]==data[3] && data[0]==1'b1) || (data[0]==data[1] && data[0]==data[4] && data[0]==1'b1) ||
                      (data[0]==data[2] && data[0]==data[3] && data[0]==1'b1) || (data[0]==data[2] && data[0]==data[4] && data[0]==1'b1) ||
                      (data[0]==data[3] && data[0]==data[4] && data[0]==1'b1) ||
                      (data[1]==data[2] && data[1]==data[3] && data[1]==1'b1) || (data[1]==data[2] && data[1]==data[4] && data[1]==1'b1) ||
                      (data[1]==data[3] && data[1]==data[4] && data[1]==1'b1) ||
                      (data[2]==data[3] && data[2]==data[4] && data[2]==1'b1)
                      );
         end
      endfunction // majority

      ////////////////////////////////////////////////////////////////////////////////////////////
      // property definition
      ////////////////////////////////////////////////////////////////////////////////////////////
      // property checking for mismatch assertion on input error
      property mismatch_triggered_on_error_reg(int position,
                                               logic [K_MMR-1:0] input_i,
                                               logic [K_MMR-1:0] output_o,
                                               logic             mismatch_o,
                                               logic             disable_signal);
         disable iff(disable_signal)
           ($past(input_i[position]) != output_o[0]) |-> (mismatch_o==1'b1);
      endproperty

      property mismatch_asserted_correctly(logic disable_signal, logic [K_MMR-1:0] input_i, logic mismatch_o);
         disable iff(disable_signal)
           // data is changed and data with upset |=> get a mismatch
           input_i!=$past(input_i) && upset(input_i) |=> mismatch_o==1'b1;
      endproperty

      property mismatch_asserted_correctly_1(logic disable_signal, logic [K_MMR-1:0] input_i, logic mismatch_o);
         disable iff(disable_signal)
           // data is changed and data with upset |=> get a mismatch
           input_i!=$past(input_i) && upset($past(input_i)) |-> mismatch_o==1'b1;
      endproperty

      property reset_takes_place_on_reset(logic rst, logic disable_signal, logic [K_MMR-1:0] output_o);
         disable iff(disable_signal)
           rst |=> output_o == {K_MMR{RESET_VALUE}};
      endproperty

      property output_is_the_same_in_single_voter_scheme(logic [K_MMR-1:0] output_o,
                                                         int position, logic disable_signal);
         disable iff(disable_signal)
           (output_o[position] == output_o[0]);
      endproperty

      property output_is_consistent(logic disable_signal, logic [K_MMR-1:0] output_o);
         disable iff(disable_signal)
           no_upset(output_o);
      endproperty

      property output_is_consistent_in_cross_vote_logic(logic disable_signal, logic [K_MMR-1:0] input_i, logic output_o [K_MMR-1:0]);
         disable iff(disable_signal)
           // output is the cross vote: MSBs are the replica of the LSBs, LSBs are the voted version of the whole input
           input_i!=$past(input_i) |=> output_o == {input_i[1:0], {(K_MMR-2){majority((input_i))}}};
           //input_i!=$past(input_i) |=> output_o == {(input_i[1:0]), {(K_MMR-2){majority((input_i))}}};
      endproperty

      // property output_is_correct_in_full_voted_registers(logic [K_MMR-1:0] output_o, logic [K_MMR-1:0] input_i,
      //                                                    logic disable_signal);
      //    disable iff(disable_signal)
      // endproperty

      ////////////////////////////////////////////////////////////////////////////////////////////
      // assert
      ////////////////////////////////////////////////////////////////////////////////////////////
      kmmr_is_odd_assert: assert property((K_MMR_is_odd(.K_MMR(K_MMR),  .disable_signal(cb.rst))))
        else $error("K_MMR should be an odd value! Current K_MMR is %d", K_MMR);

      kmmr_is_valid_assert: assert property((K_MMR_is_valid(.K_MMR(K_MMR), .disable_signal(cb.rst))))
        else $error("K_MMR should be an implemented value [3,5]! Current K_MMR is %d", K_MMR);

      kmmrclock_is_valid_assert: assert property((K_MMR_CLOCK_is_valid(.K_MMR_CLOCK(K_MMR_CLOCK),
                                                                  .K_MMR(K_MMR),
                                                                  .disable_signal(cb.rst))))
        else $error("K_MMR_CLOCK should be either 1 or K_MMR! Current K_MMR_CLOCK is %d", K_MMR_CLOCK);

      // voting logic
      generate
         if (VOTING_SCHEME!=0 && MISMATCH_EN==1)
           begin
              check_error: assert property(mismatch_asserted_correctly(.disable_signal(cb.rst),
                                                                       .input_i(cb.D_i_packed),
                                                                       .mismatch_o(cb.mismatch_o)))
                else $error("error not spotted at output!");

            // check_error_1: assert property(mismatch_asserted_correctly_1(.disable_signal(cb.rst),
            //                                                              .input_i(cb.D_i_packed),
            //                                                              .mismatch_o(cb.mismatch_o)))
            //   else $error("error not spotted at output!");

           end
      endgenerate

      // reset
      check_reset: assert property(reset_takes_place_on_reset(.rst(cb.rst),
                                                              .disable_signal(1'b0),
                                                              .output_o(cb.Q_o_packed)))
        else $error("reset did not take place");

      // voting scheme 0,1,3:
      generate
         if_gen_output_consistency_ass : if (VOTING_SCHEME!=2) // voting scheme 2 is not
           begin
              output_consistency: assert property(output_is_consistent(.disable_signal(cb.rst||rst),
                                                                       .output_o(cb.Q_o_packed)))
                else $error("output is not consistent in tmr register");
         end  else begin
             output_consistency_xvote: assert property(output_is_consistent_in_cross_vote_logic(.disable_signal(cb.rst||rst),
                                                                                          .input_i(cb.D_i_packed),
                                                                                          .output_o(cb.Q_o_packed)))
               else $error("output is not consistent in tmr register with cross vote");
          end
      endgenerate

      ////////////////////////////////////////////////////////////////////////////////////////////
      // coverage
      ////////////////////////////////////////////////////////////////////////////////////////////
      generate
         if_gen_mismatch_assert : if (MISMATCH_EN==1 && VOTING_SCHEME!=0) begin
            mismatch_triggered:  cover property($rose(cb.mismatch_o));
            mismatch_released:   cover property($fell(cb.mismatch_o));
         end
      endgenerate

      rst_released:   cover property($fell(cb.rst));

      endmodule // mmr_register_assertions

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions" "../../common/assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
