class Chip;

   parameter int          gDataWidth = 16;

   // Registers
   const int REG_COMMAND       = 'h0;

   const int OPCODE_GRST       = 'hD2;
   const int OPCODE_PRST       = 'hE4;
   const int OPCODE_PULSE      = 'h78;
   const int OPCODE_BCRST      = 'h36;
   const int OPCODE_RORST      = 'h63;
   const int OPCODE_WROP       = 'h9C;
   const int OPCODE_RDOP       = 'h4E;
   const int OPCODE_TRIGGER    = 'h55;
   const int OPCODE_XOFF       = 'hFF10;
   const int OPCODE_XON        = 'hFF11;

   Communication comm;
   logic [6:0] chipid;
   function new(ref Communication comm, input logic[6:0] chipid);
      this.comm = comm;
      this.chipid = chipid;
   endfunction // new

   task init(input bit manchesterEncodingDisabled = 1);
      logic [15:0] config_data = '0;

      chip_opcode(OPCODE_GRST);

      // chipid -> Initial token and prev_chipID
      if(this.chipid[6:4] > 3'd0 && this.chipid[3:0] == '0) begin
         config_data[3:0] = '0;
         config_data[4] = 1;
      end
      config_data[5] = manchesterEncodingDisabled; // manchaster encoding disabled
      config_data[6] = 1;
      comm.chip_write(16'h10, config_data,chipid);
      if (manchesterEncodingDisabled==1'b0)
        $display(">>>Manchester encoding enabled in chip init<<<<<<");
      else
        $display(">>>Manchester encoding disabled in chip init<<<<<<");
   endtask // init

   task chip_opcode(input logic [7:0] Opcode);
      comm.chip_opcode(Opcode,chipid);
   endtask // chip_opcode

   task trigger();
      $display("Send a trigger");
      chip_opcode(OPCODE_TRIGGER);
   endtask // trigger

   task send_xoff(bit xoff = 1);
      if(xoff)
        chip_opcode(OPCODE_XOFF);
      else
        chip_opcode(OPCODE_XON);
   endtask // send_xoff


   task configure_dtu();
      comm.chip_write(16'd20,16'h0185,chipid);
      comm.chip_write(16'd20,16'h018D,chipid);
      comm.chip_write(16'd20,16'h0085,chipid);
   endtask // configure_dtu

   task initialize_readout_test();
      set_chipmode(2'd1);
      chip_opcode(OPCODE_RORST);
   endtask // initialize_readout_test

   task propagate_prbs(logic[1:0] rate);
      logic [15:0] config_data = '0;
      config_data[0] = 1; // test enable
      config_data[1] = 1; // internal pattern enable
      config_data[4:3] = rate;
      config_data[5] = 1; // Bypass 8b10b
      comm.chip_write(16'd24, config_data, chipid);
   endtask // propagate_prbs


   // Set the readout link speed:
   // Possible values: 0 -> 400Mbps, 1 -> 600 Mbps, 2,3 -> 1200 Mbps
   task set_readout_speed(logic [1:0] linkSpeed);
      logic[15:0] data_rd;
      comm.chip_read(16'd1,chipid,data_rd);
      data_rd[5:4] = linkSpeed;
      comm.chip_write(16'd1,data_rd,chipid);
      $display("Set redout speed; write to register: %h",data_rd);
   endtask // set_readout_speed


   task set_chipmode(logic [1:0] chipMode);
      logic[15:0] data_rd;
      comm.chip_read(16'd1,chipid,data_rd);
      $display("time: %t, set_chipmode: Readback %h",$time,data_rd);
      data_rd[1:0] = chipMode;
      comm.chip_write(16'd1,data_rd,chipid);
      comm.chip_read(16'd1,chipid,data_rd);
      $display("time: %t, set_chipmode: Readback %h",$time,data_rd);
   endtask // set_chipmode

endclass // Chip
