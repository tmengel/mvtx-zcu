-------------------------------------------------------------------------------
-- Title      : ws_master_config
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : ws_master_config.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-06
-- Last update: 2017-09-22
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave to be inserted inside
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-07-06  1.0      ML      Created
-- 2016-11-02  1.1      ML      Added selection for DPmux
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
  generic (
    DP_SELECT_WIDTH : natural := 3;
    DNA_CLK_DIVIDER : natural := 4
    );
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type;          -- Wishbone slave output signals

    -- WM ERROR COUNTERs
    -- STS registers
    WBM_RDERRCNTR    : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    WBM_WRERRCNTR    : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    -- CMD registers
    WBM_RST_WRERRCNT : out std_logic;
    WBM_RST_RDERRCNT : out std_logic;

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

end ws_master_config;

architecture str of ws_master_config is

  -- wishbone signal for reading
  signal s_wb_wbs_o : wbs_o_type;

  -- dp23 signals
  signal s_dp2_cfg_producer_select : std_logic_vector(DP_SELECT_WIDTH-1 downto 0);
  signal s_dp3_cfg_producer_select : std_logic_vector(DP_SELECT_WIDTH-1 downto 0);

  -- dna port
  component dna_read is
    generic(C_DNA_SIZE        : integer;
            WbDataWidth       : integer;
            C_DNA_CLK_DIVIDER : natural);
    port(
      clk_i         : in  std_logic;
      rst_i         : in  std_logic;
      do_read_dna_i : in  std_logic;
      dna_value_o   : out std_logic_vector(6*WbDataWidth-1 downto 0)
      );
  end component dna_read;

  signal s_dna_do_read       : std_logic;
  signal s_dna_read_value    : std_logic_vector(6*WB_DATA_WIDTH-1 downto 0);
  signal s_dna_read_value_w0 : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dna_read_value_w1 : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dna_read_value_w2 : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dna_read_value_w3 : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dna_read_value_w4 : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dna_read_value_w5 : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  constant s_dna_read_pos_w0   : std_logic_vector(1*WB_DATA_WIDTH-1 downto 0*WB_DATA_WIDTH) := (others => '0');
  constant s_dna_read_pos_w1   : std_logic_vector(2*WB_DATA_WIDTH-1 downto 1*WB_DATA_WIDTH) := (others => '0');
  constant s_dna_read_pos_w2   : std_logic_vector(3*WB_DATA_WIDTH-1 downto 2*WB_DATA_WIDTH) := (others => '0');
  constant s_dna_read_pos_w3   : std_logic_vector(4*WB_DATA_WIDTH-1 downto 3*WB_DATA_WIDTH) := (others => '0');
  constant s_dna_read_pos_w4   : std_logic_vector(5*WB_DATA_WIDTH-1 downto 4*WB_DATA_WIDTH) := (others => '0');
  constant s_dna_read_pos_w5   : std_logic_vector(6*WB_DATA_WIDTH-1 downto 5*WB_DATA_WIDTH) := (others => '0');

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
        WBM_RST_RDERRCNT                    <= '0';
        WBM_RST_WRERRCNT                    <= '0';
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
        s_dna_do_read                       <= '0';
      else
        if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
          case WB_WBS_I.addr_i is

            when WB_ADD.RST_WBM_CNTR =>  -- Write/Read register
              WBM_RST_RDERRCNT <= WB_WBS_I.dat_i(C_WBM_RST_bit_RDERRCNT);
              WBM_RST_WRERRCNT <= WB_WBS_I.dat_i(C_WBM_RST_bit_WRERRCNT);

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

            when WB_ADD.DNA_PORT_DO_READ =>  -- Write/Only
              s_dna_do_read <= WB_WBS_I.dat_i(C_DNA_PORT_DO_READ);

            when others =>
              null;

          end case;

        else                            -- pulse signals
          WBM_RST_RDERRCNT                    <= '0';
          WBM_RST_WRERRCNT                    <= '0';
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
          s_dna_do_read                       <= '0';
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

          when WB_ADD.RST_WBM_CNTR =>   -- Read / Write registers
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when WB_ADD.DP23_CMD =>       -- Read / Write registers
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when WB_ADD.READ_WBM_RDERRCNTR =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_WBM_WRERRCNTR =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_WRDS_MSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_WRDS_LSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_RDWRDS_MSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_RDWRDS_LSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_OVFL =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP2_FULL =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_WRDS_MSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_WRDS_LSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_RDWRDS_MSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_RDWRDS_LSB =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_OVFL =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_DP23_STS_DP3_FULL =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CFG_DP23_PRODUCER_ADDRESS =>  -- Read / Write registers
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when WB_ADD.DNA_PORT_DO_READ =>  -- Write only registers
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.DNA_PORT_VALUE_W0 =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.DNA_PORT_VALUE_W1 =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.DNA_PORT_VALUE_W2 =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.DNA_PORT_VALUE_W3 =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.DNA_PORT_VALUE_W4 =>  -- Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.DNA_PORT_VALUE_W5 =>  -- Read only error
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
  p_wishbone_data : process (WB_WBS_I, WBM_RDERRCNTR, WBM_WRERRCNTR,
                             DP23_STS_DP2_OVFL, DP23_STS_DP2_WRDS_MSB, DP23_STS_DP2_WRDS_LSB,
                             DP23_STS_DP2_FULL, DP23_STS_DP2_RDWRDS_MSB, DP23_STS_DP2_RDWRDS_LSB,
                             DP23_STS_DP3_OVFL, DP23_STS_DP3_WRDS_MSB, DP23_STS_DP3_WRDS_LSB,
                             DP23_STS_DP3_FULL, DP23_STS_DP3_RDWRDS_MSB, DP23_STS_DP3_RDWRDS_LSB,
                             s_dp2_cfg_producer_select,
                             s_dp3_cfg_producer_select,
                             s_dna_read_value_w0, s_dna_read_value_w1,
                             s_dna_read_value_w2, s_dna_read_value_w3,
                             s_dna_read_value_w4, s_dna_read_value_w5) is
  begin  -- process p_wishbone_data
    case WB_WBS_I.addr_i is

      when WB_ADD.RST_WBM_CNTR =>        -- Write only register
        s_wb_wbs_o.dat_o <= (others => '0');
      when WB_ADD.READ_WBM_RDERRCNTR =>  -- Read only error
        s_wb_wbs_o.dat_o <= WBM_RDERRCNTR;
      when WB_ADD.READ_WBM_WRERRCNTR =>  -- Read only error
        s_wb_wbs_o.dat_o <= WBM_WRERRCNTR;

      when WB_ADD.DP23_CMD =>                      -- Write only register
        s_wb_wbs_o.dat_o <= (others => '0');
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

      when WB_ADD.DNA_PORT_VALUE_W0 =>  -- Read only error
        s_wb_wbs_o.dat_o <= s_dna_read_value_w0;

      when WB_ADD.DNA_PORT_VALUE_W1 =>  -- Read only error
        s_wb_wbs_o.dat_o <= s_dna_read_value_w1;

      when WB_ADD.DNA_PORT_VALUE_W2 =>  -- Read only error
        s_wb_wbs_o.dat_o <= s_dna_read_value_w2;

      when WB_ADD.DNA_PORT_VALUE_W3 =>  -- Read only error
        s_wb_wbs_o.dat_o <= s_dna_read_value_w3;

      when WB_ADD.DNA_PORT_VALUE_W4 =>  -- Read only error
        s_wb_wbs_o.dat_o <= s_dna_read_value_w4;

      when WB_ADD.DNA_PORT_VALUE_W5 =>  -- Read only error
        s_wb_wbs_o.dat_o <= s_dna_read_value_w5;

      when others =>
        s_wb_wbs_o.dat_o <= x"DEAD";
    end case;
  end process p_wishbone_data;

  WB_WBS_O <= s_wb_wbs_o;

  -------------------------------------------------------------------------------
  -- DNA interface for unique FPGA ID
  -------------------------------------------------------------------------------

  dna_read_INST : dna_read
    generic map (
      C_DNA_SIZE        => 96,
      WbDataWidth       => WB_DATA_WIDTH,
      C_DNA_CLK_DIVIDER => DNA_CLK_DIVIDER)
    port map (
      clk_i         => WB_CLK,
      rst_i         => WB_RST,
      do_read_dna_i => s_dna_do_read,
      dna_value_o   => s_dna_read_value);

  s_dna_read_value_w0 <= s_dna_read_value(s_dna_read_pos_w0'range);
  s_dna_read_value_w1 <= s_dna_read_value(s_dna_read_pos_w1'range);
  s_dna_read_value_w2 <= s_dna_read_value(s_dna_read_pos_w2'range);
  s_dna_read_value_w3 <= s_dna_read_value(s_dna_read_pos_w3'range);
  s_dna_read_value_w4 <= s_dna_read_value(s_dna_read_pos_w4'range);
  s_dna_read_value_w5 <= s_dna_read_value(s_dna_read_pos_w5'range);

end architecture str;
