//-----------------------------------------------------------------------------
// Title          : mvtr.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : mvtr.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : mvtr.v - parameterizable voter
// M - number of input vectors (multiplication level)
// N - width of an input vector (voted vector)
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ns/100ps

module mvtr #(
  parameter M = 3,          // Number of input vectors
            N = 4)(         // Width of an input vector
  input   [M*N-1:0] vtr_i,  // input data for voting, width = M*N
  output  [N-1:0]   vtr_o,  // output voted data, width = N
  output            warn_o  // warning output (when asserted it means that one of the inputs if faulty)
);
  
reg  [N-1:0]  vtr_r   = {N{1'b0}};
reg  [N-1:0]  warn_r  = {N{1'b0}};
localparam log2_M = $clog2(M);

// function that returns the number of "1" in the input vector
function automatic [log2_M-1:0] f_count_ones(
  input [M-1:0] x
);
  begin : func_body
    integer i;
    reg [log2_M-1:0] cnt_r = {log2_M{1'b0}};
    
    for(i = 0; i < M; i = i + 1)
      if(x[i])
        cnt_r = cnt_r + 1;
      else
        cnt_r = cnt_r;
      f_count_ones = cnt_r;
    end
endfunction

wire [M-1:0] vtr2vt_w[N-1:0]; // an array of vectors to vote from
genvar  g, h;

generate
  for (g = 0; g < N; g = g + 1) begin
    for(h = 0; h < M; h = h + 1)
      assign vtr2vt_w[g][h] = vtr_i[g+h*N];
    
    always @(*) begin
      vtr_r[g]  <= (f_count_ones(vtr2vt_w[g]) > (M >> 1)) ? 1 : 0;
      warn_r[g] <= (f_count_ones(vtr2vt_w[g]) > 0 & f_count_ones(vtr2vt_w[g]) < M) ? 1 : 0;
    end
  end
endgenerate

assign vtr_o  = vtr_r;
assign warn_o = |warn_r;

endmodule
