-------------------------------------------------------------------------------
-- Title      : ws_usb_if
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : ws_usb_if_config.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-08-03
-- Last update: 2017-08-23
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave to be inserted inside the usb_if
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.ws_usb_if_pkg.all;

entity ws_usb_if is
  generic (
    DP_SELECT_WIDTH : natural := 3
    );
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type;          -- Wishbone slave output signals
    -- DP23 monitor
    -- STS registers
    DP23_STS_DP2_WRDS_MSB               : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP2_WRDS_LSB               : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP2_RDWRDS_MSB             : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP2_RDWRDS_LSB             : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP2_OVFL                   : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP2_FULL                   : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP3_WRDS_MSB               : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP3_WRDS_LSB               : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP3_RDWRDS_MSB             : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP3_RDWRDS_LSB             : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP3_OVFL                   : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    DP23_STS_DP3_FULL                   : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    -- CMD bits
    DP23_CMD_bit_dp2_rst_cntr_words     : out std_logic;
    DP23_CMD_bit_dp2_rst_cntr_rdwords   : out std_logic;
    DP23_CMD_bit_dp2_rst_cntr_ovfl      : out std_logic;
    DP23_CMD_bit_dp2_rst_cntr_full      : out std_logic;
    DP23_CMD_bit_dp2_latch_cntr_words   : out std_logic;
    DP23_CMD_bit_dp2_latch_cntr_rdwords : out std_logic;
    DP23_CMD_bit_dp2_latch_cntr_ovfl    : out std_logic;
    DP23_CMD_bit_dp2_latch_cntr_full    : out std_logic;
    DP23_CMD_bit_dp3_rst_cntr_words     : out std_logic;
    DP23_CMD_bit_dp3_rst_cntr_rdwords   : out std_logic;
    DP23_CMD_bit_dp3_rst_cntr_ovfl      : out std_logic;
    DP23_CMD_bit_dp3_rst_cntr_full      : out std_logic;
    DP23_CMD_bit_dp3_latch_cntr_words   : out std_logic;
    DP23_CMD_bit_dp3_latch_cntr_rdwords : out std_logic;
    DP23_CMD_bit_dp3_latch_cntr_ovfl    : out std_logic;
    DP23_CMD_bit_dp3_latch_cntr_full    : out std_logic;
    -- CFG bits
    DP2_CFG_PRODUCER_SELECT             : out std_logic_vector(DP_SELECT_WIDTH-1 downto 0);
    DP3_CFG_PRODUCER_SELECT             : out std_logic_vector(DP_SELECT_WIDTH-1 downto 0)
    );

end ws_usb_if;

architecture str of ws_usb_if is

  -- wishbone signal for reading
  signal s_wb_wbs_o : wbs_o_type;

  -- dp23 signals
  signal s_dp2_cfg_producer_select : std_logic_vector(DP_SELECT_WIDTH-1 downto 0);
  signal s_dp3_cfg_producer_select : std_logic_vector(DP_SELECT_WIDTH-1 downto 0);

begin  -- architecture str

  DP2_CFG_PRODUCER_SELECT <= s_dp2_cfg_producer_select;
  DP3_CFG_PRODUCER_SELECT <= s_dp3_cfg_producer_select;

  -----------------------------------------------------------------------------
  -- Wishbone interface
  -----------------------------------------------------------------------------

  -- purpose: writes the wishbone register form the WB side
  p_wishbone_reg : process (WB_CLK) is
  begin  -- process p_wishbone_reg
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        DP23_CMD_bit_dp2_rst_cntr_words     <= '0';
        DP23_CMD_bit_dp2_rst_cntr_rdwords   <= '0';
        DP23_CMD_bit_dp2_rst_cntr_ovfl      <= '0';
        DP23_CMD_bit_dp2_rst_cntr_full      <= '0';
        DP23_CMD_bit_dp2_latch_cntr_words   <= '0';
        DP23_CMD_bit_dp2_latch_cntr_rdwords <= '0';
        DP23_CMD_bit_dp2_latch_cntr_ovfl    <= '0';
        DP23_CMD_bit_dp2_latch_cntr_full    <= '0';
        DP23_CMD_bit_dp3_rst_cntr_words     <= '0';
        DP23_CMD_bit_dp3_rst_cntr_rdwords   <= '0';
        DP23_CMD_bit_dp3_rst_cntr_ovfl      <= '0';
        DP23_CMD_bit_dp3_rst_cntr_full      <= '0';
        DP23_CMD_bit_dp3_latch_cntr_words   <= '0';
        DP23_CMD_bit_dp3_latch_cntr_rdwords <= '0';
        DP23_CMD_bit_dp3_latch_cntr_ovfl    <= '0';
        DP23_CMD_bit_dp3_latch_cntr_full    <= '0';
        s_dp2_cfg_producer_select           <= (others => '0');
        s_dp3_cfg_producer_select           <= (others => '0');
      else
        if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
          case WB_WBS_I.addr_i is

            when WB_ADD.DP23_CMD =>     -- Write/Read register
              DP23_CMD_bit_dp2_rst_cntr_words     <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_rst_cntr_words);
              DP23_CMD_bit_dp2_rst_cntr_rdwords   <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_rst_cntr_rdwords);
              DP23_CMD_bit_dp2_rst_cntr_ovfl      <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_rst_cntr_ovfl);
              DP23_CMD_bit_dp2_rst_cntr_full      <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_rst_cntr_full);
              DP23_CMD_bit_dp2_latch_cntr_words   <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_latch_cntr_words);
              DP23_CMD_bit_dp2_latch_cntr_rdwords <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_latch_cntr_rdwords);
              DP23_CMD_bit_dp2_latch_cntr_ovfl    <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_latch_cntr_ovfl);
              DP23_CMD_bit_dp2_latch_cntr_full    <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp2_latch_cntr_full);
              DP23_CMD_bit_dp3_rst_cntr_words     <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_rst_cntr_words);
              DP23_CMD_bit_dp3_rst_cntr_rdwords   <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_rst_cntr_rdwords);
              DP23_CMD_bit_dp3_rst_cntr_ovfl      <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_rst_cntr_ovfl);
              DP23_CMD_bit_dp3_rst_cntr_full      <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_rst_cntr_full);
              DP23_CMD_bit_dp3_latch_cntr_words   <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_latch_cntr_words);
              DP23_CMD_bit_dp3_latch_cntr_rdwords <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_latch_cntr_rdwords);
              DP23_CMD_bit_dp3_latch_cntr_ovfl    <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_latch_cntr_ovfl);
              DP23_CMD_bit_dp3_latch_cntr_full    <= WB_WBS_I.dat_i(C_DP23_CMD_bit_dp3_latch_cntr_full);

            when WB_ADD.CFG_DP23_PRODUCER_ADDRESS =>  -- Write/Read register
              s_dp2_cfg_producer_select <= WB_WBS_I.dat_i(C_CFG_DP23_bit_dp2_producer_address'range);
              s_dp3_cfg_producer_select <= WB_WBS_I.dat_i(C_CFG_DP23_bit_dp3_producer_address'range);

            when others =>
              null;

          end case;

        else                            -- pulse signals
          DP23_CMD_bit_dp2_rst_cntr_words     <= '0';
          DP23_CMD_bit_dp2_rst_cntr_rdwords   <= '0';
          DP23_CMD_bit_dp2_rst_cntr_ovfl      <= '0';
          DP23_CMD_bit_dp2_rst_cntr_full      <= '0';
          DP23_CMD_bit_dp2_latch_cntr_words   <= '0';
          DP23_CMD_bit_dp2_latch_cntr_rdwords <= '0';
          DP23_CMD_bit_dp2_latch_cntr_ovfl    <= '0';
          DP23_CMD_bit_dp2_latch_cntr_full    <= '0';
          DP23_CMD_bit_dp3_rst_cntr_words     <= '0';
          DP23_CMD_bit_dp3_rst_cntr_rdwords   <= '0';
          DP23_CMD_bit_dp3_rst_cntr_ovfl      <= '0';
          DP23_CMD_bit_dp3_rst_cntr_full      <= '0';
          DP23_CMD_bit_dp3_latch_cntr_words   <= '0';
          DP23_CMD_bit_dp3_latch_cntr_rdwords <= '0';
          DP23_CMD_bit_dp3_latch_cntr_ovfl    <= '0';
          DP23_CMD_bit_dp3_latch_cntr_full    <= '0';
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
        v_ack_o          := '0';
        v_err_o          := '0';
        s_wb_wbs_o.ack_o <= '0';
        s_wb_wbs_o.err_o <= '0';
      else

        case WB_WBS_I.addr_i is

          when WB_ADD.DP23_CMD =>       -- Write only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);


          when WB_ADD.READ_DP23_STS_DP2_WRDS_MSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_WRDS_LSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_RDWRDS_MSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_RDWRDS_LSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_OVFL =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_FULL =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_WRDS_MSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_WRDS_LSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_RDWRDS_MSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_RDWRDS_LSB =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_OVFL =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_FULL =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);


          when WB_ADD.CFG_DP23_PRODUCER_ADDRESS =>  -- Read / Write registers
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

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
                             DP23_STS_DP2_OVFL, DP23_STS_DP2_WRDS_MSB, DP23_STS_DP2_WRDS_LSB,
                             DP23_STS_DP2_FULL, DP23_STS_DP2_RDWRDS_MSB, DP23_STS_DP2_RDWRDS_LSB,
                             DP23_STS_DP3_OVFL, DP23_STS_DP3_WRDS_MSB, DP23_STS_DP3_WRDS_LSB,
                             DP23_STS_DP3_FULL, DP23_STS_DP3_RDWRDS_MSB, DP23_STS_DP3_RDWRDS_LSB,
                             s_dp2_cfg_producer_select,
                             s_dp3_cfg_producer_select) is
  begin  -- process p_wishbone_data
    case WB_WBS_I.addr_i is

      when WB_ADD.READ_DP23_STS_DP2_WRDS_MSB =>    -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP2_WRDS_MSB;
      when WB_ADD.READ_DP23_STS_DP2_WRDS_LSB =>    -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP2_WRDS_LSB;
      when WB_ADD.READ_DP23_STS_DP2_RDWRDS_MSB =>  -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP2_RDWRDS_MSB;
      when WB_ADD.READ_DP23_STS_DP2_RDWRDS_LSB =>  -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP2_RDWRDS_LSB;
      when WB_ADD.READ_DP23_STS_DP2_OVFL =>        -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP2_OVFL;
      when WB_ADD.READ_DP23_STS_DP2_FULL =>        -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP2_FULL;
      when WB_ADD.READ_DP23_STS_DP3_WRDS_MSB =>    -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP3_WRDS_MSB;
      when WB_ADD.READ_DP23_STS_DP3_WRDS_LSB =>    -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP3_WRDS_LSB;
      when WB_ADD.READ_DP23_STS_DP3_RDWRDS_MSB =>  -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP3_RDWRDS_MSB;
      when WB_ADD.READ_DP23_STS_DP3_RDWRDS_LSB =>  -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP3_RDWRDS_LSB;
      when WB_ADD.READ_DP23_STS_DP3_OVFL =>        -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP3_OVFL;
      when WB_ADD.READ_DP23_STS_DP3_FULL =>        -- Read only error
        s_wb_wbs_o.dat_o <= DP23_STS_DP3_FULL;

      when WB_ADD.CFG_DP23_PRODUCER_ADDRESS =>  -- Write/Read register
        s_wb_wbs_o.dat_o                                            <= (others => '0');
        s_wb_wbs_o.dat_o(C_CFG_DP23_bit_dp2_producer_address'range) <= s_dp2_cfg_producer_select;
        s_wb_wbs_o.dat_o(C_CFG_DP23_bit_dp3_producer_address'range) <= s_dp3_cfg_producer_select;

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
