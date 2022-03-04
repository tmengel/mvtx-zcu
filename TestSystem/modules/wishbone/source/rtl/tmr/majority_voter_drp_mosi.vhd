-------------------------------------------------------------------------------
-- Title      : Majority Voter for DRP interface
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : wishbone_drp_bridge_tmr_wrapper.vhd
-- Author     : Emanuele Canessa <e.canessa@cern.ch>
-- Company    : CERN / Politecnico di Torino
-- Created    : 2017-10-16
-- Last update: 2017-11-02
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Dynamic Reconfiguration Port (MOSI) Voter
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Rev  Author  Description
-- 2017-10-16  1.0  EC      Initial relase
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library work;
use work.drp_pkg.all;
use work.tmr_pkg.all;

entity majority_voter_drp_mosi is
  generic (
    MISMATCH_EN           : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0;
    G_ADDITIONAL_MISMATCH : integer := 1
  );
  port (
    ASSERTION_CLK         : in    std_logic;
    ASSERTION_RST         : in    std_logic;
    INPUT                 : in    drp_mosi_array_type (0 to C_K_TMR-1);
    OUTPUT                : out   drp_mosi_type;
    MISMATCH              : out   std_logic;
    MISMATCH_2ND          : out   std_logic
  );
  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of majority_voter_drp_mosi : entity is "TRUE";
end entity; -- majority_voter_drp_mosi

architecture rtl of majority_voter_drp_mosi is

  signal sDen  : std_logic_vector    (0 to C_K_TMR-1);
  signal sDwe  : std_logic_vector    (0 to C_K_TMR-1);
  signal sAddr : drp_addr_array_type (0 to C_K_TMR-1);
  signal sDi   : drp_di_array_type   (0 to C_K_TMR-1);

  signal sMismatchDen1  : std_logic;
  signal sMismatchDen2  : std_logic;
  signal sMismatchDwe1  : std_logic;
  signal sMismatchDwe2  : std_logic;
  signal sMismatchAddr1 : std_logic;
  signal sMismatchAddr2 : std_logic;
  signal sMismatchDi1   : std_logic;
  signal sMismatchDi2   : std_logic;

begin

  gen_assign_signals : for i in 0 to C_K_TMR-1 generate
    sDen(i)        <= INPUT(i).den;
    sDwe(i)        <= INPUT(i).dwe;
    sAddr(i)       <= INPUT(i).addr;
    sDi(i)         <= INPUT(i).di;
  end generate; -- gen_assign_signals

  DEN_VOTER_inst : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH
    )
    port map (
      ASSERTION_CLK         => ASSERTION_CLK,
      ASSERTION_RST         => ASSERTION_RST,
      INPUT                 => sDen,
      OUTPUT                => OUTPUT.den,
      MISMATCH              => sMismatchDen1,
      MISMATCH_2ND          => sMismatchDen2
    );

  DWE_VOTER_inst : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH
    )
    port map (
      ASSERTION_CLK         => ASSERTION_CLK,
      ASSERTION_RST         => ASSERTION_RST,
      INPUT                 => sDwe,
      OUTPUT                => OUTPUT.dwe,
      MISMATCH              => sMismatchDwe1,
      MISMATCH_2ND          => sMismatchDwe2
    );

  ADDR_VOTER_inst : entity work.majority_voter_array_wrapper
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      C_WIDTH               => DRP_ADDR_WIDTH
    )
    port map (
      ASSERTION_CLK         => ASSERTION_CLK,
      ASSERTION_RST         => ASSERTION_RST,
      INPUT_A               => sAddr(0),
      INPUT_B               => sAddr(1),
      INPUT_C               => sAddr(2),
      OUTPUT                => OUTPUT.addr,
      MISMATCH              => sMismatchAddr1,
      MISMATCH_2ND          => sMismatchAddr2
    );

  DI_VOTER_inst : entity work.majority_voter_array_wrapper
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      C_WIDTH               => DRP_DATA_WIDTH
    )
    port map (
      ASSERTION_CLK         => ASSERTION_CLK,
      ASSERTION_RST         => ASSERTION_RST,
      INPUT_A               => sDi(0),
      INPUT_B               => sDi(1),
      INPUT_C               => sDi(2),
      OUTPUT                => OUTPUT.di,
      MISMATCH              => sMismatchDi1,
      MISMATCH_2ND          => sMismatchDi2
    );

  MISMATCH <= sMismatchDen1 or sMismatchDwe1 or sMismatchAddr1 or sMismatchDi1;

  if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
    MISMATCH_2ND <= sMismatchDen2 or sMismatchDwe2 or sMismatchAddr2 or
                    sMismatchDi2;
  end generate; -- if_add_mismatch_gen

  if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
    MISMATCH_2ND <= '0';
  end generate; -- if_not_add_mismatch_gen

end architecture; -- rtl
