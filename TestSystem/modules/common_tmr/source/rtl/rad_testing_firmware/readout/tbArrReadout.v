// tbArrReadout.v

module tbArrReadout (
  input           clk_i,
  input           rst_i,
  input   [255:0] monitor_i,
  input           fifo_full_i,
  input           fifo_almst_full_i,
  output          fifo_wr_o,
  output  [31:0]  fifo_data_o
);

// generate 256 32-bit counters
wire [8191:0] cnt_w;
genvar i;
generate
	for(i = 0; i < 256; i = i + 1)
	begin : cntnbit
      cntnbit #(.N(32)) cntnbit_i(
        clk_i,
        rst_i,
        1'b0,
        monitor_i[i],
        cnt_w[i * 32 + 31 -: 32]
      );
	end
endgenerate

// for simulation only
/*(* dont_touch = "true" *) reg [8191:0] temp_r;
integer i;
always @(*)
  for(i = 0; i < 256; i = i + 1) begin
    temp_r[i * 32 + 31 -: 32] <= i;
  end*/

// test-beam array counters readout
tbArrCntsReadout tbArrCntsReadout(
  .clk_i              (clk_i),
  .rst_i              (rst_i),
  .data_i             (cnt_w),
  //.data_i             (temp_r),
  .fifo_full_i        (fifo_full_i),
  .fifo_almst_full_i  (fifo_almst_full_i),
  .fifo_wr_o          (fifo_wr_o),
  .fifo_data_o        (fifo_data_o)
);

endmodule
