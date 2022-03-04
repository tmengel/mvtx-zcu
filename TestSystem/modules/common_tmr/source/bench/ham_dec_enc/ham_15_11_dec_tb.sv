//-----------------------------------------------------------------------------
// Title          : ham_15_11_dec_tb.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : ham_15_11_dec_tb.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : ham_15_11_dec_tb.v - hamming (15,11) decoder test bench
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
`timescale 1ns/100ps

module ham_15_11_dec_tb();

reg   [14:0]  enc_data_r = 15'd0;
wire  [10:0]  dec_data;

ham_15_11_dec ham_15_11_dec(
  .data_i  (enc_data_r),
  .data_o  (dec_data)
);

initial begin
  #10
  enc_data_r <= 15'b110_0011_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_1:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");
  
  #10
  enc_data_r <= 15'b110_0011_0101_0001;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_2:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");
  
  #10
  enc_data_r <= 15'b110_0011_0101_0010;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_3:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0011_0101_0100;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_4:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0011_0101_1000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_5:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0011_0100_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_6:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0011_0111_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_7:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0011_0001_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_8:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0011_1101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_9:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0010_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_10:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0001_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_11:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_0111_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_12:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b110_1011_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_13:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b111_0011_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_14:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b100_0011_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_15:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");

  #10
  enc_data_r <= 15'b010_0011_0101_0000;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_16:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");
  
  #10
  enc_data_r <= 15'b010_0011_0101_0011;
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_17:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");
  
  #10
  $display("%d:\t%b\t%b", $stime, enc_data_r, dec_data);
  output_check_18:
    assert(dec_data == 11'b11000111010)
      $display ("Assertion OK!");
    else
      $error("Fault assertion!");
  $stop;
end

endmodule
