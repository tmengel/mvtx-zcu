-------------------------------------------------------------------------------
-- Title      : Wishbone master wrapper
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : wishbone_master_wrapper.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2015-09-02
-- Last update: 2017-09-27
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

library UNISIM;
use UNISIM.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.ws_master_pkg.all;

entity wishbone_master_wrapper is
  generic (
    ENABLE_DEBUG               : string  := "FALSE";
    MISMATCH_EN                : integer := 1;
    MISMATCH_REGISTERED        : integer := 1;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_WBMSTR_MISMATCH_WIDTH    : integer := 6;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );
  port (
    -- Wishbone interface signals
    WB_CLK         : in  std_logic;
    WB_RST         : in  std_logic;
    WB_WBM_I       : in  wbm_i_type;
    WB_WBM_O       : out wbm_o_type;
    -- Wishbone slave interface
    WB_WBS_I       : in  wbs_i_type;
    WB_WBS_O       : out wbs_o_type;
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
end entity wishbone_master_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture wishbone_master_wrapper_arch of wishbone_master_wrapper is

  -- usb_if_wrpr component declaration
  component wbmstr
    generic(
      GpifWidth                  : integer;
      WbDataWidth                : integer;
      WbAddWidth                 : integer;
      MISMATCH_EN                : integer;
      MISMATCH_REGISTERED        : integer;
      G_SEE_MITIGATION_TECHNIQUE : integer;
      G_WBMSTR_MISMATCH_WIDTH    : integer;
      G_ADDITIONAL_MISMATCH      : integer
      );
    port (
      clk_i : in std_logic;
      rst_i : in std_logic;

      adr_o : out std_logic_vector(WbAddWidth-1 downto 0);
      dt_i  : in  std_logic_vector(WbDataWidth-1 downto 0);
      dt_o  : out std_logic_vector(WbDataWidth-1 downto 0);
      we_o  : out std_logic;
      stb_o : out std_logic;
      ack_i : in  std_logic;
      err_i : in  std_logic;
      cyc_o : out std_logic;

      rderrcntr_o      : out std_logic_vector(WbDataWidth-1 downto 0);
      wrerrcntr_o      : out std_logic_vector(WbDataWidth-1 downto 0);
      seeerrcntr_o     : out std_logic_vector(WbDataWidth-1 downto 0);
      rst_rderrcntr_i  : in  std_logic;
      rst_wrerrcntr_i  : in  std_logic;
      rst_seeerrcntr_i : in  std_logic;

      DP0_DT_I   : in  std_logic_vector(GpifWidth-1 downto 0);
      DP0_EPTY_I : in  std_logic;
      DP0_RD_O   : out std_logic;
      DP1_DT_O   : out std_logic_vector(GpifWidth-1 downto 0);
      DP1_FULL_I : in  std_logic;
      DP1_WR_O   : out std_logic;

      mismatch_o     : out std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0);
      mismatch_2nd_o : out std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0)
      );
  end component;

  -- Wishbone interface signals
  signal dat_i_s              : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal dat_o_s              : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal addr_s               : std_logic_vector(WB_ADD_WIDTH-1 downto 0);
  signal we_s                 : std_logic;
  signal cyc_s                : std_logic;
  signal stb_s                : std_logic;
  signal ack_s                : std_logic;
  signal err_s                : std_logic;
  signal wbm_ack_i, wbm_err_i : std_logic;

  -- errors counters
  signal s_wbm_rderrcntr     : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_wrerrcntr     : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_seeerrcntr    : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_wbm_rst_wrerrcnt  : std_logic;
  signal s_wbm_rst_rderrcnt  : std_logic;
  signal s_wbm_rst_seeerrcnt : std_logic;

  signal s_mismatch, s_mismatch_2nd : std_logic_vector(G_WBMSTR_MISMATCH_WIDTH-1 downto 0);

  attribute mark_debug              : string;
  attribute mark_debug of dat_o_s   : signal is ENABLE_DEBUG;
  attribute mark_debug of dat_i_s   : signal is ENABLE_DEBUG;
  attribute mark_debug of addr_s    : signal is ENABLE_DEBUG;
  attribute mark_debug of cyc_s     : signal is ENABLE_DEBUG;
  attribute mark_debug of stb_s     : signal is ENABLE_DEBUG;
  attribute mark_debug of we_s      : signal is ENABLE_DEBUG;
  attribute mark_debug of wbm_ack_i : signal is ENABLE_DEBUG;
  attribute mark_debug of wbm_err_i : signal is ENABLE_DEBUG;

begin  -- architecture

  wbm_ack_i <= WB_WBM_I.ack_i;
  wbm_err_i <= WB_WBM_I.err_i;

  -- Wishbone interface
  WB_WBM_O.dat_o  <= dat_o_s;
  WB_WBM_O.we_o   <= we_s;
  WB_WBM_O.addr_o <= addr_s;
  WB_WBM_O.cyc_o  <= cyc_s;
  WB_WBM_O.stb_o  <= stb_s;

  dat_i_s <= WB_WBM_I.dat_i;
  ack_s   <= WB_WBM_I.ack_i;
  err_s   <= WB_WBM_I.err_i;
  -- end Wishbone

  MISMATCH_O     <= s_mismatch;
  MISMATCH_2ND_O <= s_mismatch_2nd;

  wbmstr_inst : wbmstr
    generic map (
      GpifWidth                  => GPIF_WIDTH,
      WbDataWidth                => WB_DATA_WIDTH,
      WbAddWidth                 => WB_ADD_WIDTH,
      MISMATCH_EN                => MISMATCH_EN,
      MISMATCH_REGISTERED        => MISMATCH_REGISTERED,
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_WBMSTR_MISMATCH_WIDTH    => G_WBMSTR_MISMATCH_WIDTH,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH
      )
    port map (
      clk_i => WB_CLK,
      rst_i => WB_RST,

      adr_o => addr_s,
      dt_i  => dat_i_s,
      dt_o  => dat_o_s,
      we_o  => we_s,
      stb_o => stb_s,
      ack_i => ack_s,
      err_i => err_s,
      cyc_o => cyc_s,

      dp0_dt_i   => DP0_DT_I,
      dp0_epty_i => DP0_EPTY_I,
      dp0_rd_o   => DP0_RD_O,

      dp1_dt_o   => DP1_DT_O,
      dp1_full_i => DP1_FULL_I,
      dp1_wr_o   => DP1_WR_O,

      rderrcntr_o      => s_wbm_rderrcntr,
      wrerrcntr_o      => s_wbm_wrerrcntr,
      seeerrcntr_o     => s_wbm_seeerrcntr,
      rst_wrerrcntr_i  => s_wbm_rst_wrerrcnt,
      rst_rderrcntr_i  => s_wbm_rst_rderrcnt,
      rst_seeerrcntr_i => s_wbm_rst_seeerrcnt,

      mismatch_o     => s_mismatch,
      mismatch_2nd_o => s_mismatch_2nd
      );

  INST_ws_master_config : entity work.ws_master_config
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

end architecture wishbone_master_wrapper_arch;
