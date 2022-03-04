////////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Module
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : smartProducer.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-09
// Last update  : 2015-12-09
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: N-bit smart producer
////////////////////////////////////////////////////////////////////////////////
module smartProducer #(parameter N = 32)(
  input               clk_i,
  input               rst_i,
  input               en_i,
  input               done_i,
  input               fifo_epty_i,
  input               fifo_full_i,
  input               fifo_almst_full_i,
  output reg          fifo_wr_o,
  output      [N-1:0] dtProd_o
);

reg           wrdCntrClr_r;
reg           wrdCntrInc_r;
wire  [7:0]   wrdCntr_w;

reg           dtProdClr_r;
reg           dtProdInc_r;
wire  [31:0]  dtProd_w;
assign dtProd_o = dtProd_w;

reg [2:0] state_r;
localparam  IDLE        = 3'd0,
            WT_FIFO_1   = 3'd1,
            WR_SHRT_PKT = 3'd2,
            WT_TMOUT1   = 3'd3,
            WT_FIFO_2   = 3'd4,
            WR_FULL_PKT = 3'd5,
            WT_TMOUT2   = 3'd6;

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IDLE;
  end else begin
    case(state_r)
      IDLE:         //0
        state_r <= WT_FIFO_1;
      WT_FIFO_1:    //1
        state_r <= (fifo_epty_i & !fifo_full_i & !fifo_almst_full_i) ? WR_SHRT_PKT : WT_FIFO_1;
      WR_SHRT_PKT:  //2
        state_r <= ((wrdCntr_w < 8'd63) & !fifo_almst_full_i) ? WR_SHRT_PKT : WT_TMOUT1;
      WT_TMOUT1:    // 3
        state_r <= (!done_i) ? WT_TMOUT1 : WT_FIFO_2;
      WT_FIFO_2:    //4
        state_r <= (fifo_epty_i & !fifo_full_i & !fifo_almst_full_i) ? WR_FULL_PKT : WT_FIFO_2;
      WR_FULL_PKT:  //5
        state_r <= ((wrdCntr_w < 8'd255) & !fifo_almst_full_i) ? WR_FULL_PKT : WT_TMOUT2;
      WT_TMOUT2:    //6
        state_r <= (!done_i) ? WT_TMOUT2 : WT_FIFO_1;
      default:      //default
        state_r <= IDLE;
    endcase
  end
end

// FSM set outputs
always @(state_r) begin
  case (state_r)
    // 0
    IDLE: begin
      wrdCntrClr_r    <= 1'b1;
      wrdCntrInc_r    <= 1'b0;
      dtProdClr_r     <= 1'b1;
      dtProdInc_r     <= 1'b0;
      fifo_wr_o       <= 1'b0;
    end
    // 1
    WT_FIFO_1: begin
      wrdCntrClr_r    <= 1'b1;
      wrdCntrInc_r    <= 1'b0;
      dtProdClr_r     <= 1'b1;
      dtProdInc_r     <= 1'b0;
      fifo_wr_o       <= 1'b0;
    end
    // 2
    WT_TMOUT1: begin
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      dtProdClr_r     <= 1'b0;
      dtProdInc_r     <= 1'b0;
      fifo_wr_o       <= 1'b0;
    end
    // 3
    WR_SHRT_PKT: begin
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      dtProdClr_r     <= 1'b0;
      dtProdInc_r     <= 1'b1;
      fifo_wr_o       <= 1'b1;
    end
    // 4
    WT_FIFO_2: begin
      wrdCntrClr_r    <= 1'b1;
      wrdCntrInc_r    <= 1'b0;
      dtProdClr_r     <= 1'b1;
      dtProdInc_r     <= 1'b0;
      fifo_wr_o       <= 1'b0;
    end
    // 5
    WR_FULL_PKT: begin
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b1;
      dtProdClr_r     <= 1'b0;
      dtProdInc_r     <= 1'b1;
      fifo_wr_o       <= 1'b1;
    end
    // 6
    WT_TMOUT2: begin
      wrdCntrClr_r    <= 1'b0;
      wrdCntrInc_r    <= 1'b0;
      dtProdClr_r     <= 1'b0;
      dtProdInc_r     <= 1'b0;
      fifo_wr_o       <= 1'b0;
    end
    // default
    default: begin
      wrdCntrClr_r    <= 1'b1;
      wrdCntrInc_r    <= 1'b0;
      dtProdClr_r     <= 1'b1;
      dtProdInc_r     <= 1'b0;
      fifo_wr_o       <= 1'b0;      
    end
  endcase
end

// word counter
cntnbit #(.N(8)) wrdCntr(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .clr_i  (wrdCntrClr_r),
  .inc_i  (wrdCntrInc_r),
  .cnt_o  (wrdCntr_w)
);

// data producer
cntnbit #(.N(32)) dtProd(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .clr_i  (dtProdClr_r),
  .inc_i  (dtProdInc_r),
  .cnt_o  (dtProd_w)
);

endmodule
