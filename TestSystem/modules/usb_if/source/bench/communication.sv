//-----------------------------------------------------------------------------
// Title      : Communication module to abstract communication with RUv0a
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : communication.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2016-04-11
// Last update: 2016-04-11
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Abstraction class to communicate with the readout unit board,
//              providing functions for read/write to a chip or board
//
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
//-----------------------------------------------------------------------------

class Communication;

   const int  ADD_WRITE_CTRL	        = 0;
   const int  ADD_WRITE_ADDRESS	= 1;
   const int  ADD_WRITE_DATA	        = 2;
   const int  ADD_WRITE_PHASE	        = 3;
   const int  ADD_READ_STATUS		= 4;
   const int  ADD_READ_DATA		= 5;

   const int  OPCODE_WROP		= 'b1001_1100;
   const int  OPCODE_RDOP		= 'b0100_1110;

   parameter int          gDataWidth = 16;

   usb_fx3 fx3;

   byte                   mbuffer[$];
   int                    mReadCntr = 0;

   int                    WS_DCTRL = 0;

   bit                    verbose = 0;

   function new(ref usb_fx3 fx3, input int WS_DCTRL, input bit verbose);
      this.fx3 = fx3;
      this.WS_DCTRL = WS_DCTRL;
      this.verbose = verbose;
   endfunction // new

   task buffer_write(input logic[6:0] mod, input logic[7:0] address, input logic[15:0] data);
      mbuffer.push_back({1'd1, mod});
      mbuffer.push_back(address);
      mbuffer.push_back(data[15:8]);
      mbuffer.push_back(data[7:0]);
   endtask // buffer_write

   task buffer_read(input logic[6:0] mod, input logic[7:0] address);
      mbuffer.push_back({1'd0, mod});
      mbuffer.push_back(address);
      mbuffer.push_back(8'd0);
      mbuffer.push_back(8'd0);
      mReadCntr++;
   endtask // buffer_read

   task flush();
      byte buffer[];
      int  bytesWritten;

      buffer = new[mbuffer.size()](mbuffer);
      fx3.writeControl(buffer,bytesWritten);
      assert(bytesWritten == buffer.size()) else
        $warning("Write: Timeout while writing to Control, Written: %d/4",bytesWritten);

      mbuffer = {};
   endtask // flush

   task read_results(output [15:0] datalist []);

      logic [15:0] data;
      byte         buffer [] = new[4];
      int          bytesWritten = 4*mReadCntr;
      int          bytesRead = 0;
      byte         packet[];
      bit          isTimeout = 0;
      int          j = 0;
      int          i = 0;

      buffer = new[1024];
      while(bytesRead < bytesWritten && !isTimeout) begin
         fx3.readControl(1024,packet,isTimeout);
         for(i = 0; i < packet.size(); i++)
           buffer[bytesRead + i] = packet[i];
         bytesRead += packet.size();
      end
      assert (bytesRead == bytesWritten) else
        $warning("Read from board timed out!");
      datalist = new[mReadCntr];
      for (j=0; j<mReadCntr; j++) begin
         data = {buffer[j*4 + 2], buffer[j*4 + 3]};
         assert (buffer[j*4]>>7 == 0) else
           $warning("Wishbone read error: 0x%h%h%h%h", buffer[j],buffer[j+1],buffer[j+2],buffer[j+3]); //
         datalist[j] = data;
      end
      mReadCntr = 0;
   endtask // read_results

   task write_to_board(input logic[6:0] mod, input logic[7:0] address, input logic[15:0] data, input bit commit=1);
      if (commit == 1)
         single_write_to_board(mod, address, data);
      else
        buffer_write(mod, address, data);
      if(verbose)
        $display("Communication: Write to board module 0x%h, address 0x%h, data 0x%h",mod,address,data);
   endtask // write_to_board

   task single_write_to_board(input logic[6:0] mod, input logic[7:0] address, input logic[15:0] data);

      byte buffer[] = new[4];
      int  bytesWritten = 0;

      buffer[0] = {1'd1, mod};
      buffer[1] = address;
      buffer[2] = data[15:8];
      buffer[3] = data[7:0];

      fx3.writeControl(buffer,bytesWritten);
      assert(bytesWritten == buffer.size()) else
        $warning("Write: Timeout while writing to Control, Written: %d/4",bytesWritten);

   endtask // single_write_to_board

   task read_from_board(input logic[6:0] mod, input logic[7:0] address, output logic[15:0] data, input bit commit=1);
      if (commit==1)
        single_read_from_board(mod, address, data);
      else begin
         buffer_read(mod, address);
      end
      if(verbose)
        if(commit == 1)
          $display("Communication: Read from board  module 0x%h, address 0x%h, data read 0x%h",mod,address,data);
        else
          $display("Communication: Scheduled Read from board  module 0x%h, address 0x%h. Not committed yet",mod,address);
   endtask // read_from_board

   task single_read_from_board(input logic[6:0] mod, input logic[7:0] address, output logic[15:0] data);
      byte buffer[] = new[4];
      int  bytesWritten = 0;
      int  bytesRead = 0;
      byte packet[];
      bit  isTimeout = 0;


      buffer[0] = {1'd0, mod};
      buffer[1] = address;
      buffer[2] = '0;
      buffer[3] = '0;

      fx3.writeControl(buffer,bytesWritten);
      assert(bytesWritten == buffer.size()) else
        $warning("Write: Timeout while writing to Control, Written: %d/4",bytesWritten);

      buffer = new[1024];
      while(bytesRead < bytesWritten && !isTimeout) begin
         fx3.readControl(1024,packet,isTimeout);
         for(int i = 0; i < packet.size(); i++)
           buffer[bytesRead + i] = packet[i];
         bytesRead += packet.size();
      end
      data = {buffer[2],buffer[3]};
      assert (bytesRead == bytesWritten) else begin
         $warning("Read from board timed out!");
         data = 'X;
      end
   endtask // read_from_board

   task read_DP2(input int size, output byte data[], output bit isTimedOut);
      fx3.readData0(size,data,isTimedOut);
   endtask // read_DP2

   task read_DP3(input int size, output byte data[], output bit isTimedOut);
      fx3.readData1(size,data,isTimedOut);
   endtask // read_DP2

   // pALPIDE/ALPIDE write/read
   task chip_write(input logic [15:0] Addr, input logic [15:0] Dat, input logic [7:0] ChipId, input bit commit = 1);
     begin
	write_to_board(WS_DCTRL, ADD_WRITE_ADDRESS, Addr, 0);
	write_to_board(WS_DCTRL, ADD_WRITE_DATA, Dat, 0);
	write_to_board(WS_DCTRL, ADD_WRITE_CTRL, {OPCODE_WROP,ChipId}, 0);
        if (commit)
          flush();
     end
   endtask // chip_write

   task chip_opcode(input logic [7:0] OPCODE, input logic [7:0] ChipId, input bit commit = 1);
      begin
	 write_to_board(WS_DCTRL, ADD_WRITE_CTRL, {OPCODE,ChipId}, commit);
      end
   endtask // chip_opcode

   task chip_read(input logic [15:0]            Addr,
                  input logic [7:0]             ChipId ,
                  output logic [gDataWidth-1:0] data_read,
                  input bit                     commit = 1,
                  input bit                     verbose = 0);
      logic [15:0] status_read;
      logic [15:0] datalist [];
      logic [2:0]  phase_selected;

      write_to_board(WS_DCTRL, ADD_WRITE_ADDRESS, Addr, 0);
      write_to_board(WS_DCTRL, ADD_WRITE_CTRL, {OPCODE_RDOP,ChipId}, 0);
      read_from_board(WS_DCTRL,ADD_READ_STATUS, status_read, 0);
      read_from_board(WS_DCTRL,ADD_READ_DATA, data_read, 0);
      flush();
      read_results(datalist);
      status_read = datalist[0];
      data_read = datalist[1];
      phase_selected = status_read[15:13];

      assert(status_read[12:7] == 6'h3F) else
        $warning("Alpide control status register NOK: %h",status_read[12:7]);
      assert(status_read[6:0] == ChipId) else
        $warning("ChipId mismatch: read: %h, expected: %h",status_read[6:0],ChipId);
      if (verbose == 1) begin
         $display("Communication: Read from chip, phase selected 0x%h", phase_selected);
      end

   endtask // chip_read

endclass // Communication
