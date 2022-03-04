// tbRdout.v

module tbRdout #(parameter
                 READOUT_WIDTH_G = 32,
                 LANES_G = 576)(
                                input                        clk_i,
                                input                        rst_i,
                                input [LANES_G-1:0]          monitor_i,
                                input                        fifo_full_i,
                                input                        fifo_almst_full_i,
                                output                       fifo_wr_o,
                                output [READOUT_WIDTH_G-1:0] fifo_data_o
                                );

   // generate LANES_G 32-bit counters
   wire [LANES_G*READOUT_WIDTH_G-1:0]                        cnt_w;
   genvar                                                    i;
   generate
      for(i = 0; i < LANES_G; i = i + 1)
	begin : cntnbit
           cntnbit #(.N(READOUT_WIDTH_G)) cntnbit_i(
                                                    clk_i,
                                                    rst_i,
                                                    1'b0,
                                                    monitor_i[i],
                                                    cnt_w[i * 32 + 31 -: 32]
                                                    );
	end
   endgenerate

   // for simulation only
   /*(* DONT_TOUCH = "true" *) reg [K*N-1:0] temp_r;
    integer i;
    //initial begin
    always @(rst_i) begin
    if(rst_i)
    temp_r  <= {K*N{1'b0}};
    else
    for(i = 0; i < K; i = i + 1)
    temp_r[i * 32 + 31 -: 32] <= i;
end*/

   // test-beam array counters readout
   tbRdoutCntrl #(.N(READOUT_WIDTH_G), .K(LANES_G)) tbRdoutCntrl(
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

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../../../../../usb_if/source/rtl")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
