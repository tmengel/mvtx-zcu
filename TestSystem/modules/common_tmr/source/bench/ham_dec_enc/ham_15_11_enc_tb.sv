//-----------------------------------------------------------------------------
// Title          : ham_15_11_enc_tb.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : ham_15_11_enc_tb.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : ham_15_11_enc_tb.v - hamming (15,11) encoder test bench
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
`timescale 1ns/100ps

module ham_15_11_enc_tb();

reg   [10:0]  data2enc_r = 11'd0;
wire  [14:0]  enc_data;

ham_15_11_enc ham_15_11_enc(
  .data_i  (data2enc_r),
  .data_o  (enc_data)
);

initial begin
  #10
  data2enc_r <= 11'b110_0011_1010;
  $display("%d:\t%b\n\t\t%b", $stime, data2enc_r, enc_data);
  
  #10
  data2enc_r <= 11'b110_1011_1000;
  $display("%d:\t%b\n\t\t%b", $stime, data2enc_r, enc_data);
  
  #10
  $display("%d:\t%b\n\t\t%b", $stime, data2enc_r, enc_data);
  $stop;
end

endmodule
