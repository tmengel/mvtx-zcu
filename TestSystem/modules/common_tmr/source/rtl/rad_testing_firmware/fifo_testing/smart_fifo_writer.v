// krzysztof.sielewicz@cern.ch
// smart_fifo_writer.v

(* DONT_TOUCH = "true" *) module smart_fifo_writer #(parameter
  N = 32,
  M = 3)(
  input           clk_i,
  input           rst_i,
  output reg      en_rdr_o,
  input           fifo_almst_empty_i,
  input           fifo_full_i,
  input           fifo_almst_full_i,
  output reg      fifo_wr_o,
  output [N-1:0]  fifo_data_o,
  output          pg_warn_o
);

reg en_pat_gen_r;

// TMR-ed pattern generator
pat_gen #(.N(N), .M(M)) pat_gen(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .en_i   (en_pat_gen_r),
  .pat_o  (fifo_data_o),
  .warn_o (pg_warn_o)
);

reg [7:0] cnt_r;

reg [3:0] state_r;
localparam  IDLE        = 4'd0, // IDLE - IDLE state
            WAIT_DLY    = 4'd1,
            CHK_FIFO    = 4'd2,
            WRITE_DATA  = 4'd3,
            WAIT_FIFO   = 4'd4,
            WAIT_EN     = 4'd5,
            WRITE_CONT  = 4'd6;

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    state_r <= IDLE;
    cnt_r   <= 8'd0;
  end else begin
    case(state_r)
      IDLE: begin
        state_r <= WAIT_DLY;
        cnt_r   <= 8'd0;
      end
      WAIT_DLY : begin
        if(cnt_r < 8'd15) begin
          state_r <= WAIT_DLY;
          cnt_r   <= cnt_r + 8'd1;
        end else begin
          state_r <= CHK_FIFO;
          cnt_r   <= 8'd0;
        end
      end
      CHK_FIFO : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i)
          state_r <= WRITE_DATA;
        else
          state_r <= WAIT_FIFO;
      end
      WRITE_DATA : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i & fifo_almst_empty_i)
          state_r <= WRITE_DATA;
        else if (!fifo_almst_full_i & !fifo_almst_empty_i)
          state_r <= WAIT_EN;
        else
          state_r <= WAIT_FIFO;
      end
      WAIT_FIFO : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i)
          state_r <= WRITE_DATA;
        else
          state_r <= WAIT_FIFO;
      end
      WAIT_EN : begin
        if(cnt_r < 8'd4) begin
          state_r <= WAIT_EN;
          cnt_r   <= cnt_r + 8'd1;
        end else begin
          state_r <= WRITE_CONT;
          cnt_r   <= 8'd0;
        end
      end
      WRITE_CONT : begin
        cnt_r <= 8'd0;
        state_r <= WRITE_CONT;
      end
      default: begin
        cnt_r <= 8'd0;
        state_r <= IDLE;
      end
    endcase
  end
end

// FSM set outputs
always @(state_r) begin
  case (state_r)
    IDLE: begin
      fifo_wr_o     <= 1'b0;
      en_pat_gen_r  <= 1'b0;
      en_rdr_o      <= 1'b0;
    end
    WAIT_DLY : begin
      fifo_wr_o     <= 1'b0;
      en_pat_gen_r  <= 1'b0;
      en_rdr_o      <= 1'b0;
    end
    CHK_FIFO : begin
      fifo_wr_o     <= 1'b0;
      en_pat_gen_r  <= 1'b0;
      en_rdr_o      <= 1'b0;
    end
    WRITE_DATA : begin
      fifo_wr_o     <= 1'b1;
      en_pat_gen_r  <= 1'b1;
      en_rdr_o      <= 1'b0;
    end
    WAIT_FIFO : begin
      fifo_wr_o     <= 1'b0;
      en_pat_gen_r  <= 1'b0;
      en_rdr_o      <= 1'b0;
    end
    WAIT_EN : begin
      fifo_wr_o     <= 1'b1;
      en_pat_gen_r  <= 1'b1;
      en_rdr_o      <= 1'b0;
    end
    WRITE_CONT : begin
      fifo_wr_o     <= 1'b1;
      en_pat_gen_r  <= 1'b1;
      en_rdr_o      <= 1'b1;
    end
    // default
    default: begin
      fifo_wr_o     <= 1'b0;
      en_pat_gen_r  <= 1'b0;
      en_rdr_o      <= 1'b0;
    end
  endcase
end

endmodule
