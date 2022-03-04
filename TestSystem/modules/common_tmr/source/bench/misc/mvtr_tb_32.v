// mvtr_tb - multi voter test bench
`timescale 1 ns / 100 ps

module mvtr_tb_32();

reg         rst_r;
reg   [31:0] A, B, C;
wire  [31:0] D_vtr;
wire        warn_w;

mvtr #(.M(3), .N(32)) mvtr(
  .vtr_i  ({A, B, C}),
  .vtr_o  (D_vtr),
  .warn_o (warn_w)
);

initial begin
  rst_r = 1'b1;
  # 100
  rst_r = 1'b0;
  
  # 1000
  $finish;
end

initial begin
  A = 32'h00000000;
  B = 32'h00000000;
  C = 32'h00000000;
  
  # 200
  A = 32'h000000FF;
  B = 32'h000000FF;
  C = 32'h000000FF;
  
  # 100
  A = 32'h1000;
  B = 32'h1100;
  C = 32'h0100;
  
/*  # 100
  A = 8'b1111;
  B = 8'b1111;
  C = 8'b1111;
  
  # 100
  A = 8'b0000;
  B = 8'b1111;
  C = 8'b1111;
  
  # 100
  A = 8'b0000;
  B = 8'b0000;
  C = 8'b1111;
  
  # 100
  A = 8'b0000;
  B = 8'b0000;
  C = 8'b0000;*/
end

initial begin
  $display("\t\ttime\tA\tB\tC\tD_vtr\twarn_w");
  $monitor("%d\t%b\t%b\t%b\t%b\t%b", $time, A, B, C, D_vtr, warn_w);
end

endmodule
