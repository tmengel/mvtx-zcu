// sem_0_sem_mon_tb.v test bench
`timescale 1 ns / 100 ps

module sem_0_sem_mon_tb2();

reg         clk_r, rst_r;
reg   [7:0] txdata_r;
wire        tx_w;//, txfull_w;
reg         tx_write_r;

reg         rx_r;
wire  [7:0] rxdata_w;
//reg         rxread_r;
//wire        rxempty_w;
wire        data_available_w;
wire        data_sent_w;

always @(posedge clk_r)
  begin
    rx_r = tx_w;
  end

uart uart(  
  .clk            (clk_r),
  .dbg            (),
  .rst            (rst_r),
  .RS232in        (rx_r),
  .RS232out       (tx_w),
  .RxD            (rxdata_w),
  .TxD            (txdata_r),
  .data_available (data_available_w),
  .data_sent      (data_sent_w),
  .enable_send    (tx_write_r)
  );

initial begin
  clk_r = 1'b1;
  rst_r = 1'b1;
  
  repeat(10) #5 clk_r = ~clk_r;
  rst_r = 1'b0;
  
  repeat(50000) #5 clk_r = ~clk_r;
  
  $finish;
end

initial begin
  //rx_r        <= 1'd0;
  txdata_r    <= 8'd0;
  tx_write_r  <= 1'd0;
  //rxread_r    <= 1'd0;
  
  #20
  @(posedge clk_r);
  txdata_r    <= 8'hAA;
  tx_write_r  <= 1'b1;
  
//  #10
//  @(posedge clk_r);
//  txdata      <= 8'hEE;
//  tx_write_r  <= 1'b1;
  
//  #10
//  @(posedge clk_r);
//  tx_write_r  <= 1'b0;
  
  @(posedge data_sent_w)
  tx_write_r    <= 1'b0;
//  
//  #10
//  @(posedge clk_r);
//  rxread_r    <= 1'b0;
end

endmodule
