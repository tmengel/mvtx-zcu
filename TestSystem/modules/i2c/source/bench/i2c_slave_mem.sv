//-----------------------------------------------------------------------------
// Title      : I2C Slave Memory Module
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : i2c_slave_mem.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2017-07-13
// Last update: 2017-07-13
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: I2C Slave Module for testing, acting as a Memory device.
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-07-13  1.0      mbonora        Created
//-----------------------------------------------------------------------------
module i2c_slave_mem#(integer ADR_BYTES=2,
                      integer DATA_BYTES=1)
   (
    input logic CLK,
    input logic RST,
    inout logic SCL,
    inout logic SDA,
    input [6:0] SLV_ADR
    );

   int                           i2c_rx_idx;
   logic [(8*DATA_BYTES)-1:0]                   i2c_mem[*];
   logic [(8*ADR_BYTES)-1:0]                  i2c_adr;
   logic [7:0]                   i2c_rx_data, i2c_tx_data;
   logic                         i2c_rx_data_valid;
   logic                         i2c_busy;
   logic [1:0]                   i2c_error_c;
   wire                          i2c_scl_i, i2c_sda_o, i2c_sda_i;

   assign i2c_scl_i = (SCL == 0)?0:1;
   assign i2c_sda_i = (SDA == 0)?0:1;

   assign SDA = (i2c_sda_o == 1)?'z:0;

   always_comb i2c_tx_data <= (^i2c_adr === 1'bX)? 'X : i2c_mem[i2c_adr];

   always @(posedge CLK) begin
      if(RST) begin
         i2c_rx_idx = 0;
         i2c_mem[16'h0] = 8'hBC;
      end else begin
         if(i2c_rx_data_valid) begin
            if(i2c_rx_idx < ADR_BYTES) begin
               i2c_adr[i2c_rx_idx*8 +:8] <= i2c_rx_data;
            end else begin
               i2c_mem[i2c_adr][(i2c_rx_idx-ADR_BYTES)*8 +:8] = i2c_rx_data;
            end
            i2c_rx_idx = (i2c_rx_idx + 1) % (ADR_BYTES+DATA_BYTES);
         end
         // Reset idx if slave is not busy anymore (reset transaction)
         if(i2c_busy == 0)
           i2c_rx_idx = 0;
      end
   end // always @ (posedge CLK)

   i2c_slave
     i2c_slave_inst_gbt(
                            .CLK(CLK),
                            .RESET(RST),
                            .SCL(i2c_scl_i),
                            .SDA_i(i2c_sda_i),
                            .SDA_o(i2c_sda_o),
                            .SLV_ADR(SLV_ADR),
                            .TX_DATA(i2c_tx_data),
                            .TX_WR(1'b1),
                            .TX_EMPTY(),
                            .RX_DATA(i2c_rx_data),
                            .RX_VLD(i2c_rx_data_valid),
                            .RX_ACK(1'b1),
                            .BUSY(i2c_busy),
                            .ERROR_C(i2c_error_c)
                            );
endmodule // i2c_slave_mem
