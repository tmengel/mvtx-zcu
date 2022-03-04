//-----------------------------------------------------------------------------
// Title          : ham_16_11_dec_tb.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : ham_16_11_dec_tb.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : ham_16_11_dec_tb.v -  hamming (16,11) decoder test bench
//                                        (with SECDED)
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
`timescale 1ns/100ps

module ham_16_11_dec_tb();

reg   [15:0]  enc_data_r = 16'd0;
wire  [10:0]  dec_data;
wire          err_w;

ham_16_11_dec ham_16_11_dec(
  .data_i (enc_data_r),
  .data_o (dec_data),
  .err_o  (err_w)
);

initial begin
  enc_data_r <= 16'b0000_0000_0000_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  
  #10
  enc_data_r <= 16'b0110_0011_0101_0000; // OK
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b1110_0011_0101_0000; // only error in the global parity bit
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b0110_0011_0101_0000; // OK
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b1110_0011_0101_0001; // 2-bit error: global parity + enc_data_r[0]
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b0110_0011_0101_0000; // OK
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b0110_0011_0101_0101; // 2-bit error: enc_data_r[0] + enc_data_r[2]
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b0110_0011_0101_0000; // OK
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  enc_data_r <= 16'b0110_0011_0101_0001; // 1-bit error: enc_data_r[0]
  $display("%d:\t%b\t%b\t%b", $stime, enc_data_r, dec_data, err_w);
  
  #10
  $stop;
end

endmodule
