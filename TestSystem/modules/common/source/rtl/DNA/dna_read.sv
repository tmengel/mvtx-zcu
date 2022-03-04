//-----------------------------------------------------------------------------
// Title         : dna_read
// Project       : RUv1_Test
//-----------------------------------------------------------------------------
// File          : dna_read.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2016-11-29
// Last update  : 2016-08-09
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-Ultrascale
// Standard     : System Verilog
//-----------------------------------------------------------------------------
// Description : FSM for reading the "unique" DNA value from the FPGA
//-----------------------------------------------------------------------------
// Copyright (c) 2016 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

module dna_read
    #(parameter int C_DNA_SIZE = 96,
      parameter int WbDataWidth = 16,
      parameter int C_DNA_CLK_DIVIDER = 4)
   (
    input  logic                     clk_i,
    input  logic                     rst_i,
    input  logic                     do_read_dna_i,
    output logic [6*WbDataWidth-1:0] dna_value_o
    );

   localparam [1:0] C_IDLE = 2'd0, // IDLE state: waits for input
     C_READ  = 2'd1, // READ state: reads the value and loads it into the shirt register
     C_SCROLL = 2'd2, // SCROLL state: reads all the bits of the DNA
     C_DONE   = 2'd3; // DONE state:
   logic [1:0]                   state_s;

   localparam C_SIM_DNA_VALUE = 96'h76543210FEDCBA9876543210;

   logic                        read_s, shift_s, writeout_s;
   logic                        dout_s;
   logic [C_DNA_SIZE-1:0]       dna_value_s, dna_value_clk_i_s;
   logic                        do_read_dna_clk_dna_s, do_read_dna_s;
   logic                        start_read_dna_s;

   int                        cnt_i;

   int                        clk_divider_cnt_i;
   logic                      clk_dna;
   logic                      rst_clk_dna_s;
   logic                      writeout_clk_i_s;

   // synthesis translate off
   assert #0 (C_DNA_CLK_DIVIDER%2 == 0)
     else $error("C_DNA_CLK_DIVIDER has an odd value! Please check it in usb_if/ws_master_config/dna_read!");
   // synthesis translate on

   always @(posedge clk_i)
     begin
        if (rst_i) begin
           clk_divider_cnt_i = 0;
           clk_dna <= 1'b1;
        end else begin
           clk_divider_cnt_i = (clk_divider_cnt_i == 3)? 0 : (clk_divider_cnt_i + 1);
           clk_dna <= ((clk_divider_cnt_i == 0)|(clk_divider_cnt_i == ((C_DNA_CLK_DIVIDER/2))))? ~clk_dna : clk_dna;
        end
     end


   always @(posedge clk_i)
     begin
        if (rst_i == 1) begin
           do_read_dna_s <= 1'b0;
           start_read_dna_s <= 1'b0;
        end else begin
           if (do_read_dna_i == 1'b1)
             start_read_dna_s <= 1'b1;
           if (start_read_dna_s == 1'b1)
             if (clk_divider_cnt_i == 3)
               if (do_read_dna_s == 1'b0)
                 do_read_dna_s <= 1'b1;
               else begin
                  do_read_dna_s <= 1'b0;
                  start_read_dna_s <= 1'b0;
               end
             else
               do_read_dna_s <= do_read_dna_s;
        end
     end

   xpm_cdc_single
     #(
       //Commonmoduleparameters
       .DEST_SYNC_FF(2),//integer;range:2-10
       .SIM_ASSERT_CHK(1),//integer;0=disablesimulationmessages,1=enablesimulationmessages
       .SRC_INPUT_REG(0)//integer;0=donotregisterinput,1=registerinput
       )
   xpm_cdc_single_do_read_dna_clk_i_to_clk_dna
     (
      .src_clk(1'b1),//optional;requiredwhenSRC_INPUT_REG=1
      .src_in(rst_i),
      .dest_clk(clk_dna),
      .dest_out(rst_clk_dna_s)
      );

   xpm_cdc_single
     #(
       //Commonmoduleparameters
       .DEST_SYNC_FF(2),//integer;range:2-10
       .SIM_ASSERT_CHK(1),//integer;0=disablesimulationmessages,1=enablesimulationmessages
       .SRC_INPUT_REG(0)//integer;0=donotregisterinput,1=registerinput
       )
   xpm_cdc_single_rst_clk_i_to_clk_dna
     (
      .src_clk(1'b1),//optional;requiredwhenSRC_INPUT_REG=1
      .src_in(do_read_dna_s),
      .dest_clk(clk_dna),
      .dest_out(do_read_dna_clk_dna_s)
      );


   // synthesis translate_off
   dna_read_assertions dna_read_assertions_inst (.clk(clk_i),
                                                .rst(rst_i),
                                                .do_read_dna_i(do_read_dna_i),
                                                .do_read_dna_clk_dna_s(do_read_dna_clk_dna_s));
   // synthesis translate_on

   // FSM for generating reset high for N cycles
   always @(posedge clk_dna)
     begin
        if (rst_clk_dna_s) begin
           state_s <= C_IDLE;
           read_s <= 1'b0;
           cnt_i = 0;
           shift_s <= 1'b0;
           writeout_s <= 1'b0;
        end else begin
           case(state_s)
             C_IDLE: begin // 0
                state_s <= (do_read_dna_clk_dna_s)? C_READ : C_IDLE;
                read_s <= 1'b0;
                cnt_i = 0;
                shift_s <= 1'b0;
                writeout_s <= 1'b0;
             end
             C_READ: begin // 1
                state_s <=  C_SCROLL;
                read_s <= 1'b1;
                cnt_i = 0;
                shift_s <= 1'b0;
                writeout_s <= 1'b0;
             end
             C_SCROLL: begin // 2
                state_s <= ((cnt_i == C_DNA_SIZE-2))? C_DONE : C_SCROLL;
                read_s <= 1'b0;
                cnt_i++;
                shift_s <= 1'b1;
                writeout_s <= 1'b0;
             end
             C_DONE: begin // 3
                state_s <= C_IDLE;
                read_s <= 1'b0;
                cnt_i = 0;
                shift_s <= 1'b0;
                writeout_s <= 1'b1;
             end
             default: begin
                state_s <= C_IDLE;
                read_s <= 1'b0;
                cnt_i = 0;
                shift_s <= 1'b0;
                writeout_s <= 1'b0;
             end
           endcase
        end // else: !if(rst_i)
     end // always @ (posedge clk_i)


   // // DNA_PORT: Device DNA Access Port
   // //           7 Series
   // // Xilinx HDL Libraries Guide, version 14.7
   // DNA_PORT
   //   #(
   //     .SIM_DNA_VALUE(C_SIM_DNA_VALUE)  // Specifies a sample 57-bit DNA value for simulation
   //     )
   // DNA_PORT_inst
   //   (
   //    .DOUT(dout_s),// 1-bit output: DNA output data.
   //    .CLK(clk_i),// 1-bit input: Clock input.
   //    .DIN(1'b0),// 1-bit input: User data input pin.
   //    .READ(read_s),// 1-bit input: Active high load DNA, active low read input.
   //    .SHIFT(shift_s)// 1-bit input: Active high shift enable input.
   //    );

   DNA_PORTE2
     #(
       .SIM_DNA_VALUE(C_SIM_DNA_VALUE)  // Specifies a sample 96-bit DNA value for simulation
       )
   DNA_PORT_inst
     (
      .DOUT(dout_s),// 1-bit output: DNA output data.
      .CLK(clk_dna),// 1-bit input: Clock input.
      .DIN(1'b0),// 1-bit input: User data input pin.
      .READ(read_s),// 1-bit input: Active high load DNA, active low read input.
      .SHIFT(shift_s)// 1-bit input: Active high shift enable input.
      );

   always @(posedge clk_dna) begin
      if (rst_clk_dna_s)
        dna_value_s <= 'd0;
      else begin
         if (shift_s)
           dna_value_s <= {dout_s, dna_value_s[C_DNA_SIZE-2:1]};
         else
           dna_value_s <= dna_value_s;
      end
   end

   // CLK_I logic (and CDC logic)

   xpm_cdc_single
     #(
       //Commonmoduleparameters
       .DEST_SYNC_FF(2),//integer;range:2-10
       .SIM_ASSERT_CHK(1),//integer;0=disablesimulationmessages,1=enablesimulationmessages
       .SRC_INPUT_REG(0)//integer;0=donotregisterinput,1=registerinput
       )
   xpm_cdc_single_clk_dna_to_clk_i
     (
      .src_clk(1'b1),//optional;requiredwhenSRC_INPUT_REG=1
      .src_in(writeout_s),
      .dest_clk(clk_i),
      .dest_out(writeout_clk_i_s)
      );


   xpm_cdc_array_single
     #(
       //Commonmoduleparameters
       .DEST_SYNC_FF  (2),//integer;range:2-10
       .SIM_ASSERT_CHK(1),//integer;0=disablesimulationmessages,1=enablesimulationmessages
       .SRC_INPUT_REG (0),//integer;0=donotregisterinput,1=registerinput
       .WIDTH         (C_DNA_SIZE)//integer;range:2-1024
       )
   xpm_cdc_array_single_clk_dna_to_clk_i
       (
        .src_clk(1'b1),//optional;requiredwhenSRC_INPUT_REG=1
        .src_in(dna_value_s),
        .dest_clk(clk_i),
        .dest_out(dna_value_clk_i_s)
        );

   always @(posedge clk_i) begin
      if (rst_i)
        dna_value_o <= 'd0;
      else
        if (writeout_clk_i_s)
          dna_value_o <= dna_value_clk_i_s;
   end

endmodule // dna_read
