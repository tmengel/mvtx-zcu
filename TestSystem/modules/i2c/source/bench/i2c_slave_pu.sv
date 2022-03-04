//-----------------------------------------------------------------------------
// Title      : I2C Slave Memory Module for Power Unit
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : i2c_slave_pu.sv
// Author     : Joachim Schambach (jschamba@physics.utexas.edu)
// Company    : University of Texas at Austin
// Created    : 2018-01-18
// Last update: 2018-01-18
// Platform   :
// Target     : Kintex Ultrascale / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: I2C Slave Module for testing, acting as a Memory device.
//              (based on i2c_slave_mem.sv from mbonora)
//-----------------------------------------------------------------------------
// Copyright (c)   2018
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-07-13  1.0      jschamba      Created
//-----------------------------------------------------------------------------
module i2c_slave_pu
   (
    input logic CLK,
    input logic RST,
    input       SCL_i,
    output      SCL_o,
    input       SDA_i,
    output      SDA_o,
    input [6:0] SLV_ADR
    );

   logic [7:0]                   i2c_mem;
   logic [7:0]                   i2c_rx_data, i2c_tx_data;
   logic                         i2c_rx_data_valid;
   logic                         i2c_busy;
   logic [1:0]                   i2c_error_c;
   wire                          i2c_scl_i, i2c_sda_o, i2c_sda_i;

   assign SCL_o = SCL_i;


   always_comb i2c_tx_data <= i2c_mem;

   always @(posedge CLK) begin
      if(RST) begin
         i2c_mem = 8'hBC;
      end else begin
         if(i2c_rx_data_valid) begin
            i2c_mem = i2c_rx_data;
         end
      end
   end // always @ (posedge CLK)

   i2c_slave
     i2c_slave_inst_pu(
                       .CLK(CLK),
                       .RESET(RST),
                       .SCL(SCL_i),
                       .SDA_i(SDA_i),
                       .SDA_o(SDA_o),
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
