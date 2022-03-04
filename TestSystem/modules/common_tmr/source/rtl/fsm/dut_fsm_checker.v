////////////////////////////////////////////////////////////////////////////////
// Title        : An N-bit counter
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : dut_fsm_checker.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2017-04-16
// Last update  : 2017-04-16
////////////////////////////////////////////////////////////////////////////////
// Description: DUT FSM checker
////////////////////////////////////////////////////////////////////////////////

// (* DONT_TOUCH = "true" *)
module dut_fsm_checker #(parameter IO_SIZE_G=4)(
  input               clk_i,
  input               rst_i,
  input       [IO_SIZE_G-1:0] data_i,
  output reg          err_data_o,
  output reg          err_state_o
);

// data_marker_r is a 3-bit register that keeps the information
// about which data has been spotted
// data_marker[0] - if "1" then IO_SIZE_G'd1 has been spotted
// data_marker[1] - if "1" then IO_SIZE_G'd2 has been spotted
// data_marker[2] - if "1" then IO_SIZE_G'd3 has been spotted
reg [2:0] data_marker_r;
wire ovrflv_w;

// cntr_nbit_ovrflv
// it works like a watchdog and generates a 1-clock cycle pulse
// on ovrflv_o every 16 ticks
cntr_nbit_ovrflv #(.N(IO_SIZE_G)) cntr_nbit_ovrflv(
  .clk_i    (clk_i),
  .rst_i    (rst_i),
  .inc_i    (1'b1),
  .cnt_o    (),
  .ovrflv_o (ovrflv_w)
);

always @(posedge clk_i) begin
  if(rst_i) begin
    data_marker_r <= 3'd0;
    err_data_o    <= 1'b0;
  end else if(ovrflv_w) begin
    err_data_o    <= (data_marker_r == 3'b111) ? 1'b0 : 1'b1;
    data_marker_r <= 3'd0;
  end else begin
    err_data_o    <= 1'b0;
    case(data_i)
      4'd1: begin
        data_marker_r[0]  <= 1'b1;
      end
      4'd2: begin
        data_marker_r[1]  <= 1'b1;
      end
      4'd3: begin
        data_marker_r[2]  <= 1'b1;
      end
      4'd15: begin
        data_marker_r     <= data_marker_r;
      end
      default: begin
        data_marker_r     <= data_marker_r;
      end
    endcase
  end
end

always @(posedge clk_i) begin
  if(rst_i)
    err_state_o <= 1'b0;
  else if(data_i == 4'd15)
    err_state_o <= 1'b1;
  else
    err_state_o <= 1'b0;
end

endmodule
