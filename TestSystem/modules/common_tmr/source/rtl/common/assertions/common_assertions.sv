// =============================================================================
// Title      : ALPIDE Lightweight Simulation Model
// Project    : Upgrade of ALICE Inner Tracking System, ALICE Collaboration
// =============================================================================
// File       :  common_assertions.sv
// Author     : Svetlomir Hristozkov <svetlomir.hristozkov@cern.ch>
// =============================================================================
// Copyright (c) 2016 CERN and INFN and CEA-IRFU.
//
// This file is part of ALPIDE Lightweight Simulation Model.
// ALPIDE Lightweight Simulation Model is free software: it is distributed
// under the terms of the GNU Lesser General Public License Version 3
// (LGPL Version 3) as published by the Free Software Foundation and
// copied verbatim in files "COPYING.LESSER.LGPLv3" and "COPYING.GPLv3".
//
// In applying this licence, CERN does not waive the privileges and
// immunities granted to it by virtue of its status as an
// Intergovernmental Organization or submit itself to any jurisdiction.
//
// ALPIDE Lightweight Simulation Model is distributed in the hope that it
// will be useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Lesser General Public License for more details.
// You should have received a verbatim copy of the GNU Lesser General
// Public License Version 3 along with ALPIDE Lightweight Simulation Model.
// If not, see <http://www.gnu.org/licenses/>.
// =============================================================================


/* -- Description: File containing general assert definitions. This is to be included
 in every module that is to instantiate various assertion/coverage points as deemed necessary
 by designers.
 */

package common_assertions;


   // Property to assert/cover cases where two signals are asserted sequentially with the input delay specified. If
   // the input delay is not observed and the second signal is asserted earlier/later than the exact delay specified,
   // the assertion fails or the coverage is not triggered.
   property two_signals_programmable_delay(bit first_signal, bit second_signal, bit [2:0] delay, bit disable_signal);
      bit [2:0] sampled_delay;
      disable iff (disable_signal)
      ($rose(first_signal), sampled_delay = delay) |-> first_match((!second_signal, sampled_delay -= 1'b1)[*0:$] ##1 sampled_delay == 0) ##0 $rose(second_signal);
   endproperty

   // Property to ensure/cover that two signals are never sequentially asserted with exactly the input delay specified.
   property two_signals_illegal_delay(bit first_signal, bit second_signal, bit [2:0] delay, bit disable_signal);
      bit [2:0] sampled_delay;
      disable iff (disable_signal)
      ($rose(first_signal), sampled_delay = delay) |-> first_match((!second_signal, sampled_delay -= 1'b1)[*0:$] ##1 sampled_delay == 0) ##0 !second_signal;
   endproperty

   // A property to ensure that if A is asserted, then B is asserted, always.
   property two_signals_if_first_then_second(bit first_signal, bit second_signal, bit disable_signal);
      disable iff (disable_signal)
	(first_signal == 1) |-> (second_signal == 1);
   endproperty


   // A property to verify that a signal is a delayed version of another. For convention, second signal will be the delayed version of first signal with programmable delay.
   // The assertion triggers on changing of the first input (first_signal). The value of this input is then latched in the observed region of the scheduler so that the correct new value is taken
   // After a programmable delay it is checked that the latched value of the  original signal matches the second signal.
   // There is no intermediate checking
   property first_signal_delayed_version_of_second_signal_programmable_delay(bit first_signal, second_signal, bit [2:0] delay, bit disable_signal);
      bit [2:0] count_delay;
      bit 	latch_first_signal;
      disable iff (disable_signal)
	($changed(first_signal), count_delay = delay) |-> 1 ##0 (1, latch_first_signal =  first_signal) ##0 first_match((1, count_delay -= 1'b1)[*0:$] ##1 count_delay ==0) ##0 second_signal == latch_first_signal;
   endproperty


   // Property to cover/assert that a given signal has the duration specified.
   // Property fires on posedge of cmu_trigger at which point the current value of the trigger delay
   // variable is sampled into a local variable "sampled_delay".
   // The implication operator ensures that for the next sampled_delay cycles,
   //  fromu_trigger remains low and only rises once the programmed delay has passed.
   // If the assertion fires at time T0, we need the sampled_delay variable to be 0 at time T0 + (delay - 1) * clk_period.
   property check_duration_single_bit_exact(bit line, bit [15:0] duration, bit disable_signal);
      int 	sampled_delay;
      disable iff (disable_signal)
	  ($rose(line) & duration>0, sampled_delay = duration-1'b1) |=> first_match(( $stable(line), sampled_delay = (sampled_delay - 1'b1))[*0:$] ##1 sampled_delay == 0) ##0  $fell(line);
   endproperty


   // Property to cover/assert that a given signal has been active at least for the duration specified during a single pulse.
   property check_duration_single_bit_atleast(bit line, bit [15:0] duration, bit disable_signal);
      int 	sampled_delay;
      disable iff (disable_signal)
	($rose(line) & duration > 0, sampled_delay = duration-1'b1) |=> first_match(( $stable(line), sampled_delay = (sampled_delay - 1'b1))[*0:$] ##0 sampled_delay == 0) ##0  $stable(line);
   endproperty

endpackage // common_assertions
