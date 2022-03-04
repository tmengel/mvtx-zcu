//-----------------------------------------------------------------------------
// Title      : Usb Communication module interface
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : usb_comm.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2016-04-19
// Last update: 2016-04-19
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Interface with python scripts via DPI
//-----------------------------------------------------------------------------
// Copyright (c)   2016
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-04-19  1.0      mbonora        Created
//-----------------------------------------------------------------------------

class UsbComm;

   const string flush_cmd_python = "\"import xmlrpc.client;import sys;sys.tracebacklimit=0;xmlrpc.client.ServerProxy(\\\"http://localhost:32223/\\\").flush_dp0()\"";
   const string clear_cmd_python = "\"import xmlrpc.client;import sys;sys.tracebacklimit=0;xmlrpc.client.ServerProxy(\\\"http://localhost:32223/\\\").clear()\"";

   usb_fx3 m_fx3;
   integer m_dp[4];
   bit     verbose;
   bit     m_controlOnly;
   function new(ref usb_fx3 fx3, input bit verbose=0, input bit controlOnly=0);
      int  retval;
      this.m_fx3 = fx3;
      this.m_dp[0] = $fopen("fifo_dp0.fifo","r");
      assert(this.m_dp[0] != 0) else $fatal(1, "fifo_dp0.fifo open failed");
      this.m_dp[1] = $fopen("fifo_dp1.fifo","w");
      assert(this.m_dp[1] != 0) else $fatal(1, "fifo_dp1.fifo open failed");
      this.m_dp[2] = $fopen("fifo_dp2.fifo","w");
      assert(this.m_dp[2] != 0) else $fatal(1, "fifo_dp2.fifo open failed");
      this.m_dp[3] = $fopen("fifo_dp3.fifo","w");
      assert(this.m_dp[3] != 0) else $fatal(1, "fifo_dp3.fifo open failed");
      this.verbose = verbose;
      this.m_controlOnly = controlOnly;
      // set read fifo to end
      void'($fseek(this.m_dp[0],0,2));

      retval = $system({"python3 -c ",clear_cmd_python});
      assert(retval == 0) else $fatal(1, "Python call failed with return value %d",retval);
   endfunction // new

   function bit readFromFifo(input int DP, output byte packet[]);
      string line;
      int    i;
      bit    eof;
      eof = $fgets(line,m_dp[DP]) == 0;
      if(line != "NOP\n" && line.len() > 0) begin
         if(line == "EXIT\n") $finish;
         packet = new[line.len() / 2];
         for (i = 0; i < packet.size(); i++) begin
            string sub = line.substr(2*i,2*i+1);
            packet[i] = sub.atohex();
         end
      end
      readFromFifo = eof;
   endfunction // readWord

   function void writeToFifo(input int DP, input byte packet[]);
      int i;
      for(i = 0; i < packet.size(); i+=4) begin
         $fwrite(m_dp[DP],"%02H",packet[i+3]);
         $fwrite(m_dp[DP],"%02H",packet[i+2]);
         $fwrite(m_dp[DP],"%02H",packet[i+1]);
         $fwrite(m_dp[DP],"%02H",packet[i]);
      end
      $fwrite(m_dp[DP],"\n");
      $fflush(m_dp[DP]);
   endfunction // writeWord

   task write();
      forever begin
         int i = 0;
         byte data[];
         byte b0,b1,b2,b3;
         int  written = 0;
         bit  eof;
         int  retval = 0;
         retval = $system({"python3 -c ",flush_cmd_python});
         assert(retval == 0) else $fatal(1, "Python call failed with return value %d",retval);
         do begin
            eof = readFromFifo(0,data);
            if(data.size() > 0) begin
               if(verbose) begin
                  $write("write %d bytes to FX3 control: {",data.size());
                  foreach(data[i])
                    $write("%02h, ",data[i]);
                  $write("}\n");
               end
               for(i = 0; i < data.size(); i=i+4) begin
                  b0 = data[i];
                  b1 = data[i+1];
                  b2 = data[i+2];
                  b3 = data[i+3];
                  data[i] = b3;
                  data[i+1] = b2;
                  data[i+2] = b1;
                  data[i+3] = b0;
               end
               this.m_fx3.writeControl(data,written);
            end
         end while(!eof);
         #100ns;
      end
   endtask // read

   task read(input int DP);
      forever begin
         byte buffer[] = new[1024];
         bit  isTimeout;
         if(DP == 1)
           this.m_fx3.readControl(1024,buffer,isTimeout);
         else if(DP==2)
           this.m_fx3.readData0(1024,buffer,isTimeout);
         else if(DP==3)
           this.m_fx3.readData1(1024,buffer,isTimeout);
         else
           $error("wrong DP");

         if(buffer.size() > 0) begin
            if(verbose) begin
               $write("Received %d bytes from FX3 port %d: {",buffer.size(),DP);
               foreach(buffer[i])
                 $write("%02h, ",buffer[i]);
               $write("}\n");
               $display();
            end
            writeToFifo(DP,buffer);
         end

         #1000ns;
      end
   endtask // write

   task start_comm();
      fork
         write();
         read(1);
         if(!m_controlOnly)
            read(2);
         if(!m_controlOnly)
           read(3);
      join
   endtask // start_comm
endclass // UsbComm
