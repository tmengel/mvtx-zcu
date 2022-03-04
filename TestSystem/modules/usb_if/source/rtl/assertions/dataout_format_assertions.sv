////////////////////////////////////////////////////////////////////////////////
// Title        : dataout_format_assertions module
// Project      : Probecard (Imported to RUv0)
////////////////////////////////////////////////////////////////////////////////
// File         : dataout_format_assertions.sv
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2016-07-01
// Last update  : 2016-07-01
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: assertion module (non synth) to check correctness of design
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-07-29  1.0      ML            Created (work/WP3/ali-itsug-asic/shristoz/
//                                     ALPIDE_lightweight_model_release_development/
//                                     source/rtl/digital_periphery_rtl/assertions/
//                                     dtu_logic_itfc_assertions.sv)
//-----------------------------------------------------------------------------

module dataout_format_assertions
  #(
    parameter StateBitWidth_c = 3 // state_bit_width
    )
  (input clk,
   input                       rst,
   input                       fsm_stop,
   input                       fifoin_empty,
   input [StateBitWidth_c-1:0] next_RO_state,
   input [StateBitWidth_c-1:0] state
   );

   import common_assertions::*;

   clocking cb@(posedge clk);
      input                    rst, fsm_stop, state, next_RO_state, fifoin_empty;
   endclocking // cb

   // state mapping: (see dataout_format.vhd for confirm!)
   localparam RESET             =3'b000;
   localparam IDLE              =3'b001;
   localparam D0                =3'b010;
   localparam D1                =3'b011;
   localparam D2                =3'b100;
   localparam WAIT_FOR_NEXT_DATA=3'b101;
   localparam TX_AND_CONTINUE   =3'b110;
   localparam TX_END            =3'b111;

   default clocking cb;

      //********************
      // ASSERTIONS
      //********************

     // D0 -> tx_end
      logic                            d0_go_to_tx_end_condition;
      logic                            state_is_tx_end;

      assign d0_go_to_tx_end_condition = (cb.state == D0) &&
                                         (cb.fsm_stop == 1'b1);
      assign state_is_tx_end = (cb.state == TX_END);

      dataout_format_assert_d0_to_tx_end : assert property
      (two_signals_programmable_delay(.first_signal(d0_go_to_tx_end_condition), .second_signal(state_is_tx_end), .delay(3'd1), .disable_signal(cb.rst)))
        else
          $error("%m: No transition from D0 and fsm_stop to TX_END");

      // D1 -> tx_end
      logic                            d1_go_to_tx_end_condition;

      assign d1_go_to_tx_end_condition = (cb.state == D1) &&
                                         (cb.fsm_stop == 1'b1);

      dataout_format_assert_d1_to_tx_end : assert property
      (two_signals_programmable_delay(.first_signal(d1_go_to_tx_end_condition), .second_signal(state_is_tx_end), .delay(3'd1), .disable_signal(cb.rst)))
        else
          $error("%m: No transition from D1 and fsm_stop to TX_END");

      // D2 -> tx_end
      logic                            d2_go_to_tx_end_condition;

      assign d2_go_to_tx_end_condition = (cb.state == D2) &&
                                         (cb.fsm_stop == 1'b1);

      dataout_format_assert_d2_to_tx_end : assert property
      (two_signals_programmable_delay(.first_signal(d2_go_to_tx_end_condition), .second_signal(state_is_tx_end), .delay(3'd1), .disable_signal(cb.rst)))
        else
          $error("%m: No transition from D2 and fsm_stop to TX_END");


      // wait_for_next -> D0
      logic                            wait_for_next_go_to_d0_condition;
      logic                            state_is_d0;

      assign wait_for_next_go_to_d0_condition = (cb.state == WAIT_FOR_NEXT_DATA) &&
                                                (cb.fifoin_empty == 1'b0) &&
                                                (cb.next_RO_state == D0);
      assign state_is_d0 = (cb.state == D0);

      dataout_format_assert_wait_for_next_to_d0 : assert property
      (two_signals_programmable_delay(.first_signal(wait_for_next_go_to_d0_condition), .second_signal(state_is_d0), .delay(3'd1), .disable_signal(cb.rst)))
        else
          $error("%m: No transition from WAIT_FOR_NEXT and !fifoin_empty to D0");

      // wait_for_next -> D1
      logic                            wait_for_next_go_to_d1_condition;
      logic                            state_is_d1;

      assign wait_for_next_go_to_d1_condition = (cb.state == WAIT_FOR_NEXT_DATA) &&
                                                (cb.fifoin_empty == 1'b0) &&
                                                (cb.next_RO_state == D1);
      assign state_is_d1 = (cb.state == D1);

      dataout_format_assert_wait_for_next_to_d1 : assert property
      (two_signals_programmable_delay(.first_signal(wait_for_next_go_to_d1_condition), .second_signal(state_is_d1), .delay(3'd1), .disable_signal(cb.rst)))
        else
          $error("%m: No transition from WAIT_FOR_NEXT and !fifoin_empty to D1");

      // wait_for_next -> D2
      logic                            wait_for_next_go_to_d2_condition;
      logic                            state_is_d2;

      assign wait_for_next_go_to_d2_condition = (cb.state == WAIT_FOR_NEXT_DATA) &&
                                                (cb.fifoin_empty == 1'b0) &&
                                                (cb.next_RO_state == D2);
      assign state_is_d2 = (cb.state == D2);

      dataout_format_assert_wait_for_next_to_d2 : assert property
      (two_signals_programmable_delay(.first_signal(wait_for_next_go_to_d2_condition), .second_signal(state_is_d2), .delay(3'd1), .disable_signal(cb.rst)))
        else
          $error("%m: No transition from WAIT_FOR_NEXT and !fifoin_empty to D2");

      //********************
      // COVERAGE
      //********************

      // Coverage of alternative normal operating modes
       // logic sel_1200Mbps_mode;
       // assign sel_1200Mbps_mode = (cb.single_mode == 1'b0)              &&
       // (cb.rst_n      != 3'b000)              &&
       // (cb.ib_serial_link_speed == 2'b10 ||
       //  cb.ib_serial_link_speed == 2'b11)    &&
       // (cb.data_ready == 1'b1)               &&
       // (cb.tx_test_en == 1'b0);


       // dtu_logic_itfc_cov_1200Mbps_mode:
       // cover property(check_duration_single_bit_atleast(.line(sel_1200Mbps_mode),
       //  					        .duration(16'd4096),
       //  					        .disable_signal(1'b0)));

endmodule // dtu_logic_itfc_assertions
