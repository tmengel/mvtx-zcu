// sem_0_sem_mon_tb.v test bench
`timescale 1 ns / 100 ps

module sem_0_sem_mon_tb();

reg         clk_r;
reg   [7:0] txdata;
wire        tx_w, txfull_w;
reg         tx_write_r;

reg         rx_r;
wire  [7:0] rxdata_w;
reg         rxread_r;
wire        rxempty_w;

  always @(posedge clk_r)
    begin
      rx_r = tx_w;
    end

sem_0_sem_mon uart(
  //input  wire        .icap_clk        (clk_r),
  //output wire        .monitor_tx      (tx_w),
  //input  wire        .monitor_rx      (rx_r),
  //input  wire  [7:0] .monitor_txdata  (txdata),
  //input  wire        .monitor_txwrite (tx_write_r),
  //output wire        .monitor_txfull  (txfull_w),

  //output wire  [7:0] .monitor_rxdata  (rxdata_w),
  //input  wire        .monitor_rxread  (rxread_r),
  //output wire        .monitor_rxempty (rxempty_w)
  .icap_clk        (clk_r),
  .monitor_tx      (tx_w),
  .monitor_rx      (rx_r),
  .monitor_txdata  (txdata),
  .monitor_txwrite (tx_write_r),
  .monitor_txfull  (txfull_w),
  .monitor_rxdata  (rxdata_w),
  .monitor_rxread  (rxread_r),
  .monitor_rxempty (rxempty_w)
  );

initial begin
  clk_r = 1'b1;
  
  repeat(50000) #5 clk_r = ~clk_r;
  
  $finish;
end

initial begin
  //rx_r        <= 1'd0;
  txdata      <= 8'd0;
  tx_write_r  <= 1'd0;
  rxread_r    <= 1'd0;
  
  #20
  @(posedge clk_r);
  txdata      <= 8'hAA;
  tx_write_r  <= 1'b1;
  
  #10
  @(posedge clk_r);
  txdata      <= 8'hEE;
  tx_write_r  <= 1'b1;
  
  #10
  @(posedge clk_r);
  tx_write_r  <= 1'b0;
  
//  @(negedge rxempty_w)
//  rxread_r    <= 1'b1;
//  
//  #10
//  @(posedge clk_r);
//  rxread_r    <= 1'b0;
end

endmodule
