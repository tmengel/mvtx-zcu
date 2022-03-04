-------------------------------------------------------------------------------
-- Title      : Wishbone master tripleoutput
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : wishbone_master_tripleoutput.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2015-09-02
-- Last update: 2018-04-18
-- Platform   : Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Top level module containing the wishbone master and a wishbone
--              slave (wb_master_config) with error counters.
-- Interfaces:
--                      wishbone master
--                      wishbone slave
--                      incoming command fifo
--                      outgoing command fifo
--                      mismatch
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.tmr_pkg.all;
use work.ws_master_pkg.all;
use work.xpm_cdc_components_pkg.all;

entity wishbone_master_tripleoutput is
  generic (
    ENABLE_DEBUG               : string  := "FALSE";
    MISMATCH_EN                : integer := 1;
    G_MISMATCH_REGISTERED      : integer := 0;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_WBMSTR_MISMATCH_WIDTH    : integer := 7;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );
  port (
    -- Wishbone interface signals
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBM_I : in  t_wbm_i_array(0 to C_K_TMR-1);
    WB_WBM_O : out t_wbm_o_array(0 to C_K_TMR-1);

    --WB_WBM_I_A     : in  wbm_i_type;
    --WB_WBM_O_A     : out wbm_o_type;
    --WB_WBM_I_B     : in  wbm_i_type;
    --WB_WBM_O_B     : out wbm_o_type;
    --WB_WBM_I_C     : in  wbm_i_type;
    --WB_WBM_O_C     : out wbm_o_type;
    -- Wishbone slave interface
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);

    --WB_WBS_I_A     : in  wbs_i_type;
    --WB_WBS_O_A     : out wbs_o_type;
    --WB_WBS_I_B     : in  wbs_i_type;
    --WB_WBS_O_B     : out wbs_o_type;
    --WB_WBS_I_C     : in  wbs_i_type;
    --WB_WBS_O_C     : out wbs_o_type;
    -- Interface to incoming command fifo
    DP0_DT_I       : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DP0_EPTY_I     : in  std_logic;
    DP0_RD_O       : out std_logic;
    -- Interface to outgoing command fifo
    DP1_DT_O       : out std_logic_vector(GPIF_WIDTH-1 downto 0);
    DP1_FULL_I     : in  std_logic;
    DP1_WR_O       : out std_logic;
    -- mismatch control
    MISMATCH_O     : out std_logic_vector(C_WBMSTR_MISMATCH_WIDTH-1 downto 0);
    MISMATCH_2ND_O : out std_logic_vector(C_WBMSTR_MISMATCH_WIDTH-1 downto 0)
    );
end entity wishbone_master_tripleoutput;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture wishbone_master_tripleoutput_arch of wishbone_master_tripleoutput is

  -- usb_if_wrpr component declaration
  component wbmstr_tripleoutput
    generic(
      GpifWidth                  : integer;
      WbDataWidth                : integer;
      WbAddWidth                 : integer;
      MISMATCH_EN                : integer;
      G_MISMATCH_REGISTERED      : integer;
      G_SEE_MITIGATION_TECHNIQUE : integer;
      G_WBMSTR_MISMATCH_WIDTH    : integer;
      G_ADDITIONAL_MISMATCH      : integer;
      G_K_TMR                    : integer
      );
    port (
      clk_i : in std_logic;
      rst_i : in std_logic;

      wbm_we_o  : out std_logic_vector(C_K_TMR-1 downto 0);
      wbm_stb_o : out std_logic_vector(C_K_TMR-1 downto 0);
      wbm_ack_i : in  std_logic_vector(C_K_TMR-1 downto 0);
      wbm_err_i : in  std_logic_vector(C_K_TMR-1 downto 0);
      wbm_cyc_o : out std_logic_vector(C_K_TMR-1 downto 0);

      wbm_A_adr_o : out std_logic_vector(WbAddWidth-1 downto 0);
      wbm_A_dt_i  : in  std_logic_vector(WbDataWidth-1 downto 0);
      wbm_A_dt_o  : out std_logic_vector(WbDataWidth-1 downto 0);

      wbm_B_adr_o : out std_logic_vector(WbAddWidth-1 downto 0);
      wbm_B_dt_i  : in  std_logic_vector(WbDataWidth-1 downto 0);
      wbm_B_dt_o  : out std_logic_vector(WbDataWidth-1 downto 0);

      wbm_C_adr_o : out std_logic_vector(WbAddWidth-1 downto 0);
      wbm_C_dt_i  : in  std_logic_vector(WbDataWidth-1 downto 0);
      wbm_C_dt_o  : out std_logic_vector(WbDataWidth-1 downto 0);

      rderrcntr_o      : out std_logic_vector(WbDataWidth-1 downto 0);
      wrerrcntr_o      : out std_logic_vector(WbDataWidth-1 downto 0);
      seeerrcntr_o     : out std_logic_vector(WbDataWidth-1 downto 0);
      rst_rderrcntr_i  : in  std_logic;
      rst_wrerrcntr_i  : in  std_logic;
      rst_seeerrcntr_i : in  std_logic;

      DP0_DT_I     : in  std_logic_vector(GpifWidth-1 downto 0);
      DP0_EPTY_I   : in  std_logic;
      DP0_RD_O     : out std_logic;
      DP1_DT_O     : out std_logic_vector(GpifWidth-1 downto 0);
      DP1_FULL_I   : in  std_logic;
      DP1_WR_O     : out std_logic;

      mismatch_o     : out std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0);
      mismatch_2nd_o : out std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0)
      );
  end component;

  -- Wishbone interface signals
  signal s_wbm_we  : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_wbm_cyc : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_wbm_stb : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_wbm_ack : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_wbm_err : std_logic_vector(C_K_TMR-1 downto 0);

  signal s_wbm_A_dat_i : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_A_dat_o : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_A_addr  : std_logic_vector(WB_ADD_WIDTH-1 downto 0);

  signal s_wbm_B_dat_i : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_B_dat_o : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_B_addr  : std_logic_vector(WB_ADD_WIDTH-1 downto 0);

  signal s_wbm_C_dat_i : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_C_dat_o : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_C_addr  : std_logic_vector(WB_ADD_WIDTH-1 downto 0);

  -- errors counters
  signal s_wbm_rderrcntr     : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_wrerrcntr     : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_seeerrcntr    : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_rst_wrerrcnt  : std_logic;
  signal s_wbm_rst_rderrcnt  : std_logic;
  signal s_wbm_rst_seeerrcnt : std_logic;

  signal s_mismatch, s_mismatch_2nd       : std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0);
  signal s_mismatch_wb, s_mismatch_2nd_wb : std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0);

  attribute mark_debug                  : string;
  attribute mark_debug of s_wbm_we      : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_ack     : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_cyc     : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_err     : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_stb     : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_A_addr  : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_A_dat_i : signal is ENABLE_DEBUG;
  attribute mark_debug of s_wbm_A_dat_o : signal is ENABLE_DEBUG;

begin  -- architecture

  -- Wishbone interface
  gen_wishbone_ctrl_for : for i in 0 to C_K_TMR-1 generate
    WB_WBM_O(i).we_o  <= s_wbm_we(i);
    WB_WBM_O(i).cyc_o <= s_wbm_cyc(i);
    WB_WBM_O(i).stb_o <= s_wbm_stb(i);
    s_wbm_ack(i)      <= WB_WBM_I(i).ack_i;
    s_wbm_err(i)      <= WB_WBM_I(i).err_i;
  end generate gen_wishbone_ctrl_for;

  WB_WBM_O(0).dat_o  <= s_wbm_A_dat_o;
  WB_WBM_O(0).addr_o <= s_wbm_A_addr;
  s_wbm_A_dat_i      <= WB_WBM_I(0).dat_i;

  WB_WBM_O(1).dat_o  <= s_wbm_B_dat_o;
  WB_WBM_O(1).addr_o <= s_wbm_B_addr;
  s_wbm_B_dat_i      <= WB_WBM_I(1).dat_i;

  WB_WBM_O(2).dat_o  <= s_wbm_C_dat_o;
  WB_WBM_O(2).addr_o <= s_wbm_C_addr;
  s_wbm_C_dat_i      <= WB_WBM_I(2).dat_i;


  --WB_WBM_O_A.we_o   <= s_wbm_A_we;
  --WB_WBM_O_A.cyc_o  <= s_wbm_A_cyc;
  --WB_WBM_O_A.stb_o  <= s_wbm_A_stb;
  --WB_WBM_O_A.dat_o  <= s_wbm_A_dat_o;
  --WB_WBM_O_A.addr_o <= s_wbm_A_addr;

  --s_wbm_A_ack   <= WB_WBM_I_A.ack_i;
  --s_wbm_A_err   <= WB_WBM_I_A.err_i;
  --s_wbm_A_dat_i <= WB_WBM_I_A.dat_i;

  --WB_WBM_O_B.we_o   <= s_wbm_B_we;
  --WB_WBM_O_B.cyc_o  <= s_wbm_B_cyc;
  --WB_WBM_O_B.stb_o  <= s_wbm_B_stb;
  --WB_WBM_O_B.dat_o  <= s_wbm_B_dat_o;
  --WB_WBM_O_B.addr_o <= s_wbm_B_addr;

  --s_wbm_B_ack   <= WB_WBM_I_B.ack_i;
  --s_wbm_B_err   <= WB_WBM_I_B.err_i;
  --s_wbm_B_dat_i <= WB_WBM_I_B.dat_i;

  --WB_WBM_O_C.we_o   <= s_wbm_C_we;
  --WB_WBM_O_C.cyc_o  <= s_wbm_C_cyc;
  --WB_WBM_O_C.stb_o  <= s_wbm_C_stb;
  --WB_WBM_O_C.dat_o  <= s_wbm_C_dat_o;
  --WB_WBM_O_C.addr_o <= s_wbm_C_addr;

  --s_wbm_C_ack   <= WB_WBM_I_C.ack_i;
  --s_wbm_C_err   <= WB_WBM_I_C.err_i;
  --s_wbm_C_dat_i <= WB_WBM_I_C.dat_i;
  -- end Wishbone

  wbmstr_inst : wbmstr_tripleoutput
    generic map (
      GpifWidth                  => GPIF_WIDTH,
      WbDataWidth                => WB_DATA_WIDTH,
      WbAddWidth                 => WB_ADD_WIDTH,
      MISMATCH_EN                => MISMATCH_EN,
      G_MISMATCH_REGISTERED      => G_MISMATCH_REGISTERED,
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_WBMSTR_MISMATCH_WIDTH    => G_WBMSTR_MISMATCH_WIDTH,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH,
      G_K_TMR                    => C_K_TMR
      )
    port map (
      clk_i => WB_CLK,
      rst_i => WB_RST,

      wbm_we_o  => s_wbm_we,
      wbm_stb_o => s_wbm_stb,
      wbm_ack_i => s_wbm_ack,
      wbm_err_i => s_wbm_err,
      wbm_cyc_o => s_wbm_cyc,

      wbm_A_adr_o => s_wbm_A_addr,
      wbm_A_dt_i  => s_wbm_A_dat_i,
      wbm_A_dt_o  => s_wbm_A_dat_o,
      wbm_B_adr_o => s_wbm_B_addr,
      wbm_B_dt_i  => s_wbm_B_dat_i,
      wbm_B_dt_o  => s_wbm_B_dat_o,
      wbm_C_adr_o => s_wbm_C_addr,
      wbm_C_dt_i  => s_wbm_C_dat_i,
      wbm_C_dt_o  => s_wbm_C_dat_o,

      DP0_DT_I   => DP0_DT_I,
      DP0_EPTY_I => DP0_EPTY_I,
      DP0_RD_O   => DP0_RD_O,

      DP1_DT_O     => DP1_DT_O,
      DP1_FULL_I   => DP1_FULL_I,
      DP1_WR_O     => DP1_WR_O,

      rderrcntr_o      => s_wbm_rderrcntr,
      wrerrcntr_o      => s_wbm_wrerrcntr,
      seeerrcntr_o     => s_wbm_seeerrcntr,
      rst_wrerrcntr_i  => s_wbm_rst_wrerrcnt,
      rst_rderrcntr_i  => s_wbm_rst_rderrcnt,
      rst_seeerrcntr_i => s_wbm_rst_seeerrcnt,

      mismatch_o     => s_mismatch,
      mismatch_2nd_o => s_mismatch_2nd
      );

  INST_ws_master_config : entity work.ws_master_config_tmr_wrapper
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => WB_WBS_I,
      WB_WBS_O => WB_WBS_O,

      WBM_RDERRCNTR     => s_wbm_rderrcntr,
      WBM_WRERRCNTR     => s_wbm_wrerrcntr,
      WBM_SEEERRCNTR    => s_wbm_seeerrcntr,
      WBM_RST_WRERRCNT  => s_wbm_rst_wrerrcnt,
      WBM_RST_RDERRCNT  => s_wbm_rst_rderrcnt,
      WBM_RST_SEEERRCNT => s_wbm_rst_seeerrcnt,

      MISMATCH_I => s_mismatch
      );

  --INST_bridge_to_nontmr_slave: entity work.bridge_to_nontmr_slave
  --  generic map (
  --    MISMATCH_EN           => MISMATCH_EN,
  --    G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
  --  port map (
  --    WB_CLK         => WB_CLK,
  --    WB_RST         => WB_RST,
  --    wb_wbs_i       => wb_wbs_i,
  --    wb_wbs_o       => wb_wbs_o,
  --    WB_WBS_I_A     => WB_WBS_I_A,
  --    WB_WBS_O_A     => WB_WBS_O_A,
  --    WB_WBS_I_B     => WB_WBS_I_B,
  --    WB_WBS_O_B     => WB_WBS_O_B,
  --    WB_WBS_I_C     => WB_WBS_I_C,
  --    WB_WBS_O_C     => WB_WBS_O_C,
  --    MISMATCH_O     => MISMATCH_O,
  --    MISMATCH_2ND_O => MISMATCH_2ND_O);

  ---- not triplicated, slave is connected to the 3 outputs
  --WB_WBS_O_A          <= s_wb_wbs_o;
  --WB_WBS_O_B          <= s_wb_wbs_o;
  --WB_WBS_O_C          <= s_wb_wbs_o;
  ---- not triplicated slave: connected to 3 input
  --s_wb_wbs_array_i(0) <= WB_WBS_I_A;
  --s_wb_wbs_array_i(1) <= WB_WBS_I_B;
  --s_wb_wbs_array_i(2) <= WB_WBS_I_C;

  --INST_majority_voter_wbs_i : entity work.majority_voter_wbs_i
  --  generic map (
  --    --MISMATCH_EN           => MISMATCH_EN, -- temporary, remove after slave is protected
  --    MISMATCH_EN           => '0',
  --    G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
  --  port map (
  --    ASSERTION_CLK => WB_CLK,
  --    ASSERTION_RST => WB_RST,
  --    INPUT         => s_wb_wbs_array_i,
  --    OUTPUT        => s_wb_wbs_i,
  --    MISMATCH      => open,
  --    MISMATCH_2ND  => open);

  ---- implementation with array of WBS inputs
  --INST_majority_voter_wbs_i : entity work.majority_voter_wbs_i
  --  generic map (
  --    --MISMATCH_EN           => MISMATCH_EN, -- temporary, remove after slave is protected
  --    MISMATCH_EN           => '0',
  --    G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
  --  port map (
  --    ASSERTION_CLK => WB_CLK,
  --    ASSERTION_RST => WB_RST,
  --    INPUT         => WB_WBS_I,
  --    OUTPUT        => s_wb_wbs_i,
  --    MISMATCH      => open,
  --    MISMATCH_2ND  => open);

  --WB_WBS_O(0)          <= s_wb_wbs_o;
  --WB_WBS_O(1)          <= s_wb_wbs_o;
  --WB_WBS_O(2)          <= s_wb_wbs_o;

  -----------------------------------------------------------------------------
  -- MISMATCH
  -----------------------------------------------------------------------------

  INST_mismatch_sync : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      SIM_ASSERT_CHK => 0,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
      WIDTH          => C_WBMSTR_MISMATCH_WIDTH  -- integer; range: 2-1024
      )
    port map (
      src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
      src_in   => s_mismatch,
      dest_clk => WB_CLK,
      dest_out => s_mismatch_wb
      );

  INST_mismatch_2nd_sync : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      SIM_ASSERT_CHK => 0,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
      WIDTH          => C_WBMSTR_MISMATCH_WIDTH  -- integer; range: 2-1024
      )
    port map (
      src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
      src_in   => s_mismatch_2nd,
      dest_clk => WB_CLK,
      dest_out => s_mismatch_2nd_wb
      );

  MISMATCH_O     <= s_mismatch_wb;
  MISMATCH_2ND_O <= s_mismatch_2nd_wb;

end architecture wishbone_master_tripleoutput_arch;
