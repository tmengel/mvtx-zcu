// krzysztof.sielewicz@cern.ch
// fifo_glue_logic2.v

`define SWIDTH  4
`define M 3

module fifo_glue_logic2(
  input           clk_i,
  input           rst_i,
  output          warn_o,
  
  output reg      fifoA_rd_o,
  input           fifoA_almst_empty_i,
  input           fifoA_almst_full_i,
  
  input           fifoB_almst_full_i,
  output reg      fifoB_wr_o
);

(* DONT_TOUCH = "true" *) reg [`SWIDTH*`M-1:0] state_in_r;
wire [3:0] state_out_w;

wire state_mvtr_warn_w;
assign warn_o = state_mvtr_warn_w;

// state register voter
mvtr #(.M(`M), .N(`SWIDTH)) state_mvtr(
  .vtr_i  (state_in_r),
  .vtr_o  (state_out_w),
  .warn_o (state_mvtr_warn_w)
);

// task write state
task write_state;
  input   [`SWIDTH-1:0]   state_i;
  output  [`SWIDTH*`M-1:0] state_o;
  
  begin
    state_o = {state_i, state_i, state_i};
  end
endtask

localparam  IDLE              = 4'd0, // IDLE - IDLE state
            WAIT_FIFOA_FULL   = 4'd1, //
            READ_FIFOA        = 4'd2, //
            READ_FIFOA_DLY    = 4'd3, //
            READA_WRITEB_FIFO = 4'd4, //
            WRITEB_DLY_0      = 4'd5, //
            WRITEB_DLY_1      = 4'd6, //
            WAIT_FIFOB_NFULL  = 4'd7; //

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    write_state(IDLE, state_in_r);
  end else begin
    case(state_out_w)
      IDLE : begin
        write_state(WAIT_FIFOA_FULL, state_in_r);
      end
      WAIT_FIFOA_FULL : begin
        if(!fifoA_almst_full_i)
          write_state(WAIT_FIFOA_FULL, state_in_r);
        else
          if(!fifoA_almst_empty_i & !fifoB_almst_full_i)
            write_state(READ_FIFOA, state_in_r);
          else
            write_state(WAIT_FIFOA_FULL, state_in_r);
      end
      READ_FIFOA : begin
        write_state(READ_FIFOA_DLY, state_in_r);
      end
      READ_FIFOA_DLY : begin
        write_state(READA_WRITEB_FIFO, state_in_r);
      end
      READA_WRITEB_FIFO : begin
        if(!fifoB_almst_full_i)
          write_state(READA_WRITEB_FIFO, state_in_r);
        else
          write_state(WRITEB_DLY_0, state_in_r);
      end
      WRITEB_DLY_0 : begin
        write_state(WRITEB_DLY_1, state_in_r);
      end
      WRITEB_DLY_1 : begin
        write_state(WAIT_FIFOB_NFULL, state_in_r);
      end
      WAIT_FIFOB_NFULL : begin
        if(!fifoB_almst_full_i)
          write_state(WAIT_FIFOA_FULL, state_in_r);
        else
          write_state(WAIT_FIFOB_NFULL, state_in_r);
      end
      default : begin
        write_state(IDLE, state_in_r);
      end
    endcase
  end
end

// FSM set outputs
always @(state_out_w) begin
  case (state_out_w)
    IDLE: begin
      fifoA_rd_o <= 1'b0;
      fifoB_wr_o <= 1'b0;
    end
    WAIT_FIFOA_FULL : begin
      fifoA_rd_o <= 1'b0;
      fifoB_wr_o <= 1'b0;
    end
    READ_FIFOA : begin
      fifoA_rd_o <= 1'b1;
      fifoB_wr_o <= 1'b0;
    end
    READ_FIFOA_DLY : begin
      fifoA_rd_o <= 1'b1;
      fifoB_wr_o <= 1'b0;
    end
    READA_WRITEB_FIFO : begin
      fifoA_rd_o <= 1'b1;
      fifoB_wr_o <= 1'b1;
    end
    WRITEB_DLY_0 : begin
      fifoA_rd_o <= 1'b0;
      fifoB_wr_o <= 1'b1;
    end
    WRITEB_DLY_1 : begin
      fifoA_rd_o <= 1'b0;
      fifoB_wr_o <= 1'b1;
    end
    WAIT_FIFOB_NFULL : begin
      fifoA_rd_o <= 1'b0;
      fifoB_wr_o <= 1'b0;
    end
    default : begin
      fifoA_rd_o <= 1'b0;
      fifoB_wr_o <= 1'b0;
    end
  endcase
end

endmodule
