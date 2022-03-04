// @ksielewi
// tbRdoutCntrl.v

module tbRdoutCntrl #(parameter
  N = 32,
  K = 576)(
  input                 clk_i,
  input                 rst_i,
  input       [K*N-1:0] data_i,
  input                 fifo_full_i,
  input                 fifo_almst_full_i,
  output reg            fifo_wr_o,
  output      [N-1:0] fifo_data_o
);

reg         wrdCntrClr_r;
reg         wrdCntrInc_r;
wire [15:0] wrdCntr_w;
reg         sh_data_r;
wire [31:0] cntr_data_w;
reg [1:0]   dataOutMux; // 2'd0/2'd3 = HEADER, 2'd1 = cntr_data_w, 2'd2 = FOOTER
reg [31:0]  HEADER = 32'h00AAAAAA;
reg [31:0]  FOOTER = 32'h00FFFFFF;
reg load_r;

reg [3:0] state_r;
localparam  IDLE        = 4'd0, // IDLE - IDLE state
            LOAD_DT     = 4'd2,
            WR_HEADER   = 4'd3,
            WAIT_1      = 4'd4,
            WR_DATA     = 4'd5,
            WAIT_2      = 4'd6,
            WR_FOOTER   = 4'd7;

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IDLE;
  end else begin
    case(state_r)
      IDLE: begin
        state_r <= LOAD_DT;
      end
      LOAD_DT: begin
        state_r <= (!fifo_almst_full_i) ? WR_HEADER : IDLE;
      end
      WR_HEADER: begin
        state_r <= (!fifo_almst_full_i) ? WR_DATA : WAIT_1;
      end
      WAIT_1: begin
        state_r <= (!fifo_almst_full_i) ? WR_DATA : WAIT_1;
      end
      WR_DATA: begin
        if(fifo_almst_full_i) begin
          state_r <= WAIT_2;
        end else begin
          //state_r <= (wrdCntr_w < 16'd255) ? WR_DATA : WR_FOOTER;
          state_r <= (wrdCntr_w < K-1) ? WR_DATA : WR_FOOTER;
        end
      end
      WAIT_2: begin
        //if(!fifo_almst_full_i & wrdCntr_w < 16'd256) begin
        if(!fifo_almst_full_i & wrdCntr_w < K) begin
          state_r <= WR_DATA;
        //end else if(!fifo_almst_full_i & wrdCntr_w > 16'd255) begin
        end else if(!fifo_almst_full_i & wrdCntr_w > K-1) begin
          state_r <= WR_FOOTER;
        end else begin
          state_r <= WAIT_2;
        end
      end
      WR_FOOTER: begin
        state_r <= IDLE;
      end
      default: begin
        state_r <= IDLE;
      end
    endcase
  end
end

// FSM set outputs
always @(state_r) begin
  case (state_r)
    IDLE: begin
      dataOutMux    <= 2'd0;
      fifo_wr_o     <= 1'b0;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b1;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
    LOAD_DT: begin
      dataOutMux    <= 2'd0;
      fifo_wr_o     <= 1'b0;
      load_r        <= 1'b1;
      wrdCntrClr_r  <= 1'b1;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
    // 1
    WR_HEADER: begin
      dataOutMux    <= 2'd0;
      fifo_wr_o     <= 1'b1;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
    // 2
    WAIT_1: begin
      dataOutMux    <= 2'd0;
      fifo_wr_o     <= 1'b0;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
    // 3
    WR_DATA: begin
      dataOutMux    <= 2'd1;
      fifo_wr_o     <= 1'b1;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b1;
      sh_data_r     <= 1'b1;
    end
    // 4
    WAIT_2: begin
      dataOutMux    <= 2'd1;
      fifo_wr_o     <= 1'b0;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
    // 5
    WR_FOOTER: begin
      dataOutMux    <= 2'd2;
      fifo_wr_o     <= 1'b1;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
    // default
    default: begin
      dataOutMux    <= 2'd0;
      fifo_wr_o     <= 1'b0;
      load_r        <= 1'b0;
      wrdCntrClr_r  <= 1'b0;
      wrdCntrInc_r  <= 1'b0;
      sh_data_r     <= 1'b0;
    end
  endcase
end

assign fifo_data_o =
  (dataOutMux == 2'd0) ? HEADER       :
  (dataOutMux == 2'd1) ? cntr_data_w  :
  (dataOutMux == 2'd2) ? FOOTER       : HEADER;

// word counter
cntnbit #(.N(16)) wrdCntr(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .clr_i  (wrdCntrClr_r),
  .inc_i  (wrdCntrInc_r),
  .cnt_o  (wrdCntr_w)
);

// data shifter
dataShifter #(.N(N*K), .M(N)) dataShifter(
  .clk_i      (clk_i),
  .rst_i      (rst_i),
  .load_i     (load_r),
  .sh_data_i  (sh_data_r),
  .data_i     (data_i),
  .data_o     (cntr_data_w)
);

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../../../../../usb_if/source/rtl")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
