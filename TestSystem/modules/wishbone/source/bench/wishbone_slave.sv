//-----------------------------------------------------------------------------
// Title      : Wishbone Ram module
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : wishbone_slave.sv
// Author     : Rainer Findenig (rainer.findenig@fh-hagenberg.at)
// Company    : Upper Austria University of Applied Sciences
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: 
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-18  1.0      mbonora        Created
//-----------------------------------------------------------------------------

module wishbone_ram # (
		parameter int gDataWidth = 32,
		parameter int gAddrWidth = 8
	)(
	 	input logic clk_i, rst_i,
		input logic [gAddrWidth-1:0] adr_i,
		input logic [gDataWidth-1:0] dat_i,
		input logic cyc_i, stb_i, we_i,
		output logic [gDataWidth-1:0] dat_o,
		output logic ack_o
	);

	logic [gDataWidth-1:0] mem[0:(1<<gAddrWidth)-1];
	int nextWs;

	class WaitStates;
		rand int val[1000];
		local int i = 0;

 		constraint v {
  			foreach(val[i]) {
 				val[i] >= 1;
 				val[i] < 10;
  			}
 		}

		function int nextVal();
			int ret = val[i];
			i = (i+1) % 1000;
			return ret;
		endfunction
	endclass

	WaitStates ws;

	initial begin
		ws = new;
		void'(ws.randomize());
	end
	
	always @(posedge clk_i)
	  begin
	     if (rst_i) begin
		ack_o = 0;
		dat_o = '0;
		mem = '{(1<<gAddrWidth){'0}};
	     end else begin
		ack_o <= 0;
		dat_o <= 'x;
		
		if (cyc_i == 1 && stb_i == 1) begin
		   nextWs = ws.nextVal();
 		   repeat (nextWs-1) @ (posedge clk_i);
		   ack_o <= 1;
		   if (!we_i) begin
		      dat_o <= mem[adr_i];
		      @(posedge clk_i);
		      dat_o <= 'x;
		   end else begin
		      @(posedge clk_i);
		      mem[adr_i] <= dat_i;
		   end
		   ack_o <= 0;
		end
	     end
	  end
	
endmodule
