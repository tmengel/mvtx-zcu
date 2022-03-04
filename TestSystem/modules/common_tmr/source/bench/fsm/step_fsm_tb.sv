//-----------------------------------------------------------------------------
// Title         : step_fsm_tb
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : step_fsm_tb.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// tb for the step_fsm module
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module testbench
  #(
    parameter int IO_SIZE_G = 3,
    parameter int STEPS_G = 1
    )(
      input logic                    clk,
      output logic                   rst_o,
      output logic [IO_SIZE_G-1:0] data_o,
      input logic [IO_SIZE_G-1:0]  data_i,
      output logic                   correct_o
      );

   clocking cb@(posedge clk);
      output                         rst_o;
      output                         data_o;
      output                         correct_o;
   endclocking // cb

   bit [IO_SIZE_G-1:0]             data_delay [STEPS_G:0];

   localparam int                    seqlen_c = 4;
   localparam int                    repeat_cycles = 2;

   bit [IO_SIZE_G-1:0]             seq_idle[] = {0, 0, 0, 0};
   bit [IO_SIZE_G-1:0]             seq_1[] = {0, 1, 2, 3, 1, 2, 3, 0};
   bit [IO_SIZE_G-1:0]             seq_2[] = {0, 4, 5, 6, 4, 5, 6, 0};
   bit [IO_SIZE_G-1:0]             seq_3[] = {3, 2, 1, 3, 2, 1, 6, 5, 4, 3, 2, 1};
   bit [IO_SIZE_G-1:0]             seq_4[] = {1, 2, 3, 4, 5, 6, 0, 0, 0, 1, 2, 3, 1, 2, 3, 4, 5, 6, 1, 2, 3, 0, 0, 0, 0};

   task print_array(input bit [IO_SIZE_G-1:0] array[]);
      int i;
      $write("Q contains: ");
      for (i=0; i<array.size(); i++)
        $write("%g, ", array[i]);
      $write("\n");
   endtask // print_array

   task correct_sequence(input int repeat_cycles, input bit [IO_SIZE_G-1:0] array[], input bit correct = 1'b1);
      int i, j;
      bit [IO_SIZE_G-1:0] actual_data;
      int                      len ;

      len = array.size();

      $display("Starting test using sequence:");
      print_array(array);

      for (i = 0; i<2**repeat_cycles; i++) begin
         for (j =0; j<len; j++) begin
            @cb begin
               actual_data = array[j];
               cb.data_o <= actual_data;
            end
         end
      end
   endtask // correct_sequence

   initial
     begin
        int i, j;
        cb.correct_o <= 1'b1;
        cb.data_o <= 0;
        cb.rst_o <= 1'b1;

        #3 @cb;
        @cb
          cb.rst_o <= 1'b0;

        correct_sequence(.repeat_cycles(repeat_cycles),
                         .array(seq_idle),
                         .correct(1'b1));

        correct_sequence(.repeat_cycles(repeat_cycles),
                         .array(seq_1),
                         .correct(1'b1));

        correct_sequence(.repeat_cycles(repeat_cycles),
                         .array(seq_2),
                         .correct(1'b1));

        correct_sequence(.repeat_cycles(repeat_cycles),
                         .array(seq_3),
                         .correct(1'b1));

        correct_sequence(.repeat_cycles(repeat_cycles),
                         .array(seq_4),
                         .correct(1'b1));

        correct_sequence(.repeat_cycles(repeat_cycles),
                         .array(seq_idle),
                         .correct(1'b1));

        repeat(STEPS_G) @(posedge clk);
          @cb
          $finish;
     end // initial begin



endmodule

module checker_module
  #(parameter int IO_SIZE_G = 1
    )(
      input logic [IO_SIZE_G-1:0] data_dut_i, data_golden_i,
      input logic correct
      );

   assert #0 (data_dut_i == data_golden_i) else
     $error("data mismatch DUT %b, golden %b", data_dut_i, data_golden_i);

endmodule // checker

module top ();

   localparam int DATA_SIZE_C = 3;
   localparam int STEPS_C = 12;
   bit            clk;
   bit            tb_rst;
   bit [DATA_SIZE_C-1:0] tb_data, dut_data, golden_data, dut_data_tmr, dut_data_tmr_noio, dut_data_tmr_triplevoter, dut_data_hammingsec;
   localparam bit [DATA_SIZE_C-1:0] IDLE = 0,
                                      S1_A = 1,
                                      S1_B = 2,
                                      S1_C = 3,
                                      S2_A = 4,
                                      S2_B = 5,
                                      S2_C = 6,
                                      ERROR = 7;
   localparam bit [DATA_SIZE_C-1:0] RESET_STATE_C = IDLE;
   localparam bit [DATA_SIZE_C-1:0] DEFAULT_STATE_C = ERROR;

   always
     #6ns assign clk = !clk;

   testbench #(
               // Parameters
               .IO_SIZE_G             (DATA_SIZE_C),
               .STEPS_G                   (STEPS_C)
               /*autoinstparam*/)
     testbench_inst(
                    // Outputs
                    .rst_o              (tb_rst),
                    .data_o             (tb_data),
                    // Inputs
                    .clk                (clk),
                    .data_i             (dut_data),
                    .correct_o          (tb_correct)
                    /*autoinst*/);

   lane_fsm #(
              // Parameters
              .IO_SIZE_G              (DATA_SIZE_C),
              .IDLE                     (IDLE),
              .S1_A                     (S1_A),
              .S1_B                     (S1_B),
              .S1_C                     (S1_C),
              .S2_A                     (S2_A),
              .S2_B                     (S2_B),
              .S2_C                     (S2_C),
              .ERROR                    (ERROR),
              .RESET_STATE_G            (RESET_STATE_C),
              .DEFAULT_STATE_G          (DEFAULT_STATE_C),
              .STEPS_G                  (STEPS_C),
              .LANE_MITIGATION_G        (0)
              /*autoinstparam*/)
   DUT(
       // Outputs
       .data_o                          (dut_data),
       // Inputs
       .clk_i                           (clk),
       .rst_i                           (tb_rst),
       .data_i                          (tb_data)
       /*autoinst*/);

   lane_fsm #(
              // Parameters
              .IO_SIZE_G              (DATA_SIZE_C),
              .IDLE                     (IDLE),
              .S1_A                     (S1_A),
              .S1_B                     (S1_B),
              .S1_C                     (S1_C),
              .S2_A                     (S2_A),
              .S2_B                     (S2_B),
              .S2_C                     (S2_C),
              .ERROR                    (ERROR),
              .RESET_STATE_G            (RESET_STATE_C),
              .DEFAULT_STATE_G          (DEFAULT_STATE_C),
              .STEPS_G                  (STEPS_C),
              .LANE_MITIGATION_G        (1)
              /*autoinstparam*/)
   DUT_hammingsec(
           // Outputs
           .data_o                          (dut_data_hammingsec),
           // Inputs
           .clk_i                           (clk),
           .rst_i                           (tb_rst),
           .data_i                          (tb_data)
       /*autoinst*/);

   lane_fsm_tmr #(
              // Parameters
              .IO_SIZE_G              (DATA_SIZE_C),
              .IDLE                     (IDLE),
              .S1_A                     (S1_A),
              .S1_B                     (S1_B),
              .S1_C                     (S1_C),
              .S2_A                     (S2_A),
              .S2_B                     (S2_B),
              .S2_C                     (S2_C),
              .ERROR                    (ERROR),
              .RESET_STATE_G            (RESET_STATE_C),
              .DEFAULT_STATE_G          (DEFAULT_STATE_C),
              .STEPS_G                  (STEPS_C),
              .LANE_MITIGATION_G        (3)
              /*autoinstparam*/)
   DUT_tmr(
           // Outputs
           .data_o                          (dut_data_tmr),
           // Inputs
           .clk_i                           (clk),
           .rst_i                           (tb_rst),
           .data_a_i                          (tb_data),
           .data_b_i                          (tb_data),
           .data_c_i                          (tb_data)
       /*autoinst*/);

   lane_fsm #(
              // Parameters
              .IO_SIZE_G              (DATA_SIZE_C),
              .IDLE                     (IDLE),
              .S1_A                     (S1_A),
              .S1_B                     (S1_B),
              .S1_C                     (S1_C),
              .S2_A                     (S2_A),
              .S2_B                     (S2_B),
              .S2_C                     (S2_C),
              .ERROR                    (ERROR),
              .RESET_STATE_G            (RESET_STATE_C),
              .DEFAULT_STATE_G          (DEFAULT_STATE_C),
              .STEPS_G                  (STEPS_C),
              .LANE_MITIGATION_G        (4)
              /*autoinstparam*/)
   DUT_tmr_noio(
           // Outputs
           .data_o                          (dut_data_tmr_noio),
           // Inputs
           .clk_i                           (clk),
           .rst_i                           (tb_rst),
           .data_i                          (tb_data)
       /*autoinst*/);

   lane_fsm_tmr #(
              // Parameters
              .IO_SIZE_G              (DATA_SIZE_C),
              .IDLE                     (IDLE),
              .S1_A                     (S1_A),
              .S1_B                     (S1_B),
              .S1_C                     (S1_C),
              .S2_A                     (S2_A),
              .S2_B                     (S2_B),
              .S2_C                     (S2_C),
              .ERROR                    (ERROR),
              .RESET_STATE_G            (RESET_STATE_C),
              .DEFAULT_STATE_G          (DEFAULT_STATE_C),
              .STEPS_G                  (STEPS_C),
              .LANE_MITIGATION_G        (5)
              /*autoinstparam*/)
   DUT_tmr_triplevoter(
           // Outputs
           .data_o                          (dut_data_tmr_triplevoter),
           // Inputs
           .clk_i                           (clk),
           .rst_i                           (tb_rst),
           .data_a_i                          (tb_data),
           .data_b_i                          (tb_data),
           .data_c_i                          (tb_data)
       /*autoinst*/);

   lane_fsm_beh
     #(
       // Parameters
       .IO_SIZE_G                     (DATA_SIZE_C),
       .STEPS_G                         (STEPS_C),
       .IDLE                            (IDLE),
       .S1_A                            (S1_A),
       .S1_B                            (S1_B),
       .S1_C                            (S1_C),
       .S2_A                            (S2_A),
       .S2_B                            (S2_B),
       .S2_C                            (S2_C),
       .ERROR                           (ERROR),
       .RESET_STATE_G                   (RESET_STATE_C),
       .DEFAULT_STATE_G                 (DEFAULT_STATE_C)
       /*AUTOinstparam*/)
   GOLDEN
     (
      // Outputs
      .data_o                           (golden_data),
      // Inputs
      .clk_i                            (clk),
      .rst_i                            (tb_rst),
      .data_i                           (tb_data),
      .correct_i                        (tb_correct)
      /*autoinst*/);

   checker_module
     #(
       // Parameters
       .IO_SIZE_G                     (DATA_SIZE_C))
   checker_module(

                  // Inputs
                  .data_dut_i           (dut_data),
                  .data_golden_i        (golden_data),
                  .correct              (1'b1));

   checker_module
     #(
       // Parameters
       .IO_SIZE_G                     (DATA_SIZE_C))
   checker_module_hammingsec(

                  // Inputs
                  .data_dut_i           (dut_data_hammingsec),
                  .data_golden_i        (golden_data),
                  .correct              (1'b1));

   checker_module
     #(
       // Parameters
       .IO_SIZE_G                     (DATA_SIZE_C))
   checker_module_tmr(

                      // Inputs
                      .data_dut_i           (dut_data_tmr),
                      .data_golden_i        (golden_data),
                      .correct              (1'b1));

   checker_module
     #(
       // Parameters
       .IO_SIZE_G                     (DATA_SIZE_C))
   checker_module_tmr_noio(

                      // Inputs
                      .data_dut_i           (dut_data_tmr_noio),
                      .data_golden_i        (golden_data),
                      .correct              (1'b1));

   checker_module
     #(
       // Parameters
       .IO_SIZE_G                     (DATA_SIZE_C))
   checker_module_tmr_triplevoter(

                      // Inputs
                      .data_dut_i           (dut_data_tmr_triplevoter),
                      .data_golden_i        (golden_data),
                      .correct              (1'b1));


endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../../rtl/fsm/.")
// verilog-library-extensions:(".v" ".h" ".sv")
// eval:(verilog-read-includes)
// End:
