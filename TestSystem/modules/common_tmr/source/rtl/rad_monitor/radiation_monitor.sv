////////////////////////////////////////////////////////////////////////////////
// Title        : Radiation monitor
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : radiation_monitor.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-08-17
// Last update  : 2017-08-17
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-7
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Radiation monitor for the different modules in the firmware
//              Provides a
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module radiation_monitor
  #(
    parameter int G_SINGLE_ARRAY_INPUT_SIZE = 16, // max size of the single mismatch array from a module
    parameter int G_MODULES_CONNECTED = 5, // number of modules connected
    parameter int G_OUTPUT_ARRAY_SIZE = 8,  // output array size
    parameter int G_ADDITIONAL_MISMATCH = 1 //
    )
   (
    input logic                                                          clk_i, // clock input
    input logic                                                          rst_i, // synchronous reset input

    // inputs from different modules
    input logic [G_MODULES_CONNECTED-1:0][G_SINGLE_ARRAY_INPUT_SIZE-1:0] mismatch_i,
    input logic [G_MODULES_CONNECTED-1:0][G_SINGLE_ARRAY_INPUT_SIZE-1:0] mismatch_2nd_i,

    // fifo interface
    output logic                                                         fifo_writeclock_o,
    output logic                                                         fifo_write_o,
    output logic [G_OUTPUT_ARRAY_SIZE-1:0]                               fifo_data_o,
    input logic                                                          fifo_full_i
    );

   logic [G_MODULES_CONNECTED-1:0][G_OUTPUT_ARRAY_SIZE-1:0] module_cnt_s, module_cnt_2nd_s;
   (* DONT_TOUCH = "true" *) logic [G_MODULES_CONNECTED-1:0]                          module_cntup_s, module_cntup_2nd_s;

   // counters:
   // The instantaneous value of the mismatch signals is latched and recorded
   generate
      for (genvar i = 0; i<G_MODULES_CONNECTED; i++) begin

         assign module_cntup_s[i] = (mismatch_i[i]==16'b0)? 1'b0 : 1'b1;

         upcounter_tmr_wrapper #(
                                 .BIT_WIDTH                  (G_OUTPUT_ARRAY_SIZE),
                                 .IS_SATURATING              (1'b0),
                                 .VERBOSE                    (1'b0),
                                 .G_SEE_MITIGATION_TECHNIQUE (0),
                                 .G_MISMATCH_EN              (1'b0)
                                 )
         mismatch_counter_inst (
                                .CLK          (clk_i),
                                .RST          (rst_i),
                                .RST_CNT      (1'b0),
                                .CNT_UP       (module_cntup_s[i]),
                                .CNT_VALUE    (module_cnt_s[i]),
                                .MISMATCH     (),
                                .MISMATCH_2ND     ()
                                );

         if (G_ADDITIONAL_MISMATCH == 1) begin

            assign module_cntup_2nd_s[i] = (mismatch_i[i]==mismatch_2nd_i[i])? 1'b0 : 1'b1;

            upcounter_tmr_wrapper #(
                                    .BIT_WIDTH                  (G_OUTPUT_ARRAY_SIZE),
                                    .IS_SATURATING              (1'b0),
                                    .VERBOSE                    (1'b0),
                                    .G_SEE_MITIGATION_TECHNIQUE (0),
                                    .G_MISMATCH_EN              (1'b0)
                                    )
            mismatch_counter_2nd_inst (
                                   .CLK          (clk_i),
                                   .RST          (rst_i),
                                   .RST_CNT      (1'b0),
                                   .CNT_UP       (module_cntup_2nd_s[i]),
                                   .CNT_VALUE    (module_cnt_2nd_s[i]),
                                       .MISMATCH     (),
                                       .MISMATCH_2ND     ()
                                   );
         end
      end
   endgenerate

   // FSM handling the data transmission
   localparam int                                 STATE_BITS = 3;
   localparam int                                 RESET_ST          = 0,
                                                  IDLE_ST           = 1,
                                                  TX_ADDRESS_ST     = 2,
                                                  TX_VALUE_ST       = 3,
                                                  TX_COUNTER_ST     = 4,
                                                  TX_VALUE_2ND_ST   = 5,
                                                  TX_COUNTER_2ND_ST = 6;

   logic [STATE_BITS-1:0]                         actual_state_s, next_state_s;

   int                                            actual_module_s, next_module_s;

   function int f_increment_module_cntr(input int actual_value);
      int                                         next_value;
      begin
         next_value = actual_value + 1;
         if (next_value==G_MODULES_CONNECTED) begin
            next_value = 0;
         end
         return next_value;
      end
   endfunction // if


   // Sequential next state process (SRST)
   always_ff @(posedge clk_i) begin : p_update
      if (rst_i) begin
         actual_state_s  <= RESET_ST;
         actual_module_s <= 0;
      end else begin
        actual_state_s <= next_state_s;
         actual_module_s <= next_module_s;
      end
   end

   // comb process to calculate next stage
   always_comb  begin : p_next

      fifo_write_o = 1'b0;
      fifo_data_o  = 'hDEAD;
      next_module_s  = actual_module_s;

      case (actual_state_s)
        RESET_ST: begin
           next_state_s = IDLE_ST;
           next_module_s = 0;
        end

        IDLE_ST:
          next_state_s = TX_ADDRESS_ST;

        TX_ADDRESS_ST:
          if (fifo_full_i) begin
             next_state_s = TX_ADDRESS_ST;
          end else begin
             next_state_s = TX_VALUE_ST;
             fifo_write_o = 1'b1;
             fifo_data_o  = actual_module_s[G_OUTPUT_ARRAY_SIZE-1:0];
          end

        TX_VALUE_ST:
          if (fifo_full_i) begin
             next_state_s = TX_VALUE_ST;
          end else begin
             next_state_s = TX_COUNTER_ST;
             fifo_write_o = 1'b1;
             fifo_data_o  = mismatch_i[actual_module_s][G_OUTPUT_ARRAY_SIZE-1:0];
          end

        TX_COUNTER_ST:
          if (fifo_full_i) begin
             next_state_s = TX_COUNTER_ST;
          end else begin
             fifo_write_o = 1'b1;
             fifo_data_o  = module_cnt_s[actual_module_s];
             if (G_ADDITIONAL_MISMATCH) begin
                next_state_s = TX_VALUE_2ND_ST;
                next_module_s = actual_module_s;
             end else begin
                next_state_s = TX_ADDRESS_ST;
                next_module_s = f_increment_module_cntr(.actual_value(actual_module_s));
             end
          end

        TX_VALUE_2ND_ST:
          if (G_ADDITIONAL_MISMATCH) begin
             if (fifo_full_i) begin
                next_state_s = TX_VALUE_2ND_ST;
             end else begin
                next_state_s = TX_COUNTER_2ND_ST;
                fifo_write_o = 1'b1;
                fifo_data_o  = mismatch_2nd_i[actual_module_s];
             end
          end else
            next_state_s = RESET_ST;

        TX_COUNTER_2ND_ST:
          if (G_ADDITIONAL_MISMATCH) begin
             if (fifo_full_i) begin
                next_state_s = TX_COUNTER_2ND_ST;
             end else begin
                next_state_s = TX_ADDRESS_ST;
                fifo_write_o = 1'b1;
                fifo_data_o  = module_cnt_2nd_s[actual_module_s];
                next_module_s = f_increment_module_cntr(.actual_value(actual_module_s));
             end
          end else
            next_state_s = RESET_ST;

        default: begin // default state for safety
           next_state_s = RESET_ST;
           fifo_write_o = 1'b0;
           fifo_data_o  = 'hDEAD;
           next_module_s = actual_module_s;
        end
      endcase
   end

   // Output fifo
   assign fifo_writeclock_o = clk_i;

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
