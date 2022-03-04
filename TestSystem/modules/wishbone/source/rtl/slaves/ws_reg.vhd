-------------------------------------------------------------------------------
-- Title      : Wishbone slave register
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : ws_reg.vhd
-- Author     : Arild Velure <arild.velure@cern.ch>
-- Company    : CERN
-- Created    : 2018-01-25
-- Last update: 2018-01-25
-- Platform   : Xilinx Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright 2017 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Description: General slave register module
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
use work.intercon_pkg.all;

entity ws_reg is
  generic(
    WB_ADD_WE      : t_wbs_reg_we_array;                           -- Write enable for each register
    WB_ILLEGAL_VAL : std_logic_vector(WB_DATA_WIDTH - 1 downto 0); -- Default value for illegal register access
    WB_REG_INIT    : t_wbs_reg_array                               -- Reset value for registers
  );
  port(
    WB_CLK      : in  std_logic;            -- Wishbone clock
    WB_RST      : in  std_logic;            -- Wishbone reset
    WB_WBS_I    : in  wbs_i_type;           -- Wishbone slave input signals
    WB_WBS_O    : out wbs_o_type;           -- Wishbone slave output signals
    WBS_REG_I   : in  t_wbs_reg_array;      -- Register input 
    WBS_REG_O   : out t_wbs_reg_array       -- Register output
  );
end entity ws_reg;

architecture RTL of ws_reg is
  signal s_wb_wbs_o           : wbs_o_type;                                     -- Pre-registered output of wishbone
  signal WB_WBS_I_addr_i_int  : natural range 0 to 2**WB_WBS_I.addr_i'length-1; -- WB_WBS_I.addr_i converted to int
begin
  
  WB_WBS_I_addr_i_int <= to_integer(unsigned(WB_WBS_I.addr_i));

  -----------------------------------------------------------------------------
  -- Wishbone interface
  -----------------------------------------------------------------------------

  -- purpose: writes the wishbone register form the WB side
  g_wishbone_reg : for i in WBS_REG_I'range generate
    g_wishbone_reg_we : if ((WB_ADD_WE(i) = w) or (WB_ADD_WE(i) = rw)) generate
      p_wishbone_reg : process (WB_CLK) is
      begin
        if rising_edge(WB_CLK) then
          if (WB_RST = '1') then
            WBS_REG_O(i) <= WB_REG_INIT(i);
          else
            WBS_REG_O(i)(WBS_REG_I(i)'range) <= WBS_REG_I(i);  -- Feedback
            if ((WB_WBS_I.we_i = '1') and (WB_WBS_I.stb_i = '1') and (WB_WBS_I.cyc_i = '1') and (WB_WBS_I_addr_i_int = i)) then
              WBS_REG_O(i)(WBS_REG_I(i)'range) <= WB_WBS_I.dat_i(WBS_REG_I(i)'range);
            end if;
          end if;
        end if;
      end process p_wishbone_reg;
    end generate g_wishbone_reg_we;
    g_wishbone_reg_n_we : if not ((WB_ADD_WE(i) = w) or (WB_ADD_WE(i) = rw)) generate -- Avoid "no driver" warnings
      WBS_REG_O(i) <= WB_REG_INIT(i);
    end generate g_wishbone_reg_n_we;
  end generate g_wishbone_reg;

  -- purpose: generates the Ack and Err signals for the wishbone
  p_wishbone_answer : process (all) is
  begin
    case WB_WBS_I_addr_i_int is
      
      when WBS_REG_I'range =>
        if ((WB_WBS_I.we_i  = '1' and (WB_ADD_WE(WB_WBS_I_addr_i_int) = r)) or      -- Write to read only
           ( WB_WBS_I.we_i  = '0' and (WB_ADD_WE(WB_WBS_I_addr_i_int) = w))) then   -- Read from write only
          s_wb_wbs_o.err_o <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i;  
          s_wb_wbs_o.ack_o <= '0';
        else
          s_wb_wbs_o.err_o <= '0';
          s_wb_wbs_o.ack_o <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
        end if;
      when others =>
        s_wb_wbs_o.err_o <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i;  
        s_wb_wbs_o.ack_o <= '0';
    end case;
  end process p_wishbone_answer;

  -- Generates the data answer to the wishbone request
  p_wishbone_data : process (all) is
  begin
    s_wb_wbs_o.dat_o  <= (others  => '0');
    case WB_WBS_I_addr_i_int is
      
      when WBS_REG_I'range =>
        if (WB_ADD_WE(WB_WBS_I_addr_i_int) = w) then -- write only
          s_wb_wbs_o.dat_o <= WB_ILLEGAL_VAL;
        else
          s_wb_wbs_o.dat_o(WBS_REG_I(WB_WBS_I_addr_i_int)'range) <= WBS_REG_I(WB_WBS_I_addr_i_int);
        end if;
        
      when others =>
        s_wb_wbs_o.dat_o <= WB_ILLEGAL_VAL;
    end case;
  end process p_wishbone_data;

  -- Re-timing flop for wishbone answer
  p_retime_wishbone_output : process (WB_CLK) is
  begin
    if rising_edge(WB_CLK) then
      if (WB_RST = '1') then
        WB_WBS_O.ack_o <= '0';
        WB_WBS_O.err_o <= '0';
        WB_WBS_O.dat_o <= WB_ILLEGAL_VAL;
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
      NR_ADDRESSES => WBS_REG_I'length)
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => WB_WBS_I,
      WB_WBS_O => s_wb_wbs_o);
  -- synthesis translate on

end architecture RTL;
