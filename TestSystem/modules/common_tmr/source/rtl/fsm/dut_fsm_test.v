// @ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_test.v

module dut_fsm_test
  #(
    parameter LANES_G=2,  // number of lanes
    parameter STEPS_G=32, // number of DUT FSMs in the lane
    parameter READOUT_WIDTH_G=32  // width of the output FIFO data vector
    )
   (
      // general inputs
    input                        clk_i,
    input                        rst_i,
    input                        inj_err_i,
                        // DP2 FIFO interface
    input                        DP2_fifo_full_i,
    input                        DP2_fifo_almst_full_i,
    output                       DP2_fifo_wr_o,
    output [READOUT_WIDTH_G-1:0] DP2_fifo_data_o,
                        // DP3 FIFO interface
    input                        DP3_fifo_full_i,
    input                        DP3_fifo_almst_full_i,
    output                       DP3_fifo_wr_o,
    output [READOUT_WIDTH_G-1:0] DP3_fifo_data_o
    );

   wire [LANES_G-1:0]            err_data_w;
   wire [LANES_G-1:0]            err_state_w;

   localparam integer                FSM_IO_SIZE_C = 4;

   // Generate a chain of LANES_G dut_fsm_lanes
   generate
      genvar                         i;
      for(i=0; i<LANES_G; i=i+1)
        begin : dut_fsm_lane
           (* DONT_TOUCH = "true" *)
           dut_fsm_lane
            #(
              .IO_SIZE_G(FSM_IO_SIZE_C),
              .STEPS_G(STEPS_G)
              ) dut_fsm_lane
            (
             clk_i,
             rst_i,
             inj_err_i,
             err_data_w[i],
             err_state_w[i]
             );
        end
   endgenerate

   // tbRdout DP2
   tbRdout #(.READOUT_WIDTH_G(READOUT_WIDTH_G), .LANES_G(LANES_G))
   tbRdout_DP2(
               .clk_i              (clk_i),
               .rst_i              (rst_i),
               .monitor_i          (err_data_w),
               .fifo_full_i        (DP2_fifo_full_i),
               .fifo_almst_full_i  (DP2_fifo_almst_full_i),
               .fifo_wr_o          (DP2_fifo_wr_o),
               .fifo_data_o        (DP2_fifo_data_o)
               );

   // tbRdout DP3
   tbRdout #(.READOUT_WIDTH_G(READOUT_WIDTH_G), .LANES_G(LANES_G))
   tbRdout_DP3(
               .clk_i              (clk_i),
               .rst_i              (rst_i),
               .monitor_i          (err_state_w),
               .fifo_full_i        (DP3_fifo_full_i),
               .fifo_almst_full_i  (DP3_fifo_almst_full_i),
               .fifo_wr_o          (DP3_fifo_wr_o),
               .fifo_data_o        (DP3_fifo_data_o)
               );

endmodule
