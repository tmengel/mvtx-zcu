//-----------------------------------------------------------------------------
// Title      : GBT Packer Testbench
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : gbt_packer_tb.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2018-04-16
// Last update: 2018-04-16
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description:
//-----------------------------------------------------------------------------
// Copyright (c)   2018
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2018-04-16  1.0      mbonora        Created
//-----------------------------------------------------------------------------

import DataGenPkg::DataGenerator;

interface gbt_packer_if(input CLK);

   localparam int NR_LANES = 28;

   logic [6:0]   chip_mask[NR_LANES];
   logic [15:0]  lane_timeout;
   logic         RST;

   logic [7:0]   data_in[NR_LANES];
   logic         data_in_write[NR_LANES], data_in_full[NR_LANES];


   logic [80:0]  gbtx_tx_data;
   logic         gbtx_data_valid;

   logic [100 : 0] trigger_data;
   logic           trigger_empty;
   logic           trigger_read;

   logic [NR_LANES-1:0] lane_mask;
   logic [15 : 0]       wait_data_timeout;
   logic [15 : 0]       send_data_timeout;

   logic [15 : 0]       gbt_max_word_count;
   logic [15 : 0]       gbt_max_packet_count;
   logic [15 : 0]       gbt_fee_id;
   logic [ 7 : 0]       gbt_priority;

   logic                mismatch;
   logic                mismatch_2nd;

   clocking cb@(posedge CLK);
      default input #1ns output #1ns;
      input     data_in_full;
      input     trigger_read;
      input     mismatch;
      input     mismatch_2nd;
      input     gbtx_tx_data;
      input     gbtx_data_valid;
      output    RST;
      output    chip_mask;
      output    lane_timeout;
      output    data_in;
      output    data_in_write;
      output    trigger_data;
      output    trigger_empty;
      output    lane_mask;
      output    wait_data_timeout;
      output    send_data_timeout;
      inout     gbt_max_word_count;
      inout     gbt_max_packet_count;
      inout     gbt_fee_id;
      inout     gbt_priority;
   endclocking // cb

   modport data_checker(clocking cb, import task write_byte(), import task read_package());

   task automatic write_byte(input logic [7:0] data, input int lane);
      if(data_in_full[lane]) begin // don't check the cb value, as it is delayed a cycle
         @(cb iff !cb.data_in_full[lane]);
      end
      cb.data_in[lane] <= data;
      cb.data_in_write[lane] <= 1;
      @(cb);
      cb.data_in_write[lane] <= 0;
      cb.data_in[lane] <= 'X;
   endtask // write_byte

   task automatic read_package(output logic [80:0] data);
      @(cb iff cb.gbtx_data_valid);
      data = cb.gbtx_tx_data;
   endtask // read_package

endinterface // gbt_packer_if

interface error_inject_if(input CLK);
   localparam int NR_LANES = 28;
   localparam int NR_STATES = 14;

   logic [2:0]    inject;
   logic [3:0]    inject_state;
   logic [3:0]    current_state;
   logic          gbt_packet_done;
   logic          no_inject_cycle;

   logic          inject_td_expect_data;
   logic [31:0]   inject_td_hb_orbit;
   logic [11:0]   inject_td_hb_bc;
   logic [31:0]   inject_td_trigger_orbit;
   logic [15:0]   inject_td_trigger_type;
   logic [11:0]   inject_td_trigger_bc;

   logic [15:0]   inject_wd_timeout_count;
   logic [15:0]   inject_sd_timeout_count;
   logic          inject_transmission_done;
   logic          inject_transmission_timeout;
   logic [80:0]   inject_tx_data;
   logic          inject_tx_datavalid;
   logic [NR_LANES-1 :0] inject_lane_active;
   logic [NR_LANES-1 :0] inject_lane_starts;
   logic [NR_LANES-1 :0] inject_lane_starts_violation;
   logic [NR_LANES-1 :0] inject_lane_timeouts;
   logic [NR_LANES-1 :0] inject_lane_stops;
   logic [4 :0]          inject_lane_idx;
   logic [NR_LANES-1 :0] inject_lanes_read;
   logic [15 :0]         inject_word_count;
   logic [15 :0]         inject_packet_idx;

   event                 inject_done;

   clocking cb@(posedge CLK);
      default input #1ns output #1ns;
      output inject;
      input  current_state;
      input  gbt_packet_done;
      output  no_inject_cycle;

      output inject_state;
      output inject_td_expect_data;
      output inject_td_hb_orbit;
      output inject_td_hb_bc;
      output inject_td_trigger_orbit;
      output inject_td_trigger_type;
      output inject_td_trigger_bc;
      output inject_wd_timeout_count;
      output inject_sd_timeout_count;
      output inject_transmission_done;
      output inject_transmission_timeout;
      output inject_tx_data;
      output inject_tx_datavalid;
      output inject_lane_active;
      output inject_lane_starts;
      output inject_lane_starts_violation;
      output inject_lane_timeouts;
      output inject_lane_stops;
      output inject_lane_idx;
      output inject_lanes_read;
      output inject_word_count;
      output inject_packet_idx;
   endclocking // cb

   modport injector(clocking cb, inject_done);

   // Check that there were error injections in all states
   covergroup inject_state_change @(inject_done);
      cs : coverpoint current_state {ignore_bins no_state={14,15};}
      is : coverpoint inject_state  {ignore_bins no_state={14,15};}
      state_cross : cross cs,is;
   endgroup // inject_state_change

   inject_state_change cover_inject_state_change = new();
endinterface // error_inject_if

class ErrorInjector#(NR_LANES=28);

   virtual   error_inject_if.injector inject_if;

   localparam NR_REGS = 22;

   integer   nr_lanes;

   rand logic [3:0] rinject_position_state;

   rand int unsigned rinject_sel;
   rand logic [2:0] rinject;

   rand logic [3:0] rinject_state;
   rand logic       rinject_td_expect_data;
   rand logic [31:0] rinject_td_hb_orbit;
   rand logic [11:0] rinject_td_hb_bc;
   rand logic [31:0] rinject_td_trigger_orbit;
   rand logic [15:0] rinject_td_trigger_type;
   rand logic [11:0] rinject_td_trigger_bc;
   rand logic [15:0] rinject_wd_timeout_count;
   rand logic [15:0] rinject_sd_timeout_count;
   rand logic        rinject_transmission_done;
   rand logic        rinject_transmission_timeout;
   rand logic [80:0] rinject_tx_data;
   rand logic        rinject_tx_datavalid;
   rand logic [NR_LANES-1 :0] rinject_lane_active;
   rand logic [NR_LANES-1 :0] rinject_lane_starts;
   rand logic [NR_LANES-1 :0] rinject_lane_starts_violation;
   rand logic [NR_LANES-1 :0] rinject_lane_timeouts;
   rand logic [NR_LANES-1 :0] rinject_lane_stops;
   rand logic [4 :0]          rinject_lane_idx;
   rand logic [NR_LANES-1 :0] rinject_lanes_read;
   rand logic [15 :0]         rinject_word_count;
   rand logic [15 :0]         rinject_packet_idx;

   constraint nrRegs {
      rinject_sel < NR_REGS;
      rinject_sel dist{0:=NR_REGS/2, [1:NR_REGS-1]:=1};
   };
   constraint inject_location {
      $countones(rinject) == 1;
   };
   constraint lane_index {
      rinject_lane_idx < NR_LANES;
   };

   constraint state {
      rinject_state < 4'd14;
      rinject_position_state < 4'd14;
   };

   function new(virtual error_inject_if.injector inject_if);
      this.inject_if = inject_if;
   endfunction // new

   task init();
      inject_if.cb.no_inject_cycle <= 0;
      inject_if.cb.inject <= '0;
   endtask // init

   task automatic inject_error();
      case(rinject_sel)
        0: inject_if.cb.inject_state <= rinject_state;
        1: inject_if.cb.inject_td_expect_data <= rinject_td_expect_data;
        2: inject_if.cb.inject_td_hb_orbit <= rinject_td_hb_orbit;
        3: inject_if.cb.inject_td_hb_bc <= rinject_td_hb_bc;
        4: inject_if.cb.inject_td_trigger_orbit <= rinject_td_trigger_orbit;
        5: inject_if.cb.inject_td_trigger_type <= rinject_td_trigger_type;
        6: inject_if.cb.inject_td_trigger_bc <= rinject_td_trigger_bc;
        7: inject_if.cb.inject_wd_timeout_count <= rinject_wd_timeout_count;
        8: inject_if.cb.inject_sd_timeout_count <= rinject_sd_timeout_count;
        9: inject_if.cb.inject_transmission_done <= rinject_transmission_done;
        10: inject_if.cb.inject_transmission_timeout <= rinject_transmission_timeout;
        11: inject_if.cb.inject_tx_data <= rinject_tx_data;
        12: inject_if.cb.inject_tx_datavalid <= rinject_tx_datavalid;
        13: inject_if.cb.inject_lane_active <= rinject_lane_active;
        14: inject_if.cb.inject_lane_starts <= rinject_lane_starts;
        15: inject_if.cb.inject_lane_starts_violation <= rinject_lane_starts_violation;
        16: inject_if.cb.inject_lane_timeouts <= rinject_lane_timeouts;
        17: inject_if.cb.inject_lane_stops <= rinject_lane_stops;
        18: inject_if.cb.inject_lane_idx <= rinject_lane_idx;
        19: inject_if.cb.inject_lanes_read <= rinject_lanes_read;
        20: inject_if.cb.inject_word_count <= rinject_word_count;
        21: inject_if.cb.inject_packet_idx <= rinject_packet_idx;
      endcase // case (rinject_sel)

      // Strobe
      inject_if.cb.inject <= rinject;
      @(inject_if.cb);
      ->inject_if.inject_done;
      inject_if.cb.inject <= '0;

      // Reset
      inject_if.cb.inject_state <= 'X;
      inject_if.cb.inject_td_expect_data <= 'X;
      inject_if.cb.inject_td_hb_orbit <= 'X;
      inject_if.cb.inject_td_hb_bc <= 'X;
      inject_if.cb.inject_td_trigger_orbit <= 'X;
      inject_if.cb.inject_td_trigger_type <= 'X;
      inject_if.cb.inject_td_trigger_bc <= 'X;
      inject_if.cb.inject_wd_timeout_count <= 'X;
      inject_if.cb.inject_sd_timeout_count <= 'X;
      inject_if.cb.inject_transmission_done <= 'X;
      inject_if.cb.inject_transmission_timeout <= 'X;
      inject_if.cb.inject_tx_data <= 'X;
      inject_if.cb.inject_tx_datavalid <= 'X;
      inject_if.cb.inject_lane_active <= 'X;
      inject_if.cb.inject_lane_starts <= 'X;
      inject_if.cb.inject_lane_starts_violation <= 'X;
      inject_if.cb.inject_lane_timeouts <= 'X;
      inject_if.cb.inject_lane_stops <= 'X;
      inject_if.cb.inject_lane_idx <= 'X;
      inject_if.cb.inject_lanes_read <= 'X;
      inject_if.cb.inject_word_count <= 'X;
      inject_if.cb.inject_packet_idx <= 'X;
      @(inject_if.cb);
   endtask // inject_error

   task automatic inject_procedure();
      forever begin
         assert(this.randomize()) else $error("Could not randomize ErrorInjector");
         inject_if.cb.no_inject_cycle <= 0;
         @(inject_if.cb.current_state == rinject_position_state);
         inject_error();
         @(inject_if.cb.gbt_packet_done == 1);
         @(inject_if.cb);
         inject_if.cb.no_inject_cycle <= 1;
         @(inject_if.cb.gbt_packet_done == 1);
      end
   endtask // inject_procedure

endclass // ErrorInjector

class DataPackagerDriverChecker;
   DataGenerator datagen;

   mailbox input_data;
   mailbox expected_output_data;
   mailbox received_output_data;

   bit [10:0] fromu_bunch_count;

   virtual    gbt_packer_if.data_checker dp_if;
   int        lane_id;

   int        protected_count;

   int        output_schedule_time;
   int        input_schedule_time;

   bit        verbose;

   function new(virtual gbt_packer_if.data_checker dp_if, input int lane_id=0, bit verbose = 1);
      this.dp_if = dp_if;
      this.lane_id = lane_id;
      this.datagen = new();

      this.protected_count = 0;
      this.fromu_bunch_count = 10'd16;
      this.output_schedule_time = 0;
      this.input_schedule_time = 0;
      this.verbose = verbose;

      this.input_data = new();
      this.expected_output_data = new();
      this.received_output_data = new();

   endfunction // new

   function void set_output_schedule_time(input int sh);
      output_schedule_time = sh;
   endfunction // set_output_schedule_time

   function void set_input_schedule_time(input int sh);
      input_schedule_time = sh;
   endfunction // set_input_schedule_time

   function bit is_idle(input [7:0] data);
      // idle output
      if(data != 8'hFF)
        is_idle = 0;
      else
        is_idle = this.protected_count == 0;
      // track protocol
      if (this.protected_count == 0) begin
         if(data[7:6] == 2'b00)
           this.protected_count = 2;
         else if(data[7:6] == 2'b01)
           this.protected_count = 1;
         else if(data[7:4] == 4'b1110)
           this.protected_count = 1;
         else if(data[7:4] == 4'b1010)
           this.protected_count = 1;
      end else
        this.protected_count--;
   endfunction // is_idle

   task automatic schedule_packet(input int chips[$], input bit busy_violation[$],
                                  output int nr_words, input bit timeouts[$], output bit no_lane_timeout);
      automatic int  i;
      automatic int j;

      automatic logic [74:0] data_packaged = '0;
      automatic int          p_idx = 0;
      automatic bit [7:0]    generated_data[$];
      automatic bit [3:0]    chipid;

      automatic int word_count;
      automatic bit lane_is_timeout;

      word_count = 0;
      lane_is_timeout = 0;

      generated_data = {};
      data_packaged[73] = (chips.size() > 0)?1:0; // Start of data
      foreach(chips[i]) begin
         chipid = chips[i];
         if(verbose)
           $display("Lane %d, schedule chip %d, (%p, %d)",lane_id, chipid,chips, i);
         datagen.generateEvent(generated_data,chipid,busy_violation[i],fromu_bunch_count);
         if(timeouts[i]) begin
            lane_is_timeout = 1;
            if(verbose) $display("Lane %d, chip %d will be timeout", lane_id, chipid);
            assert(generated_data.pop_back());
            if(generated_data.size() > 0)
              assert(generated_data.pop_back());
            if(generated_data.size() > 0)
              assert(generated_data.pop_back());
         end
         fromu_bunch_count = fromu_bunch_count + 8;
      end
      if(verbose) begin
         $write("Lane %d, Generated Event: {",lane_id);
         foreach(generated_data[j])
           $write("%02H ",generated_data[j]);
         $write("}\n");
      end

      foreach(generated_data[j]) begin
         input_data.put(generated_data[j]);
      end
      foreach(generated_data[j]) begin
         if(!is_idle(generated_data[j])) begin
            if(p_idx == 9) begin
               if(verbose)
                 $display("Lane %d, Schedule data: %20H", lane_id, data_packaged);
               repeat(output_schedule_time)@(dp_if.cb);
               expected_output_data.put(data_packaged);
               word_count++;
               data_packaged = '0;
               p_idx = 0;
            end
            repeat(output_schedule_time)@(dp_if.cb);
            data_packaged[p_idx*8 +: 8] = generated_data[j];
            p_idx++;
         end
      end // foreach (generated_data[j])
      data_packaged[72] = 1; // Stop bit
      if(p_idx == 9 && lane_is_timeout) begin
         no_lane_timeout = 1;
         data_packaged[72] = 0; // Stop bit
      end else begin
         data_packaged[74] = 1; // Timeout bit
      end
      if(verbose) begin
         $display("Lane %d, Schedule data: %20H", lane_id, data_packaged);
      end
      expected_output_data.put(data_packaged);
      word_count++;

      nr_words = word_count;
   endtask // schedule_packet

   task automatic fill_input_data();
      automatic logic [7:0] data;
      forever begin
         input_data.get(data);
         repeat(input_schedule_time) @(dp_if.cb);
         dp_if.write_byte(data, lane_id);
      end
   endtask // fill_input_data

   task automatic fill_output_data(input logic [73:0] data_read);
      received_output_data.put(data_read);
   endtask // add_output_data

   task automatic check_output_data();
      automatic logic [71:0] data_read;
      automatic logic [73:0] data_expected;
      forever begin
         received_output_data.get(data_read);
         expected_output_data.get(data_expected);
         assert (data_read == data_expected[71:0]) else
           $error("Lane %d, Data mismatch, packaged data not as expected(%18H/%18H)",
                  lane_id, data_read,data_expected[71:0]);
      end
   endtask // check_output_data

   task automatic wait_idle(input int timeout = 100000);
      automatic int count;
      count = 0;
      while(input_data.num() > 0 || expected_output_data.num() > 0) begin
        @(dp_if.cb);
        if(count++ > timeout)
          $error("Lane %d, Timeout while waiting to idle",lane_id);
      end
      count = 0;
   endtask // wait_idle

   task automatic background_tasks();
      fork
         fill_input_data();
         check_output_data();
      join_none
   endtask // background_tasks


   task automatic reset();
      this.input_data = new();
      this.expected_output_data = new();
      this.received_output_data = new();
      fromu_bunch_count = '0;
   endtask // reset
endclass // DataPackagerDriverChecker

class GbtPackerDriverChecker;

   virtual gbt_packer_if dp_if;

   DataPackagerDriverChecker lane_drivers[];
   int lane_chips[][$];
   bit lane_busy_violations[][$];

   int NR_LANES;
   bit verbose;

   mailbox input_triggers;
   mailbox expected_output_data;

   logic [31:0] hb_orbit;
   logic [11 : 0] hb_bc;
   logic [31:0]   trigger_orbit;
   logic [11:0]   trigger_bc;
   logic [15:0]   trigger_type;


   function new(virtual gbt_packer_if.data_checker dp_if, input int nr_lanes, bit verbose = 1);
      int i;

      this.dp_if = dp_if;
      this.NR_LANES = nr_lanes;
      this.verbose = verbose;

      lane_drivers = new[nr_lanes];
      lane_chips = new[nr_lanes];
      lane_busy_violations = new[nr_lanes];

      input_triggers = new();
      expected_output_data = new();

      reset_bc();
      trigger_type = 16'h8;


      for(i = 0; i < nr_lanes; i++)
        lane_drivers[i] = new(dp_if,i,verbose);
   endfunction // new

   function void updateEventSize(input int maxHitsPerRegion, input int maxRegions);
      foreach(lane_drivers[i])
        lane_drivers[i].datagen.updateEventSize(maxHitsPerRegion,maxRegions);
   endfunction // updateEventSize

   function void set_output_schedule_time(input int sh);
      foreach(lane_drivers[i])
        lane_drivers[i].output_schedule_time = sh;
   endfunction // set_output_schedule_time

   function void set_input_schedule_time(input int sh);
      foreach(lane_drivers[i])
        lane_drivers[i].input_schedule_time = sh;
   endfunction // set_input_schedule_time

   function void reset_bc();
      hb_orbit = '0;
      hb_bc = '0;
      trigger_orbit = '0;
      trigger_bc = '0;
   endfunction // reset_bc

   function void increase_bc();
      trigger_bc++;
      if(trigger_bc % 3 == 2)
        trigger_orbit++;
      if(trigger_bc % 7 == 6)
        hb_bc = trigger_bc;
      if(trigger_orbit % 11 == 10)
        hb_orbit = trigger_orbit;
   endfunction // increase_bc

   task schedule_trigger(input bit expect_data,
                         input logic [27:0] active_lanes,
                         input int          maxHitsPerRegion,
                         input int          maxRegions,
                         input bit          chip_timeouts [28][$],
                         input bit          wait_timeout = 0
                         );

      automatic logic [100:0] generated_trigger;
      automatic logic [80:0] expected_output;
      automatic logic [15:0] packet_idx;
      automatic logic [7:0] packet_status;
      automatic logic [15:0] word_count;
      automatic logic [27:0] lane_stops;
      automatic logic [27:0] lane_stops_packet;

      automatic int i,j, lane_idx;
      automatic int packet_size, lane_size, words_left;

      automatic bit is_lane_timeout;
      automatic bit is_gbt_timeout;
      automatic bit [27:0] no_lane_timeout = '0;

      active_lanes = active_lanes & ((1<<NR_LANES)-1);


      increase_bc();
      updateEventSize(maxHitsPerRegion, maxRegions);
      is_lane_timeout = 0;
      is_gbt_timeout = 0;

      generated_trigger[100] = expect_data;
      generated_trigger[99:68] = hb_orbit;
      generated_trigger[67:56] = hb_bc;
      generated_trigger[55:24] = trigger_orbit;
      generated_trigger[23:12] = trigger_bc;
      generated_trigger[11:0 ] = trigger_type;

      $display("%d, Add input trigger", $time);

      input_triggers.put(generated_trigger);

      // generate data if needed
      if(expect_data && !wait_timeout) begin
         lane_stops = active_lanes;
         for(i = 0; i < NR_LANES; i++) begin
            if(active_lanes[i]) begin
               $display("Lane %d, schedule packet", i);
               lane_drivers[i].schedule_packet(lane_chips[i],
                                               lane_busy_violations[i],
                                               lane_size,
                                               chip_timeouts[i],
                                               no_lane_timeout[i]
                                               );
               packet_size = packet_size + lane_size;
               for(j=0; j< chip_timeouts[i].size(); j++)
                 if(chip_timeouts[i][j] == 1) begin
                       if(no_lane_timeout[i]) begin
                          is_gbt_timeout = 1;
                          lane_stops[i]=0;
                       end else
                         is_lane_timeout = 1;
                 end
            end
         end
      end else // if (expect_data)
        lane_stops = '0;

      if(verbose) $display("Lane Data scheduled: %d words", packet_size);

      if(wait_timeout)
        is_gbt_timeout = 1;
      words_left = packet_size;
      i=0;
      do begin
         if(words_left <= dp_if.cb.gbt_max_word_count-4) begin
            word_count = words_left;
            packet_status = {3'h0,
                             is_lane_timeout,
                             1'h0,
                             1'h0,
                             is_gbt_timeout,
                             1'h1};

         end else begin
            word_count = dp_if.cb.gbt_max_word_count-4;
            packet_status = 8'h00;
         end
         words_left = words_left - word_count;

         packet_idx = i++;

         if(packet_status[0] == 1)
           lane_stops_packet = lane_stops;
         else
           lane_stops_packet = 'Z;

         if(packet_idx == dp_if.cb.gbt_max_packet_count) begin
            packet_status[0] = 1;
            packet_status[2] = 1;
            words_left = 0;
         end


         if(verbose) $display("Schedule gbt word: Index: %d, words: %d, ", packet_idx, word_count);



         expected_output = 81'h010000000000000000000;
         if(verbose) $display("Schedule SOP: %21H", expected_output);
         expected_output_data.put(expected_output); // SOP

         expected_output = {25'h1000000,dp_if.cb.gbt_priority,
                        dp_if.cb.gbt_fee_id,16'hffff,
                        16'h0303}; // CDH0
         if(verbose) $display("Schedule CDH0: %21H", expected_output);
         expected_output_data.put(expected_output);

         expected_output = {1'h1,16'h0000,hb_orbit,trigger_orbit}; // CDH1
         if(verbose) $display("Schedule CDH1: %21H", expected_output);
         expected_output_data.put(expected_output);

         expected_output = {1'h1,16'h0000, 16'h0000, trigger_type, 4'h0,hb_bc,4'h0,trigger_bc}; // CDH2
         if(verbose) $display("Schedule CDH2: %21H", expected_output);
         expected_output_data.put(expected_output);

         expected_output = {1'h1,16'h0000, 8'h00, packet_idx, 8'h00, 16'h0000, 16'h0000}; // CDH3
         if(verbose) $display("Schedule CDH3: %21H", expected_output);
         expected_output_data.put(expected_output);

         expected_output = {9'h1E0,28'h00000000,active_lanes,packet_idx}; // HEADER
         if(verbose) $display("Schedule Header: %21H", expected_output);
         expected_output_data.put(expected_output);

         word_count = word_count + 5;
         expected_output = {9'h1F0,packet_status,20'h0,lane_stops_packet,word_count}; // TRAILER
         if(verbose) $display("Schedule Trailer: %21H", expected_output);
         expected_output_data.put(expected_output);

         expected_output = 81'h020000000000000000000;
         word_count++;
         expected_output[15:0] = word_count;
         if(verbose) $display("Schedule EOP: %21H", expected_output);

         expected_output_data.put(expected_output); // EOP

         expected_output = '0;
         expected_output_data.put(expected_output); // IDLE

         active_lanes = 'Z;
      end while(words_left > 0 ); // do begin
      wait_idle(1000000);
      if(packet_status[2] == 1) begin

         $display("Packet transmission stopped due to packet overflow. Reset data lanes");
         foreach(lane_drivers[i]) begin
            lane_drivers[i].reset();
         end
         dp_if.cb.RST <= 1;
         repeat(10) @(dp_if.cb);
         dp_if.cb.RST <= 0;
         repeat(10)@(dp_if.cb);

      end
   endtask // schedule_trigger

   task fill_input_data();
      automatic logic [100:0] trigger_data;
      forever begin
         input_triggers.get(trigger_data);
         dp_if.cb.trigger_data <= trigger_data;
         dp_if.cb.trigger_empty <= 0;
         @(dp_if.cb iff dp_if.cb.trigger_read);
         dp_if.cb.trigger_empty <= 1;
      end
   endtask // fill_input_data


   task check_output_data();
      automatic logic [80:0] data_read;
      automatic logic [80:0] data_expected;
      automatic int cdh_left = 4;
      automatic bit datalane_pkg = 0;
      automatic int lane_id = 0;
      automatic bit mismatch = 0;
      automatic int i;

      forever begin
         @(dp_if.cb iff dp_if.cb.gbtx_data_valid);
         data_read = dp_if.cb.gbtx_tx_data;

         datalane_pkg = 0;
         if(data_read[80:76]=={1'h0,4'h1})
           cdh_left = 4; // CDH
         else if(data_read[80]==1) begin // Data_valid
            if(cdh_left > 0)
              cdh_left--;
            else if(data_read[80] == 1 && data_read[79:72] < 8'h28)
              datalane_pkg = 1;
         end
         if(datalane_pkg) begin
            if(verbose) $display("Read: %21H, sent to lane",data_read);
            lane_id = data_read[79:72] - 1;
            lane_drivers[lane_id].received_output_data.put(data_read);
         end else begin
            assert (expected_output_data.try_get(data_expected)) else
              $error("Data received on gbt link, but no data expected: %21H",data_read);
            if(verbose) $display("Read: %21H, expect: %21H)",data_read,data_expected);
            mismatch = 0;
            for(i=0; i < 81; i++)
              if(data_expected[i] !== 'Z && data_expected[i] != data_read[i])
                mismatch = 1;

            assert (mismatch == 0) else
              $error("Data mismatch, packaged data not as expected(%21H/%21H)",data_read,data_expected);
         end
      end
   endtask // check_output_data

   task wait_idle(input int timeout = 100000);
      automatic int count;
      count = 0;
      while(input_triggers.num() > 0 || expected_output_data.num() > 0) begin
         @(dp_if.cb);
         if(count++ > timeout)
           $error("Timeout while waiting to idle");
      end
      count = 0;
   endtask // wait_idle

   task reset();
      // Reset signals
      automatic int i;

      dp_if.cb.RST <= 1;
      dp_if.cb.lane_timeout <= 16'h0FFF;

      for(i=0;i<NR_LANES;i++) begin
         dp_if.cb.data_in[i] <= 'X;
         dp_if.cb.data_in_write[i] <= 0;
      end

      dp_if.cb.trigger_data <= '0;
      dp_if.cb.trigger_empty <= 1;
      dp_if.cb.lane_mask <= '0;
      dp_if.cb.wait_data_timeout <= 16'h0FFF;
      dp_if.cb.send_data_timeout <= 16'h1FFF;
      dp_if.gbt_max_word_count <= 16'h0FFF;
      dp_if.gbt_max_packet_count <= 8'hFF;
      dp_if.gbt_fee_id <= 16'hABCD;
      dp_if.gbt_priority <= '0;

      foreach(lane_drivers[i])
        lane_drivers[i].reset();

      repeat(3) @(dp_if.cb);
      dp_if.cb.RST <= 0;
      @(dp_if.cb);
   endtask // reset

   task background_tasks();
      automatic int id;
      for(id=0; id<NR_LANES;id++)
         lane_drivers[id].background_tasks();
      fork
         check_output_data();
         fill_input_data();
      join_none
   endtask // background_tasks

endclass // GbtPackerDriverChecker

class TestParams;

   rand bit[27:0] rActiveLanes;
   rand int unsigned rMaxRegions;
   rand int unsigned rMaxHits;
   rand bit rWaitTimeout;

   rand bit rChipTimeout;
   rand int unsigned rChipTimeoutLane;
   rand int unsigned rChipTimeoutChip;

   rand bit rChipBusy;
   rand int unsigned rChipBusyLane;
   rand int unsigned rChipBusyChip;

   rand bit rExpectData;


   rand int unsigned rInputDelay;
   rand int unsigned rOutputDelay;
   rand int unsigned rTestDelay;

   const int OB_MODE;
   const int NR_LANES;

   function new(bit OB_MODE=1, int NR_LANES=28);
      this.OB_MODE=OB_MODE;
      this.NR_LANES=NR_LANES;
   endfunction // new

   constraint limitChipTimeout {
      rChipTimeoutLane < NR_LANES;
      if(OB_MODE)
         rChipTimeoutChip < 7;
      else
         rChipTimeoutChip < 1;
   };
   constraint limitChipBusy {
      rChipBusyLane < NR_LANES;
      if(OB_MODE)
         rChipBusyChip < 7;
      else
         rChipBusyChip < 1;
   };


   constraint limitEventSize {
      if(OB_MODE) {
         rMaxRegions <= 1;
         rMaxHits <= 2;
      }else{
         rMaxRegions <= 32;
         rMaxHits <= 128;
      }
   };
   constraint limitTimeouts {
      rWaitTimeout & rChipTimeout != 1;

      rWaitTimeout dist {0 := 9, 1 := 1};
      rChipTimeout dist{0 := 9, 1 := 1};
   };
   constraint limitDelays {
      rInputDelay <= 20;
      rOutputDelay == 0;
      rTestDelay <= 10;
   };

   function void print_params();
      $display("Test Parameters: Active lanes: %b, Expect Data: %d, Max Regions: %d, Max Hits: %d",
               rActiveLanes,rExpectData,rMaxRegions,rMaxHits);
      $display("                 Chip Busy: %d (Lane: %d, Chip: %d)",rChipBusy,rChipBusyLane,rChipBusyChip);
      $display("                 Chip Timeout: %d (Lane: %d, Chip: %d)",rChipTimeout,rChipTimeoutLane,rChipTimeoutChip);
      $display("                 Input Delay: %d, Output Delay: %d, Test Delay: %d",rInputDelay,rOutputDelay,rTestDelay);
   endfunction // print_params

endclass // TestParams

module gbt_packer_testbench(gbt_packer_if.data_checker dp_if,
                            error_inject_if.injector inject_if,
                            output event finished_event);
   parameter bit OB_MODE=1;
   parameter int NR_LANES = 28;
   parameter bit verbose = 1;

   GbtPackerDriverChecker gpdc = new(dp_if,NR_LANES,verbose);
   TestParams params = new(OB_MODE,NR_LANES);

   ErrorInjector#(NR_LANES) error_injector = new(inject_if);

   task automatic schedule_manual_cases();
      automatic int chips [$];
      automatic bit busy_violations[$];

      automatic logic [6:0] busy_violation = '0;
      automatic int i,j;
      automatic logic [27:0] active_lanes;
      automatic bit chip_timeouts[28][$];

      // set defaults
      dp_if.cb.lane_timeout <= 16'h0FFF;
      dp_if.cb.lane_mask <= '0;
      dp_if.cb.wait_data_timeout <= 16'h0FFF;
      dp_if.cb.send_data_timeout <= 16'h1FFF;
      dp_if.cb.gbt_max_word_count <= 16'd256;
      dp_if.cb.gbt_max_packet_count <= 8'hFF;
      dp_if.cb.gbt_fee_id <= 16'hABCD;
      dp_if.cb.gbt_priority <= 8'h1;

      active_lanes = '0;
      active_lanes[0 +: NR_LANES] = '1;

      $display("  Normal Events (OB=%d)", OB_MODE);
      gpdc.updateEventSize(5,6); // Normal events
      for(i = 0; i < NR_LANES; i++) begin
         chips = {};
         busy_violations = {};
         if(OB_MODE==1)
           for(j=0; j<7; j++) begin
              if(i%2 == 0)
                chips.push_back(j);
              else
                chips.push_back(j+8);
              busy_violations.push_back(0);
              chip_timeouts[i].push_back(0);
           end
         else begin
            chips.push_back(i);
            busy_violations.push_back(0);
            chip_timeouts[i].push_back(0);
         end
         gpdc.lane_chips[i] = chips;
         gpdc.lane_busy_violations[i] = busy_violations;

         dp_if.cb.chip_mask[i] <= '0;
      end

      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,5,6,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(0,active_lanes,5,6,chip_timeouts);
      @(dp_if.cb);
      gpdc.wait_idle();
      gpdc.schedule_trigger(1,active_lanes,32,32,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,32,64,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,16,128,chip_timeouts);
      @(dp_if.cb);

      // less then all active lanes
      $display("  Not all Lanes active (OB=%d)", OB_MODE);
      active_lanes[2:0] = '0;
      dp_if.cb.lane_mask <= ~active_lanes;
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,5,6,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,32,64,chip_timeouts);
      @(dp_if.cb);
      active_lanes[2:0] = '1;
      dp_if.cb.lane_mask <= ~active_lanes;

      // timeouts
      $display("  Test Timeouts (OB=%d)", OB_MODE);
      chip_timeouts[0][0]=1;
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,5,6,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,32,64,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,16,128,chip_timeouts);
      chip_timeouts[0][0]=0;
      @(dp_if.cb);
      gpdc.wait_idle();

      // Play with timeouts and word counter overflows
      dp_if.cb.wait_data_timeout <= 16'h0FF;
      dp_if.cb.send_data_timeout <= 16'h1FF;
      dp_if.cb.gbt_max_word_count <= 16'd10;
      dp_if.cb.gbt_max_packet_count <= 8'hFF;
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,5,6,chip_timeouts);
      @(dp_if.cb);
      gpdc.schedule_trigger(1,active_lanes,7,10,chip_timeouts);
      gpdc.wait_idle();
   endtask // special_cases

   task automatic schedule_random_cases(input int nrTests);
      automatic int i,j;
      automatic logic [27:0] active_lanes;
      automatic bit chip_timeouts[28][$];

      $display("  Random Events (OB=%d)", OB_MODE);
      // set defaults
      dp_if.cb.lane_timeout <= 16'h0FFF;
      dp_if.cb.lane_mask <= '0;
      dp_if.cb.wait_data_timeout <= 16'h0FFF;
      dp_if.cb.send_data_timeout <= 16'h1FFF;
      dp_if.cb.gbt_max_word_count <= 16'd256;
      dp_if.cb.gbt_max_packet_count <= 8'hFF;
      dp_if.cb.gbt_fee_id <= 16'hABCD;
      dp_if.cb.gbt_priority <= 8'h1;

      for(i = 0; i < NR_LANES; i++) begin
         gpdc.lane_chips[i] = {};
         gpdc.lane_busy_violations[i] = {};
         if(OB_MODE==1)
           for(j=0; j<7; j++) begin
              if(i%2 == 0)
                gpdc.lane_chips[i].push_back(j);
              else
                gpdc.lane_chips[i].push_back(j+8);
              gpdc.lane_busy_violations[i].push_back(0);
              chip_timeouts[i].push_back(0);
           end
         else begin
            gpdc.lane_chips[i].push_back(i);
            gpdc.lane_busy_violations[i].push_back(0);
            chip_timeouts[i].push_back(0);
         end
         dp_if.cb.chip_mask[i] <= '0;
      end

      for(int i = 0; i < nrTests; i++) begin
         assert(params.randomize());
         if(verbose) begin
            $display("Run Testcase number %d", i);
            params.print_params();
         end
         dp_if.cb.lane_mask <= ~params.rActiveLanes;
         @(dp_if.cb);

         if(params.rChipBusy)
           gpdc.lane_busy_violations[params.rChipBusyLane][params.rChipBusyChip]=1;
         if(params.rChipTimeout)
           chip_timeouts[params.rChipTimeoutLane][params.rChipTimeoutChip]=1;

         gpdc.set_input_schedule_time(params.rInputDelay);
         gpdc.set_output_schedule_time(params.rOutputDelay);
         gpdc.schedule_trigger(params.rExpectData,params.rActiveLanes,params.rMaxHits,params.rMaxRegions,chip_timeouts);

         repeat(params.rTestDelay)@(dp_if.cb);
         gpdc.wait_idle(1000000);
         gpdc.lane_busy_violations[params.rChipBusyLane][params.rChipBusyChip]=0;
         chip_timeouts[params.rChipTimeoutLane][params.rChipTimeoutChip]=0;
         if(verbose) begin
            $display("Testcase number %d done", i);
         end
      end
   endtask // schedule_random_cases

   initial begin
      $display("Reset packager (OB=%d)", OB_MODE);
      gpdc.reset();

      $display("Start injecting of errors");
      fork
         error_injector.inject_procedure();
      join_none;

      $display("Run manual cases(OB=%d)", OB_MODE);
      schedule_manual_cases();
      $display("Run generated cases (OB=%d)", OB_MODE);
      schedule_random_cases(100);
      $display("Simulation done (OB=%d)", OB_MODE);
      -> finished_event;
   end

   // Background tasks for checking and running
   initial begin
      error_injector.init();
      @(dp_if.cb);
      @(dp_if.cb);
      gpdc.background_tasks();
   end
endmodule // gbt_packer_testbench

module test_module(input logic CLK, output event module_finished);
   parameter int NR_LANES = 9;
   parameter bit OB_MODE = 0;
   parameter bit verbose = 0;

   gbt_packer_if dp_if(CLK);
   error_inject_if inject_if(CLK);
   gbt_packer_testbench#(.OB_MODE(OB_MODE), .verbose(verbose), .NR_LANES(NR_LANES))
   data_packager_tb_inst(dp_if,inject_if,module_finished);

   logic [NR_LANES*72 -1  : 0] lane_fifo_data;
   logic [NR_LANES-1  : 0]   lane_fifo_start;
   logic [NR_LANES-1  : 0]   lane_fifo_stop;
   logic [NR_LANES-1  : 0]   lane_fifo_timeout;

   logic [NR_LANES-1  : 0]     lane_fifo_valid;
   logic [NR_LANES-1  : 0]     lane_fifo_read;

   genvar                              i;
   generate
      for(i = 0; i < NR_LANES; i++) begin
         logic fifo_rd_en;
         logic fifo_empty;
         logic [7:0] fifo_dout;

         alpide_datapath datapath(
                                  .DATA_CLK(CLK),
                                  .DATA_RST(dp_if.RST),
                                  .enable_i(1'd1),
                                  .data_i(dp_if.data_in[i]),
                                  .data_valid_i(dp_if.data_in_write[i]),
                                  .data_error_i(1'd0),
                                  .busy_o               (),
                                  .decode_error_o       (),
                                  .event_o              (),
                                  .event_error_o        (),
                                  .busy_violation_o     (),
                                  .double_busy_on_o     (),
                                  .double_busy_off_o    (),
                                  .empty_region_o       (),
                                  .idle_word_o          (),
                                  .lane_fifo_full_o     (),
                                  .lane_fifo_overflow_o (),
                                  .readout_fifo_empty_out(fifo_empty),
                                  .readout_fifo_full_out(dp_if.data_in_full[i]),
                                  .readout_fifo_rd_in(fifo_rd_en),
                                  .readout_fifo_data_out(fifo_dout)
                                  );

         data_packager#(.IS_OUTER_BARREL(OB_MODE))
         data_packager_inst(.DATA_CLK(CLK),
                            .DATA_RST(dp_if.RST),
                            .sensor_mask_i(dp_if.chip_mask[i]),
                            .timeout_i(dp_if.lane_timeout),
                            .lane_fifo_data_i(fifo_dout),
                            .lane_fifo_empty_i(fifo_empty),
                            .lane_fifo_read_o(fifo_rd_en),
                            .packaged_fifo_data_o(lane_fifo_data[i*72 +: 72]),
                            .packaged_fifo_start_o(lane_fifo_start[i]),
                            .packaged_fifo_stop_o(lane_fifo_stop[i]),
                            .packaged_fifo_timeout_o(lane_fifo_timeout[i]),
                            .packaged_fifo_valid_o(lane_fifo_valid[i]),
                            .packaged_fifo_read_i(lane_fifo_read[i])
                            );
      end // for (i = 0; i < NR_LANES; i++)
   endgenerate

   gbt_packer_error_inject#(.NR_LANES(NR_LANES),
                            .G_SEE_MITIGATION_TECHNIQUE(1),
                            .G_MISMATCH_REGISTERED(1))
   INST_gbt_packer_error_inject(.CLK(CLK),
                                .RST(dp_if.RST),
                                .lane_mask_i(dp_if.lane_mask[0 +: NR_LANES]),
                                .wait_data_timeout_i(dp_if.wait_data_timeout),
                                .send_data_timeout_i(dp_if.send_data_timeout),
                                .gbt_max_word_count_i(dp_if.gbt_max_word_count),
                                .gbt_max_packet_count_i(dp_if.gbt_max_packet_count),
                                .gbt_fee_id_i(dp_if.gbt_fee_id),
                                .gbt_priority_i(dp_if.gbt_priority),
                                .trigger_data_i(dp_if.trigger_data),
                                .trigger_empty_i(dp_if.trigger_empty),
                                .trigger_rd_o(dp_if.trigger_read),
                                .lane_fifo_data_i(lane_fifo_data),
                                .lane_fifo_start_i(lane_fifo_start),
                                .lane_fifo_stop_i(lane_fifo_stop),
                                .lane_fifo_timeout_i(lane_fifo_timeout),
                                .lane_fifo_valid_i(lane_fifo_valid),
                                .lane_fifo_read_o(lane_fifo_read),
                                .gbtx_tx_data_o(dp_if.gbtx_tx_data),
                                .gbtx_tx_datavalid_o(dp_if.gbtx_data_valid),
                                .MISMATCH(dp_if.mismatch),
                                .MISMATCH_2ND(dp_if.mismatch_2nd),
                                //Tracing/Inject Interface
                                .inject(inject_if.inject),
                                .inject_state(inject_if.inject_state),
                                .inject_td_expect_data(inject_if.inject_td_expect_data),
                                .inject_td_hb_orbit(inject_if.inject_td_hb_orbit),
                                .inject_td_hb_bc(inject_if.inject_td_hb_bc),
                                .inject_td_trigger_orbit(inject_if.inject_td_trigger_orbit),
                                .inject_td_trigger_type(inject_if.inject_td_trigger_type),
                                .inject_td_trigger_bc(inject_if.inject_td_trigger_bc),
                                .inject_wd_timeout_count(inject_if.inject_wd_timeout_count),
                                .inject_sd_timeout_count(inject_if.inject_sd_timeout_count),
                                .inject_transmission_done(inject_if.inject_transmission_done),
                                .inject_transmission_timeout(inject_if.inject_transmission_timeout),
                                .inject_tx_data(inject_if.inject_tx_data),
                                .inject_tx_datavalid(inject_if.inject_tx_datavalid),
                                .inject_lane_active(inject_if.inject_lane_active[NR_LANES-1:0]),
                                .inject_lane_starts(inject_if.inject_lane_starts[NR_LANES-1:0]),
                                .inject_lane_starts_violation(inject_if.inject_lane_starts_violation[NR_LANES-1:0]),
                                .inject_lane_timeouts(inject_if.inject_lane_timeouts[NR_LANES-1:0]),
                                .inject_lane_stops(inject_if.inject_lane_stops[NR_LANES-1:0]),
                                .inject_lane_idx(inject_if.inject_lane_idx),
                                .inject_lanes_read(inject_if.inject_lanes_read[NR_LANES-1:0]),
                                .inject_word_count(inject_if.inject_word_count),
                                .inject_packet_idx(inject_if.inject_packet_idx),
                                .current_state(inject_if.current_state),
                                .gbt_packet_done(inject_if.gbt_packet_done)
                                );

   // Check proper mismatch behaviour
   // On an inject cycle, a gbt_packet done must clear the mismatch 1 clock cycle after the signal at the latest
   default clocking aclk @(posedge CLK);
      input RST = dp_if.RST;
      input gbt_packet_done = inject_if.gbt_packet_done;
      input no_inject_cycle = inject_if.no_inject_cycle;
      input mismatch = dp_if.mismatch;
      input mismatch_2nd = dp_if.mismatch_2nd;
   endclocking // aclk

   mismatch_cleared :
     assert property(disable iff(aclk.RST !== 0)
                     aclk.no_inject_cycle==0 &&  aclk.gbt_packet_done |-> ##[0:2] aclk.mismatch == 0
                     );
   mismatch_2nd_cleared :
     assert property(disable iff(aclk.RST !== 0)
                     aclk.no_inject_cycle==0 && aclk.gbt_packet_done  |-> ##[0:2] aclk.mismatch_2nd == 0
                     );
   no_mismatch_on_ref_cycle :
     assert property(
                     disable iff(aclk.RST !== 0)
                     aclk.no_inject_cycle == 1 |-> aclk.mismatch == 0
                     );
   no_mismatch_2nd_on_ref_cycle :
     assert property(disable iff(aclk.RST !== 0)
                     aclk.no_inject_cycle == 1 |-> aclk.mismatch_2nd == 0
                     );
endmodule // test_module

module top;

   logic CLK = 0;

   always #(12.5ns) CLK=~CLK;

   localparam int OB_LANES = 28;
   localparam int IB_LANES = 9;

   event       ob_finished;
   event       ib_finished;

   test_module#(.NR_LANES(OB_LANES),.OB_MODE(1), .verbose(1)) test_ob(.CLK(CLK), .module_finished(ob_finished));
   test_module#(.NR_LANES(IB_LANES),.OB_MODE(0), .verbose(1)) test_ib(.CLK(CLK), .module_finished(ib_finished));

   // Finish simulation

   initial begin
      fork
         @(ob_finished);
         @(ib_finished);
      join
      $display("Simulation done");
      $finish;
   end
endmodule // top

// 026ac9025dc1021bb9
// d1026ac9025dc1021b
