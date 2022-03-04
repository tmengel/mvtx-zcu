////////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Module
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : dp_arbtr.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-03
// Last update  : 2015-12-03
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: The data port arbiter
////////////////////////////////////////////////////////////////////////////////

module dp_arbtr(
  input               clk_i,      // clock input
  input               rst_i,      // synchronous reset input
  
  output reg  [3:0]   strt_o,     //
  input       [3:0]   done_i,     //
  
  input       [2:0]   SLWRn_i,    //
  input       [2:0]   PKTENDn_i,  //
  
  output reg  [1:0]   SLADDR_o,   // slave endpoint address output
  output reg          SLOEn_o,    // slave output enable
  output reg          SLCSn_o,    // slave chip select output
  output              SLWRn_o,    // slave write request output
  output              PKTENDn_o,  // packet end output
  output      [1:0]   dpoMuxSel_o
);

reg [1:0] dpoMuxSel_r;
assign dpoMuxSel_o = dpoMuxSel_r;

localparam  DP1_MUX_SEL  = 2'd0,
            DP2_MUX_SEL  = 2'd1,
            DP3_MUX_SEL  = 2'd2;

localparam  DP0_EP_ADDR  = 2'd0,
            DP1_EP_ADDR  = 2'd1,
            DP2_EP_ADDR  = 2'd2,
            DP3_EP_ADDR  = 2'd3;

reg [3:0] state_r;
localparam  IDLE        = 4'd0, // IDLE
            DP0_STRT    = 4'd1, // DP0_STRT
            DP0_WT_DONE = 4'd2, // DP0_WT_DONE
            DP1_STRT    = 4'd3, // DP1_STRT
            DP1_WT_DONE = 4'd4, // DP1_WT_DONE
            DP2_STRT    = 4'd5, // DP2_STRT
            DP2_WT_DONE = 4'd6, // DP2_WT_DONE
            DP3_STRT    = 4'd7, // DP3_STRT
            DP3_WT_DONE = 4'd8; // DP3_WT_DONE

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IDLE;
  end else begin
    case(state_r)
      IDLE: //0
        state_r <= DP0_STRT;
      DP0_STRT: //1
        state_r <= DP0_WT_DONE;
      DP0_WT_DONE: //2
        state_r <= (done_i[0]) ? DP1_STRT : DP0_WT_DONE;
      DP1_STRT: //3
        state_r <= DP1_WT_DONE;
      DP1_WT_DONE: //4
        state_r <= (done_i[1]) ? DP2_STRT : DP1_WT_DONE;
      DP2_STRT: //5
        state_r <= DP2_WT_DONE;
      DP2_WT_DONE: //6
        state_r <= (done_i[2]) ? DP3_STRT : DP2_WT_DONE;
      DP3_STRT: //7
        state_r <= DP3_WT_DONE;
      DP3_WT_DONE: //8
        state_r <= (done_i[3]) ? DP0_STRT : DP3_WT_DONE;
      default:
        state_r <= IDLE;
    endcase
  end
end

// FSM set outputs
always @(state_r) begin
  case (state_r)
    // 0
    IDLE: begin
      strt_o      <= 4'b0000;
      SLADDR_o    <= DP0_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b1;
      dpoMuxSel_r <= DP1_MUX_SEL;
    end
    // 1
    DP0_STRT: begin
      strt_o      <= 4'b0001;
      SLADDR_o    <= DP0_EP_ADDR;
      SLOEn_o     <= 1'b0;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP1_MUX_SEL;
    end
    // 2
    DP0_WT_DONE: begin
      strt_o      <= 4'b0000;
      SLADDR_o    <= DP0_EP_ADDR;
      SLOEn_o     <= 1'b0;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP1_MUX_SEL;
    end
    // 3
    DP1_STRT: begin
      strt_o      <= 4'b0010;
      SLADDR_o    <= DP1_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP1_MUX_SEL;
    end
    // 4
    DP1_WT_DONE: begin
      strt_o      <= 4'b0000;
      SLADDR_o    <= DP1_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP1_MUX_SEL;
    end
    // 5
    DP2_STRT: begin
      strt_o      <= 4'b0100;
      SLADDR_o    <= DP2_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP2_MUX_SEL;
    end
    // 6
    DP2_WT_DONE: begin
      strt_o      <= 4'b0000;
      SLADDR_o    <= DP2_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP2_MUX_SEL;
    end
    // 7
    DP3_STRT: begin
      strt_o      <= 4'b1000;
      SLADDR_o    <= DP3_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP3_MUX_SEL;
    end
    // 8
    DP3_WT_DONE: begin
      strt_o      <= 4'b0000;
      SLADDR_o    <= DP3_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b0;
      dpoMuxSel_r <= DP3_MUX_SEL;
    end
    // default
    default: begin
      strt_o      <= 4'b0000;
      SLADDR_o    <= DP0_EP_ADDR;
      SLOEn_o     <= 1'b1;
      SLCSn_o     <= 1'b1;
      dpoMuxSel_r <= DP1_MUX_SEL;
    end
  endcase
end

// multiplexer to select the SLWRn_o
assign SLWRn_o =  (dpoMuxSel_o == DP1_MUX_SEL) ? SLWRn_i[0]  :
                  (dpoMuxSel_o == DP2_MUX_SEL) ? SLWRn_i[1]  :
                  (dpoMuxSel_o == DP3_MUX_SEL) ? SLWRn_i[2]  :
                  SLWRn_i[0];

// multiplexer to select the PKTENDn_o
assign PKTENDn_o  = (dpoMuxSel_o == DP1_MUX_SEL) ? PKTENDn_i[0]  :
                    (dpoMuxSel_o == DP2_MUX_SEL) ? PKTENDn_i[1]  :
                    (dpoMuxSel_o == DP3_MUX_SEL) ? PKTENDn_i[2]  :
                    PKTENDn_i[0];

endmodule
