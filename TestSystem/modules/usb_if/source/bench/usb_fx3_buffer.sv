//-----------------------------------------------------------------------------
// Title      : Fx3 Buffer implementation
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : usb_fx3_buffer.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-30
// Last update: 2015-11-30
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Buffer behaviour of Fx3 chip (including channel switching
//              timeouts)
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-30  1.0      mbonora        Created
//-----------------------------------------------------------------------------

class fx3_buffer;

   const int               bufferSize;
   const int               bufferCount;
   const int               flagBeforeFull;
   const int               flagBeforeEmpty;

   // time to switch between buffer channels
   const time              bufferSwitchTime = 1us;

   typedef byte            buffer_t[$];

   local buffer_t producerBuffer;

   local buffer_t           buffers[$];

   local bit               bufferSwitch;
   event                   consumer_readable;
   event                   producer_writable;
   bit                     verbose;


   function new(int bufferSize = 1024, int bufferCount = 2,
                int flagBeforeFull = 4, int flagBeforeEmpty = 4, bit verbose = 0);

      this.bufferSize = bufferSize;
      this.bufferCount = bufferCount;
      this.flagBeforeFull = flagBeforeFull;
      this.flagBeforeEmpty = flagBeforeEmpty;
      this.verbose = verbose;

      bufferSwitch = 0;
      assert(bufferSize % 4 == 0) else $error("Buffer size must be multiple of 4");
      assert(bufferCount > 0) else $error("Buffer count must be positive");
   endfunction // new

   function bit isFull();
      isFull = buffers.size() == bufferCount;
   endfunction // isFull

   function bit isEmpty();
      isEmpty = buffers.size() == 0;
   endfunction // isEmpty

   local function isWriteWatermarkSet();
      isWriteWatermarkSet = producerBuffer.size() >= (bufferSize - 4*flagBeforeFull);
   endfunction // writeWatermarkSet

   local function isReadWatermarkSet();
      isReadWatermarkSet = buffers[0].size() <= 4* flagBeforeEmpty;
   endfunction // isReadWatermarkSet

   local function getCommittedBufferSize();
      int           size = 0;
      foreach(buffers[i])
        size += buffers[i].size();
      getCommittedBufferSize = size;
   endfunction

   // commits a buffer (packet end)
   task commitBuffer();

      bit wasEmpty = this.isEmpty();

      if(verbose) begin
         $write("Commit Buffer: {");
         foreach(producerBuffer[i])
           $write("%02h, ",producerBuffer[i]);
         $write("}\n");
      end
      buffers.push_back(producerBuffer);
      producerBuffer = {};
      bufferSwitch = 1;
      fork begin
         #bufferSwitchTime;
         bufferSwitch = 0;
         if(wasEmpty)
           -> consumer_readable;
         if(!this.isFull())
           -> producer_writable;
      end join_none
   endtask // commitBuffer


   // nonblocking read packet burst
   task readBurst(output byte packet[], output bit valid);
      if(this.isEmpty())
        valid = 0;
      else begin
         if(this.isFull()) fork begin
            bufferSwitch = 1;
            #bufferSwitchTime;
            -> producer_writable;
            bufferSwitch = 0;
         end join_none
         packet = buffers.pop_front();
         valid = 1;
         if(verbose) begin
	    $write("Read Buffer: {");
            foreach(packet[i])
	      $write("%02h, ",packet[i]);
            $write("}\n");
         end
      end
   endtask // readPacket

   // nonblocking write packet burst
   task writeBurst(input byte packet[], output bit written);
      if(this.isFull())
        written = 0;
      else begin
         buffer_t b;
         if(this.isEmpty()) fork begin
            #0 bufferSwitch = 1;
            #bufferSwitchTime;
            -> consumer_readable;
            bufferSwitch = 0;
         end join_none
         b = packet;
         assert(b.size() % 4 == 0)
           else $error("Illegal packet size (must be multiple of 4)");
         buffers.push_back(b);
         written = 1;
      end
   endtask // writePacket

   task writeWord(input logic[31:0] word, input bit commitBuffer, output bit flag);
      if(this.isFull())
        $warning("No write buffer available, discarding word");
      else if(bufferSwitch)
        $warning("Buffer switch in progress, discarding word");
      else begin
         producerBuffer.push_back(word[31:24]);
         producerBuffer.push_back(word[23:16]);
         producerBuffer.push_back(word[15:8]);
         producerBuffer.push_back(word[7:0]);

         if(producerBuffer.size() == bufferSize || commitBuffer) begin
            flag = 1;
            this.commitBuffer();
         end
         else if(isWriteWatermarkSet())
           flag = 1;
      end
   endtask // writeWord

   task readWord(output logic[31:0] word, output bit flag);
      if(this.isEmpty()) begin
         $warning("No buffer for read commited, nothing written");
         word = 'X;
      end else if(bufferSwitch) begin
         $warning("Buffer switch in progress, nothing read");
         word = 'X;
      end else begin
         word[31:24] = buffers[0].pop_front();
         word[23:16] = buffers[0].pop_front();
         word[15:8] = buffers[0].pop_front();
         word[7:0] = buffers[0].pop_front();

         if(isReadWatermarkSet())
           flag = 1;

         if(buffers[0].size() == 0) fork begin
            bit fireEvent;
            bufferSwitch = 1;

            #bufferSwitchTime;
            fireEvent = this.isFull();
            buffers.delete(0);
            if(fireEvent)
              -> producer_writable;
            if(buffers.size() > 0)
              -> consumer_readable;
            bufferSwitch = 0;
         end join_none
      end
   endtask // readWord

endclass // fx3_buffer
