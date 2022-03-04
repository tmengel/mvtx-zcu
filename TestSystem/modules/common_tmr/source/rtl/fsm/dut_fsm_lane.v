// ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm_lane.v

`timescale 10ns/1ns

module dut_fsm_lane
    #(parameter IO_SIZE_G=4, // number of bits interconnecting the fsms
      parameter STEPS_G=32 // number of steps in each lane
    )
   (
    input  clk_i,
    input  rst_i,
    input  inj_err_i,
    output err_data_o,
    output err_state_o
    );

   wire [IO_SIZE_G-1:0] data_gen_w;
   wire [IO_SIZE_G-1:0] data_chkr_w;

   localparam integer       C_PATTERN_GENERATOR_LIM = 14;

   // m_pat_gen
   m_pat_gen #(.IO_SIZE_G(IO_SIZE_G), .LIM(C_PATTERN_GENERATOR_LIM))
   m_pat_gen(
             .clk_i      (clk_i),
             .rst_i      (rst_i),
             .inc_i      (1'b1),
             .inj_err_i  (inj_err_i),
             .cnt_o      (data_gen_w),
             .warn_o     ()
             );

   // dut_fsm_chain
   dut_fsm_chain #(.IO_SIZE_G(IO_SIZE_G), .STEPS_G(STEPS_G))
   dut_fsm_chain(
                 .clk_i      (clk_i),
                 .rst_i      (rst_i),
                 .data_i     (data_gen_w),
                 .data_o     (data_chkr_w)
                 );

   // dut_fsm_checker
   dut_fsm_checker #(.IO_SIZE_G(IO_SIZE_G))
   dut_fsm_checker(
                   .clk_i        (clk_i),
                   .rst_i        (rst_i),
                   .data_i       (data_chkr_w),
                   .err_data_o   (err_data_o),
                   .err_state_o  (err_state_o)
                   );
endmodule
