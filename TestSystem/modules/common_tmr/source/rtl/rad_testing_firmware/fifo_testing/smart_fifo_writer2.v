// krzysztof.sielewicz@cern.ch
// smart_fifo_writer.v

`define SWIDTH  4

(* DONT_TOUCH = "true" *) module smart_fifo_writer2 #(parameter
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

(* DONT_TOUCH = "true" *) reg [`SWIDTH*M-1:0] state_in_r;
wire [3:0] state_out_w;

reg [7:0] cnt_r;

// TMR-ed pattern generator
pat_gen #(.N(N), .M(M)) pat_gen(
  .clk_i  (clk_i),
  .rst_i  (rst_i),
  .en_i   (en_pat_gen_r),
  .pat_o  (fifo_data_o),
  .warn_o (pg_warn_o)
);

mvtr #(.M(M), .N(`SWIDTH)) state_mvtr(
  .vtr_i  (state_in_r),
  .vtr_o  (state_out_w),
  .warn_o ()
);

task write_state;
  input   [`SWIDTH-1:0]   state_i;
  output  [`SWIDTH*M-1:0] state_o;
  
  begin
    state_o = {state_i, state_i, state_i};
  end
endtask

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
    write_state(IDLE, state_in_r);
    cnt_r   <= 8'd0;
  end else begin
    case(state_out_w)
      IDLE: begin
        write_state(WAIT_DLY, state_in_r);
        cnt_r   <= 8'd0;
      end
      WAIT_DLY : begin
        if(cnt_r < 8'd15) begin
          write_state(WAIT_DLY, state_in_r);
          cnt_r   <= cnt_r + 8'd1;
        end else begin
          write_state(CHK_FIFO, state_in_r);
          cnt_r   <= 8'd0;
        end
      end
      CHK_FIFO : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i)
          write_state(WRITE_DATA, state_in_r);
        else
          write_state(WAIT_FIFO, state_in_r);
      end
      WRITE_DATA : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i & fifo_almst_empty_i)
          write_state(WRITE_DATA, state_in_r);
        else if (!fifo_almst_full_i & !fifo_almst_empty_i)
          write_state(WAIT_EN, state_in_r);
        else
          write_state(WAIT_FIFO, state_in_r);
      end
      WAIT_FIFO : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i)
          write_state(WRITE_DATA, state_in_r);
        else
          write_state(WAIT_FIFO, state_in_r);
      end
      WAIT_EN : begin
        if(cnt_r < 8'd4) begin
          write_state(WAIT_EN, state_in_r);
          cnt_r <= cnt_r + 8'd1;
        end else begin
          write_state(WRITE_CONT, state_in_r);
          cnt_r <= 8'd0;
        end
      end
      WRITE_CONT : begin
        cnt_r <= 8'd0;
        write_state(WRITE_CONT, state_in_r);
      end
      default: begin
        cnt_r <= 8'd0;
        write_state(IDLE, state_in_r);
      end
    endcase
  end
end

// FSM set outputs
always @(state_out_w) begin
  case (state_out_w)
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
