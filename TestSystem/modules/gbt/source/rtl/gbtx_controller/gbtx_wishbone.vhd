-------------------------------------------------------------------------------
-- Title      : GBTx wishbone
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : gbtx_wishbone.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Author     : J. Schambach (Joachim.Schambach@cern.ch
-- Company    : University of Texas at Austin
-- Created    : 2017-07-25
-- Last update: 2018-10-11
-- Platform   : CERN OS7, Xilinx Vivado 2017.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone connection for controlling the gbtx_controller
--
--              The generic G_SEE_HARDENING_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter (not implemented)
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library work;
use work.intercon_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;
use work.xpm_cdc_components_pkg.all;

entity gbtx_wishbone is
  port (
    WB_CLK                 : in  std_logic;
    WB_RST                 : in  std_logic;
    --
    --GBTx handler interface (WB CLK)
    GBTX_CONTROLLER_ENABLE : out std_logic;
    RST_GBTX_n             : out std_logic;
    IDELAY_VALUES          : out t_idelay_values;
    IDELAY_READ_VALUES     : in  t_idelay_values;
    IDELAY_LOAD            : out std_logic;
    BITSLIP_RX_VALUE       : out std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_TX_VALUE       : out std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_LOAD           : out std_logic;
    TX_PATTERN_SELECTION   : out std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    TX1_PATTERN_SELECTION  : out std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    GBTX_RXRDY             : in  std_logic;
    -- wishbone registers
    WISHBONE_REGISTERS_I : in  t_wishbone_registers;
    WISHBONE_REGISTERS_O : out t_wishbone_registers
    );
end entity gbtx_wishbone;

architecture structural of gbtx_wishbone is

  -- wishbone
  signal s_wishbone_registers, s_wishbone_registers_voted : t_wishbone_registers;

  signal WB_WBS_I : wbs_i_type;
  signal WB_WBS_O : wbs_o_type;

  signal s_idelay_read_values_retiming : t_idelay_values;

  signal sRxRdyLostFlag    : std_logic;
  signal sRxRdyLostFlagRst : std_logic;
  signal sRxRdy_sync       : std_logic;

  signal s_wbs_reg_i : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Read registers
  signal s_wbs_reg_o : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Write registers

begin  -- architecture structural

  -----------------------------------------------------------------------------
  -- Assigns output
  -----------------------------------------------------------------------------
  GBTX_CONTROLLER_ENABLE <= s_wishbone_registers.gbtx_controller_enable;
  RST_GBTX_n             <= s_wishbone_registers.gbtx_reset_n;
  IDELAY_VALUES          <= s_wishbone_registers.idelay_values;
  IDELAY_LOAD            <= s_wishbone_registers.idelay_load;
  BITSLIP_RX_VALUE       <= s_wishbone_registers.bitslip_rx_value;
  BITSLIP_TX_VALUE       <= s_wishbone_registers.bitslip_tx_value;
  BITSLIP_LOAD           <= s_wishbone_registers.bitslip_load;
  TX_PATTERN_SELECTION   <= s_wishbone_registers.tx_pattern_selection;
  TX1_PATTERN_SELECTION  <= s_wishbone_registers.tx1_pattern_selection;
  WISHBONE_REGISTERS_O   <= s_wishbone_registers;

  -----------------------------------------------------------------------------
  -- Input assignement
  -----------------------------------------------------------------------------
  s_wishbone_registers_voted <= WISHBONE_REGISTERS_I;

  -----------------------------------------------------------------------------
  -- Read and write registers to be passed to the wishbone register module
  -----------------------------------------------------------------------------
  p_wishbone_data : process (s_wbs_reg_o, 
                             s_wishbone_registers_voted, s_idelay_read_values_retiming,
                             sRxRdyLostFlag) is
  begin  -- process p_wishbone_data
    s_wbs_reg_i <= (others => x"0000");  -- initialize all bits to 0

    -- Read
    s_wbs_reg_i(WB_ADD'pos(A_RXRDY_LOST_FLAG))   <= wb_resize_bit(sRxRdyLostFlag, C_RXRDY_LOST_FLAG_bit);
    s_wbs_reg_i(WB_ADD'pos(A_MISMATCH))          <= (others => '0');
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE0)) <= wb_resize(s_idelay_read_values_retiming(0));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE1)) <= wb_resize(s_idelay_read_values_retiming(1));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE2)) <= wb_resize(s_idelay_read_values_retiming(2));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE3)) <= wb_resize(s_idelay_read_values_retiming(3));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE4)) <= wb_resize(s_idelay_read_values_retiming(4));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE5)) <= wb_resize(s_idelay_read_values_retiming(5));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE6)) <= wb_resize(s_idelay_read_values_retiming(6));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE7)) <= wb_resize(s_idelay_read_values_retiming(7));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE8)) <= wb_resize(s_idelay_read_values_retiming(8));
    s_wbs_reg_i(WB_ADD'pos(A_GET_IDELAY_VALUE9)) <= wb_resize(s_idelay_read_values_retiming(9));

    -- Write
    s_wishbone_registers.gbtx_controller_enable <= s_wbs_reg_o(WB_ADD'pos(A_GBTX_CONTROLLER_ENABLE))(C_GBTX_CONTROLLER_ENABLE_bit);
    s_wishbone_registers.gbtx_reset_n           <= s_wbs_reg_o(WB_ADD'pos(A_GBTX_RESET))(C_GBTX_RESET_bit);
    s_wishbone_registers.idelay_values(0)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE0))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(1)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE1))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(2)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE2))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(3)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE3))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(4)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE4))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(5)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE5))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(6)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE6))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(7)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE7))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(8)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE8))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.idelay_values(9)       <= s_wbs_reg_o(WB_ADD'pos(A_SET_IDELAY_VALUE9))(C_IDELAY_VALUE_bit'range);
    s_wishbone_registers.bitslip_rx_value       <= s_wbs_reg_o(WB_ADD'pos(A_BITSLIP_RX_VALUE))(C_BITSLIP_VALUE_bit'range);
    s_wishbone_registers.bitslip_tx_value       <= s_wbs_reg_o(WB_ADD'pos(A_BITSLIP_TX_VALUE))(C_BITSLIP_VALUE_bit'range);
    s_wishbone_registers.tx_pattern_selection   <= s_wbs_reg_o(WB_ADD'pos(A_TX_PATTERN_SELECTION))(C_TX_PATTERN_SELECTION_bit'range);
    s_wishbone_registers.tx1_pattern_selection  <= s_wbs_reg_o(WB_ADD'pos(A_TX_PATTERN_SELECTION))(C_TX_PATTERN_SELECTION_bit'range);
    s_wishbone_registers.idelay_load            <= s_wbs_reg_o(WB_ADD'pos(A_IDELAY_LOAD))(C_IDELAY_LOAD_bit);
    s_wishbone_registers.bitslip_load           <= s_wbs_reg_o(WB_ADD'pos(A_BITSLIP_LOAD))(C_BITSLIP_LOAD_bit);
    sRxRdyLostFlagRst                           <= s_wbs_reg_o(WB_ADD'pos(A_RXRDY_LOST_FLAG))(C_RXRDY_LOST_FLAG_RST_bit);

    -- Write feedback
    s_wbs_reg_i(WB_ADD'pos(A_GBTX_CONTROLLER_ENABLE)) <= wb_resize_bit(s_wishbone_registers_voted.gbtx_controller_enable, C_GBTX_CONTROLLER_ENABLE_bit);
    s_wbs_reg_i(WB_ADD'pos(A_GBTX_RESET))             <= wb_resize_bit(s_wishbone_registers_voted.gbtx_reset_n, C_GBTX_RESET_bit);
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE0))      <= wb_resize(s_wishbone_registers_voted.idelay_values(0));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE1))      <= wb_resize(s_wishbone_registers_voted.idelay_values(1));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE2))      <= wb_resize(s_wishbone_registers_voted.idelay_values(2));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE3))      <= wb_resize(s_wishbone_registers_voted.idelay_values(3));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE4))      <= wb_resize(s_wishbone_registers_voted.idelay_values(4));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE5))      <= wb_resize(s_wishbone_registers_voted.idelay_values(5));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE6))      <= wb_resize(s_wishbone_registers_voted.idelay_values(6));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE7))      <= wb_resize(s_wishbone_registers_voted.idelay_values(7));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE8))      <= wb_resize(s_wishbone_registers_voted.idelay_values(8));
    s_wbs_reg_i(WB_ADD'pos(A_SET_IDELAY_VALUE9))      <= wb_resize(s_wishbone_registers_voted.idelay_values(9));
    s_wbs_reg_i(WB_ADD'pos(A_BITSLIP_RX_VALUE))       <= wb_resize(s_wishbone_registers_voted.bitslip_rx_value);
    s_wbs_reg_i(WB_ADD'pos(A_BITSLIP_TX_VALUE))       <= wb_resize(s_wishbone_registers_voted.bitslip_tx_value);
    s_wbs_reg_i(WB_ADD'pos(A_TX_PATTERN_SELECTION))   <= wb_resize(s_wishbone_registers_voted.tx_pattern_selection);
    s_wbs_reg_i(WB_ADD'pos(A_TX1_PATTERN_SELECTION))  <= wb_resize(s_wishbone_registers_voted.tx1_pattern_selection);
    -- all others are "pulsed" (set to 0 when not written to)

  end process p_wishbone_data;

  
  -- no wishbone bus attached, just defaults
  WB_WBS_I.dat_i  <= (others => '0');
  WB_WBS_I.we_i   <= '0';
  WB_WBS_I.addr_i <= (others => '0');
  WB_WBS_I.cyc_i  <= '0';
  WB_WBS_I.stb_i  <= '0';
                    
  -----------------------------------------------------------------------------
  -- Wishbone register handling
  -----------------------------------------------------------------------------
  INST_wishbone_slave_register : entity work.ws_reg
    generic map (
      WB_ADD_WE      => C_WB_ADD_WE,
      WB_ILLEGAL_VAL => x"DEAD",
      WB_REG_INIT    => C_WB_REG_DEFAULT
      )
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => WB_WBS_I,
      WB_WBS_O  => WB_WBS_O,
      WBS_REG_I => s_wbs_reg_i,
      WBS_REG_O => s_wbs_reg_o
      );


  -----------------------------------------------------------------------------
  -- sync GBX_RXRDY to wishbone clock
  -----------------------------------------------------------------------------
  INST_sync_gbtx_rxrdy : xpm_cdc_single
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      SIM_ASSERT_CHK => 1,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0  -- integer; 0=do not register input, 1=register input
      )
    port map (
      src_clk  => '0',     -- optional; required when SRC_INPUT_REG = 1
      src_in   => GBTX_RXRDY,
      dest_clk => WB_CLK,
      dest_out => sRxRdy_sync
      );

  -----------------------------------------------------------------------------
  -- latch a '1' when GBTX_RXRDY goes low; reset from wishbone
  -----------------------------------------------------------------------------
  p_readyLostFlag_reg : process (WB_CLK) is
  begin  -- process p_wishbone_reg
    if rising_edge(WB_CLK) then
      if (sRxRdyLostFlagRst = '1') then
        sRxRdyLostFlag <= '0';
      elsif sRxRdy_sync = '0' then
        -----------------------------------------------------------------------
        -- Latch if GTBX_RXRDY = 0
        -----------------------------------------------------------------------
        sRxRdyLostFlag <= '1';
      else
        sRxRdyLostFlag <= sRxRdyLostFlag;
      end if;
    end if;
  end process p_readyLostFlag_reg;


  -----------------------------------------------------------------------------
  -- Retiming for critical singnals
  -----------------------------------------------------------------------------

  p_idelay_read_retiming : process (WB_CLK) is
  begin  -- process p_idelay_read_retiming
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        s_idelay_read_values_retiming <= C_IDELAY_READ_DEFAULT;
      else
        s_idelay_read_values_retiming <= IDELAY_READ_VALUES;
      end if;
    end if;
  end process p_idelay_read_retiming;

  -- p_mismatch_wb_retiming : process (WB_CLK) is
  -- begin  -- process p_idelay_read_retiming
  -- if rising_edge(WB_CLK) then
  -- if WB_RST = '1' then
  -- s_mismatch_wb_retiming <= (others => '0');
  -- else
  -- s_mismatch_wb_retiming <= MISMATCH_WB;
  -- end if;
  -- end if;
  -- end process p_mismatch_wb_retiming;

end architecture structural;
