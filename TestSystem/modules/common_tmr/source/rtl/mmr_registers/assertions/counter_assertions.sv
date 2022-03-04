//-----------------------------------------------------------------------------
// Title         : counter_assertions
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : counter_assertions.svh
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
// Created       : 07.03.2017
// Last modified : 07.03.2017
//-----------------------------------------------------------------------------
// Description :
// Asserion module for counter
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 07.03.2017 : created (ML)
//-----------------------------------------------------------------------------

module counter_assertions
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter bit MISMATCH_EN = 1'b1, // if 1 warnign signal is generated
    parameter bit RESET_VALUE = 1'b0,
    parameter int VOTING_SCHEME = -1, // voting scheme used in the register
    parameter int BIT_WIDTH = 16, // counter bit width
    parameter bit IS_SATURATING = 0, // 1 if the counter saturates (displays a message if set in verbose mode)
    parameter bit VERBOSE = 0
    )
    (input bit clk, rst,
     input bit                 reset_counter_i,
     input bit                 countup_i [K_MMR-1:0],
     input bit [BIT_WIDTH-1:0] counter_value_o [K_MMR-1:0],
     input bit                 mismatch_o
    );

   import common_assertions::*;
   import mmr_general_assertions::*;

   clocking cb@(posedge clk);
      input               rst;
      input               countup_i, reset_counter_i, mismatch_o;
      input               counter_value_o;
   endclocking // cb

   default clocking cb;

      function bit no_upset(logic data [K_MMR-1:0]);
         begin
            return (data=={K_MMR{1'b1}} || data=={K_MMR{1'b0}} || data=={K_MMR{1'bX}});
         end
      endfunction // no_upset

      function bit upset(logic data [K_MMR-1:0]);
         begin
            return (data!={K_MMR{1'b1}} && data!={K_MMR{1'b0}});
         end
      endfunction // upset

      function bit majority(logic data [K_MMR-1:0]);
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

      function bit majority_array(logic [BIT_WIDTH-1:0] data [K_MMR-1:0]);
         begin
            logic [BIT_WIDTH-1:0] dataout;
            for (int i=0; i<BIT_WIDTH; i++) begin
               logic data_in [K_MMR-1:0];
               for (int j=0; j<K_MMR; j++) begin
                  data_in[j] <= data[j][i];
               end
               dataout[i] <= majority(data_in);
            end
            return dataout;
         end
      endfunction

      logic countup_voted;
      logic counter_value_voted;

      assign countup_voted = majority(cb.countup_i);
      assign counter_value_voted = majority_array(cb.counter_value_o);

      ////////////////////////////////////////////////////////////////////////////////////////////
      // property definition
      ////////////////////////////////////////////////////////////////////////////////////////////
      // property checking for mismatch assertion on input error

      property reset_results_in_reset(logic rst, logic disable_signal,
                                      logic [BIT_WIDTH-1:0] counter_value [K_MMR-1:0],
                                      int   position);
        disable iff(disable_signal)
          rst |=> counter_value_o[position]==0;
      endproperty

      property countup_prop_0(logic countup_voted, logic disable_signal,
                              logic [BIT_WIDTH-1:0] counter_value [K_MMR-1:0],
                              int                   position);
         disable iff(disable_signal)
           countup |=> counter_value_o[position]!=$past(counter_value[position]);
      endproperty

      property countup_prop(logic countup_voted, logic disable_signal,
                            logic [BIT_WIDTH-1:0] counter_value [K_MMR-1:0],
                            int                   position);
        disable iff(disable_signal)
          countup |=> counter_value_o[position]==($past(counter_value[position])+1);
      endproperty

      property saturation_prop(logic countup_voted, logic disable_signal,
                               logic [BIT_WIDTH-1:0] counter_value [K_MMR-1:0],
                               int                   position);
         disable iff(disable_signal)
           majority_array(counter_value)==(2**BIT_WIDTH) && countup |=> counter_value[position]==(2**BIT_WIDTH);
      endproperty

      property wraparound_prop(logic countup_voted, logic disable_signal,
                               logic [BIT_WIDTH-1:0] counter_value [K_MMR-1:0],
                               int                   position);
         disable iff(disable_signal)
           majority_array(counter_value)==(2**BIT_WIDTH) && countup |=> counter_value[position]==0;
      endproperty

      // property reset_takes_place_on_reset(logic rst, logic disable_signal, logic output_o [K_MMR-1:0]);
      //    disable iff(disable_signal)
      //      rst |=> ;
      // endproperty

      ////////////////////////////////////////////////////////////////////////////////////////////
      // assert
      ////////////////////////////////////////////////////////////////////////////////////////////
      kmmr_is_odd_assert: assert property((K_MMR_is_odd(.K_MMR(K_MMR),  .disable_signal(cb.rst))))
        else $error("K_MMR should be an odd value! Current K_MMR is %d", K_MMR);

      kmmr_is_valid_assert: assert property((K_MMR_is_valid(.K_MMR(K_MMR), .disable_signal(cb.rst))))
        else $error("K_MMR should be an implemented value [3,5]! Current K_MMR is %d", K_MMR);

      // voting logic

      // resets and countup
      generate
         genvar                 i;
         for (i=0; i<K_MMR; i++) begin
            if (VOTING_SCHEME!=2 ||(VOTING_SCHEME!=2 && i==2)) begin
               // Resets
               rst: assert property(reset_results_in_reset(.rst(cb.rst), .disable_signal(1'b0),
                                                           .counter_value(cb.counter_value_o),
                                                           .position(i)))
                 else $error("reset did not result into a reset of the output value");

               rst_cntr: assert property(reset_results_in_reset(.rst(cb.reset_counter_i),
                                                                .disable_signal(1'b0),
                                                                .counter_value(cb.counter_value_o),
                                                                .position(i)))
                 else $error("reset_counter did not result into a reset of the output value");

               // countup
               countup: assert property(countup_prop(.countup_voted(countup_voted),
                                                     .disable_signal(cb.rst||cb.reset_counter_i||IS_SATURATING),
                                                     .counter_value(cb.counter_value_o),
                                                     .position(i)))
                 else $error("countup failed");

               countup_0: assert property(countup_prop_0(.countup_voted(countup_voted),
                                                         .disable_signal(cb.rst||cb.reset_counter_i),
                                                         .counter_value(cb.counter_value_o),
                                                         .position(i)))
                 else $error("countup failed");

               if (IS_SATURATING) begin
                  saturation_ass: assert property(saturation_prop(.countup_voted(countup_voted),
                                                                  .disable_signal(cb.rst||cb.reset_counter_i),
                                                                  .counter_value(cb.counter_value_o),
                                                                  .position(i)))
                    else $error("saturation failed");

               end else begin

                  wraparound_ass: assert property(wraparound_prop(.countup_voted(countup_voted),
                                                                  .disable_signal(cb.rst||cb.reset_counter_i),
                                                                  .counter_value(cb.counter_value_o),
                                                                  .position(i)))
                    else $error("wraparound failed");

               end
            end // if (VOTING_SCHEME!=2 ||(VOTING_SCHEME!=2 && i==2))
         end // for (i=0; i<K_MMR; i++)
      endgenerate

      ////////////////////////////////////////////////////////////////////////////////////////////
      // coverage
      ////////////////////////////////////////////////////////////////////////////////////////////

      generate
         genvar k;
         for (k=0; k<K_MMR; k++) begin
            countup_asserted: cover property($rose(cb.countup_i[k]));
            countup_released: cover property($fell(cb.countup_i[k]));
         end
      endgenerate

      rst_cntr_asserted: cover property($rose(cb.reset_counter_i));
      rst_cntr_released: cover property($fell(cb.reset_counter_i));

      rst_released: cover property($fell(cb.rst));

      endmodule // counter_assertions

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "../." "../../common/assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
