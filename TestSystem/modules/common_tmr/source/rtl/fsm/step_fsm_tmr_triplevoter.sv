//-----------------------------------------------------------------------------
// Title         : step_fsm_tmr_triplevoter
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : step_fsm_tmr_triplevoter.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// Tmr-ed version of the step_fsm.sv state machine
// (Triple voter)
//
// 8 state-Moore machine given as example.
// It is able to recognize two different sequences (S1, S2)
// FSM starts in IDLE and stays there until one of the two sequences header
// is recognized.
// At this stage the machine expects the sequence in input, else it goes to
// ERROR and then to idle.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module step_fsm_tmr_triplevoter
  #(parameter int IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter [IO_SIZE_G-1:0]      IDLE = 0,
    S1_A = 1,
    S1_B = 2,
    S1_C = 3,
    S2_A = 4,
    S2_B = 5,
    S2_C = 6,
    ERROR  = 7,
    parameter logic [IO_SIZE_G-1:0] RESET_STATE_G = IDLE,
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR
    )
   (input logic        clk_i, rst_i,
    (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0]     data_a_i, data_b_i, data_c_i,
    output logic [IO_SIZE_G-1:0]    data_a_o, data_b_o, data_c_o
    );

   // Declare state register
   (* DONT_TOUCH = "true" *) logic [IO_SIZE_G-1:0]         next_state_a_s, actual_state_a_s, actual_state_voted_a_s;
   (* DONT_TOUCH = "true" *) logic [IO_SIZE_G-1:0]         next_state_b_s, actual_state_b_s, actual_state_voted_b_s;
   (* DONT_TOUCH = "true" *) logic [IO_SIZE_G-1:0]         next_state_c_s, actual_state_c_s, actual_state_voted_c_s;

   localparam TMR_MULTIPLICITY_C = 3;
   logic [IO_SIZE_G-1:0]            actual_state_tmr_s [TMR_MULTIPLICITY_C-1:0];


   // Sequential next state process (SRST)
   always_ff @(posedge clk_i) begin : p_update_a
      if (rst_i)
        actual_state_a_s <= RESET_STATE_G;
      else
        actual_state_a_s <= next_state_a_s;
   end

   always_ff @(posedge clk_i) begin : p_update_b
      if (rst_i)
        actual_state_b_s <= RESET_STATE_G;
      else
        actual_state_b_s <= next_state_b_s;
   end

   always_ff @(posedge clk_i) begin : p_update_c
      if (rst_i)
        actual_state_c_s <= RESET_STATE_G;
      else
        actual_state_c_s <= next_state_c_s;
   end


   // voting for output stage and next state
   assign actual_state_tmr_s[0] = actual_state_a_s;
   assign actual_state_tmr_s[1] = actual_state_b_s;
   assign actual_state_tmr_s[2] = actual_state_c_s;

   majority_voter_array#(
                         // Parameters
                         .K_MMR                 (TMR_MULTIPLICITY_C),
                         .MISMATCH_EN           (1'b0),
                         .N                     (IO_SIZE_G)
                         /*autoinstparam*/)
   voter_state_array_a(
                     // Outputs
                     .mismatch_o     (),
                     .output_o       (actual_state_voted_a_s),
                     // Inputs
                     .assert_clk_i   (clk_i),
                     .assert_rst_i   (rst_i),
                     .input_i        (actual_state_tmr_s)
                     /*autoinst*/);

   majority_voter_array#(
                         // Parameters
                         .K_MMR                 (TMR_MULTIPLICITY_C),
                         .MISMATCH_EN           (1'b0),
                         .N                     (IO_SIZE_G)
                         /*autoinstparam*/)
   voter_state_array_b(
                     // Outputs
                     .mismatch_o     (),
                     .output_o       (actual_state_voted_b_s),
                     // Inputs
                     .assert_clk_i   (clk_i),
                     .assert_rst_i   (rst_i),
                     .input_i        (actual_state_tmr_s)
                     /*autoinst*/);

   majority_voter_array#(
                         // Parameters
                         .K_MMR                 (TMR_MULTIPLICITY_C),
                         .MISMATCH_EN           (1'b0),
                         .N                     (IO_SIZE_G)
                         /*autoinstparam*/)
   voter_state_array_c(
                     // Outputs
                     .mismatch_o     (),
                     .output_o       (actual_state_voted_c_s),
                     // Inputs
                     .assert_clk_i   (clk_i),
                     .assert_rst_i   (rst_i),
                     .input_i        (actual_state_tmr_s)
                     /*autoinst*/);


   // combinatorial next state process
   // 3 processes:
   next_state #(
                // Parameters
                .IO_SIZE_G              (IO_SIZE_G),
                .IDLE                   (IDLE),
                .S1_A                   (S1_A),
                .S1_B                   (S1_B),
                .S1_C                   (S1_C),
                .S2_A                   (S2_A),
                .S2_B                   (S2_B),
                .S2_C                   (S2_C),
                .ERROR                  (ERROR),
                .RESET_STATE_G          (RESET_STATE_G),
                .DEFAULT_STATE_G        (DEFAULT_STATE_G)
                /*autoinstparam*/)
   p_next_a(
            // Outputs
            .next_state_o                 (next_state_a_s),
            // Inputs
            .actual_state_i               (actual_state_voted_a_s),
            .data_i                       (data_a_i)
            /*autoinst*/);

   next_state #(
                // Parameters
                .IO_SIZE_G              (IO_SIZE_G),
                .IDLE                   (IDLE),
                .S1_A                   (S1_A),
                .S1_B                   (S1_B),
                .S1_C                   (S1_C),
                .S2_A                   (S2_A),
                .S2_B                   (S2_B),
                .S2_C                   (S2_C),
                .ERROR                  (ERROR),
                .RESET_STATE_G          (RESET_STATE_G),
                .DEFAULT_STATE_G        (DEFAULT_STATE_G)
                /*autoinstparam*/)
   p_next_b(
            // Outputs
            .next_state_o                 (next_state_b_s),
            // Inputs
            .actual_state_i               (actual_state_voted_b_s),
            .data_i                       (data_b_i)
            /*autoinst*/);

   next_state #(
                // Parameters
                .IO_SIZE_G              (IO_SIZE_G),
                .IDLE                   (IDLE),
                .S1_A                   (S1_A),
                .S1_B                   (S1_B),
                .S1_C                   (S1_C),
                .S2_A                   (S2_A),
                .S2_B                   (S2_B),
                .S2_C                   (S2_C),
                .ERROR                  (ERROR),
                .RESET_STATE_G          (RESET_STATE_G),
                .DEFAULT_STATE_G        (DEFAULT_STATE_G)
                /*autoinstparam*/)
   p_next_c(
            // Outputs
            .next_state_o                 (next_state_c_s),
            // Inputs
            .actual_state_i               (actual_state_voted_c_s),
            .data_i                       (data_c_i)
            /*autoinst*/);


   // Output combinatorial process
   // this allows inferring a LUT for the output
   always_comb begin : p_output_a
      data_a_o = actual_state_voted_a_s;
   end

   always_comb begin : p_output_b
      data_b_o = actual_state_voted_b_s;
   end

   always_comb begin : p_output_c
      data_c_o = actual_state_voted_c_s;
   end

endmodule // step_fsm_tmr_triplevoter

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
