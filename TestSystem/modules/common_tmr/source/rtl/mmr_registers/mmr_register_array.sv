//-----------------------------------------------------------------------------
// Title         : mmr_register_array
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : mmr_register_array.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.03.2017
// Last modified : 04.03.2017
//-----------------------------------------------------------------------------
// Description :
// MMR register with different voting configurations
// reset is sync
// voiting scheme:
//                 0: no voting, only valid input is 0
//                 1: 1 single voter, output of voter is triplicated
//                 2: 1 single voter, output 0 is from voter, output K_MMR-1:K_MMR-2 is from 0:1
//                 3: 3 voters
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 04.03.2017 : created (ML)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module mmr_register_array
      #(parameter int VOTING_SCHEME = -1, // voting scheme used in the register
        parameter int         K_MMR = 3, // K value used for K-modular redundancy
        parameter int         N = 16, // register width
        parameter int         MISMATCH_EN = 1, // if 1 warnign signal is generated
        parameter int [N-1:0] RESET_VALUE = 0 // reset value for the ff
    )
   (input logic clk_i, rst_i,
    input logic [N-1:0]  D_i [K_MMR-1:0],
    output logic [N-1:0] Q_o [K_MMR-1:0],
    output logic         mismatch_o
    );

   logic [N-1:0]                    mismatch_s;

         generate
            for (genvar i=0; i<N ; i++) begin : for_gen_register_array
               mmr_register
                          #(
                            // Parameters
                            .VOTING_SCHEME   (VOTING_SCHEME),
                            .K_MMR           (K_MMR),
                            .MISMATCH_EN     (MISMATCH_EN),
                            .RESET_VALUE     (RESET_VALUE[i])
                            /*autoinstparam*/)
               mmr_register_inst_i
                          (
                           // Outputs
                           .Q_o              (Q_o[i]),
                           .mismatch_o       (mismatch_s[i]),
                           // Inputs
                           .clk_i            (clk_i),
                           .rst_i            (rst_i),
                           .D_i              (D_i[i])
                           /*autoinst*/);
            end
         endgenerate

   assign mismatch_o = |mismatch_s;

endmodule // mmr_register_array

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
