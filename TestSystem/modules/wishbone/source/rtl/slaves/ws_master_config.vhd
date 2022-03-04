-------------------------------------------------------------------------------
-- Title      : ws_master_config
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : ws_master_config.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-06
-- Last update: 2017-08-23
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave to be inserted inside the wishbone master wrapper
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.ws_master_pkg.all;

entity ws_master_config is
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type;          -- Wishbone slave output signals

    -- WM ERROR COUNTERs
    -- STS registers
    WBM_RDERRCNTR     : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    WBM_WRERRCNTR     : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    WBM_SEEERRCNTR    : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    -- CMD registers
    WBM_RST_WRERRCNT  : out std_logic;
    WBM_RST_RDERRCNT  : out std_logic;
    WBM_RST_SEEERRCNT : out std_logic;
    -- MISMATCH
    MISMATCH_I        : in  std_logic_vector(C_WBMSTR_MISMATCH_WIDTH-1 downto 0)
    );

end ws_master_config;

architecture str of ws_master_config is

  -- wishbone signal for reading
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  -----------------------------------------------------------------------------
  -- Wishbone interface
  -----------------------------------------------------------------------------

  -- purpose: writes the wishbone register form the WB side
  p_wishbone_reg : process (WB_CLK) is
  begin  -- process p_wishbone_reg
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        WBM_RST_RDERRCNT  <= '0';
        WBM_RST_WRERRCNT  <= '0';
        WBM_RST_SEEERRCNT <= '0';
      else
        if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
          case WB_WBS_I.addr_i is

            when WB_ADD.RST_WBM_CNTR =>  -- Write/Read register
              WBM_RST_RDERRCNT  <= WB_WBS_I.dat_i(C_WBM_RST_bit_RDERRCNT);
              WBM_RST_WRERRCNT  <= WB_WBS_I.dat_i(C_WBM_RST_bit_WRERRCNT);
              WBM_RST_SEEERRCNT <= WB_WBS_I.dat_i(C_WBM_RST_bit_SEEERRCNT);

            when others =>
              null;

          end case;

        else                            -- pulse signals
          WBM_RST_RDERRCNT  <= '0';
          WBM_RST_WRERRCNT  <= '0';
          WBM_RST_SEEERRCNT <= '0';
        end if;
      end if;
    end if;
  end process p_wishbone_reg;

  -- purpose: generates the Ack and Err signals for the wishbone
  p_wishbone_answer : process (WB_CLK) is
    variable v_ack_o, v_err_o : std_logic;
  begin  -- process p_wishbone_answer
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        s_wb_wbs_o.ack_o <= '0';
        s_wb_wbs_o.err_o <= '0';
      else

        case WB_WBS_I.addr_i is

          when WB_ADD.RST_WBM_CNTR =>   -- Write only registers
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_WBM_RDERRCNTR =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_WBM_WRERRCNTR =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_WBM_SEEERRCNTR =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.MISMATCH =>       -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when others =>
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;  -- read or write to an illegal address
            v_ack_o := '0';

        end case;
        s_wb_wbs_o.ack_o <= v_ack_o;
        s_wb_wbs_o.err_o <= v_err_o;
      end if;
    end if;
  end process p_wishbone_answer;

  -- purpose: generates the data answer to the wishbone request
  p_wishbone_data : process (WB_WBS_I,
                             WBM_RDERRCNTR, WBM_WRERRCNTR, WBM_SEEERRCNTR,
                             MISMATCH_I) is
  begin  -- process p_wishbone_data
    case WB_WBS_I.addr_i is

      when WB_ADD.READ_WBM_RDERRCNTR =>   -- Read only error
        s_wb_wbs_o.dat_o <= WBM_RDERRCNTR;
      when WB_ADD.READ_WBM_WRERRCNTR =>   -- Read only error
        s_wb_wbs_o.dat_o <= WBM_WRERRCNTR;
      when WB_ADD.READ_WBM_SEEERRCNTR =>  -- Read only error
        s_wb_wbs_o.dat_o <= WBM_SEEERRCNTR;

      when WB_ADD.MISMATCH =>           -- Read only error
        s_wb_wbs_o.dat_o                                     <= (others => '0');
        s_wb_wbs_o.dat_o(C_WBMSTR_MISMATCH_WIDTH-1 downto 0) <= MISMATCH_I;

      when others =>
        s_wb_wbs_o.dat_o <= x"DEAD";
    end case;
  end process p_wishbone_data;

  -- purpose: retiming flop for wishbone answer
  -- type   : sequential
  p_retime_wishbone_output : process (WB_CLK) is
  begin  -- process p_retime_wishbone_output
    if rising_edge(WB_CLK) then         -- rising clock edge
      if WB_RST = '1' then      -- synchronous reset (active high)
        WB_WBS_O.ack_o <= '0';
        WB_WBS_O.err_o <= '0';
        WB_WBS_O.dat_o <= x"DEAD";
      else
        WB_WBS_O <= s_wb_wbs_o;
      end if;
    end if;
  end process p_retime_wishbone_output;


  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  -- synthesis translate off
  INST_wishbone_slave_checker : entity work.wishbone_slave_checker
    generic map (
      NR_ADDRESSES => to_integer(unsigned(WB_ADD.NUM_REGS)))
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => WB_WBS_I,
      WB_WBS_O => s_wb_wbs_o);
  -- synthesis translate on

end architecture str;
