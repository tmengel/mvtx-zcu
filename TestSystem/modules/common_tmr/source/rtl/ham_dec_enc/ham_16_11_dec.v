//-----------------------------------------------------------------------------
// Title          : ham_16_11_dec.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : ham_16_11_dec.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : ham_16_11_dec.v - hamming (16,11) decoder with SECDED
// data_i = {P16, D11, D10, D9, D8, D7, D6, D5, P8, D4, D3, D2, P4, D1, P2, P1}
// data_o = {D11, D10, D9, D8, D7, D6, D5, D4, D3, D2, D1}
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ns/100ps

module ham_16_11_dec(
  input       [15:0]  data_i, // 15-bit encoded output data
  output reg  [10:0]  data_o, // 11-bit input data to be encoded
  output reg          err_o   // double-error output
);

reg           c1_r, c2_r, c4_r, c8_r, c16_r;  // check bits C1, C2, C4, C8
wire          p1_w, p2_w, p4_w, p8_w;         // parity bits P1, P2, P4, P8
wire  [10:0]  data_w;                         // data extracted from input vector
reg   [14:0]  data_cor_r;                     // corrected data

// data bits remapping
assign data_w[0]   = data_i[2];
assign data_w[1]   = data_i[4];
assign data_w[2]   = data_i[5];
assign data_w[3]   = data_i[6];
assign data_w[4]   = data_i[8];
assign data_w[5]   = data_i[9];
assign data_w[6]   = data_i[10];
assign data_w[7]   = data_i[11];
assign data_w[8]   = data_i[12];
assign data_w[9]   = data_i[13];
assign data_w[10]  = data_i[14];

// parity bits remapping
assign p1_w = data_i[0];
assign p2_w = data_i[1];
assign p4_w = data_i[3];
assign p8_w = data_i[7];

always @(*) begin
  // calulating check bits
  c1_r  = p1_w ^ data_w[0] ^ data_w[1] ^ data_w[3] ^ data_w[4] ^ data_w[6] ^ data_w[8] ^ data_w[10];
  c2_r  = p2_w ^ data_w[0] ^ data_w[2] ^ data_w[3] ^ data_w[5] ^ data_w[6] ^ data_w[9] ^ data_w[10];
  c4_r  = p4_w ^ data_w[1] ^ data_w[2] ^ data_w[3] ^ data_w[7] ^ data_w[8] ^ data_w[9] ^ data_w[10];
  c8_r  = p8_w ^ data_w[4] ^ data_w[5] ^ data_w[6] ^ data_w[7] ^ data_w[8] ^ data_w[9] ^ data_w[10];
  c16_r =   data_i[14]
          ^ data_i[13]
          ^ data_i[12]
          ^ data_i[11]
          ^ data_i[10]
          ^ data_i[9]
          ^ data_i[8]
          ^ data_i[7]
          ^ data_i[6]
          ^ data_i[5]
          ^ data_i[4]
          ^ data_i[3]
          ^ data_i[2]
          ^ data_i[1]
          ^ data_i[0];
  
  // generating double-bit error
  err_o = (!c16_r & !data_i[15] & {c8_r, c4_r, c2_r, c1_r} > 4'd0) ? 1'b1 : 1'b0;
  
  // correction here
  case({c8_r, c4_r, c2_r, c1_r})
    4'd0: begin
      data_cor_r = data_i;
    end
    4'd1: begin
      data_cor_r[0]     = ~data_i[0];
      data_cor_r[14:1]  = data_i[14:1];
    end
    4'd2: begin
      data_cor_r[0]     = data_i[0];
      data_cor_r[1]     = ~data_i[1];
      data_cor_r[14:2]  = data_i[14:2];
    end
    4'd3: begin
      data_cor_r[1:0]   = data_i[1:0];
      data_cor_r[2]     = ~data_i[2];
      data_cor_r[14:3]  = data_i[14:3];
    end
    4'd4: begin
      data_cor_r[2:0]   = data_i[2:0];
      data_cor_r[3]     = ~data_i[3];
      data_cor_r[14:4]  = data_i[14:4];
    end    
    4'd5: begin
      data_cor_r[3:0]   = data_i[3:0];
      data_cor_r[4]     = ~data_i[4];
      data_cor_r[14:5]  = data_i[14:5];
    end
    4'd6: begin
      data_cor_r[4:0]   = data_i[4:0];
      data_cor_r[5]     = ~data_i[5];
      data_cor_r[14:6]  = data_i[14:6];
    end
    4'd7: begin
      data_cor_r[5:0]   = data_i[5:0];
      data_cor_r[6]     = ~data_i[6];
      data_cor_r[14:7]  = data_i[14:7];
    end
    4'd8: begin
      data_cor_r[6:0]   = data_i[6:0];
      data_cor_r[7]     = ~data_i[7];
      data_cor_r[14:8]  = data_i[14:8];
    end
    4'd9: begin
      data_cor_r[7:0]   = data_i[7:0];
      data_cor_r[8]     = ~data_i[8];
      data_cor_r[14:9]  = data_i[14:9];
    end
    4'd10: begin
      data_cor_r[8:0]   = data_i[8:0];
      data_cor_r[9]     = ~data_i[9];
      data_cor_r[14:10] = data_i[14:10];
    end
    4'd11: begin
      data_cor_r[9:0]   = data_i[9:0];
      data_cor_r[10]    = ~data_i[10];
      data_cor_r[14:11] = data_i[14:11];
    end
    4'd12: begin
      data_cor_r[10:0]  = data_i[10:0];
      data_cor_r[11]    = ~data_i[11];
      data_cor_r[14:12] = data_i[14:12];
    end
    4'd13: begin
      data_cor_r[11:0]  = data_i[11:0];
      data_cor_r[12]    = ~data_i[12];
      data_cor_r[14:13] = data_i[14:13];
    end
    4'd14: begin
      data_cor_r[12:0]  = data_i[12:0];
      data_cor_r[13]    = ~data_i[13];
      data_cor_r[14]    = data_i[14];
    end
    4'd15: begin
      data_cor_r[13:0]  = data_i[13:0];
      data_cor_r[14]    = ~data_i[14];
    end
  endcase
  
  data_o = {data_cor_r[14],
            data_cor_r[13],
            data_cor_r[12],
            data_cor_r[11],
            data_cor_r[10],
            data_cor_r[9],
            data_cor_r[8],
            data_cor_r[6],
            data_cor_r[5],
            data_cor_r[4],
            data_cor_r[2]};

end

endmodule
