////////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Module
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : dpo_fsm.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-2
// Last update  : 2015-12-2
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: The output data port (DP1/2/3) finite state machine
////////////////////////////////////////////////////////////////////////////////

module dpo_fsm(
  input               clk_i,            // clock input
  input               rst_i,            // synchronous reset input
  
  input               strt_i,           // start signal input
  output reg          done_o,           // done signal input
  
  // FX3 GPIFII Slave Fifo signals
  input               FLAG_i,           // FLAGx input
  output reg          SLWRn_o,          // slave write request output
  output reg          PKTENDn_o,        // packet end output
  
  // data port 1 FIFO (fx3_ctrl reades data from the DPO)
  input       [31:0]  dpo_dt_i,         // data port x data input
  output      [31:0]  dpo_dt_o,         // data port x data output
  input               dpo_epty_i,       // data port x empty input
  input               dpo_almst_epty_i, // data port x almost empty input
  output reg          dpo_rd_o          // data port x read output
);

reg   wrdCntrClr_r;
reg   wrdCntrInc_r;
wire  [15:0] wrdCntr_w;

reg   tmOutCntrClr_r;
reg   tmOutCntrInc_r;
wire  [7:0] tmOutCntr_w;

reg [5:0] state_r;
localparam  IDLE            = 6'd0,   // IDLE             - idle
            FIFO_RD_STRT    = 6'd1,   // FIFO_RD_STRT     - start reading data from the DP FIFO
            FIFO_RD_WT_1    = 6'd2,   // FIFO_RD_WT_1     - wait for the data from the DP FIFO
            FIFO_NF_PPLN    = 6'd3,   // FIFO_NF_PPLN     - not full pipeline
            FIFO_RD_WT_2    = 6'd4,   // FIFO_RD_WT_2     - wait for the data from the DP FIFO
            FX3_WR_DT       = 6'd5,   // FX3_WR_DT        - write the data to the FX3
            FX3_WR_DT_SL_1  = 6'd6,   // FX3_WR_DT_SL_1   - slowly write the data to the FX3
            FX3_WR_DT_SL_2  = 6'd7,   // FX3_WR_DT_SL_2   - slowly write the data to the FX3
            WR_LST_WRD      = 6'd8,   // WR_LST_WRD       - write the last word with PKTENDn=0            
            FLSH_PPLN_1     = 6'd9,   // FLSH_PPLN_1      - push the data through the pipeline
            FLSH_PPLN_2     = 6'd10,  // FLSH_PPLN_2      - push the data through the pipeline
            TIME_OUT_CNT    = 6'd11,  // TIME_OUT_CNT     - start the time out counter
            WR_REM_WRD      = 6'd12,  // WR_REM_WRD       - write the remaining word to the FX3
            DONE            = 6'd13,  // DONE             - assert done signal
            FLSH_PPLN_3     = 6'd14;  // FLSH_PPLN_3      - push the data through the pipeline

localparam  MAX_TIMEOUT     = 8'd16;
localparam  MAX_PKT_SIZE    = 16'd256;

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IDLE;
  end else begin
    case(state_r)
      IDLE: //0
        state_r <=  (strt_i & FLAG_i & !dpo_epty_i) ? FIFO_RD_STRT  :
                    (strt_i)                        ? DONE          :
                    IDLE;
      FIFO_RD_STRT: //1
        state_r <= (dpo_almst_epty_i | (wrdCntr_w == (MAX_PKT_SIZE - 16'd1))) ? TIME_OUT_CNT : FIFO_RD_WT_1;
      FIFO_RD_WT_1: //2
        state_r <= (dpo_almst_epty_i | (wrdCntr_w == (MAX_PKT_SIZE - 16'd2))) ? FIFO_NF_PPLN : FIFO_RD_WT_2;
      FIFO_NF_PPLN: //
        state_r <= FLSH_PPLN_2;
      FIFO_RD_WT_2: //4
        state_r <= (dpo_almst_epty_i| (wrdCntr_w == (MAX_PKT_SIZE - 16'd3))) ? FLSH_PPLN_1 : FX3_WR_DT;
      FX3_WR_DT: //5
        if (wrdCntr_w > (MAX_PKT_SIZE - 16'd5)) begin
          state_r <= FX3_WR_DT_SL_1;
        end else if(dpo_almst_epty_i) begin
          state_r <= FLSH_PPLN_1;
        end else begin
          state_r <= FX3_WR_DT;
        end      
      FX3_WR_DT_SL_1: //6
        state_r <= FX3_WR_DT_SL_2;
      FX3_WR_DT_SL_2: //7
        state_r <= WR_LST_WRD;
      WR_LST_WRD: //8
        state_r <= DONE;
      FLSH_PPLN_1: //9
        state_r <= FLSH_PPLN_2;
      FLSH_PPLN_2: //10
        state_r <= TIME_OUT_CNT;
      TIME_OUT_CNT: //11
        if(wrdCntr_w  < (MAX_PKT_SIZE - 16'd1)) begin
          if(tmOutCntr_w < (MAX_TIMEOUT - 8'd2)) begin
            if(!dpo_epty_i & (tmOutCntr_w > 8'd0)) begin
              state_r <= WR_REM_WRD;
            end else begin
              state_r <= TIME_OUT_CNT;
            end
          end else begin
            state_r <= WR_LST_WRD;
          end
        end else begin
          state_r <= FLSH_PPLN_3;
        end
      FLSH_PPLN_3: //14
        state_r <= WR_LST_WRD;
      WR_REM_WRD: //12
        state_r <= FIFO_RD_STRT;
      DONE: //13
        state_r <= IDLE;
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
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b1;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b1;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 1
    FIFO_RD_STRT: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b1;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b1;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 2
    FIFO_RD_WT_1: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b1;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 3
    FIFO_NF_PPLN: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 4
    FIFO_RD_WT_2: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b1;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 5
    FX3_WR_DT: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b1;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 6
    FX3_WR_DT_SL_1: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 7
    FX3_WR_DT_SL_2: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 8
    WR_LST_WRD: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b0;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 9
    FLSH_PPLN_1: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 10
    FLSH_PPLN_2: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 11
    TIME_OUT_CNT: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b1;
    end
    // 12
    WR_REM_WRD: begin
      SLWRn_o         <= 1'b0;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      tmOutCntrClr_r  <= 1'b1;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 14
    FLSH_PPLN_3: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // 13
    DONE: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b1;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b0;
      tmOutCntrInc_r  <= 1'b0;
    end
    // default
    default: begin
      SLWRn_o         <= 1'b1;
      PKTENDn_o       <= 1'b1;
      done_o          <= 1'b0;
      dpo_rd_o        <= 1'b0;
      wrdCntrClr_r    <= 1'b1;
      wrdCntrInc_r    <= 1'b0;
      tmOutCntrClr_r  <= 1'b1;
      tmOutCntrInc_r  <= 1'b0;
    end
  endcase
end

// word counter
cntnbit #(.N(16)) wrdCntr(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .clr_i  (wrdCntrClr_r),
  .inc_i  (wrdCntrInc_r),
  .cnt_o  (wrdCntr_w)
);

// timeout counter
cntnbit #(.N(8)) tmOutCntr(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .clr_i  (tmOutCntrClr_r),
  .inc_i  (tmOutCntrInc_r),
  .cnt_o  (tmOutCntr_w)
);

assign dpo_dt_o = dpo_dt_i;

// for debug only
//always @(posedge clk_i) begin
//  if (rst_i) begin
//    dpo_dt_o = 32'd0;
//  end else begin
//    dpo_dt_o = dpo_dt_i;
//  end
//end

endmodule
