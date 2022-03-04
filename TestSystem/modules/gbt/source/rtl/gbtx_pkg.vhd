-------------------------------------------------------------------------------
-- Title      : GBTx package
-- Project    :
-------------------------------------------------------------------------------
-- File       : gbtx_pkg.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-11-03
-- Last update: 2018-10-04
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Common declarations for the GBTx controler
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

package gbtx_pkg is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant C_IDELAY_DELAY_WIDTH  : integer                                            := 9;
  constant C_ELINK_GROUPS_NUMBER : integer                                            := 5;  -- number of elink groups
  constant C_GBTX_ELINKS_TX      : integer                                            := 10;
  constant C_GBTX_ELINKS_RX      : integer                                            := 10;
  constant C_GBTX_DATA_WIDTH     : integer                                            := 81;
  constant C_GBTX_DATAFRAME_SIZE : integer                                            := C_GBTX_DATA_WIDTH -1;
  constant C_GBTX_IDLE_PACKET    : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0) := (others => '0');

  -----------------------------------------------------------------------------
  -- GBT Data Packer
  -----------------------------------------------------------------------------
  constant C_GBT_LANE_BYTES         : natural := 9;  -- Number of bytes from a GBT lane
  constant C_GBT_LANE_WIDTH         : natural := C_GBT_LANE_BYTES * 8;
  constant C_GBT_MAX_PACKET_SIZE    : natural := 1000;

  constant C_GBT_WD_TIMEOUT_WIDTH : natural := 16;
  constant C_GBT_SD_TIMEOUT_WIDTH : natural := 16;
  constant C_WORD_COUNT_WIDTH     : natural := 16;
  constant C_PACKET_COUNT_WIDTH   : natural := 16;

  constant C_GBT_RDH_FEE_ID_WIDTH   : natural                       := 16;
  constant C_GBT_RDH_PRIORITY_WIDTH : natural                       := 8;
  constant C_GBT_RDH_BLOCK_LENGTH   : std_logic_vector(15 downto 0) := x"ffff";
  constant C_GBT_RDH_HEADER_SIZE    : std_logic_vector(7 downto 0)  := x"40";
  constant C_GBT_RDH_HEADER_VERSION : std_logic_vector(7 downto 0)  := x"03";

  constant C_GBT_HEADER_ID  : std_logic_vector(7 downto 0) := x"E0";
  constant C_GBT_TRAILER_ID : std_logic_vector(7 downto 0) := x"F0";

  constant C_GBT_PACKER_WB_REG_COUNT : natural := 10;

   -----------------------------------------------------------------------------
  -- CRU protocol definition
  -----------------------------------------------------------------------------
  constant C_CRU_WORD_PREFIX_WIDTH       : integer := 4;
  constant C_CRU_WORD_MESSAGE_WIDTH      : integer := C_GBTX_DATA_WIDTH -1 -C_CRU_WORD_PREFIX_WIDTH -1;
  constant C_CRU_WORD_TRIGGER_INFO_WIDTH : integer := 12;

  constant C_CRU_WORD_DATAVALID_POSITION : integer                                                                                      := 80;
  constant C_CRU_WORD_PREFIX_RANGE       : std_logic_vector(C_GBTX_DATA_WIDTH -1 -1 downto C_GBTX_DATA_WIDTH-1-C_CRU_WORD_PREFIX_WIDTH) := (others => '0');
  constant C_CRU_WORD_MESSAGE_RANGE      : std_logic_vector(C_CRU_WORD_MESSAGE_WIDTH-1 downto 0)                                        := (others => '0');
  constant C_CRU_WORD_TRIGGER_INFO_RANGE : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0)                                   := (others => '0');

  constant C_IDLE_DATAVALID    : std_logic := '0';
  constant C_SOP_DATAVALID     : std_logic := '0';
  constant C_EOP_DATAVALID     : std_logic := '0';
  constant C_SWT_DATAVALID     : std_logic := '0';
  constant C_TRIGGER_DATAVALID : std_logic := '1';

  constant C_IDLE_PREFIX : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0) := x"0";
  constant C_SOP_PREFIX  : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0) := x"1";
  constant C_EOP_PREFIX  : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0) := x"2";
  constant C_SWT_PREFIX  : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0) := x"3";

  constant C_IDLE_MESSAGE : std_logic_vector(C_CRU_WORD_MESSAGE_WIDTH-1 downto 0) := (others => '0');

  -----------------------------------------------------------------------------
  -- CRU protocol words
  -----------------------------------------------------------------------------
  constant C_IDLE_CTRL_WORD : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0) := '0' & C_IDLE_PREFIX & x"000_0000_0000_0000_0000";
  constant C_SOP_CTRL_WORD  : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0) := '0' & C_SOP_PREFIX & x"000_0000_0000_0000_0000";
  constant C_EOP_CTRL_WORD  : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0) := '0' & C_EOP_PREFIX & x"000_0000_0000_0000_0000";

  -----------------------------------------------------------------------------
  -- Trigger types
  -----------------------------------------------------------------------------

  -- one hot trigger types
  constant C_TRG_ORBIT   : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"001";  -- Orbit
  constant C_TRG_HBa     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"002";  -- Heartbeat accept
  constant C_TRG_HBr     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"006";  -- Heartbeat reject
  constant C_TRG_HBc     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"008";  -- Health check
  constant C_TRG_PHYSICS : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"010";  -- Physics Trigger
  constant C_TRG_PP      : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"020";  -- Prepulse
  constant C_TRG_CAL     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"040";  -- Calibration
  constant C_TRG_SOT     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"080";  -- Start of triggered data
  constant C_TRG_EOT     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"100";  -- End of triggered data
  constant C_TRG_SOC     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"200";  -- Start of Continuous Data
  constant C_TRG_EOC     : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"400";  -- End of Continuous Data
  constant C_TRG_TF      : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_WIDTH-1 downto 0) := x"800";  -- Time Frame delimiter

  constant C_TRG_ORBIT_bit   : natural := 0;  -- Orbit
  constant C_TRG_HBa_bit     : natural := 1;  -- Heartbeat accept
  constant C_TRG_HBr_bit     : natural := 2;  -- Heartbeat reject
  constant C_TRG_HBc_bit     : natural := 3;  -- Health check
  constant C_TRG_PHYSICS_bit : natural := 4;  -- Physics Trigger
  constant C_TRG_PP_bit      : natural := 5;  -- Prepulse
  constant C_TRG_CAL_bit     : natural := 6;  -- Calibration
  constant C_TRG_SOT_bit     : natural := 7;  -- Start of triggered data
  constant C_TRG_EOT_bit     : natural := 8;  -- End of triggered data
  constant C_TRG_SOC_bit     : natural := 9;  -- Start of Continuous Data
  constant C_TRG_EOC_bit     : natural := 10; -- End of Continuous Data
  constant C_TRG_TF_bit      : natural := 11; -- Time Frame delimiter

  -----------------------------------------------------------------------------
  -- Trigger Handler records
  -----------------------------------------------------------------------------
  constant C_TRIGGER_DATA_WIDTH : integer := 101;  -- trigger handler protocol
                                                   -- between trigger handler
                                                   -- and gbt packager
  constant C_ORBIT_WIDTH : integer := 32;
  constant C_BUNCH_CROSSING_WIDTH : integer := 12;

  type t_trigger_data is record
    expect_data   : std_logic_vector(100 downto 100);
    hb_orbit      : std_logic_vector(99 downto 68);
    hb_bc         : std_logic_vector(67 downto 56);
    trigger_orbit : std_logic_vector(55 downto 24);
    trigger_bc    : std_logic_vector(23 downto 12);
    trigger_type  : std_logic_vector(11 downto 0);
  end record t_trigger_data;

  constant C_TRIGGER_DATA_DEFAULT : t_trigger_data := (expect_data    => (others => '0'),
                                                       hb_orbit       => (others => '0'),
                                                       hb_bc          => (others => '0'),
                                                       trigger_orbit  => (others => '0'),
                                                       trigger_bc     => (others => '0'),
                                                       trigger_type   => (others => '0'));

  -----------------------------------------------------------------------------
  -- function declaration
  -----------------------------------------------------------------------------
  function f_gbtx_data_is_trigger (constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0)) return boolean;

  function f_gbtx_data_is_idle (constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0)) return boolean;

  function f_gbtx_data_is_sop (constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0)) return boolean;

  function f_gbtx_data_is_eop (constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0)) return boolean;

  function f_gbtx_data_is_swt (constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0)) return boolean;

  function f_to_trigger_data (
    constant data_i : std_logic_vector(C_TRIGGER_DATA_WIDTH - 1 downto 0))
    return t_trigger_data;

  function to_std_logic_vector (
    constant trigger_data_i : t_trigger_data)
    return std_logic_vector;

end package gbtx_pkg;

package body gbtx_pkg is

  function f_gbtx_data_is_trigger (
    constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0))
    return boolean is
    variable v_datavalid          : std_logic;
    variable v_trigger_info       : std_logic_vector(C_CRU_WORD_TRIGGER_INFO_RANGE'range);
    variable v_valid_trigger_info : boolean;
  begin
    v_datavalid    := gbtx_word(C_CRU_WORD_DATAVALID_POSITION);
    v_trigger_info := gbtx_word(C_CRU_WORD_TRIGGER_INFO_RANGE'range);

    v_valid_trigger_info := v_trigger_info(C_TRG_ORBIT_bit  )     = '1' or
                            v_trigger_info(C_TRG_HBa_bit    )     = '1' or
                            v_trigger_info(C_TRG_HBr_bit    )     = '1' or
                            v_trigger_info(C_TRG_HBc_bit    )     = '1' or
                            v_trigger_info(C_TRG_PHYSICS_bit)     = '1' or
                            v_trigger_info(C_TRG_PP_bit     )     = '1' or
                            v_trigger_info(C_TRG_CAL_bit    )     = '1' or
                            v_trigger_info(C_TRG_SOT_bit    )     = '1' or
                            v_trigger_info(C_TRG_EOT_bit    )     = '1' or
                            v_trigger_info(C_TRG_SOC_bit    )     = '1' or
                            v_trigger_info(C_TRG_EOC_bit    )     = '1' or
                            v_trigger_info(C_TRG_TF_bit     )     = '1';

    return ((v_datavalid = C_TRIGGER_DATAVALID) and (v_valid_trigger_info));
  end;

  function f_gbtx_data_is_idle (
    constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0))
    return boolean is
    variable v_datavalid : std_logic;
    variable v_prefix    : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0);
    variable v_message   : std_logic_vector(C_CRU_WORD_MESSAGE_RANGE'range);
  begin
    v_datavalid := gbtx_word(C_CRU_WORD_DATAVALID_POSITION);
    v_prefix    := gbtx_word(C_CRU_WORD_PREFIX_RANGE'range);
    v_message   := gbtx_word(C_CRU_WORD_MESSAGE_RANGE'range);

    return ((v_datavalid = C_IDLE_DATAVALID) and (v_prefix = C_IDLE_PREFIX) and (v_message = C_IDLE_MESSAGE));
  end;

  function f_gbtx_data_is_sop (
    constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0))
    return boolean is
    variable v_datavalid : std_logic;
    variable v_prefix    : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0);
  begin
    v_datavalid := gbtx_word(C_CRU_WORD_DATAVALID_POSITION);
    v_prefix    := gbtx_word(C_CRU_WORD_PREFIX_RANGE'range);

    return v_datavalid = C_SOP_DATAVALID and v_prefix = C_SOP_PREFIX;
  end;

  function f_gbtx_data_is_eop (
    constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0))
    return boolean is
    variable v_datavalid : std_logic;
    variable v_prefix    : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0);
  begin
    v_datavalid := gbtx_word(C_CRU_WORD_DATAVALID_POSITION);
    v_prefix    := gbtx_word(C_CRU_WORD_PREFIX_RANGE'range);

    return v_datavalid = C_EOP_DATAVALID and v_prefix = C_EOP_PREFIX;
  end;

  function f_gbtx_data_is_swt (
    constant gbtx_word : std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0))
    return boolean is
    variable v_datavalid : std_logic;
    variable v_prefix    : std_logic_vector(C_CRU_WORD_PREFIX_WIDTH-1 downto 0);
  begin
    v_datavalid := gbtx_word(C_CRU_WORD_DATAVALID_POSITION);
    v_prefix    := gbtx_word(C_CRU_WORD_PREFIX_RANGE'range);

    return v_datavalid = C_SWT_DATAVALID and v_prefix = C_SWT_PREFIX;
  end;

  function f_to_trigger_data (
    constant data_i : std_logic_vector(C_TRIGGER_DATA_WIDTH - 1 downto 0))
    return t_trigger_data is
    variable vRet : t_trigger_data;
  begin  -- function f_to_trigger_data
    vRet.trigger_type  := data_i(vRet.trigger_type'range);
    vRet.trigger_bc    := data_i(vRet.trigger_bc'range);
    vRet.trigger_orbit := data_i(vRet.trigger_orbit'range);
    vRet.hb_bc         := data_i(vRet.hb_bc'range);
    vRet.hb_orbit      := data_i(vRet.hb_orbit'range);
    vRet.expect_data   := data_i(vRet.expect_data'range);
    return vRet;
  end function f_to_trigger_data;

  function to_std_logic_vector (
    constant trigger_data_i : t_trigger_data)
    return std_logic_vector is
    variable vRet : std_logic_vector(C_TRIGGER_DATA_WIDTH-1 downto 0);
  begin
    vRet(trigger_data_i.trigger_type'range)  := trigger_data_i.trigger_type;
    vRet(trigger_data_i.trigger_bc'range)    := trigger_data_i.trigger_bc;
    vRet(trigger_data_i.trigger_orbit'range) := trigger_data_i.trigger_orbit;
    vRet(trigger_data_i.hb_bc'range)         := trigger_data_i.hb_bc;
    vRet(trigger_data_i.hb_orbit'range)      := trigger_data_i.hb_orbit;
    vRet(trigger_data_i.expect_data'range)   := trigger_data_i.expect_data;
    return vRet;
  end function to_std_logic_vector;
end package body gbtx_pkg;
