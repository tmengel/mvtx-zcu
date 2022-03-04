// @ksielewi
// krzysztof.sielewicz@cern.ch
// dut_fsm.v

(* DONT_TOUCH = "true" *) module
   dut_fsm
     #(parameter IO_SIZE_G = 4)
   (
    input                      clk_i,
    input                      rst_i,
    input [IO_SIZE_G-1:0]      data_i,
    output reg [IO_SIZE_G-1:0] data_o
    );

   (* fsm_encoding = "sequential" *) reg [IO_SIZE_G-1:0] state_r;
   localparam  S0    = 4'd0,
     S1    = 4'd1,
     S2    = 4'd2,
     S3    = 4'd3,
     S_ERR = 4'd15;

   // FSM state changing part
   always @(posedge clk_i) begin
      if (rst_i) begin
         state_r <= S0;
      end else begin
         case(state_r)
           S0: begin
              if(data_i == 4'd1)
                state_r <= S1;
              else if(data_i == 4'd15)
                state_r <= S_ERR;
              else
                state_r <= S0;
           end
           S1: begin
              if(data_i == 4'd1)
                state_r <= S1;
              else if(data_i == 4'd2)
                state_r <= S2;
              else
                state_r <= S_ERR;
           end
           S2: begin
              if(data_i == 4'd2)
                state_r <= S2;
              else if(data_i == 4'd3)
                state_r <= S3;
              else
                state_r <= S_ERR;
           end
           S3: begin
              if(data_i == 4'd3)
                state_r <= S3;
              else if(data_i == 4'd15)
                state_r <= S_ERR;
              else
                state_r <= S0;
           end
           S_ERR: begin
              state_r <= S0;
           end
           default: begin
              state_r <= S_ERR;
           end
         endcase
      end
   end

   // FSM set outputs
   always @(state_r) begin
      case(state_r)
        S0: begin
           data_o <= 4'd0;
        end
        S1: begin
           data_o <= 4'd1;
        end
        S2: begin
           data_o <= 4'd2;
        end
        S3: begin
           data_o <= 4'd3;
        end
        S_ERR: begin
           data_o <= 4'd15;
        end
        default: begin
           data_o <= 4'd0;
        end
      endcase
   end

endmodule
