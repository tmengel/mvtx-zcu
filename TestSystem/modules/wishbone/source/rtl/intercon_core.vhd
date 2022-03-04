-------------------------------------------------------------------------------
-- Title      : intercon core
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : intercon_corevhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-26
-- Last update: 2018-04-27
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Intercon entity (wishbone bus)
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-02-26  1.0      mlupi   Imported from wishbone_pkg.vhd where is has
--                              been removed
-- 2016-02-29  1.1      ML      Reordering of signals to ease adding wb slaves
-- 2016-02-29           ML      Added 3rd slave
-- 2015-03-02           ML      Added 4th slave for debug purposes
-- 2015-03-08           ML      Slaves starting from 0
-- 2015-07-05  2.0      ML      Parametrization of number of slaves
-- 2016-07-21  2.1      ML      git rebase
-- 2017-03-08  3.0      ML      moved intercon.vhd to intercon_core.vhd,
--                              watchdog moved outside the core
-- 2018-09-23  3.1      ML      Updated wb_master_mux to use package defined
--                              constants instead of generics (redundant)
-- 2018-03-23  3.2      ML      Configurable number of masters
-- 2018-04-09  3.3      ML      Updated to wb_arbiter for better TMR
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.intercon_pkg.all;

entity intercon_core is
  generic (
    G_WB_MASTER_NUMBER       : natural := 2;  -- defined to avoid package entanglement
    G_WB_SLAVE_NUMBER        : natural := 8;
    G_WB_ARBITER_GRANT_WIDTH : natural := 1);  -- defined to avoid package entanglement
  port (
    -- wishbone master port(s)
    wbm_wbm_i              : out t_wbm_i_array(0 to G_WB_MASTER_NUMBER-1);
    wbm_wbm_o              : in  t_wbm_o_array(0 to G_WB_MASTER_NUMBER-1);
    -- wishbone slave port(s)
    wbs_wbs_i              : out t_wbs_i_array(0 to G_WB_SLAVE_NUMBER-1);
    wbs_wbs_o              : in  t_wbs_o_array(0 to G_WB_SLAVE_NUMBER-1);
    -- clock and reset
    clk                    : in  std_logic;
    reset                  : in  std_logic;
    -- watchdog inteface
    wd_stb                 : out std_logic;
    wd_cyc                 : out std_logic;
    wd_err                 : in  std_logic;
    -- wishbone arbiter state for tmr
    wb_arbiter_count_o     : out std_logic_vector((G_WB_ARBITER_GRANT_WIDTH - 1) downto 0);
    wb_arbiter_count_voted : in  std_logic_vector((G_WB_ARBITER_GRANT_WIDTH - 1) downto 0)
    );
end intercon_core;

architecture rtl of intercon_core is

  -- masters
  signal wbm_dat_i  : t_wb_dat_array(0 to G_WB_MASTER_NUMBER-1);
  signal wbm_ack_i  : std_logic_vector(G_WB_MASTER_NUMBER-1 downto 0);
  signal wbm_err_i  : std_logic_vector(G_WB_MASTER_NUMBER-1 downto 0);
  signal wbm_dat_o  : t_wb_dat_array(0 to G_WB_MASTER_NUMBER-1);
  signal wbm_we_o   : std_logic_vector(G_WB_MASTER_NUMBER-1 downto 0);
  signal wbm_addr_o : t_wb_add_array(0 to G_WB_MASTER_NUMBER-1);
  signal wbm_cyc_o  : std_logic_vector(G_WB_MASTER_NUMBER-1 downto 0);
  signal wbm_stb_o  : std_logic_vector(G_WB_MASTER_NUMBER-1 downto 0);

  -- slaves
  signal wbs_dat_o   : t_wb_dat_array(0 to G_WB_SLAVE_NUMBER-1);
  signal wbs_ack_o   : std_logic_vector(G_WB_SLAVE_NUMBER-1 downto 0);
  signal wbs_err_o   : std_logic_vector(G_WB_SLAVE_NUMBER-1 downto 0);
  signal wbs_dat_i   : t_wb_dat_array(0 to G_WB_SLAVE_NUMBER-1);
  signal wbs_we_i    : std_logic_vector(G_WB_SLAVE_NUMBER-1 downto 0);
  signal wbs_addr_i  : t_wb_addr_array(0 to G_WB_SLAVE_NUMBER-1);
  signal wbs_cyc_i   : std_logic_vector(G_WB_SLAVE_NUMBER-1 downto 0);
  signal wbs_stb_i   : std_logic_vector(G_WB_SLAVE_NUMBER-1 downto 0);
  signal wbs_dat_sel : t_wb_dat_array(0 to G_WB_SLAVE_NUMBER-1);

  -- master multiplexer
  signal busy              : std_logic;
  signal addr              : std_logic_vector(WB_ADD_WIDTH-1 downto 0);
  signal cyc, stb, we, ack : std_logic;
  signal err               : std_logic;
  signal dat_m2s, dat_s2m  : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal dat_s2m_o         : std_logic_vector(WB_DATA_WIDTH-1 downto 0);

  --constant ZEROS : std_logic_vector(C_GRANT_WIDTH-1 downto 0) := (others => '0');  -- for psl assertion

begin  -- rtl

  INST_wb_arbiter : entity work.wb_arbiter
    generic map (
      G_WB_MASTER_NUMBER => G_WB_MASTER_NUMBER,
      G_GRANT_WIDTH      => G_WB_ARBITER_GRANT_WIDTH)
    port map (
      clk_i   => clk,
      rst_i   => reset,
      busy_i  => busy,
      count_o => wb_arbiter_count_o,
      count_i => wb_arbiter_count_voted
      );

  INST_wb_master_mux : entity work.wb_master_mux
    generic map (
      G_WB_MASTER_NUMBER => G_WB_MASTER_NUMBER,
      G_GRANT_WIDTH      => G_WB_ARBITER_GRANT_WIDTH)
    port map (
      clk_i     => clk,
      rst_i     => reset,
      cyc_i     => wbm_cyc_o,
      stb_i     => wbm_stb_o,
      we_i      => wbm_we_o,
      addr_i    => wbm_addr_o,          --m_addr, --
      dat_m2s_i => wbm_dat_o,           --m_dat, --
      dat_s2m_o => dat_s2m_o,
      ack_o     => wbm_ack_i,
      err_o     => wbm_err_i,
      cyc_o     => cyc,
      stb_o     => stb,
      addr_o    => addr,
      we_o      => we,
      dat_m2s_o => dat_m2s,
      dat_s2m_i => dat_s2m,
      ack_i     => ack,
      err_i     => err,
      wd_err_i  => wd_err,
      gnt_i     => wb_arbiter_count_voted,
      busy_o    => busy
      );

  --psl default clock is rising_edge(clk);
  --//--psl property no_double_grant is never {wbm1_bg and wbm2_bg};
  --//--psl property no_zero_grant is never {gnt = ZEROS};
  --//--psl assert no_zero_grant;
  --//-- Ensures one hot encoding (P36 of Usign PSL/Sugar for Formal and Dynamic verification)
  --//--psl property no_double_grant is never { (gnt = ZEROS) or ((gnt and std_logic_vector((unsigned(gnt)-1)))/=ZEROS)};
  --//--psl assert no_double_grant; -- impossible since the address is used,
  --//  not a one hot encoded signal
  --//--psl assert always {not wbm1_cyc_o;wbm1_cyc_o} |-> eventually! wbm1_ack_i or wbm1_err_i;
  --//--psl assert always {not wbm2_cyc_o;wbm2_cyc_o} |-> eventually! wbm2_ack_i or wbm2_err_i;
  --//--psl assert always {not wbm_cyc_o(0);wbm_cyc_o(0)} |-> eventually! wbm_ack_i(0) or wbm_err_i(0);
  --//--psl assert always {not wbm_cyc_o(1);wbm_cyc_o(1)} |-> eventually! wbm_ack_i(1) or wbm_err_i(1);
  --psl assert forall i in {0:G_WB_MASTER_NUMBER-1}: always {not wbm_cyc_o(i);wbm_cyc_o(i)} |-> eventually! wbm_ack_i(i) or wbm_err_i(i);
  --//--psl assert always {not wbm1_cyc_o;wbm1_cyc_o} |-> eventually! wbm1_ack_i or wbm1_err_i;
  --//--psl assert always {not wbm2_cyc_o;wbm2_cyc_o} |-> eventually! wbm2_ack_i or wbm2_err_i;
  --//--psl assert always {not wbm_cyc_o(0);wbm_cyc_o(0)} |-> eventually! wbm_ack_i(0) or wbm_err_i(0);
  --//--psl assert always {not wbm_cyc_o(1);wbm_cyc_o(1)} |-> eventually! wbm_ack_i(1) or wbm_err_i(1);
  --psl assert forall i in {0:G_WB_MASTER_NUMBER-1}: always {not wbm_cyc_o(i);wbm_cyc_o(i)} |-> eventually! wbm_ack_i(i) or wbm_err_i(i);

  decoder : block
  begin
    -- slave
    wbs_addr_i <= (others => addr(WB_ADDS_WIDTH-1 downto 0));
  end block decoder;


  mux : block
    signal iSlave : natural;
  begin
    iSlave <= to_integer(unsigned(addr(WB_ADD_WIDTH-1 downto WB_ADDS_WIDTH)));

    --from/to master
    for_master_data_assign_gen : for master_index in 0 to G_WB_MASTER_NUMBER-1 generate
      wbm_dat_i(master_index) <= dat_s2m_o;
    end generate for_master_data_assign_gen;


    -- master to slave
    wbs_stb_i <= (others => stb);
    wbs_we_i  <= (others => we);
    wbs_dat_i <= (others => dat_m2s);

    p_slave_sel : process (cyc, iSlave, wbs_ack_o, wbs_dat_o, wbs_err_o) is
    begin
      -- master to slave
      wbs_cyc_i <= (others => '0');
      -- slave to master
      ack       <= '0';
      err       <= '0';
      dat_s2m   <= (others => '0');

      if iSlave < G_WB_SLAVE_NUMBER then
        -- master to slave
        wbs_cyc_i(iSlave) <= cyc;
        -- slave to master
        ack               <= wbs_ack_o(iSlave);
        err               <= wbs_err_o(iSlave);
        dat_s2m           <= wbs_dat_o(iSlave);
      end if;
    end process p_slave_sel;

    -- synthesis translate_off
    assert (not(cyc = '1' and stb = '1' and err = '1' and ack = '1')) report "Error on wishbone! ACK and ERR asserted at the same time" severity error;
    assert (not(err = '1' and reset = '0')) report "Error on wishbone! Please check usb_if/usb_if_wrpr/wbmstr for the cause of the error!!" severity warning;
  -- synthesis translate_on
  end block mux;

  -- MASTERs
  for_wbm_assign_gen : for master_index in 0 to G_WB_MASTER_NUMBER-1 generate
    wbm_wbm_i(master_index).dat_i <= wbm_dat_i(master_index);
    wbm_wbm_i(master_index).ack_i <= wbm_ack_i(master_index);
    wbm_wbm_i(master_index).err_i <= wbm_err_i(master_index);
    wbm_dat_o(master_index)       <= wbm_wbm_o(master_index).dat_o;
    wbm_we_o(master_index)        <= wbm_wbm_o(master_index).we_o;
    wbm_addr_o(master_index)      <= wbm_wbm_o(master_index).addr_o;
    wbm_cyc_o(master_index)       <= wbm_wbm_o(master_index).cyc_o;
    wbm_stb_o(master_index)       <= wbm_wbm_o(master_index).stb_o;
  end generate for_wbm_assign_gen;

  -- slave
  wbs_signals_generate : for i in 0 to G_WB_SLAVE_NUMBER-1 generate
    wbs_dat_o(i)        <= wbs_wbs_o(i).dat_o;
    wbs_ack_o(i)        <= wbs_wbs_o(i).ack_o;
    wbs_err_o(i)        <= wbs_wbs_o(i).err_o;
    wbs_wbs_i(i).dat_i  <= wbs_dat_i(i);
    wbs_wbs_i(i).we_i   <= wbs_we_i(i);
    wbs_wbs_i(i).addr_i <= wbs_addr_i(i);
    wbs_wbs_i(i).cyc_i  <= wbs_cyc_i(i);
    wbs_wbs_i(i).stb_i  <= wbs_stb_i(i);
  end generate wbs_signals_generate;

  -- watchdog
  wd_stb <= stb;
  wd_cyc <= cyc;

end rtl;
