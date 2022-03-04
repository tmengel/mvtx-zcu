//-----------------------------------------------------------------------------
// Title         : dut
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : dut.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// dut block composed of a pattern generator every PATTERN_GENERATOR_FANOUT_G lane_fsm,
// and a comparator for every fsm.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps
module fsm_dut
  #(
    parameter int LANES_G = 8, // total number of lanes (NOTE LANES_G%PATTERN_GENERATOR_FANOUT_G==0)
    parameter int STEPS_G = 2, // number of steps in each lane
    parameter int PATTERN_GENERATOR_FANOUT_G = 4, // number of lanes fed by the pattern generator
    parameter int IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int READOUT_WIDTH_G = 32, // width of the output FIFO data vector
    parameter int TMR_COMPARATOR_G = 1, // if 1 the comparator is triplicated
    parameter int LANE_MITIGATION_G = 0) // if 0 no mitigation is applied, if 1 Hamming SEC is applied, if 3 full TMR (including I/O) is applied,
                                         // if 4 TMR (with single I/O) is applied, if 5 full TMR (with triple voter) is applied to the lanes.
   (
      input logic                  clk_i, rst_i,
      // DP2 FIFO interface
      input                        DP2_fifo_full_i,
      input                        DP2_fifo_almst_full_i,
      output                       DP2_fifo_wr_o,
      output [READOUT_WIDTH_G-1:0] DP2_fifo_data_o,
      // DP3 FIFO interface
      input                        DP3_fifo_full_i,
      input                        DP3_fifo_almst_full_i,
      output                       DP3_fifo_wr_o,
      output [READOUT_WIDTH_G-1:0] DP3_fifo_data_o
      );

   // synthesis translate_off
   assert #0 (LANES_G%PATTERN_GENERATOR_FANOUT_G == 0);
   // synthesis translate_on

   localparam int                BLOCKS_C = int'(LANES_G/PATTERN_GENERATOR_FANOUT_G);
   logic [LANES_G-1:0]    error_state_s, error_mismatch_s;


   genvar                 i;
   generate
      for (i=0; i<(LANES_G/PATTERN_GENERATOR_FANOUT_G); i++) begin
         if ((LANE_MITIGATION_G == 0) || (LANE_MITIGATION_G == 1) || (LANE_MITIGATION_G == 4)) begin
            (* DONT_TOUCH = "true" *)
            dut_block #(
                        // Parameters
                        .IO_SIZE_G         (IO_SIZE_G),
                        .STEPS_G           (STEPS_G),
                        .PATTERN_GENERATOR_FANOUT_G(PATTERN_GENERATOR_FANOUT_G),
                        .TMR_COMPARATOR_G  (TMR_COMPARATOR_G),
                        .LANE_MITIGATION_G(LANE_MITIGATION_G)
                        /*autoinstparam*/)
            dut_block (
                       // Outputs
                       (* DONT_TOUCH = "true" *) .error_state_o      (error_state_s[(i+1)*PATTERN_GENERATOR_FANOUT_G -1:i*PATTERN_GENERATOR_FANOUT_G]),
                       (* DONT_TOUCH = "true" *) .error_mismatch_o   (error_mismatch_s[(i+1)*PATTERN_GENERATOR_FANOUT_G -1:i*PATTERN_GENERATOR_FANOUT_G]),
                       // Inputs
                       .clk_i              (clk_i),
                       .rst_i              (rst_i)
                       /*autoinst*/);
         end // if ((LANE_MITIGATION_G == 0) || (LANE_MITIGATION_G == 1) || (LANE_MITIGATION_G == 4))
         else if ((LANE_MITIGATION_G == 3) || (LANE_MITIGATION_G == 5)) begin
            (* DONT_TOUCH = "true" *)
            dut_block_tmr #(
                            // Parameters
                            .IO_SIZE_G         (IO_SIZE_G),
                            .STEPS_G           (STEPS_G),
                            .PATTERN_GENERATOR_FANOUT_G(PATTERN_GENERATOR_FANOUT_G),
                            .LANE_MITIGATION_G  (LANE_MITIGATION_G),
                            .TMR_COMPARATOR_G  (TMR_COMPARATOR_G)
                            /*autoinstparam*/)
            dut_block_tmr (
                           // Outputs
                           (* DONT_TOUCH = "true" *) .error_state_o      (error_state_s[(i+1)*PATTERN_GENERATOR_FANOUT_G -1:i*PATTERN_GENERATOR_FANOUT_G]),
                           (* DONT_TOUCH = "true" *) .error_mismatch_o   (error_mismatch_s[(i+1)*PATTERN_GENERATOR_FANOUT_G -1:i*PATTERN_GENERATOR_FANOUT_G]),
                           // Inputs
                           .clk_i              (clk_i),
                           .rst_i              (rst_i)
                           /*autoinst*/);
         end // if ((LANE_MITIGATION_G == 3) || (LANE_MITIGATION_G == 5))
      end // for (i=0; i<(LANES_G/PATTERN_GENERATOR_FANOUT_G); i++)
   endgenerate

   // tbRdout DP2
   tbRdout #(.READOUT_WIDTH_G(READOUT_WIDTH_G), .LANES_G(LANES_G))
   tbRdout_DP2(
               .clk_i              (clk_i),
               .rst_i              (rst_i),
               .monitor_i          (error_mismatch_s),
               .fifo_full_i        (DP2_fifo_full_i),
               .fifo_almst_full_i  (DP2_fifo_almst_full_i),
               .fifo_wr_o          (DP2_fifo_wr_o),
               .fifo_data_o        (DP2_fifo_data_o)
               );

   // tbRdout DP3
   tbRdout #(.READOUT_WIDTH_G(READOUT_WIDTH_G), .LANES_G(LANES_G))
   tbRdout_DP3(
               .clk_i              (clk_i),
               .rst_i              (rst_i),
               .monitor_i          (error_state_s),
               .fifo_full_i        (DP3_fifo_full_i),
               .fifo_almst_full_i  (DP3_fifo_almst_full_i),
               .fifo_wr_o          (DP3_fifo_wr_o),
               .fifo_data_o        (DP3_fifo_data_o)
               );


endmodule // fsm_dut

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../rad_testing_firmware/readout/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
