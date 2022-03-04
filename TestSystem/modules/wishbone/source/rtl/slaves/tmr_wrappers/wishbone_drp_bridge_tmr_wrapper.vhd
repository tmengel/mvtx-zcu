-------------------------------------------------------------------------------
-- Title      : Wishbone to TMR DRP Bridge
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : wishbone_drp_bridge_tmr_wrapper.vhd
-- Author     : Emanuele Canessa <e.canessa@cern.ch>
-- Company    : CERN / Politecnico di Torino
-- Created    : 2017-10-12
-- Last update: 2017-11-02
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Standard template for a TMR Wisbone slave to DRP bridge.
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Rev  Author  Description
-- 2017-10-13  1.0  EC      Initial relase
-- 2017-10-18  1.1  EC      Vote the internal status of the FSMs
-- 2017-10-20  1.2  EC      Added mismatch signals
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library WORK;
use WORK.intercon_pkg.all;
use WORK.drp_pkg.all;
use WORK.tmr_pkg.all;

entity wishbone_drp_bridge_tmr_wrapper is
  generic (
    MISMATCH_EN           : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0;
    G_ADDITIONAL_MISMATCH : integer := 1
  );
  port (
    -- Wishbone Ports
    WB_CLK       : in    std_logic;
    WB_RST       : in    std_logic;
    WB_WBS_I     : in    t_wbs_i_array (0 to C_K_TMR-1);
    WB_WBS_O     : out   t_wbs_o_array (0 to C_K_TMR-1);
    -- Dynamic Reconfiguration Ports
    DRP_DCLK     : out   std_logic;
    DRP_MOSI     : out   drp_mosi_type;
    DRP_MISO     : in    drp_miso_type;
    -- Mismatch Ports
    MISMATCH     : out   std_logic;
    MISMATCH_2ND : out   std_logic
  );
  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of wishbone_drp_bridge_tmr_wrapper : entity is "TRUE";
end entity; -- wishbone_drp_bridge_tmr_wrapper

architecture structural of wishbone_drp_bridge_tmr_wrapper is

  constant C_STATE_BITSIZE : integer := 3;

  signal sWbsTmrIn   : t_wbs_i_array (0 to C_K_TMR-1);
  signal sWbsTmrOut  : t_wbs_o_array (0 to C_K_TMR-1);
  signal sDrpTmrMosi : drp_mosi_array_type (0 to C_K_TMR-1);
  signal sDrpTmrMiso : drp_miso_array_type (0 to C_K_TMR-1);

  type t_state_array is array (0 to C_K_TMR-1) of std_logic_vector (C_STATE_BITSIZE-1 downto 0);
  signal sStateI : t_state_array;
  signal sStateO : t_state_array;

  signal sMismatchWbsI1 : std_logic;
  signal sMismatchWbsI2 : std_logic;
  signal sMismatchWbsO1 : std_logic;
  signal sMismatchWbsO2 : std_logic;
  signal sMismatchDrpO1 : std_logic;
  signal sMismatchDrpO2 : std_logic;
  signal sMismatchStat1 : std_logic;
  signal sMismatchStat2 : std_logic;

  signal sMismatch1     : std_logic;
  signal sMismatch2     : std_logic;

begin

  MISMATCH     <= sMismatch1;
  MISMATCH_2ND <= sMismatch2;

  WBS_IN_VOTER_inst : entity work.majority_voter_triplicated_wbs_i
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED
    )
    port map (
      ASSERTION_CLK         => WB_CLK,
      ASSERTION_RST         => WB_RST,
      INPUT                 => WB_WBS_I,
      OUTPUT                => sWbsTmrIn,
      MISMATCH              => sMismatchWbsI1,
      MISMATCH_2ND          => sMismatchWbsI2
    );

  WBS_OUT_VOTER_inst : entity work.majority_voter_triplicated_wbs_o
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED
    )
    port map (
      ASSERTION_CLK         => WB_CLK,
      ASSERTION_RST         => WB_RST,
      INPUT                 => sWbsTmrOut,
      OUTPUT                => WB_WBS_O,
      MISMATCH              => sMismatchWbsO1,
      MISMATCH_2ND          => sMismatchWbsO2
    );

  DRP_MOSI_VOTER_inst : entity work.majority_voter_drp_mosi
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH
    )
    port map (
      ASSERTION_CLK         => WB_CLK,
      ASSERTION_RST         => WB_RST,
      INPUT                 => sDrpTmrMosi,
      OUTPUT                => DRP_MOSI,
      MISMATCH              => sMismatchDrpO1,
      MISMATCH_2ND          => sMismatchDrpO2
    );

  DRP_DCLK <= WB_CLK; -- Clock is not voted

  gen_wb_drp_slaves : for i in 0 to C_K_TMR-1 generate
    WB_DRP_BRIDGE_inst : entity work.wishbone_drp_bridge
      generic map (
        G_STATE_BITSIZE => C_STATE_BITSIZE
      )
      port map (
        WB_CLK          => WB_CLK,
        WB_RST          => WB_RST,
        WB_WBS_I        => sWbsTmrIn(i),
        WB_WBS_O        => sWbsTmrOut(i),
        DRP_DCLK        => open, -- Clock is not voted
        DRP_MOSI        => sDrpTmrMosi(i),
        DRP_MISO        => DRP_MISO,
        STATE_I         => sStateI(i),
        STATE_O         => sStateO(i),
        MISMATCH        => sMismatch1,
        MISMATCH_2ND    => sMismatch2
      );

    STATE_VOTER_inst : entity work.majority_voter_array_wrapper
      generic map (
        MISMATCH_EN           => MISMATCH_EN,
        G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
        C_WIDTH               => C_STATE_BITSIZE
      )
      port map (
        ASSERTION_CLK         => WB_CLK,
        ASSERTION_RST         => WB_RST,
        INPUT_A               => sStateO(0),
        INPUT_B               => sStateO(1),
        INPUT_C               => sStateO(2),
        OUTPUT                => sStateI(i),
        MISMATCH              => sMismatchStat1,
        MISMATCH_2ND          => sMismatchStat2
      );
  end generate; -- gen_wb_drp_slaves

  sMismatch1 <= sMismatchWbsI1 or sMismatchWbsO1 or sMismatchDrpO1 or
                sMismatchStat1;

  if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
    sMismatch2 <= sMismatchWbsI2 or sMismatchWbsO2 or sMismatchDrpO2 or
                  sMismatchStat2;
  end generate; -- if_add_mismatch_gen

  if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
    sMismatch2 <= '0';
  end generate; -- if_not_add_mismatch_gen

end architecture; -- structural
