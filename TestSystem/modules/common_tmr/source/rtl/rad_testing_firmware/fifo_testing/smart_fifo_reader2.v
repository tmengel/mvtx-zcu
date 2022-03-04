// krzysztof.sielewicz@cern.ch
// fifo_reader2.v

`define SWIDTH  4

(* DONT_TOUCH = "true" *) module smart_fifo_reader2 #(parameter
  N = 32,
  M = 3)(
  input           clk_i,
  input           rst_i,
  input           fifo_almst_full_i,
  input           fifo_empty_i,
  input           fifo_almst_empty_i,
  output  reg     fifo_rd_o,
  input   [N-1:0] fifo_data_i,
  output  [M-1:0] err_o
);

(* DONT_TOUCH = "true" *) reg [M-1:0] err_r;
assign err_o = err_r;

(* DONT_TOUCH = "true" *) reg [`SWIDTH*M-1:0] state_in_r;
wire [3:0] state_out_w;

// state register voter
mvtr #(.M(M), .N(`SWIDTH)) state_mvtr(
  .vtr_i  (state_in_r),
  .vtr_o  (state_out_w),
  .warn_o (state_mvtr_warn_w)
);

// task write state
task write_state;
  input   [`SWIDTH-1:0]   state_i;
  output  [`SWIDTH*M-1:0] state_o;
  
  begin
    state_o = {state_i, state_i, state_i};
  end
endtask

localparam  IDLE            = 4'd0, // IDLE - IDLE state
            WAIT_DLY        = 4'd1,
            WAIT_FIFO_FULL  = 4'd2, // WAIT_DLY - wait until FIFO is ready
            READ_FIFO       = 4'd3, // WRITE_DATA - write data to FIFO
            WAIT_FIFO       = 4'd4, // WAIT_FIFO - wait until FIFO empty again
            WAIT_EN         = 4'd5; // WAIT until right on the FIFO's output and can be compared

reg [7:0] cnt_r;    // register to keep counter value
reg       en_cmp_r; // register to keep comparator enable value

// FSM state changing part
always @(posedge clk_i) begin
  if (rst_i) begin
    write_state(IDLE, state_in_r);
    cnt_r   <= 8'd0;
  end else begin
    case(state_out_w)
      IDLE : begin
        write_state(WAIT_DLY, state_in_r);
        cnt_r   <= 8'd0;
      end
      WAIT_DLY : begin
        if(cnt_r < 8'd15) begin
          write_state(WAIT_DLY, state_in_r);
          cnt_r   <= cnt_r + 8'd1;
        end else begin
          cnt_r   <= 8'd0;
          write_state(WAIT_FIFO_FULL, state_in_r);
        end
      end
      WAIT_FIFO_FULL : begin
      cnt_r <= 8'd0;
        // if(!fifo_almst_full_i & fifo_almst_empty_i)
        if(!fifo_almst_full_i)
          write_state(WAIT_FIFO_FULL, state_in_r);
        else
          write_state(WAIT_EN, state_in_r);
      end
      READ_FIFO : begin
        cnt_r <= 8'd0;
        if (!fifo_almst_empty_i)
          write_state(READ_FIFO, state_in_r);
        else
          write_state(WAIT_FIFO, state_in_r);
      end
      WAIT_FIFO : begin
        cnt_r <= 8'd0;
        if(!fifo_almst_full_i & !fifo_almst_empty_i)
          write_state(WAIT_FIFO, state_in_r);
        else
          write_state(WAIT_EN, state_in_r);
      end
      WAIT_EN : begin
        if(cnt_r < 8'd7) begin
          write_state(WAIT_EN, state_in_r);
          cnt_r   <= cnt_r + 8'd1;
        end else begin
          cnt_r   <= 8'd0;
          write_state(READ_FIFO, state_in_r);
        end
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
      fifo_rd_o <= 1'b0;
      en_cmp_r  <= 1'b0;
    end
    WAIT_DLY : begin
      fifo_rd_o <= 1'b0;
      en_cmp_r  <= 1'b0;
    end
    WAIT_FIFO_FULL : begin
      fifo_rd_o <= 1'b0;
      en_cmp_r  <= 1'b0;
    end
    READ_FIFO : begin
      fifo_rd_o <= 1'b1;
      en_cmp_r  <= 1'b1;
    end
    WAIT_FIFO : begin
      fifo_rd_o <= 1'b0;
      en_cmp_r  <= 1'b0;
    end
    WAIT_EN : begin
      fifo_rd_o <= 1'b1;
      en_cmp_r  <= 1'b0;
    end
    default: begin
      fifo_rd_o <= 1'b0;
      en_cmp_r  <= 1'b0;
    end
  endcase
end

//reading from the FIFO
// always @(posedge clk_i) begin
  // if (rst_i) begin
    // fifo_rd_o <= 1'b0;
  // end else if(!fifo_almst_empty_i) begin
    // fifo_rd_o <= 1'b1;
  // end else begin
    // fifo_rd_o <= 1'b0;
  // end
// end

(* DONT_TOUCH = "true" *) reg [N-1:0] fifo_data_r[M*2-1:0];

always @(posedge clk_i)
  begin : shifter
    integer j;
    if (rst_i) begin
      for(j = 0; j < M*2; j = j + 1)
        fifo_data_r[j] <= {N{1'b0}};
      err_r <= {N{1'b0}};
    end else begin
      for(j = 0; j < M; j = j + 1) begin
        fifo_data_r[j*2] <= fifo_data_i;
        fifo_data_r[j*2+1] <= fifo_data_r[j*2];
        
        if((fifo_data_r[j*2] != fifo_data_r[j*2+1] + 1'd1) & en_cmp_r)
          err_r[j] <= 1'b1;
        else
          err_r[j] <= 1'b0;
      end
  end
end

endmodule
