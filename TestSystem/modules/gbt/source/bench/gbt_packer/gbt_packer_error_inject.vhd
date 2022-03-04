-------------------------------------------------------------------------------
-- Title      : GBT Packer Error Inject
-- Project    :
-------------------------------------------------------------------------------
-- File       : gbt_packer_error_inject.vhd
-- Author     : Matthias Bonora  <matthias.bonora@cern.ch>
-- Company    : CERN
-- Created    : 2018-06-04
-- Last update: 2018-06-08
-- Platform   : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Module to inject errors in a gbt_packer instance
-------------------------------------------------------------------------------
-- Copyright (c) 2018 CERN
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-06-04  1.0      mbonora Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.gbtx_pkg.all;

entity gbt_packer_error_inject is
  generic (
    NR_LANES                   : natural := 9;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 1;
    G_MISMATCH_REGISTERED      : integer := 0;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );

  port (
    CLK                    : in  std_logic;
    RST                    : in  std_logic;
    lane_mask_i            : in  std_logic_vector(NR_LANES - 1 downto 0);
    wait_data_timeout_i    : in  std_logic_vector(C_GBT_WD_TIMEOUT_WIDTH - 1 downto 0);
    send_data_timeout_i    : in  std_logic_vector(C_GBT_SD_TIMEOUT_WIDTH - 1 downto 0);
    gbt_max_word_count_i   : in  std_logic_vector(C_WORD_COUNT_WIDTH-1 downto 0);
    gbt_max_packet_count_i : in  std_logic_vector(C_PACKET_COUNT_WIDTH-1 downto 0);
    gbt_fee_id_i           : in  std_logic_vector(C_GBT_CDH_FEE_ID_WIDTH-1 downto 0);
    gbt_priority_i         : in  std_logic_vector(C_GBT_CDH_PRIORITY_WIDTH - 1 downto 0);
    trigger_data_i         : in  std_logic_vector(C_TRIGGER_DATA_WIDTH - 1 downto 0);
    trigger_empty_i        : in  std_logic;
    trigger_rd_o           : out std_logic;
    lane_fifo_data_i       : in  std_logic_vector(NR_LANES*C_GBT_LANE_WIDTH-1 downto 0);
    lane_fifo_start_i      : in  std_logic_vector(NR_LANES-1 downto 0);
    lane_fifo_stop_i       : in  std_logic_vector(NR_LANES-1 downto 0);
    lane_fifo_timeout_i    : in  std_logic_vector(NR_LANES-1 downto 0);
    lane_fifo_valid_i      : in  std_logic_vector(NR_LANES-1 downto 0);
    lane_fifo_read_o       : out std_logic_vector(NR_LANES-1 downto 0);
    gbtx_tx_data_o         : out std_logic_vector(C_GBTX_DATA_WIDTH - 1 downto 0);
    gbtx_tx_datavalid_o    : out std_logic;
    -- Mismatch
    MISMATCH               : out std_logic;
    MISMATCH_2ND           : out std_logic;

    -- Tracing/Inject Interface
    inject       : in std_logic_vector(2 downto 0);
    inject_state : in std_logic_vector(3 downto 0);

    inject_td_expect_data   : in std_logic_vector(0 downto 0);
    inject_td_hb_orbit      : in std_logic_vector(31 downto 0);
    inject_td_hb_bc         : in std_logic_vector(11 downto 0);
    inject_td_trigger_orbit : in std_logic_vector(31 downto 0);
    inject_td_trigger_type  : in std_logic_vector(15 downto 0);
    inject_td_trigger_bc    : in std_logic_vector(11 downto 0);

    inject_wd_timeout_count      : in std_logic_vector(15 downto 0);
    inject_sd_timeout_count      : in std_logic_vector(15 downto 0);
    inject_transmission_done     : in std_logic_vector(0 downto 0);
    inject_transmission_timeout  : in std_logic_vector(0 downto 0);
    inject_tx_data               : in std_logic_vector(C_GBTX_DATA_WIDTH - 1 downto 0);
    inject_tx_datavalid          : in std_logic_vector(0 downto 0);
    inject_lane_active           : in std_logic_vector(NR_LANES - 1 downto 0);
    inject_lane_starts           : in std_logic_vector(NR_LANES - 1 downto 0);
    inject_lane_starts_violation : in std_logic_vector(NR_LANES - 1 downto 0);
    inject_lane_timeouts         : in std_logic_vector(NR_LANES - 1 downto 0);
    inject_lane_stops            : in std_logic_vector(NR_LANES - 1 downto 0);
    inject_lane_idx              : in std_logic_vector(4 downto 0);
    inject_lanes_read            : in std_logic_vector(NR_LANES - 1 downto 0);
    inject_word_count            : in std_logic_vector(15 downto 0);
    inject_packet_idx            : in std_logic_vector(15 downto 0);
    current_state                : out std_logic_vector(3 downto 0);
    gbt_packet_done              : out std_logic
    );
end entity gbt_packer_error_inject;

architecture tracing of gbt_packer_error_inject is

begin  -- architecture tracing

  INST_gbt_packer_tmr_wrapper : entity work.gbt_packer_tmr_wrapper
    generic map (
      NR_LANES                   => NR_LANES,
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_MISMATCH_EN              => G_MISMATCH_EN,
      G_MISMATCH_REGISTERED      => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
    port map (
      CLK                    => CLK,
      RST                    => RST,
      lane_mask_i            => lane_mask_i,
      wait_data_timeout_i    => wait_data_timeout_i,
      send_data_timeout_i    => send_data_timeout_i,
      gbt_max_word_count_i   => gbt_max_word_count_i,
      gbt_max_packet_count_i => gbt_max_packet_count_i,
      gbt_fee_id_i           => gbt_fee_id_i,
      gbt_priority_i         => gbt_priority_i,
      trigger_data_i         => trigger_data_i,
      trigger_empty_i        => trigger_empty_i,
      trigger_rd_o           => trigger_rd_o,
      lane_fifo_data_i       => lane_fifo_data_i,
      lane_fifo_start_i      => lane_fifo_start_i,
      lane_fifo_stop_i       => lane_fifo_stop_i,
      lane_fifo_timeout_i    => lane_fifo_timeout_i,
      lane_fifo_valid_i      => lane_fifo_valid_i,
      lane_fifo_read_o       => lane_fifo_read_o,
      gbtx_tx_data_o         => gbtx_tx_data_o,
      gbtx_tx_datavalid_o    => gbtx_tx_datavalid_o,
      MISMATCH               => MISMATCH,
      MISMATCH_2ND           => MISMATCH_2ND);

  output_current_state: block is
    alias sregs0_state is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(0).gbt_packer_INST.debug_sregs_state                                 : t_gbt_packer_state >>;
    alias sregs1_state is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(1).gbt_packer_INST.debug_sregs_state                                 : t_gbt_packer_state >>;
    alias sregs2_state is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(2).gbt_packer_INST.debug_sregs_state                                 : t_gbt_packer_state >>;
    signal sregs0val,sregs1val,sregs2val : std_logic_vector(3 downto 0);

    alias debug_gbt_packet_done is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.gbt_packet_done_tmr_o : std_logic_vector(0 to 2) >>;
  begin
    sregs0val <= std_logic_vector(to_unsigned(t_gbt_packer_state'POS(sregs0_state), sregs0val'length));
    sregs1val <= std_logic_vector(to_unsigned(t_gbt_packer_state'POS(sregs1_state), sregs1val'length));
    sregs2val <= std_logic_vector(to_unsigned(t_gbt_packer_state'POS(sregs2_state), sregs2val'length));

    current_state <= (sregs0val and sregs1val) or
                     (sregs0val and sregs2val) or
                     (sregs1val and sregs2val);

    gbt_packet_done <= (debug_gbt_packet_done(0) and debug_gbt_packet_done(1)) or
                       (debug_gbt_packet_done(0) and debug_gbt_packet_done(2)) or
                       (debug_gbt_packet_done(1) and debug_gbt_packet_done(2));
  end block output_current_state;

  inject_idx_gen : for i in 0 to 2 generate
    -- PURPOSE: INJECT ERROR IN GBT_PACKER
    -- TYPE   : SEQUENTIAL
    -- INPUTS : CLK
    -- OUTPUTS:
    inject_proc : process (CLK) is
      alias debug_sregs_state is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_state                                 : t_gbt_packer_state >>;
      alias debug_sregs_td_expect_data is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_td_expect_data               : std_ulogic >>;
      alias debug_sregs_td_hb_orbit is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_td_hb_orbit                     : std_logic_vector(31 downto 0) >>;
      alias debug_sregs_td_hb_bc is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_td_hb_bc                           : std_logic_vector(11 downto 0) >>;
      alias debug_sregs_td_trigger_orbit is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_td_trigger_orbit           : std_logic_vector(31 downto 0) >>;
      alias debug_sregs_td_trigger_type is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_td_trigger_type             : std_logic_vector(15 downto 0) >>;
      alias debug_sregs_td_trigger_bc is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_td_trigger_bc                 : std_logic_vector(11 downto 0) >>;
      alias debug_sregs_wd_timeout_count is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_wd_timeout_count           : unsigned(wait_data_timeout_i'range) >>;
      alias debug_sregs_sd_timeout_count is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_sd_timeout_count           : unsigned(send_data_timeout_i'range) >>;
      alias debug_sregs_transmission_done is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_transmission_done         : std_ulogic >>;
      alias debug_sregs_transmission_timeout is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_transmission_timeout   : std_ulogic >>;
      alias debug_sregs_tx_data is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_tx_data                             : std_logic_vector(C_GBTX_DATA_WIDTH - 1 downto 0) >>;
      alias debug_sregs_tx_datavalid is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_tx_datavalid                   : std_ulogic >>;
      alias debug_sregs_lane_active is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lane_active                     : std_logic_vector(NR_LANES - 1 downto 0) >>;
      alias debug_sregs_lane_starts is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lane_starts                     : std_logic_vector(NR_LANES - 1 downto 0) >>;
      alias debug_sregs_lane_starts_violation is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lane_starts_violation : std_logic_vector(NR_LANES - 1 downto 0) >>;
      alias debug_sregs_lane_timeouts is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lane_timeouts                 : std_logic_vector(NR_LANES - 1 downto 0) >>;
      alias debug_sregs_lane_stops is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lane_stops                       : std_logic_vector(NR_LANES - 1 downto 0) >>;
      alias debug_sregs_lane_idx is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lane_idx                           : natural range 0 to NR_LANES-1 >>;
      alias debug_sregs_lanes_read is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_lanes_read                       : std_logic_vector(lane_fifo_read_o'range) >>;
      alias debug_sregs_word_count is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_word_count                       : unsigned(C_WORD_COUNT_WIDTH-1 downto 0) >>;
      alias debug_sregs_packet_idx is << signal ^.INST_gbt_packer_tmr_wrapper.if_TMR_generate.generate_instances(i).gbt_packer_INST.debug_sregs_packet_idx                       : unsigned(C_PACKET_COUNT_WIDTH-1 downto 0)>>;

    begin  -- process inject
      if rising_edge(CLK) then          -- rising clock edge
        if INJECT(i) = '1' then
          if or_reduce(inject_state) /= 'X' then
            debug_sregs_state <= force in t_gbt_packer_state'val(to_integer(unsigned(inject_state)));
          end if;
          if or_reduce(inject_td_expect_data) /= 'X' then
            debug_sregs_td_expect_data <= force in inject_td_expect_data(0);
          end if;
          if or_reduce(inject_td_hb_orbit) /= 'X' then
            debug_sregs_td_hb_orbit <= force in inject_td_hb_orbit;
          end if;
          if or_reduce(inject_td_hb_bc) /= 'X' then
            debug_sregs_td_hb_bc <= force in inject_td_hb_bc;
          end if;
          if or_reduce(inject_td_trigger_orbit) /= 'X' then
            debug_sregs_td_trigger_orbit <= force in inject_td_trigger_orbit;
          end if;
          if or_reduce(inject_td_trigger_type) /= 'X' then
            debug_sregs_td_trigger_type <= force in inject_td_trigger_type;
          end if;
          if or_reduce(inject_td_trigger_bc) /= 'X' then
            debug_sregs_td_trigger_bc <= force in inject_td_trigger_bc;
          end if;
          if or_reduce(inject_wd_timeout_count) /= 'X' then
            debug_sregs_wd_timeout_count <= force in unsigned(inject_wd_timeout_count);
          end if;
          if or_reduce(inject_sd_timeout_count) /= 'X' then
            debug_sregs_sd_timeout_count <= force in unsigned(inject_sd_timeout_count);
          end if;
          if or_reduce(inject_transmission_done) /= 'X' then
            debug_sregs_transmission_done <= force in inject_transmission_done(0);
          end if;
          if or_reduce(inject_transmission_timeout) /= 'X' then
            debug_sregs_transmission_timeout <= force in inject_transmission_timeout(0);
          end if;
          if or_reduce(inject_tx_data) /= 'X' then
            debug_sregs_tx_data <= force in inject_tx_data;
          end if;
          if or_reduce(inject_tx_datavalid) /= 'X' then
            debug_sregs_tx_datavalid <= force in inject_tx_datavalid(0);
          end if;
          if or_reduce(inject_lane_active) /= 'X' then
            debug_sregs_lane_active <= force in inject_lane_active;
          end if;
          if or_reduce(inject_lane_starts) /= 'X' then
            debug_sregs_lane_starts <= force in inject_lane_starts;
          end if;
          if or_reduce(inject_lane_starts_violation) /= 'X' then
            debug_sregs_lane_starts_violation <= force in inject_lane_starts_violation;
          end if;
          if or_reduce(inject_lane_timeouts) /= 'X' then
            debug_sregs_lane_timeouts <= force in inject_lane_timeouts;
          end if;
          if or_reduce(inject_lane_stops) /= 'X' then
            debug_sregs_lane_stops <= force in inject_lane_stops;
          end if;
          if or_reduce(inject_lane_idx) /= 'X' then
            debug_sregs_lane_idx <= force in to_integer(unsigned(inject_lane_idx));
          end if;
          if or_reduce(inject_lanes_read) /= 'X' then
            debug_sregs_lanes_read <= force in inject_lanes_read;
          end if;
          if or_reduce(inject_word_count) /= 'X' then
            debug_sregs_word_count <= force in unsigned(inject_word_count);
          end if;
          if or_reduce(inject_packet_idx) /= 'X' then
            debug_sregs_packet_idx <= force in unsigned(inject_packet_idx);
          end if;
        else
          debug_sregs_state                 <= release in;
          debug_sregs_td_expect_data        <= release in;
          debug_sregs_td_hb_orbit           <= release in;
          debug_sregs_td_hb_bc              <= release in;
          debug_sregs_td_trigger_orbit      <= release in;
          debug_sregs_td_trigger_type       <= release in;
          debug_sregs_td_trigger_bc         <= release in;
          debug_sregs_wd_timeout_count      <= release in;
          debug_sregs_sd_timeout_count      <= release in;
          debug_sregs_transmission_done     <= release in;
          debug_sregs_transmission_timeout  <= release in;
          debug_sregs_tx_data               <= release in;
          debug_sregs_tx_datavalid          <= release in;
          debug_sregs_lane_active           <= release in;
          debug_sregs_lane_starts           <= release in;
          debug_sregs_lane_starts_violation <= release in;
          debug_sregs_lane_timeouts         <= release in;
          debug_sregs_lane_stops            <= release in;
          debug_sregs_lane_idx              <= release in;
          debug_sregs_lanes_read            <= release in;
          debug_sregs_word_count            <= release in;
          debug_sregs_packet_idx            <= release in;
        end if;
      end if;
    end process inject_proc;
  end generate inject_idx_gen;

end architecture tracing;
