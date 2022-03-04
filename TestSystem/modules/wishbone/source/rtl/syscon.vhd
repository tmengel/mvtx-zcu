----------------------------------------------------------------------
-- Module name:     SYC0001a.VHD
--
-- Description:     A simple WISHBONE SYSCON for FPGA.  For more infor-
--                  mation, please refer to the WISHBONE Public Domain
--                  Library Technical Reference Manual.
--
-- History:         Project complete:           SEP 20, 2001
--                                              WD Peterson
--                                              Silicore Corporation
--
-- Release:         Notice is hereby given that this document is not
--                  copyrighted, and has been placed into the public
--                  domain.  It may be freely copied and distributed
--                  by any means.
--
-- Disclaimer:      In no event shall Silicore Corporation be liable
--                  for incidental, consequential, indirect or special
--                  damages resulting from the use of this file.  The
--                  user assumes all responsibility for its use.
--
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Load the IEEE 1164 library and make it visible.
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

----------------------------------------------------------------------
-- Entity declaration.
----------------------------------------------------------------------

-- A WISHBONE module that drives the system clock [CLK_O] and reset [RST_O] signals. 
entity syscon is
  port(
    -- WISHBONE Interface
    CLK_o  : out std_logic;   -- WB clock
    RST_o  : out std_logic;   -- WB reset
    -- NON-WISHBONE Signals
    EXTCLK : in  std_logic;   -- External clock
    EXTTST : in  std_logic    -- External reset
  );
end syscon;

----------------------------------------------------------------------
-- Architecture definition.
----------------------------------------------------------------------
architecture SYC0001a1 of syscon is

  signal sDly  : std_logic;
  signal sDly2 : std_logic;
  signal sRst  : std_logic;

begin

  ------------------------------------------------------------------
  -- Reset generator.
  ------------------------------------------------------------------

  RST_GENERATOR : process(EXTCLK)
  begin
    if (rising_edge(EXTCLK)) then
      if (EXTTST = '1') then
        sDly  <= '0';
        sDly2 <= '0';
        sRst  <= '0';
      else
        sDly  <= sDly xor sDly2;
        sDly2 <= not(sDly or sDly2);
        sRst  <= not(sDly or sDly2) xor sDly2;
      end if;
    end if;

  end process RST_GENERATOR;

  ------------------------------------------------------------------
  -- Make selected signals available to the outside world.
  ------------------------------------------------------------------

  CLK_o <= EXTCLK;
  RST_o <= sRst;

end architecture SYC0001a1;
