//-----------------------------------------------------------------------------
// Title      : Testbench for the Fx3 Slave module
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : cypress_slfifo_tb.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-12-02
// Last update: 2015-12-02
// Platform   : 
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Tests the Fx3 slave using an example Loopback master
//              from Cypress
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-12-02  1.0      mbonora        Created
//-----------------------------------------------------------------------------

`include "gpif_ii.sv"

import Fx3Pkg::*;

program Testbench#(int packetSize = 1024)(gpif_ii_if gpif, input logic clk, output logic rst, output logic [2:0] mode);
   
   const int max_burst_size = packetSize;

   const int nrLoopbackTests = 10;
   const int nrPartialTests = 10;
   const int nrZLPTests = 10;

   // Different modes for master
   const logic [2:0] PARTIAL    = 3'd1;
   const logic [2:0] ZLP        = 3'd2;
   const logic [2:0] STREAM_IN  = 3'd3;
   const logic [2:0] STREAM_OUT = 3'd4;
   const logic [2:0] LOOPBACK   = 3'd5;

   usb_fx3 #(packetSize) fx3 = new(gpif);
   
class LoopbackTest; 
   rand byte data[];
   randc int burstSize;

   constraint inRange {
      burstSize == packetSize;		 
      data.size() == burstSize;
   }
endclass; // Testcase

   task automatic testLoopback(ref LoopbackTest tc);
      byte packet[];
      int  bytesWritten;
      bit  isTimeout;
      time toTime = 10ms;
     
      assert(tc.randomize()) 
	else begin 
	   $warning("Could not generate Testcase, skipped");
	   return;
	end
	  
      fx3.writeControl(tc.data,bytesWritten,toTime);
      fx3.readControl(max_burst_size,packet,toTime,isTimeout);

      assert(!isTimeout)
	else $error("%t: Read Timeout in readControl", $time);
      assert (packet == tc.data) 
	else $error("%t: Mismatch BurstRead / BurstWrite!",$time);

   endtask // testLoopback

   task automatic testPartial();
      byte packet[];
      time toTime = 10ms;
      bit  isTimeout;
      
      fx3.readControl(2*packetSize,packet,toTime,isTimeout);
      assert(!isTimeout)
	else $error("%t: Read Timeout in readData", $time);
      assert(packet.size() == packetSize + 64)
	else $error("%t: TestPartial: unexpected packet size: %d",$time,packet.size());
   endtask // testPartial

   task automatic testZLP();
      byte packet[];
      time toTime = 10ms;
      bit  isTimeout;
      
      fx3.readControl(2*packetSize,packet,toTime,isTimeout);
      assert(!isTimeout)
	else $error("%t: Read Timeout in readData", $time);
      assert(packet.size() == packetSize)
	else $error("%t: TestZLP: unexpected packet size: %d",$time,packet.size());
   endtask // testZLP
   
   
   initial begin
      fx3.receive();
   end

   
   initial begin : stimuli
      LoopbackTest loopbackTc;      
      

      
      // generate reset -----------------------------------------------------
      rst = 0;
      @(posedge clk);
      @(negedge clk);
      rst = 1;
      @(posedge clk);
      @(posedge clk);

      
      // start stimuli
      loopbackTc = new();
      mode = LOOPBACK;
      #100ns;
      for(int i = 0; i < nrLoopbackTests; ++i)
	 testLoopback(loopbackTc);

      #100ns;
      mode = PARTIAL;
      for(int i = 0; i < nrPartialTests; ++i)
	testPartial();

      #100ns;
      mode = ZLP;
      for(int i = 0; i < nrZLPTests; ++i)
	testZLP();
      
      
      $display("stimuli finished");
      $finish;
      
   end : stimuli
endprogram // Testbench

   

module DUT(gpif_ii_if.master gpif,
	   input logic clk, 
	   input logic rst,
	   input logic[2:0] mode);


   wire [31:0] data_io;

   assign data_io = (gpif.data_t == 0) ? gpif.data_sm : 'Z;
   assign gpif.data_ms = data_io;

   wire        flaga,flagb,flagc,flagd;

   // glue logic for example flags:
   // flaga = Full, flagB = PartialFull thread0
   // flagC//  = Empty, flagD = PartialEmpty thread3

   reg 	       rflagC,rflagD;
   

   assign flagd = gpif.FLAGA;
   assign flagb = gpif.FLAGB;

   assign #60ns flagc = gpif.FLAGA;
   assign #60ns flaga = gpif.FLAGB;
   
   
   slaveFIFO2b_fpga_top
     slfifo_master(.reset_in_(rst),
		   .clk(clk),
		   .fdata(data_io),
		   .faddr(gpif.address),
		   .slrd(gpif.SLRD_n),
		   .slwr(gpif.SLWR_n),
		   .flaga(flaga),
		   .flagb(flagb),
		   .flagc(flagc),
		   .flagd(flagd),
		   .sloe(gpif.SLOE_n),
		   .slcs(gpif.SLCS_n),
		   .PCLK(gpif.PCLK),
		   .pktend(gpif.PKTEND_n),
		   .mode_p(mode),
		   .PMODE(),
		   .RESET());
endmodule // DUT

   
module top;
   
   logic clk = 0;
   logic rst;
   logic [2:0] mode;


   gpif_ii_if gpif();


   Testbench testbench(gpif,clk,rst,mode);
   DUT DUT(gpif,clk,rst,mode);
   

   always #5 clk = !clk;
         
endmodule // top
