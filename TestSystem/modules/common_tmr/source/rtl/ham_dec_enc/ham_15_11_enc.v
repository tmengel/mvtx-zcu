//-----------------------------------------------------------------------------
// Title          : ham_15_11_enc.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : ham_15_11_enc.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : hamming (15,11) encoder (SEC only)
// data_i = {D11, D10, D9, D8, D7, D6, D5, D4, D3, D2, D1}
// data_o = {D11, D10, D9, D8, D7, D6, D5, P8, D4, D3, D2, P4, D1, P2, P1}
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
`timescale 1ns/100ps

module ham_15_11_enc(
  input       [10:0]  data_i, // 11-bit input data to be encoded
  output reg  [14:0]  data_o  // 15-bit encoded output data
);

reg p1_r, p2_r, p4_r, p8_r;   // parity bits P1, P2, P4, P8

always @(*) begin
  p1_r = data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4] ^ data_i[6] ^ data_i[8] ^ data_i[10];  // parity bit P1
  p2_r = data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[6] ^ data_i[9] ^ data_i[10];  // parity bit P2
  p4_r = data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[7] ^ data_i[8] ^ data_i[9] ^ data_i[10];  // parity bit P4
  p8_r = data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7] ^ data_i[8] ^ data_i[9] ^ data_i[10];  // parity bit P8
  
  data_o = {data_i[10],
            data_i[9],
            data_i[8],
            data_i[7],
            data_i[6],
            data_i[5],
            data_i[4],
            p8_r,
            data_i[3],
            data_i[2],
            data_i[1],
            p4_r,
            data_i[0],
            p2_r,
            p1_r};
end

endmodule
