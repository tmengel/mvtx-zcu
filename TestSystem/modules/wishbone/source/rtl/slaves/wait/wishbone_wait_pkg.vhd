-------------------------------------------------------------------------------
-- Title      : wishone_wait_pkg
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : wishbone_wait_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-10-08
-- Last update: 2017-10-08
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
--
-- This file is part of Control Management Unit RTL.
-- Control Management Unit RTL is free software: you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, version 3 of the License.
-- Control Management Unit RTL is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details.
-- You should have received a copy of the GNU Lesser General Public License
-- along with Control Management Unit RTL.
-- If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

package wishbone_wait_pkg is

  -- Mapping of WB Registers
  type t_WB_ADDS is record
    WAIT_VALUE                       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    RST_CTRL_CNTRS                   : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_WAIT_EXEC_CNTR              : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    NUM_REGS                         : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record;

  constant WB_ADD : t_WB_ADDS := (WAIT_VALUE                       => x"00",
                                  RST_CTRL_CNTRS                   => x"01",
                                  READ_WAIT_EXEC_CNTR              => x"02",
                                  NUM_REGS                         => x"03"
                                  );

  -- counter reset control bit mapping
  constant C_RST_CTRL_CNTRS_bit_wait_exec        : integer := 0;

  -- WAIT_VALUE
  constant C_WAIT_DEFAULT_VALUE : std_logic_vector(WB_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, WB_DATA_WIDTH));

  -----------------------------------------------------------------------------
  -- Counters
  -----------------------------------------------------------------------------

  type t_wishbone_wait_counters_value is record
    wait_executed    : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  end record t_wishbone_wait_counters_value;

  -----------------------------------------------------------------------------
  -- Wishbibe registers definition
  -----------------------------------------------------------------------------

  type t_wb_wait is record
    ongoing : std_logic;
    value   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  end record;

  type t_wb_counters is record
    rst   : std_logic;
  end record;

  type t_wait_ws_reg is record
    wait_mod        : t_wb_wait;
    counters        : t_wb_counters;
  end record;

  constant C_WAIT_DEFAULT : t_wb_wait := (ongoing => '0',
                                          value   => C_WAIT_DEFAULT_VALUE);

  constant C_COUNTERS_CMD_DEFAULT : std_logic := '0';

  constant C_COUNTERS_DEFAULT : t_wb_counters := (rst   => C_COUNTERS_CMD_DEFAULT);
  
  constant C_WB_ASSIGN_DEFAULT : t_wait_ws_reg := ( wait_mod => C_WAIT_DEFAULT, 
                                                    counters => C_COUNTERS_DEFAULT
                                                  );

end package wishbone_wait_pkg;

package body wishbone_wait_pkg is
end package body wishbone_wait_pkg;
