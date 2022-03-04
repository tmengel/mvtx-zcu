//-----------------------------------------------------------------------------
// Title      : GBT Communication module interface
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : gbt_comm.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2017-07-27
// Last update: 2017-07-27
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Interface between gbt_elink and python via files
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-07-27  1.0      mbonora        Created
//-----------------------------------------------------------------------------

class GbtComm;

   parameter realtime pollrate = 1us;

   const string flush_cmd_python = "\"import xmlrpc.client;import sys;sys.tracebacklimit=0;xmlrpc.client.ServerProxy(\\\"http://localhost:32223/\\\").flush_gbtx()\"";
   const string clear_cmd_python = "\"import xmlrpc.client;import sys;sys.tracebacklimit=0;xmlrpc.client.ServerProxy(\\\"http://localhost:32223/\\\").clear_gbtx()\"";

   gbtx_bfm m_gbtx;

   integer      m_topython,m_frompython;

   function new(ref gbtx_bfm gbtx);
      int       retval;
      this.m_gbtx = gbtx;
      this.m_topython = $fopen("fifo_gbtx0_tp","w");
      assert(this.m_topython != 0) else $fatal(1, "fifo_gbtx0_tp open failed");
      this.m_frompython = $fopen("fifo_gbtx0_fp","r");
      assert(this.m_frompython != 0) else $fatal(1, "fifo_gbtx0_fp open failed");

      // set read fifo to end
      void'($fseek(this.m_frompython,0,2));

      // Send clear command to python if
      retval = $system({"python3 -c ",clear_cmd_python});
      assert(retval == 0) else $fatal(1, "Python call failed with return value %d",retval);
   endfunction // new

   function void readFromPython();
      string    line;
      string    dv;
      string    b;
      int       i;
      bit       eof;
      bit     data_valid;
      logic [79:0] word;

      while($fgets(line,m_frompython)) begin
         if(line != "NOP\n" && line.len() > 0) begin
            if(line == "EXIT\n") $finish;
            dv =line.substr(0,0);
            data_valid = dv.atobin();
            for(i=0;i<10;++i) begin
               b = line.substr(2+2*i,2+2*i+1);
               word[(9-i)*8 +: 8] = b.atohex();
            end
            void'(m_gbtx.write_word({data_valid,word}));
         end
      end
   endfunction // readFromPython

   function void writeToPython();
      logic [80:0] word;
      int          transactions = 0;
      while(m_gbtx.read_word(word)) begin
         $fwrite(m_topython,"%d %020H\n",word[80], word[79:0]);
         ++transactions;
      end
      if(transactions > 0)
        $fflush(m_topython);
   endfunction // writeToPython

   task read();
      int  retval = 0;
      forever begin
         retval = $system({"python3 -c ",flush_cmd_python});
         assert(retval == 0) else $fatal(1, "Python call failed with return value %d",retval);
         readFromPython();
         #pollrate;
      end
   endtask // read

   task write();
      forever begin
         writeToPython();
         #pollrate;
      end
   endtask // write

   task start_comm();
      fork
         read();
         write();
      join
   endtask // start_comm
endclass // GbtComm
