//-----------------------------------------------------------------------------
// Title         : general mmr assertions
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : mmr_general_assertions.svh
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
// Created       : 02.03.2017
// Last modified : 02.03.2017
//-----------------------------------------------------------------------------
// Description :
// File containing general assert definitions. This is to be included
// in every module that is to instantiate various assertion/coverage points as deemed necessary
//  by designers.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

package mmr_general_assertions;

   // properties for multiple modular redundancy to check that is odd and that it is in the range of implementation (3,5)
   property K_MMR_is_odd (int K_MMR, bit disable_signal);
      disable iff(disable_signal)
        (K_MMR%2 == 1);
   endproperty

   property K_MMR_is_valid (int K_MMR, bit disable_signal);
      disable iff(disable_signal)
        ((K_MMR == 3)||(K_MMR == 5));
   endproperty

   property K_MMR_CLOCK_is_valid(int K_MMR_CLOCK, int K_MMR, bit disable_signal);
      disable iff(disable_signal)
        ((K_MMR_CLOCK == 1)||(K_MMR_CLOCK == K_MMR));
   endproperty

endpackage // mmr_general_assertions

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
