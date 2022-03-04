-------------------------------------------------------------------------------
-- Title      : Radiation monitor single module
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : radiation monitor single module.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-10-21
-- Last update: 2017-11-02
-- Platform   : Vivado 2016.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Radiation monitor for a single module,
--              Multiple channels for each module
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.radiation_monitor_pkg.all;

entity radiation_monitor_single_module is
  generic (
    G_MODULE_MISMATCH_WIDTH : integer := 4;
    G_COUNTER_IS_SATURATING : integer := 0
    );
  port (
    CLK_I      : in  std_logic;
    RST_I      : in  std_logic;
    MISMATCH_I : in  std_logic_vector(G_MODULE_MISMATCH_WIDTH-1 downto 0);
    COUNTER_O  : out t_radmon_cntr_array(G_MODULE_MISMATCH_WIDTH-1 downto 0)
    );
end entity radiation_monitor_single_module;

architecture Behavior of radiation_monitor_single_module is

  component radiation_monitor_single_channel
    generic (
      G_COUNTER_WIDTH         : integer := 8;  -- output array size
      G_COUNTER_IS_SATURATING : integer := 0
      );
    port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      mismatch_i : in  std_logic;
      counter_o  : out std_logic_vector(G_COUNTER_WIDTH-1 downto 0)
      );
  end component;

begin

  for_module_gen : for i in G_MODULE_MISMATCH_WIDTH-1 downto 0 generate
    radiation_monitor_single_channel_INST : radiation_monitor_single_channel
      generic map (
        G_COUNTER_WIDTH         => C_COUNTER_WIDTH,
        G_COUNTER_IS_SATURATING => G_COUNTER_IS_SATURATING
        )
      port map (
        clk_i      => CLK_I,
        rst_i      => RST_I,
        mismatch_i => MISMATCH_I(i),
        counter_o  => COUNTER_O(i)
        );
  end generate for_module_gen;

end architecture Behavior;
