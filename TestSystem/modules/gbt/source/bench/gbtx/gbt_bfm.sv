//-----------------------------------------------------------------------------
// Title      : GBT Bus functional model
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : gbt_bfm.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2017-07-27
// Last update: 2017-07-27
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: BFM for the GBT Elink interface
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-07-27  1.0      mbonora        Created
//-----------------------------------------------------------------------------

class gbtx_bfm;

   parameter int       dclk_div = 8;
   parameter int       rx_debug_queue_size = 10;

   const logic [3:0]   GBT_IDLE = 4'd0;


   virtual             gbt_elink_if.gbtx sigs;

   logic [80:0]        tx_queue[$],tx_send_queue[$];
   logic [80:0]        rx_queue[$];
   logic [79:0]        rx_word_delayed = '0;

   typedef logic [80:0]  TBitQueue[$];
   TBitQueue        rx_debug_queue;

   int                 tx_delay_cycles = 3;
   int                 rx_delay_cycles = 6;

   bit                 verbose = 1;

   function new(virtual gbt_elink_if.gbtx _sigs);
      this.sigs = _sigs;
   endfunction // new

   virtual task gen_dclk0();
      // dclk[0]: 40MHz, dclk[1]: 160MHz
      sigs.cb.dclk[0] <= 1;
      repeat(dclk_div/2) @(sigs.cb);
      sigs.cb.dclk[0] <= 0;
      tx_schedule();
      repeat(dclk_div/2) @(sigs.cb);
   endtask // gen_clk

   virtual task gen_dclk1();
      // dclk[0]: 40MHz, dclk[1]: 160MHz
      sigs.cb.dclk[1] <= 1;
      repeat(dclk_div/8) @(sigs.cb);
      sigs.cb.dclk[1] <= 0;
      repeat(dclk_div/8) @(sigs.cb);
   endtask // gen_clk

   virtual task tx_word();
      logic [80:0] word = '0;
      logic [9:0]  slice = '0;
      int          i = 0;
      int          port = 0;
      if(tx_send_queue.size()>0) begin
        word = tx_send_queue.pop_front();
         if (word!='0 && verbose)
           $display("%0t gbt_bfm::TX_word::word: %21x", $time, word);
      end
      for(i=7; i >= 0; --i) begin
         slice = 'X;
         for(port = 0; port < 10; ++port)
           slice[port] = word[port*8 + i];
         sigs.cb.dout <= slice;
         @sigs.cb;
      end
   endtask // tx_word

   virtual task tx_schedule();
      if(tx_queue.size() > 0) begin
         fork begin
            logic[80:0] next_word = tx_queue.pop_front();
            sigs.cb.tx_valid <= next_word[80];
            tx_send_queue.push_back(next_word);
         end
         join_none

      end else begin
         sigs.cb.tx_valid <= 0;
      end
   endtask // tx_schedule

   virtual task rx_word();
      logic [79:0] word = '0;
      int          i = 0;
      int          port = 0;

      for(i=7; i >= 0; --i) begin
         for(port = 0; port < 10; ++port)
           word[port*8 + i] = sigs.cb.din[port];
         @sigs.cb;
      end
      if (word!='0 && verbose)
        $display("%0t gbt_bfm::RX_word::word: %21x", $time, word);

      if(sigs.cb.rx_valid)
        rx_queue.push_back({1'd1,rx_word_delayed});
      else if(rx_word_delayed[79:76] != GBT_IDLE) begin
        rx_queue.push_back({1'd0,rx_word_delayed});
      end
      // Debug
      rx_debug_queue.push_front({sigs.cb.rx_valid,rx_word_delayed});
      if(rx_debug_queue.size() > rx_debug_queue_size)
        void'(rx_debug_queue.pop_back());

      rx_word_delayed = word;
   endtask // rx_word

   virtual task tx_loop();
      sigs.cb.txrdy <= 1;
      forever begin
         if(tx_delay_cycles > 0) begin
            repeat(tx_delay_cycles) @(sigs.cb);
            tx_delay_cycles = 0;
         end
         tx_word();
      end
   endtask // tx_loop

   virtual task rx_loop();
      sigs.cb.rxrdy <= 1;
      forever begin
      if(rx_delay_cycles > 0) begin
         repeat(rx_delay_cycles) @(sigs.cb);
         rx_delay_cycles = 0;
      end
         rx_word();
      end
   endtask // rx_loop

   virtual task dclk_loop();
      fork
         forever gen_dclk0();
         forever gen_dclk1();
      join_none
   endtask // dclk_loop

   virtual task rx_tx_loop();
      fork
         rx_loop();
         tx_loop();
         dclk_loop();
      join_none
   endtask // rx_tx_loop

   function void write_word(logic [80:0] word);
      //if(verbose)
      //  $display("Write word: %21x", word);
      tx_queue.push_back(word);
   endfunction // write_word

   function void delay_tx(int cycles);
      tx_delay_cycles = cycles;
   endfunction // delay_tx

   function void delay_rx(int cycles);
      rx_delay_cycles = cycles;
   endfunction // delay_rx

   function TBitQueue get_debug_rx();
      return rx_debug_queue;
   endfunction // get_debug_rx

   function bit read_word(output logic [80:0] word);
      if(rx_queue.size() > 0) begin
         read_word = 1;
         word = rx_queue.pop_front();
      end else begin
         read_word = 0;
         word = 'X;
      end
   endfunction // read_word

   function int read_buffer_size();
      read_buffer_size = rx_queue.size();
   endfunction // read_buffer_size

endclass // gbt_bfm
