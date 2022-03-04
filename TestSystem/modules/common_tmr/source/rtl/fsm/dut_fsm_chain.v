// @ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_chain.v

module dut_fsm_chain
  #(parameter IO_SIZE_G=4,
    parameter STEPS_G=16
    )
   (
    input                  clk_i,
    input                  rst_i,
    input [IO_SIZE_G-1:0]  data_i,
    output [IO_SIZE_G-1:0] data_o
    );

   wire [IO_SIZE_G-1:0]    data_fsm_w[STEPS_G:0]; // STEPS_G+1 vectors of IO_SIZE_G-1-bit
   assign data_fsm_w[0] = data_i;
   assign data_o = data_fsm_w[STEPS_G];

   // Generate a chain of STEPS_G dut_fsms
   genvar                  i;
   generate
      for(i=0; i<STEPS_G; i=i+1)
	begin : dut_fsm
           dut_fsm  #(.IO_SIZE_G(IO_SIZE_G))
           dut_fsm(
                   .clk_i  (clk_i),
                   .rst_i  (rst_i),
                   .data_i (data_fsm_w[i]),
                   .data_o (data_fsm_w[i+1])
                   );
	end
   endgenerate

endmodule
