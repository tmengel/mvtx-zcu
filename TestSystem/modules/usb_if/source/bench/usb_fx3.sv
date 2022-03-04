//-----------------------------------------------------------------------------
// Title      : Cypress FX-3 GPIFii Slave BFM
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : usb_fx3.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-16
// Last update: 2015-11-16
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Slave interface for the GPIFii bus
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-16  1.0      mbonora        Created
//-----------------------------------------------------------------------------

class usb_fx3;

   virtual gpif_ii_if.slave m_if;

   fx3_buffer m_buffer_controlIn;
   fx3_buffer m_buffer_controlOut;
   fx3_buffer m_buffer_Data0Out;
   fx3_buffer m_buffer_Data1Out;

   int BUF_CONTROL_OUT = 0;
   int BUF_DATA0_OUT = 1;
   int BUF_DATA1_OUT = 2;

   int     packetSize;
   realtime    timeout_read;
   realtime    timeout_write;

   bit     flagA_active;
   bit     flagA_inactive;
   bit     verbose;


   function new(virtual gpif_ii_if.slave itf, int packetSize = 1024, bit emptyFlagActiveHigh = 1,
                realtime timeout_read = 10ms, realtime timeout_write = 10ms, bit verbose=0);

      this.m_if = itf;
      this.packetSize = packetSize;
      this.flagA_active = emptyFlagActiveHigh;
      this.flagA_inactive = ~flagA_active;
      this.timeout_read = timeout_read;
      this.timeout_write = timeout_write;
      this.verbose = verbose;

      m_buffer_controlIn = new(packetSize,2,6,0,0);
      m_buffer_controlOut = new(packetSize,2,4,6,0);
      m_buffer_Data0Out = new(packetSize,2,4,6,0);
      m_buffer_Data1Out = new(packetSize,2,4,6,0);
   endfunction // new

   task writeControl(input byte data[], output int written);
      int dataWritten = 0;
      fork
         begin : Timeout_write
            if(timeout_write == 0)
              forever #1s;
            else
              #timeout_write;
         end
         begin : Slicing
            int sliceSize = packetSize;
            bit writeOk = 0;
            while(dataWritten < data.size()) begin
               byte slice[];
               if( (data.size() - dataWritten) > packetSize )
                 sliceSize = packetSize;
               else
                 sliceSize = data.size() - dataWritten;

               slice = new[sliceSize];
               for(int i = 0; i < sliceSize; ++i)
                 slice[i] = data[dataWritten + i];
               if(m_buffer_controlIn.isFull())
                 @(m_buffer_controlIn.producer_writable);
               m_buffer_controlIn.writeBurst(slice,writeOk);
               assert(writeOk);
               dataWritten += sliceSize;
            end // while (dataWritten < data.size())
         end
      join_any
      written = dataWritten;
   endtask // writeControl

   local function is_buffer_empty(input int buffer_idx);
      case(buffer_idx)
        0 : is_buffer_empty = m_buffer_controlOut.isEmpty();
        1 : is_buffer_empty = m_buffer_Data0Out.isEmpty();
        2 : is_buffer_empty = m_buffer_Data1Out.isEmpty();
      endcase // case (buffer_idx)
   endfunction // is_buffer_empty


   local task read(input int size,
                   output byte data[],
                   input int   buffer_idx,
                   output bit  isTimedOut);

      int               readoutCount = size / packetSize;
      byte              packet[];
      byte              dataRead[$];
      bit               timedOut = 0;
      bit               valid = 1;

      assert(size % packetSize == 0);

      for(int i = 0; i < readoutCount; ++i) begin
         if(is_buffer_empty(buffer_idx))
           fork
              case(buffer_idx)
                0 : @(m_buffer_controlOut.consumer_readable);
                1 : @(m_buffer_Data0Out.consumer_readable);
                2 : @(m_buffer_Data1Out.consumer_readable);
              endcase // case (buffer_idx)
              begin
                 #timeout_read;
                 timedOut = 1;
              end
           join_any
         // readout, only if not yet timed out
         isTimedOut = timedOut;
         if(timedOut)
           break;
         case(buffer_idx)
           0 : m_buffer_controlOut.readBurst(packet,valid);
           1 : m_buffer_Data0Out.readBurst(packet,valid);
           2 : m_buffer_Data1Out.readBurst(packet,valid);
         endcase // case (buffer_idx)

         assert(valid == 1);
         foreach(packet[j])
           dataRead.push_back(packet[j]);

         // Short packets finalize the transfer
         if(packet.size() % packetSize > 0)
           break;
      end
      data = dataRead;
   endtask // read

   task readControl(input int size, output byte data[], output bit isTimedOut);
      read(size,data,BUF_CONTROL_OUT,isTimedOut);
   endtask // readControl

   task readData0(input int size, output byte data[], output bit isTimedOut);
      read(size,data,BUF_DATA0_OUT,isTimedOut);
   endtask // readControl

   task readData1(input int size, output byte data[], output bit isTimedOut);
      read(size,data,BUF_DATA1_OUT,isTimedOut);
   endtask // readControl


   local task setOutputDriver();
      begin
         forever @(m_if.SLOE_n) begin
            if(m_if.SLOE_n == 0)
              #0ns m_if.data_t = 0;
            else if(m_if.SLOE_n == 1)
              #8ns m_if.data_t = 1;
         end
      end
   endtask // setOutputDriver

   local task handleRead();
      begin
         bit flag =0, flagHandled = 0;
         logic [31:0] data = 'X;
         while(m_if.cb.SLRD_n == 0) begin
            assert(m_if.SLOE_n == 0) else
              $error("Attemted read without SLOE");
            assert(m_if.cb.SLCS_n == 0) else
              $error("Chip select high on active read");

            m_buffer_controlIn.readWord(data,flag);

            @(m_if.cb);
            m_if.cb.data_sm <= data;

            if (flag && !flagHandled) fork begin
               flagHandled = 1;
               @(m_if.cb);
               m_if.cb.FLAGA <= flagA_active;
               @(m_buffer_controlIn.consumer_readable);
               m_if.cb.FLAGA <= flagA_inactive;
            end join_none
         end // while (m_if.cb.SLRD_n == 0)
      end
   endtask // handleRead

   local task setWriteFlag();
      fork begin
         case(m_if.cb.address)
           1: begin
              repeat(3) @(m_if.cb);
              m_if.cb.FLAGB <= 0;
              @(m_buffer_controlOut.producer_writable);
              m_if.cb.FLAGB <= 1;
           end
           2: begin
              repeat(3) @(m_if.cb);
              m_if.cb.FLAGC <= 0;
              @(m_buffer_Data0Out.producer_writable);
              m_if.cb.FLAGC <= 1;
           end
           3: begin
              repeat(3) @(m_if.cb);
              m_if.cb.FLAGD <= 0;
              @(m_buffer_Data1Out.producer_writable);
              m_if.cb.FLAGD <= 1;
           end
         endcase // case (m_if.cb.address)
      end
      join_none
   endtask // setWriteFlag



   local task handleWrite();
      begin
         // set data
         while (m_if.cb.SLWR_n == 0) begin
            bit flagSet = 0, flagHandled = 0;
            bit commitBuffer = m_if.cb.PKTEND_n == 0;

            case(m_if.cb.address)
              0: $error("Tried to read from write address %0t", $time);
              1: m_buffer_controlOut.writeWord(m_if.cb.data_ms,commitBuffer,flagSet);
              2: m_buffer_Data0Out.writeWord(m_if.cb.data_ms,commitBuffer,flagSet);
              3: m_buffer_Data1Out.writeWord(m_if.cb.data_ms,commitBuffer,flagSet);
            endcase; // case (m_if.cb.address)

            if(flagSet && !flagHandled) begin
               flagHandled = 1;
               setWriteFlag();
            end

            @(m_if.cb);
         end; // while @(m_if.cb.SLWR_n == 0)
      end
   endtask // handleWrite

   local task handlePacketEnd();
      case(m_if.cb.address)
        0: $error("Can't commit buffer of read address %0t", $time);
        1: m_buffer_controlOut.commitBuffer();
        2: m_buffer_Data0Out.commitBuffer();
        3: m_buffer_Data1Out.commitBuffer();
      endcase // case (m_if.cb.address)
      setWriteFlag();
   endtask // handlePacketEnd



   local task handleBusAccess();
      begin
        forever @(m_if.cb iff (m_if.cb.SLCS_n == 0 && (m_if.cb.SLWR_n == 0 ||
                                                       m_if.cb.SLRD_n == 0 ||
                                                       m_if.cb.PKTEND_n == 0)))
          begin

             if(m_if.cb.SLRD_n == 0) begin
                assert(m_if.cb.SLWR_n == 1 && m_if.cb.PKTEND_n == 1);
                assert(m_if.cb.address == 2'd0);
                handleRead();
             end
             else if(m_if.cb.SLWR_n == 0) begin
                assert(m_if.cb.SLRD_n == 1);
                handleWrite();
             end
             else if(m_if.cb.PKTEND_n == 0) begin
                assert(m_if.cb.SLRD_n == 1);
                handlePacketEnd();
             end
             else
               $error("Illegal state"); // should not be triggered

        end // forever @(m_if.cb.SLCS_n == 0)
      end
   endtask // handleBusAccess

   task setInitialFlags();
      m_if.cb.FLAGA <= flagA_active;
      m_if.cb.FLAGB <= 1;
      m_if.cb.FLAGC <= 1;
      m_if.cb.FLAGD <= 1;

      @(m_buffer_controlIn.consumer_readable);
      m_if.cb.FLAGA <= flagA_inactive;
   endtask // setInitialFlags


   task receive();
     fork
        setOutputDriver();
        handleBusAccess();
        setInitialFlags();
     join_none
   endtask // receive
endclass // usb_fx3
