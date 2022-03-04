//-----------------------------------------------------------------------------
// Title      : CAN Bus Communication module interface
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : can_comm.sv
// Author     : Simon Voigt Nesbø  <svn@hvl.no>
// Company    : Western Norway University of Applied Sciences
// Created    : 2018-09-27
// Last update: 2018-09-27
// Platform   : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Interface with python scripts via DPI
//-----------------------------------------------------------------------------
// Copyright (c)   2018
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2018-09-27  1.0      simon	      Created
//-----------------------------------------------------------------------------

class CanComm;

   // Defines for CAN HLP protocol
   const byte      C_HLP_DATA            = 1; // not used/implemented at the moment
   const byte      C_HLP_WRITE_CMD       = 2; // Write command/request
   const byte      C_HLP_WRITE_RESP      = 3; // Write response
   const byte      C_HLP_READ_CMD        = 4; // Read command/request
   const byte      C_HLP_READ_RESP       = 5; // Read response
   const byte      C_HLP_STATUS_ALERT    = 7; // not used/implemented at the moment

   const byte      C_CAN_HLP_OK                    =  0;
   const byte      C_CAN_HLP_ARB_LOST              =  1;
   const byte      C_CAN_HLP_ACK_MISSING           =  2;
   const byte      C_CAN_HLP_TIMEOUT               =  3;
   const byte      C_CAN_HLP_CRC_ERROR             =  4;
   const byte      C_CAN_HLP_EXT_ID_ERROR          =  5;
   const byte      C_CAN_HLP_REMOTE_FRAME_ERROR    =  6;
   const byte      C_CAN_HLP_DATA_LEN_ERROR        =  7;
   const byte      C_CAN_HLP_WRONG_RESPONSE_ERROR  =  8;
   const byte      C_CAN_HLP_WRONG_NODE_ID_ERROR   =  9;
   const byte      C_CAN_HLP_DATA_MISMATCH_ERROR   = 10;
   const byte      C_CAN_HLP_ADDR_MISMATCH_ERROR   = 11;

   const byte      C_CAN_HLP_BROADCAST_NODE_ID     = 255;


   parameter realtime pollrate = 1us;

   const string flush_cmd_python = "\"import xmlrpc.client;import sys;sys.tracebacklimit=0;xmlrpc.client.ServerProxy(\\\"http://localhost:32223/\\\").flush_can()\"";
   const string clear_cmd_python = "\"import xmlrpc.client;import sys;sys.tracebacklimit=0;xmlrpc.client.ServerProxy(\\\"http://localhost:32223/\\\").clear_can()\"";

   can_bfm m_can_bfm;

   logic        m_arb_lost;
   logic        m_ack_received;
   logic        m_timeout;
   logic        m_crc_error;

   byte         m_node_id;

   // CAN controller needs a couple of microseconds after reset to be able
   // to generate sample point and sync on to incoming CAN messages.
   // Since there is no way for this class to know when reset was issued,
   // the necessary delay is added before the first package is sent,
   // which is indicated by this variable
   bit          m_first_byte = 1'b0;

   integer      m_topython,m_frompython;

   function new(ref can_bfm can, input byte node_id);
      int       retval;
      this.m_can_bfm = can;
      this.m_node_id = node_id;
      this.m_topython = $fopen("can_fifo_tp.fifo","w");
      assert(this.m_topython != 0) else $fatal(1, "can_fifo_tp.fifo open failed");
      this.m_frompython = $fopen("can_fifo_fp.fifo","r");
      assert(this.m_frompython != 0) else $fatal(1, "can_fifo_fp.fifo open failed");

      // set read fifo to end
      void'($fseek(this.m_frompython,0,2));

      // Send clear command to python if
      retval = $system({"python3 -c ",clear_cmd_python});
      assert(retval == 0) else $fatal(1, "Python call failed with return value %d",retval);
   endfunction // new

   // Each line in the fifo file contains one CAN HLP transactions
   // The lines are written in ascii hex format, each line contains 4 bytes, e.g.:
   // <Write bit (MSb) + 15-bit address> <16-bit data (only used for write)>
   // E.g. the line "8002AABB" yields:
   // Write command (MSB in address set)
   // Address (15 bit) = 0x0002
   // Data (16 bit) = 0xAABB
   //
   // TODO: Change fifo file format and add node ID:
   // <Node ID - 8 bits> <Write bit (MSb) + 15-bit address> <16-bit data (for write command only)>
   function bit readFromFifo(output byte packet[]);
      string    line;
      int       i;
      bit       eof;

      eof = $fgets(line,m_frompython) == 0;

      if(line != "NOP\n" && line.len() > 0) begin
         if(line == "EXIT\n") $finish;

         // $fgets() probably includes newline character or something,
         // because line.len() is always one character longer than expected
         assert (line.len()-1 == 8)
           else $fatal(1, "can_fifo_fp contained line with length %d, expected length is 6 or 10", line.len()-1);

         $display("CanComm: Got transaction request from fifo file.");

         packet = new[(line.len()-1) / 2];

         for (i = 0; i < packet.size(); i++) begin
            string sub = line.substr(2*i,2*i+1);
            packet[i] = sub.atohex();
         end
      end
      readFromFifo = eof;
   endfunction // readFromFifo

   function void writeToFifo(input byte packet[], input byte can_hlp_status);
      if(can_hlp_status == C_CAN_HLP_OK) begin
         int          i;
         for(i = 0; i < packet.size(); i++) begin
            $fwrite(m_topython,"%02H",packet[i]);
         end
      end else begin
         case(can_hlp_status)
           C_CAN_HLP_ARB_LOST : $fwrite(m_topython, "ARB_LOST");
           C_CAN_HLP_ACK_MISSING : $fwrite(m_topython, "ACK_MISSING");
           C_CAN_HLP_TIMEOUT : $fwrite(m_topython, "TIMEOUT");
           C_CAN_HLP_CRC_ERROR : $fwrite(m_topython, "CRC_ERROR");
           C_CAN_HLP_EXT_ID_ERROR : $fwrite(m_topython, "EXT_ID_ERROR");
           C_CAN_HLP_REMOTE_FRAME_ERROR : $fwrite(m_topython, "REMOTE_FRAME_ERROR");
           C_CAN_HLP_DATA_LEN_ERROR : $fwrite(m_topython, "DATA_LEN_ERROR");
           C_CAN_HLP_WRONG_RESPONSE_ERROR : $fwrite(m_topython, "WRONG_RESPONSE_ERROR");
           C_CAN_HLP_WRONG_NODE_ID_ERROR : $fwrite(m_topython, "WRONG_NODE_ID_ERROR");
           C_CAN_HLP_DATA_MISMATCH_ERROR : $fwrite(m_topython, "DATA_MISMATCH_ERROR");
           C_CAN_HLP_ADDR_MISMATCH_ERROR : $fwrite(m_topython, "ADDR_MISMATCH_ERROR");
         endcase
      end // else: !if(can_hlp_status == C_CAN_HLP_OK)

      $fwrite(m_topython,"\n");
      $fflush(m_topython);
   endfunction // writeToFifo


   task can_hlp_write(byte node_id, byte address[2], byte data[2], output byte status_out);
      can_package_t can_pkg_out;
      can_package_t can_pkg_in;

      can_pkg_out.arb_id[10:3] = node_id;
      can_pkg_out.arb_id[2:0] = C_HLP_WRITE_CMD;
      can_pkg_out.extended_id = 0;
      can_pkg_out.remote_frame = 0;
      can_pkg_out.data_length = 4;
      can_pkg_out.data[0] = address[0]; // MSB
      can_pkg_out.data[1] = address[1]; // LSB
      can_pkg_out.data[2] = data[0];
      can_pkg_out.data[3] = data[1];

      // Send CAN HLP write command/request
      fork
         m_can_bfm.can_write(can_pkg_out, m_arb_lost, m_ack_received);
      join

      // Check for errors
      if(m_arb_lost) begin
         status_out = C_CAN_HLP_ARB_LOST;
         return;
      end else if(!m_ack_received) begin
         status_out = C_CAN_HLP_ACK_MISSING;
         return;
      end

      // Read CAN HLP write reponse
      fork
         m_can_bfm.can_read(can_pkg_in, m_timeout, m_crc_error);
      join

      // Check for errors
      if(m_timeout) begin
         status_out = C_CAN_HLP_TIMEOUT;
         return;
      end else if(m_crc_error) begin
         status_out = C_CAN_HLP_TIMEOUT;
         return;
      end else if(can_pkg_in.extended_id) begin
         status_out = C_CAN_HLP_EXT_ID_ERROR;
         return;
      end else if(can_pkg_in.remote_frame) begin
         status_out = C_CAN_HLP_REMOTE_FRAME_ERROR;
         return;
      end else if(can_pkg_in.data_length != 4) begin
         status_out = C_CAN_HLP_DATA_LEN_ERROR;
         return;
      end else if(can_pkg_in.arb_id[2:0] != C_HLP_WRITE_RESP) begin
         status_out = C_CAN_HLP_WRONG_RESPONSE_ERROR;
         return;
      end else if(can_pkg_in.arb_id[10:3] != node_id && node_id != C_CAN_HLP_BROADCAST_NODE_ID) begin
         // When the message was broadcasted we can accept any node id
         status_out = C_CAN_HLP_WRONG_NODE_ID_ERROR;
         return;
      end else if(can_pkg_in.data[0] != can_pkg_out.data[0] ||
                  can_pkg_in.data[1] != can_pkg_in.data[1]) begin
         status_out = C_CAN_HLP_ADDR_MISMATCH_ERROR;
         return;
      end else if(can_pkg_in.data[2] != can_pkg_out.data[2] ||
                    can_pkg_in.data[3] != can_pkg_in.data[3]) begin
         status_out = C_CAN_HLP_DATA_MISMATCH_ERROR;
         return;
      end
      status_out = C_CAN_HLP_OK;
   endtask // can_hlp_write

   task can_hlp_read(byte node_id, byte address[2], output byte data_out[2], output byte status_out);
      can_package_t can_pkg_out;
      can_package_t can_pkg_in;

      can_pkg_out.arb_id[10:3] = node_id;
      can_pkg_out.arb_id[2:0] = C_HLP_READ_CMD;
      can_pkg_out.extended_id = 0;
      can_pkg_out.remote_frame = 0;
      can_pkg_out.data_length = 2;
      can_pkg_out.data[0] = address[0]; // MSB
      can_pkg_out.data[1] = address[1]; // LSB

      // Send CAN HLP read command/request
      fork
         m_can_bfm.can_write(can_pkg_out, m_arb_lost, m_ack_received);
      join

      // Check for errors
      if(m_arb_lost) begin
         status_out = C_CAN_HLP_ARB_LOST;
         return;
      end else if(!m_ack_received) begin
         status_out = C_CAN_HLP_ACK_MISSING;
         return;
      end

      // Read CAN HLP read reponse
      fork
         m_can_bfm.can_read(can_pkg_in, m_timeout, m_crc_error);
      join

      // Check for errors
      if(m_timeout) begin
         status_out = C_CAN_HLP_TIMEOUT;
         return;
      end else if(m_crc_error) begin
         status_out = C_CAN_HLP_TIMEOUT;
         return;
      end else if(can_pkg_in.extended_id) begin
         status_out = C_CAN_HLP_EXT_ID_ERROR;
         return;
      end else if(can_pkg_in.remote_frame) begin
         status_out = C_CAN_HLP_REMOTE_FRAME_ERROR;
         return;
      end else if(can_pkg_in.data_length != 4) begin
         status_out = C_CAN_HLP_DATA_LEN_ERROR;
         return;
      end else if(can_pkg_in.arb_id[2:0] != C_HLP_READ_RESP) begin
         status_out = C_CAN_HLP_WRONG_RESPONSE_ERROR;
         return;
      end else if(can_pkg_in.arb_id[10:3] != node_id && node_id != C_CAN_HLP_BROADCAST_NODE_ID) begin
         // When the message was broadcasted we can accept any node id
         status_out = C_CAN_HLP_WRONG_NODE_ID_ERROR;
         return;
      end else if(can_pkg_in.data[0] != can_pkg_out.data[0] ||
                  can_pkg_in.data[1] != can_pkg_in.data[1]) begin
         status_out = C_CAN_HLP_ADDR_MISMATCH_ERROR;
         return;
      end

      data_out[0] = can_pkg_in.data[2];
      data_out[1] = can_pkg_in.data[3];

      // The node should return the same address and data in the
      // write response as what was sent on the write command.
      // It would make sense to check that here, but it is done in
      // the python test bench instead
      status_out = C_CAN_HLP_OK;
   endtask // can_hlp_write

   task can_hlp();
      int  retval;

      forever begin
         byte packet[];
         byte packet_out[4];

         retval = $system({"python3 -c ",flush_cmd_python});
         assert(retval == 0) else $fatal(1, "Python call failed with return value %d",retval);

         readFromFifo(packet);

         if(packet.size() > 0) begin
            byte address[2] = {packet[3], packet[2]};
            bit  write_not_read = packet[3] >> 7; // MSb of address is R/W
            byte data[2];
            byte can_hlp_status;

            // Ideally the node id should have been part of the message in the FIFO files,
            // but this was not straight forward to implement in the Communication framework,
            byte node_id = m_node_id;

            if(write_not_read) begin
               address[0] = address[0] & 8'h7F; // Remove write bit, can_hlp_write() does not expect it
               data = {packet[1], packet[0]};

               // Add delay before transmitting first package, in case CAN controller
               // was just reset and needs some time before it can sync on a CAN package
               if(!m_first_byte) begin
                  #10us m_first_byte = 1'b1;
               end

               can_hlp_write(node_id, address, data, can_hlp_status);
            end else begin
               can_hlp_read(node_id, address, data, can_hlp_status);
            end

            packet_out[0] = data[1];
            packet_out[1] = data[0];
            packet_out[2] = address[1];
            packet_out[3] = address[0];

            writeToFifo(packet_out, can_hlp_status);
         end
         #pollrate;
      end
   endtask // can_hlp

   task start_comm();
      fork
         can_hlp();
      join
   endtask // start_comm
endclass // CanComm
