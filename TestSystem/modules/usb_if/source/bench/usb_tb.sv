//-----------------------------------------------------------------------------
// Title      : Testbench for USB module
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : usb_tb.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-17
// Last update: 2015-11-17
// Platform   : 
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Tests the usb module with GPIF and wishbone connectors
//
// TODO: There is a bug preventing a burst size > 1 packet size
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-17  1.0      mbonora        Created
//-----------------------------------------------------------------------------

`include "gpif_ii.sv"

import Fx3Pkg::*;


interface DataFifo(input clk);
   logic write_en;
   logic [31:0] data;
   logic 	full;
   logic 	almost_full;

   clocking wcb @(posedge clk);
      output 	data;
      output 	write_en;
      input 	full;
      input 	almost_full;
   endclocking // wcb

   modport testbench(input clk, clocking wcb);
   
   modport in(input clk, input write_en, data, output full,almost_full);
endinterface // DataFifo


program Testbench#(int gDataWidth = 16, int gAddrWidth = 8, int gModWidth = 4, int packetSize = 1024)(input logic clk, output logic rst, gpif_ii_if gpif, DataFifo.testbench data0, DataFifo.testbench data1);

   const int max_burst_size = packetSize / 4;
   const int nr_tests_single = 20;
   const int nr_tests_burst = 10;
   const int nr_tests_Data = 20;

   usb_fx3 #(packetSize,1) fx3 = new(gpif);
   
class Testcase; 
   rand logic[gModWidth-1:0] mod;
   rand logic[gAddrWidth-1:0] addr; 
   rand logic[gDataWidth-1:0] data;
   logic [gAddrWidth-1:0] burst_addr[];
   rand logic[gDataWidth-1:0] burst_data[];
   randc int burstSize;
   rand bit is_read; // read = 1, write = 0
   
   constraint inRange {
      burstSize > 0 && burstSize < max_burst_size && burstSize % 4 == 0;		 
      burst_data.size() == burstSize;
   }
endclass; // Testcase

   task singleRead(input logic [gModWidth-1:0] mod, 
		   input logic [gAddrWidth-1:0]  addr, 
		   output logic [gDataWidth-1:0] data);
     
      byte 					 word[4];
      byte 					 result[4];
      byte 					 packet[];
      int 					 bytesWritten;
      bit 					 isTimeout;
      begin

	 word[0] = {4'd0,mod};
	 word[1] = {addr};
	 word[2] = 0; word[3] = 0;
	 
	 fx3.writeControl(word,bytesWritten,10ms);
	 assert(bytesWritten == 4) 
	   else $warning("Timeout while writing to Control, Written: %d/4",bytesWritten);

	 
	 fx3.readControl(packetSize,packet,10ms,isTimeout);
	 assert(!isTimeout);
	 assert(packet.size() == 4);


	 
	 result = packet[0:3];
	 /*
	 assert(result[0:1] == word[0:1]) 
	   else $error("%t: SingleRead: Address mismatch after reading back (%H/%H)",
		       $time,{result[0],result[1]},{word[0],word[1]});
	  */
	 data = {result[2],result[3]};
      end
   endtask // singleRead

   task singleWrite(input logic [gModWidth-1:0] mod, 
		   input logic [gAddrWidth-1:0] addr,
		   input logic [gDataWidth-1:0] data);
      byte 					word[4];
      int 					bytesWritten;
      begin
	 word[0] = {4'd8,mod};
	 word[1] = addr;
	 word[2] = data[15:8]; word[3] = data[7:0];

	 fx3.writeControl(word,bytesWritten,10ms);
	 assert(bytesWritten == 4) 
	   else $warning("Timeout while writing to Control, Written: %d/4",bytesWritten);
      end
   endtask


   task automatic burstWrite(input logic[gModWidth-1:0] mod,
		   const ref logic [gAddrWidth-1:0] addr[], 
		   const ref logic [gDataWidth-1:0] data[]);

      byte buffer[] = new[4*addr.size()];
      int  bytesWritten = 0;

      for(int i = $low(data); i<= $high(data);i++) begin
	 buffer[4*i + 0] = {4'd8,mod};
	 buffer[4*i + 1] = addr[i];
	 buffer[4*i + 2] = data[i][15:8];
	 buffer[4*i + 3] = data[i][7:0];
      end
      
      fx3.writeControl(buffer,bytesWritten,10ms);
      assert(bytesWritten == buffer.size()) else
	$warning("Burst Write: Timeout while writing to Control, Written: %d/4",bytesWritten);
   endtask // burstWrite

   task automatic burstRead(input logic[gModWidth-1:0] mod, 
			    const ref logic [gAddrWidth-1:0] addr[], 
				  ref logic [gDataWidth-1:0] data[]);
      
      
      int  bytesWritten = 0, bytesRead = 0;
      byte buffer[] = new[4*addr.size()];
      byte packet[];
      int  readBufferSize = buffer.size();
      bit  isTimeout = 0;

      if(readBufferSize % packetSize > 0)
	readBufferSize += (packetSize - (readBufferSize % packetSize));

      for(int i = $low(data); i<= $high(data);i++) begin
	 buffer[4*i + 0] = {4'd0,mod};
	 buffer[4*i + 1] = addr[i];
	 buffer[4*i + 2] = '0;
	 buffer[4*i + 3] = '0;
      end

      fork 
	 begin : Write
	    fx3.writeControl(buffer,bytesWritten,10ms);
	    assert(bytesWritten == buffer.size()) else
	      $warning("Burst Read: Timeout while writing to Control, Written: %d/4",bytesWritten);
	 end
	 begin : Read
	    buffer = new[4*addr.size()];
	    while(bytesRead < bytesWritten && !isTimeout) begin
	       fx3.readControl(readBufferSize,packet,100ms,isTimeout);
	       for(int i = 0; i < packet.size; i++)
		 buffer[bytesRead + i] = packet[i];
	       bytesRead += packet.size();
	    end
	 end
      join


      assert(!isTimeout)
	else $error("%t: BurstRead: Timeout", $time);
      assert(buffer.size() == 4*addr.size())
	else $error("%t: BurstRead: BufferSize mismatch with expected size %d/%d",
		    $time,buffer.size(),4*addr.size());
      
      for(int i = $low(addr); i<= $high(addr);i++) 
	begin
	   const logic [16:0] addr_check = {4'd0,mod,addr[i]};
	   const logic [16:0] addr_readback =  {buffer[4*i + 0],buffer[4*i + 1]}; 
	   assert(addr_check ==  addr_readback) 
	     else $error("%t: BurstRead: Address mismatch after reading back (%d / %d)",$time,
			 addr_readback, addr_check);
	   data[i] =  {buffer[4*i + 2],buffer[4*i + 3]};
	end
   endtask // burstRead

   task automatic testData0(input int cntIn, output int cntOut);
      int cnt = cntIn;
      byte packet[];
      bit  isTimeout;
      for(int i = 0; i < nr_tests_Data; ++i) begin
	 fx3.readData0(packetSize,packet,10ms,isTimeout);
	 assert(!isTimeout)
	   else $error("Timeout when reading data0");
	 for(int j = 0; j < packet.size(); j+=4) begin
	    int data = {packet[j],packet[j+1],packet[j+2],packet[j+3]};
	    assert(data == cnt)
	      else $error("%t: Data0 mismatch : %d/%d",$time,data,cnt);
	    cnt++;
	 end
      end // for (int i = 0; i < nr_tests_Data; ++i)
      cntOut = cnt;
   endtask // testData0

   task automatic testData1(input int cntIn,output int cntOut);
      int cnt = cntIn;
      byte packet[];
      bit  isTimeout;
      for(int i = 0; i < nr_tests_Data; ++i) begin
	 fx3.readData1(packetSize,packet,10ms,isTimeout);
	 assert(!isTimeout)
	   else $error("Timeout when reading data1");
	 for(int j = 0; j < packet.size(); j+=4) begin
	    int data = {packet[j],packet[j+1],packet[j+2],packet[j+3]};
	    assert(data == cnt)
	      else $error("%t: Data1 mismatch : %d/%d",$time,data,cnt);
	    cnt++;
	 end
      end // for (int i = 0; i < nr_tests_Data; ++i)
      cntOut = cnt;
   endtask // testData1
   
   
   
   initial begin
      fx3.receive();
   end

   
   initial begin : stimuli
      Testcase tc;
      logic[gDataWidth-1:0] data_read;
      logic [gDataWidth-1:0] burst_read[];
      logic [gDataWidth-1:0] burst_write[];
      int 		     waitstates = 0;
      int 		     cntD0,cntD1;

      data0.wcb.write_en <= 0;
      data1.wcb.write_en <= 0;
      data0.wcb.data <= 'X;
      data1.wcb.data <= 'X;

      tc = new();
      // generate reset -----------------------------------------------------
      rst = 1;
      @(posedge clk);
      @(posedge clk);
      rst = 0;
      @(posedge clk);
      // start stimuli
      
      
      
      for(int i = 0; i < nr_tests_single; i++) begin
	 if(tc.randomize()) begin   

	    singleWrite(tc.mod,tc.addr,tc.data);
	    singleRead(tc.mod,tc.addr,data_read);

	    assert (data_read == tc.data) 
	      else $error("%t: Mismatch SingleRead(%H) / SingleWrite(%H)!",
			  $time, data_read, tc.data);

	 end // if (tc.randomize())
	 else begin
	    $display("could not generate Testcase Nr %D!", i);
         end // if (tc.randomize())	 
      end // for (int i = 0; i < nr_tests_single; i++)

      for(int i = 0; i < nr_tests_burst; i++) begin
	 if(tc.randomize()) begin
            
	    burst_read = new [tc.burstSize];

	    tc.burst_addr = new[tc.burstSize];
	    for(int i = 0; i < tc.burst_addr.size(); ++i)
	      tc.burst_addr[i] = i;

	    
	    burstWrite(tc.mod,tc.burst_addr,tc.burst_data);
	    burstRead(tc.mod, tc.burst_addr,burst_read);
	    
	    assert (burst_read == tc.burst_data) 
	      else begin 
		 $error("%t: Mismatch BurstRead / BurstWrite!",$time);
		 $display("Index;Address;Data_read;Data_wrote");
		 for(int i = 0; i < tc.burstSize; ++i)
		   if(burst_read[i] != tc.burst_data[i])
		     $display("%d,%x,%x,%x",i,tc.burst_addr[i],burst_read[i],tc.burst_data[i]);
	      end
	 end else begin
	    $display("could not generate Testcase Nr %D!", i);
         end // if (tc.randomize())	 
      end // for (int i = 0; i < nr_tests_burst; i++)

      // Test data ports
      fork
	 begin : Data0gen
	    int cnt = 0;
	    forever begin
	       @(data0.wcb);
	       if(!data0.wcb.almost_full) begin
		  data0.wcb.write_en <= 1;
		  data0.wcb.data <= cnt;
		  cnt++;
	       end else
		 data0.wcb.write_en <= 0;
	       repeat(waitstates) begin
		  @(data0.wcb);
		  data0.wcb.write_en <= 0;
	       end
	    end
	 end
	 begin : Data1gen
	    int cnt = 0;
	    forever begin
	       @(data1.wcb);
	       if(!data1.wcb.almost_full) begin
		  data1.wcb.write_en <= 1;
		  data1.wcb.data <= cnt;
		  cnt++;
	       end else
		 data1.wcb.write_en <= 0;
	       repeat(waitstates) begin
		  @(data1.wcb);
		  data1.wcb.write_en <= 0;
	       end
	    end
	 end
      join_none

      testData0(0,cntD0);
      testData1(0,cntD1);

      // Test fifo starvation
      waitstates = 20;
      testData0(cntD0,cntD0);
      testData1(cntD1,cntD1);
            
      $display("stimuli finished");
      $finish;
      
   end : stimuli
endprogram // Testbench

module DUT(input logic clk,
	   input logic rst, 
	               gpif_ii_if.master gpif,
	               DataFifo.in data0,
	               DataFifo.in data1);

   logic wb_clk;
   logic wb_rst;
   logic [11:0] wb_addr;
   logic [15:0] wb_dat_sm;
   logic [15:0] wb_dat_ms;
   logic wb_error;
   logic wb_ack;
   logic wb_we;
   logic wb_cyc;
   logic wb_stb;

   logic fx3_i2c_scl;
   logic fx3_i2c_sda_i,fx3_i2c_sda_o,fx3_i2c_sda_t;
   logic fx3_uart_rx,fx3_uart_tx;
   logic fx3_gpif_ii_dq_t;
   logic [12:0] fx3_gpif_ii_ctl_i;
   logic [12:0] fx3_gpif_ii_ctl_o;
   logic [12:0] fx3_gpif_ii_ctl_t;
   logic fx3_gpif_ii_int_n;
   logic fx3_gpif_ii_reset_n;

   assign fx3_gpif_ii_ctl_i[4] = gpif.FLAGA;
   assign fx3_gpif_ii_ctl_i[5] = gpif.FLAGB;
   assign fx3_gpif_ii_ctl_i[6] = gpif.FLAGC;
   assign fx3_gpif_ii_ctl_i[8] = gpif.FLAGD;

   assign gpif.address = {fx3_gpif_ii_ctl_o[11],fx3_gpif_ii_ctl_o[12]};
   assign gpif.PKTEND_n = fx3_gpif_ii_ctl_o[7];
   assign gpif.SLRD_n = fx3_gpif_ii_ctl_o[3];
   assign gpif.SLOE_n = fx3_gpif_ii_ctl_o[2];
   assign gpif.SLWR_n = fx3_gpif_ii_ctl_o[1];
   assign gpif.SLCS_n = fx3_gpif_ii_ctl_o[0];

   assign wb_clk = clk;
   assign wb_rst = rst;

   usb_top usb_top(
		   .WB_CLK(wb_clk),
		   .WB_RST(wb_rst),
		   .WB_ADDR_O(wb_addr),
		   .WB_DAT_I(wb_dat_sm),
		   .WB_DAT_O(wb_dat_ms),
		   .WB_ERR_I(wb_error),
		   .WB_ACK_I(wb_ack),
		   .WB_WE_O(wb_we),
		   .WB_CYC_O(wb_cyc),
		   .WB_STB_O(wb_stb),
		   .CLK(clk),
		   .RST(rst),
		   .FX3_I2C_SCL(fx3_i2c_scl),
		   .FX3_I2C_SDA_i(fx3_i2c_sda_i),
		   .FX3_I2C_SDA_o(fx3_i2c_sda_o),
		   .FX3_I2C_SDA_T(fx3_i2c_sda_t),
		   .FX3_UART_RX(fx3_uart_rx),
		   .FX3_UART_TX(fx3_uart_tx),
		   .FX3_GPIF_II_DQ_i(gpif.data_sm),
		   .FX3_GPIF_II_DQ_o(gpif.data_ms),
		   .FX3_GPIF_II_DQ_T(fx3_gpif_ii_dq_t),
		   .FX3_GPIF_II_CTL_i(fx3_gpif_ii_ctl_i),
		   .FX3_GPIF_II_CTL_o(fx3_gpif_ii_ctl_o),
		   .FX3_GPIF_II_CTL_T(fx3_gpif_ii_ctl_t),
		   .FX3_GPIF_II_PCLK(gpif.PCLK),
		   .FX3_GPIF_II_INT_n(fx3_gpif_ii_int_n),
		   .FX3_GPIF_II_RESET_n(fx3_gpif_ii_reset_n),
		   .CLK_DP2_WR_I(data0.clk),
		   .DPO2_DTI_I(data0.data),
		   .DPO2_FULL_O(data0.full),        
		   .DPO2_ALMST_FULL_O(data0.almost_full),  
		   .DPO2_WR_I(data0.write_en),          
		   .CLK_DP3_WR_I(data1.clk), 
		   .DPO3_DTI_I(data1.data),      
		   .DPO3_FULL_O(data1.full),        
		   .DPO3_ALMST_FULL_O(data1.almost_full),  
		   .DPO3_WR_I(data1.write_en)           
		   );

   wishbone_ram#(.gDataWidth(16),
		 .gAddrWidth(12)
		 ) ram(
		       .clk_i(wb_clk),
		       .rst_i(wb_rst),
		       .adr_i(wb_addr),
		       .dat_i(wb_dat_ms),
		       .dat_o(wb_dat_sm),
		       .cyc_i(wb_cyc),
		       .stb_i(wb_stb),
		       .we_i(wb_we),
		       .ack_o(wb_ack));

endmodule // DUT

   
module top;
   
   logic clk = 0;
   logic clk1 = 0;
   logic rst;

   gpif_ii_if gpif();

   DataFifo data0(clk), data1(clk_dp3);


   Testbench testbench(clk,rst, gpif,data0,data1);
   DUT DUT(clk,rst,gpif,data0,data1);
   

   always #5 clk = !clk;
   always #12.5 clk_dp3 = !clk_dp3;
         
endmodule // top
