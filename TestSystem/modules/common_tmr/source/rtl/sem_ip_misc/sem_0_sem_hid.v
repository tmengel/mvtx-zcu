/////////////////////////////////////////////////////////////////////////////
//
//
//
/////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /
// \   \   \/    Core:          sem
//  \   \        Module:        sem_0_sem_hid
//  /   /        Filename:      sem_0_sem_hid.v
// /___/   /\    Purpose:       HID Shim using Vivado Lab Tools components.
// \   \  /  \
//  \___\/\___\
//
/////////////////////////////////////////////////////////////////////////////
//
// (c) Copyright 2010 - 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 
//
/////////////////////////////////////////////////////////////////////////////
//
// Module Description:
//
// This module contains instances of Virtual Input/Output (VIO) cores to enable 
// interactive injection of errors and observation of status.
//
/////////////////////////////////////////////////////////////////////////////
//
// Port Definition:
//
// Name                          Type   Description
// ============================= ====== ====================================
// icap_clk                      input  The system clock signal.
//
// status_heartbeat              input  Heartbeat signal for external watch
//                                      dog timer implementation; pulses
//                                      when readback runs.  Synchronous to
//                                      icap_clk.
//
// status_initialization         input  Indicates initialization is taking
//                                      place.  Synchronous to icap_clk.
//
// status_observation            input  Indicates observation is taking
//                                      place.  Synchronous to icap_clk.
//
// status_correction             input  Indicates correction is taking
//                                      place.  Synchronous to icap_clk.
//
// status_classification         input  Indicates classification is taking
//                                      place.  Synchronous to icap_clk.
//
// status_injection              input  Indicates injection is taking
//                                      place.  Synchronous to icap_clk.
//
// status_essential              input  Indicates essential error condition.
//                                      Qualified by de-assertion of the
//                                      status_classification signal, and
//                                      is synchronous to icap_clk.
//
// status_uncorrectable          input  Indicates uncorrectable error
//                                      condition. Qualified by de-assertion
//                                      of the status_correction signal, and
//                                      is synchronous to icap_clk.
//
// inject_strobe                 output Error injection port strobe used
//                                      by the controller to enable capture
//                                      of the error injection address.
//                                      Synchronous to icap_clk.
//
// inject_address[39:0]          output Error injection port address used
//                                      to specify the location of a bit
//                                      to be corrupted.  Synchronous to
//                                      icap_clk.
//
/////////////////////////////////////////////////////////////////////////////
//
// Parameter and Localparam Definition:
//
// Name                          Type   Description
// ============================= ====== ====================================
// TCQ                           int    Sets the clock-to-out for behavioral
//                                      descriptions of sequential logic.
//
/////////////////////////////////////////////////////////////////////////////
//
// Module Dependencies:
//
// sem_0_sem_hid
// |
// \- sem_0_sem_vio
//
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

/////////////////////////////////////////////////////////////////////////////
// Module
/////////////////////////////////////////////////////////////////////////////

module sem_0_sem_hid (
  (* mark_debug = "true" *) input wire          icap_clk,
  (* mark_debug = "true" *) input wire          status_heartbeat,
  (* mark_debug = "true" *) input wire          status_initialization,
  (* mark_debug = "true" *) input wire          status_observation,
  (* mark_debug = "true" *) input wire          status_correction,
  (* mark_debug = "true" *) input wire          status_classification,
  (* mark_debug = "true" *) input wire          status_injection,
  (* mark_debug = "true" *) input wire          status_essential,
  (* mark_debug = "true" *) input wire          status_uncorrectable,
                            output wire         inject_strobe,
                            output wire  [39:0] inject_address
  );

  ///////////////////////////////////////////////////////////////////////////
  // Define local constants.
  ///////////////////////////////////////////////////////////////////////////

  localparam TCQ = 1;


  ///////////////////////////////////////////////////////////////////////////
  // Define local output wires for debugging
  ///////////////////////////////////////////////////////////////////////////  
  
  (* mark_debug = "true" *) wire         inject_strobe_internal;
  (* mark_debug = "true" *) wire  [39:0] inject_address_internal;
  
  ///////////////////////////////////////////////////////////////////////////
  // Create a 1-cycle pulse from the VIO inject_strobe output to ensure a 
  // single error injection command is issued to the SEM controller. 
  ///////////////////////////////////////////////////////////////////////////  
  
  reg previous_inject_strobe_internal = 1'b0;
  
  always @(posedge icap_clk) begin
    previous_inject_strobe_internal <= #TCQ inject_strobe_internal;
  end
  
  assign inject_strobe  = !inject_strobe_internal && 
			    previous_inject_strobe_internal;
  assign inject_address = inject_address_internal;
  
  
  ///////////////////////////////////////////////////////////////////////////
  // Instantiate the SEM VIO core
  ///////////////////////////////////////////////////////////////////////////
  sem_0_sem_vio example_vio (
    .clk(icap_clk),                
    .probe_in0(status_heartbeat),  
    .probe_in1(status_uncorrectable),  
    .probe_in2(status_essential),  
    .probe_in3(status_injection),  
    .probe_in4(status_classification),  
    .probe_in5(status_correction),  
    .probe_in6(status_observation),  
    .probe_in7(status_initialization),  
    .probe_out0(inject_strobe_internal),    
    .probe_out1(inject_address_internal)    		       
  );
 
  ///////////////////////////////////////////////////////////////////////////
  //
  ///////////////////////////////////////////////////////////////////////////

endmodule

/////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////
