////////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Module
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : dpi_fsm.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-04
// Last update  : 2015-12-04
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: The input data port FSM
////////////////////////////////////////////////////////////////////////////////

module dpi_fsm(
  input               clk_i,            // clock input
  input               rst_i,            // synchronous reset input
  input               strt_i,           // start signal input
  output reg          done_o,           // done signal output
  input               FLAG_i,           // FLAG input
  output reg          SLRDn_o,          // Slave FIFO read request output
  input       [31:0]  dpi_dt_i,         // dpi data input
  output      [31:0]  dpi_dt_o,         // dpi data output
  input               dpi_full_i,       // dpi full flag input
  input               dpi_almst_full_i, // dpi almost full flag input
  output reg          dpi_wr_o          // dpi write output
);

reg         ltchDtFX3_r;
reg         wrdCntrClr_r, wrdCntrInc_r;
wire  [7:0] wrdCntr_w;

reg [2:0] state_r;
localparam  IDLE        = 3'd0, // IDLE         - IDLE state
            FX3_RD_REQ  = 3'd1, // FX3_RD_REQ   - read request from the FX3
            FX3_DT_WT   = 3'd2, // FX3_DT_WT    - wait for the data from the FX3
            FX3_LTCH_DT = 3'd3, // FX3_LTCH_DT  - latch the data from the FX3
            FIFO_WR_DT  = 3'd4, // FIFO_WR_DT   - write the latched data to the data port FIFO
            FX3_WT_FLG  = 3'd5, // FX3_WT_FLG   - wait for the FX3 to update the FLAG
            CHK_FLG     = 3'd6, // CHK_FLG      - check the FLAG
            DONE        = 6'd7; // DONE         - assert done signal

localparam  MAX_WRD_PER_TRANS = 8'd8;

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IDLE;
  end else begin
    case(state_r)
      IDLE:         //0
        state_r <=  (strt_i & !FLAG_i & !dpi_full_i)  ? FX3_RD_REQ  :
                    (strt_i)                          ? DONE        :
                    IDLE;
      FX3_RD_REQ:   //1
        state_r <= FX3_DT_WT;
      FX3_DT_WT:    //2
        state_r <= FX3_LTCH_DT;
      FX3_LTCH_DT:  //3
        state_r <= FIFO_WR_DT;
      FIFO_WR_DT:   //4
        state_r <= FX3_WT_FLG;
      FX3_WT_FLG:   //5
        state_r <= ((wrdCntr_w > (MAX_WRD_PER_TRANS - 8'd1)) | dpi_full_i) ? DONE : CHK_FLG;
      CHK_FLG:      //6
        state_r <= (FLAG_i) ? DONE : FX3_RD_REQ;
      DONE:         //7
        state_r <= IDLE;
      default:      // default
        state_r <= IDLE;
    endcase
  end
end

// FSM set outputs
always @(state_r) begin
  case (state_r)
    // 0
    IDLE: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b1;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b0;
    end
    // 1
    FX3_RD_REQ: begin
      SLRDn_o       <= 1'b0;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b0;
    end
    // 2
    FX3_DT_WT: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b0;
    end
    // 3
    FX3_LTCH_DT: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b1;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b0;
    end
    // 4
    FIFO_WR_DT: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b1;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b1;
      done_o        <= 1'b0;
    end
    // 5
    FX3_WT_FLG: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b0;
    end
    // 6
    CHK_FLG: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b0;
    end
    // 7
    DONE: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      done_o        <= 1'b1;
    end
    // default
    default: begin
      SLRDn_o       <= 1'b1;
      ltchDtFX3_r   <= 1'b0;
      dpi_wr_o      <= 1'b0;
      wrdCntrClr_r  <= 1'b1;
      wrdCntrInc_r  <= 1'b1;
      done_o        <= 1'b0;
    end
  endcase
end

// a register to latch the data from the FX3 GPIFII bus
regnbit #(.N(32)) FX3_GPIFII_REG
  (
   .clk_i  (clk_i),
   .rst_i  (rst_i),
   .ce_i   (ltchDtFX3_r),
   .data_i (dpi_dt_i),
   .data_o (dpi_dt_o),
   .mismatch_o (),
   .mismatch_2nd_o()
   );

// word counter
cntnbit #(.N(8)) wrdCntr(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .clr_i  (wrdCntrClr_r),
  .inc_i  (wrdCntrInc_r),
  .cnt_o  (wrdCntr_w)
);

endmodule
