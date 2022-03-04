-------------------------------------------------------------------------------
-- Title      : Wishbone to DRP Bridge
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : wishbone_drp_bridge.vhd
-- Author     : Emanuele Canessa <e.canessa@cern.ch>
-- Company    : CERN / Politecnico di Torino
-- Created    : 2017-10-12
-- Last update: 2018-06-07
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Standard template for a Wisbone slave to DRP bridge.
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Rev  Author  Description
-- 2017-10-12  1.0  EC      Initial relase
-- 2017-10-13  1.1  EC      Added DRP package
-- 2017-10-18  1.2  EC      Expose status for TMR
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library WORK;
use WORK.intercon_pkg.all;
use WORK.drp_pkg.all;

entity wishbone_drp_bridge is
  generic (
    G_STATE_BITSIZE : integer := 3
  );
  port (
    -- Wishbone Ports
    WB_CLK       : in    std_logic;
    WB_RST       : in    std_logic;
    WB_WBS_I     : in    wbs_i_type;
    WB_WBS_O     : out   wbs_o_type;
    -- Dynamic Reconfiguration Ports
    DRP_DCLK     : out   std_logic;
    DRP_MOSI     : out   drp_mosi_type;
    DRP_MISO     : in    drp_miso_type;
    DRP_LANE     : out   std_logic_vector (DRP_LANE_WIDTH-1 downto 0);
    -- Status Ports
    STATE_I      : in    std_logic_vector (G_STATE_BITSIZE-1 downto 0);
    STATE_O      : out   std_logic_vector (G_STATE_BITSIZE-1 downto 0);
    -- Mismatch Ports
    MISMATCH     : in    std_logic;
    MISMATCH_2ND : in    std_logic
  );
end entity; -- wishbone_drp_bridge

architecture structural of wishbone_drp_bridge is

  -- DRP Registers Definitions -------------------------------------------------
  constant TMR_REGADDR_MISC : natural := 0;
  constant DRP_REGADDR_ADDR : natural := 1;
  constant DRP_REGADDR_DATA : natural := 2;
  constant WBS_N_REGS       : natural := 3;

  type t_wb_readable  is array (0 to WBS_N_REGS-1) of boolean;
  constant IS_READABLE : t_wb_readable := (true, false, true);

  type t_wb_writeable is array (0 to WBS_N_REGS-1) of boolean;
  constant IS_WRITEABLE : t_wb_writeable := (false, true, true);

  -- Wishbone State Machine ----------------------------------------------------
  type t_wb_state is (STATUS_RSET, STATUS_IDLE, STATUS_RWBS, STATUS_WWBS,
                      STATUS_RDRP, STATUS_WDRP, STATUS_ACKN, STATUS_FAIL);

  constant cResetState : t_wb_state := STATUS_RSET;

  signal sCurrentState : t_wb_state;
  signal sNextState    : t_wb_state;
  signal sVotedState   : t_wb_state;

  attribute fsm_encoding : string;
  attribute fsm_encoding of sCurrentState : signal is "sequential";
  attribute fsm_encoding of sNextState    : signal is "sequential";
  attribute fsm_encoding of sVotedState   : signal is "sequential";

  signal sEnaDadd : std_logic;
  signal sEnaDi   : std_logic;

  signal sRegMism : std_logic_vector (1 downto 0) := (others => '0');

  signal sRegAddr : std_logic_vector (DRP_ADDR_WIDTH-1 downto 0);
  signal sRegDatO : std_logic_vector (DRP_DATA_WIDTH-1 downto 0);

  signal iWbAddr   : natural range 0 to 2**WB_ADDS_WIDTH-1;
  signal sWbsMism : std_logic_vector (WB_DATA_WIDTH-1 downto 0);
  signal sWbsDrpO : std_logic_vector (WB_DATA_WIDTH-1 downto 0);

begin

  STATE_O     <= std_logic_vector(to_unsigned(t_wb_state'pos(sNextState), G_STATE_BITSIZE));
  sVotedState <= t_wb_state'val(to_integer(unsigned(STATE_I)));
  iWbAddr     <= to_integer(unsigned(WB_WBS_I.addr_i));

  DRP_DCLK    <= WB_CLK;

  sWbsMism    <= (sWbsMism'high downto 2 => '0') & sRegMism;
  sWbsDrpO    <= sRegDatO(WB_DATA_WIDTH-1 downto 0);


  WB_WBS_O.dat_o <= sWbsMism when iWbAddr = TMR_REGADDR_MISC else
                    sWbsDrpO when iWbAddr = DRP_REGADDR_DATA else
                    x"DEAD";

  sEnaDi   <= '1' when WB_WBS_I.we_i = '1' and iWbAddr = DRP_REGADDR_DATA else
              '0';

  sEnaDadd <= '1' when WB_WBS_I.we_i = '1' and iWbAddr = DRP_REGADDR_ADDR else
              '0';

  MISMATCH_REG_inst : FDRE
    generic map (
      INIT          => '0',
      IS_C_INVERTED => '0',
      IS_D_INVERTED => '0',
      IS_R_INVERTED => '0'
    )
    port map (
      Q  => sRegMism(0),
      C  => WB_CLK,
      CE => '1',
      D  => MISMATCH,
      R  => WB_RST
    );

  MISMATCH_2ND_inst : FDRE
    generic map (
      INIT          => '0',
      IS_C_INVERTED => '0',
      IS_D_INVERTED => '0',
      IS_R_INVERTED => '0'
    )
    port map (
      Q  => sRegMism(1),
      C  => WB_CLK,
      CE => '1',
      D  => MISMATCH_2ND,
      R  => WB_RST
    );

  gen_drp_addr : for i in 0 to DRP_ADDR_WIDTH-1 generate
    FDRE_drp_addr_inst : FDRE
      generic map (
        INIT          => '0',
        IS_C_INVERTED => '0',
        IS_D_INVERTED => '0',
        IS_R_INVERTED => '0'
      )
      port map (
        Q  => DRP_MOSI.addr(i),
        C  => WB_CLK,
        CE => sEnaDadd,
        D  => WB_WBS_I.dat_i(i),
        R  => WB_RST
      );
  end generate; -- gen_drp_addr

  gen_drp_lane : for i in 0 to DRP_LANE_WIDTH-1 generate
    FDRE_drp_addr_inst : FDRE
      generic map (
        INIT          => '0',
        IS_C_INVERTED => '0',
        IS_D_INVERTED => '0',
        IS_R_INVERTED => '0'
      )
      port map (
        Q  => DRP_LANE(i),
        C  => WB_CLK,
        CE => sEnaDadd,
        D  => WB_WBS_I.dat_i(DRP_ADDR_WIDTH + i),
        R  => WB_RST
      );
  end generate; -- gen_drp_lane

  gen_drp_di : for i in 0 to DRP_DATA_WIDTH-1 generate
    FDRE_drp_di_inst : FDRE
      generic map (
        INIT          => '0',
        IS_C_INVERTED => '0',
        IS_D_INVERTED => '0',
        IS_R_INVERTED => '0'
      )
      port map (
        Q  => DRP_MOSI.di(i),
        C  => WB_CLK,
        CE => sEnaDi,
        D  => WB_WBS_I.dat_i(i),
        R  => WB_RST
      );
  end generate; -- gen_drp_di

  gen_drp_do : for i in 0 to DRP_DATA_WIDTH-1 generate
    FDRE_drp_di_inst : FDRE
      generic map (
        INIT          => '0',
        IS_C_INVERTED => '0',
        IS_D_INVERTED => '0',
        IS_R_INVERTED => '0'
      )
      port map (
        Q  => sRegDatO(i),
        C  => WB_CLK,
        CE => DRP_MISO.drdy,
        D  => DRP_MISO.do(i),
        R  => WB_RST
      );
  end generate; -- gen_drp_do


  wb_fsm_state_update : process (WB_CLK)
  begin
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        sCurrentState <= cResetState;
      else
        sCurrentState <= sVotedState;
      end if;
    end if;
  end process; -- wb_fsm_state_update


  wb_fsm_next_state : process (sCurrentState, WB_WBS_I, DRP_MISO, iWbAddr)
  begin

    sNextState <= sCurrentState;

    case sCurrentState is

      when STATUS_RSET =>
        sNextState <= STATUS_IDLE;

      when STATUS_IDLE =>
        if (WB_WBS_I.cyc_i and WB_WBS_I.stb_i) = '1' then
          if WB_WBS_I.we_i = '0' then -- Read
            if iWbAddr < WBS_N_REGS and IS_READABLE(iWbAddr) then
              if iWbAddr = DRP_REGADDR_DATA then
                -- Start a DRP Read Transaction
                sNextState <= STATUS_RDRP;
              else
                -- Read from an interal WBS Register
                sNextState <= STATUS_RWBS;
              end if;
            else
              sNextState <= STATUS_FAIL;
            end if;
          else -- Write
            if iWbAddr < WBS_N_REGS and IS_WRITEABLE(iWbAddr) then
              if iWbAddr = DRP_REGADDR_DATA then
                -- Start a DRP Write Transaction
                sNextState <= STATUS_WDRP;
              else
                -- Write to an interal WBS Register
                sNextState <= STATUS_WWBS;
              end if;
            else
              sNextState <= STATUS_FAIL;
            end if;
          end if;
        end if;

      when STATUS_RDRP =>
        if DRP_MISO.drdy = '1' then
          sNextState <= STATUS_ACKN;
        end if;

      when STATUS_WDRP =>
        sNextState <= STATUS_ACKN;

      when STATUS_RWBS =>
        sNextState <= STATUS_ACKN;

      when STATUS_WWBS =>
        sNextState <= STATUS_ACKN;

      when STATUS_ACKN =>
        sNextState <= STATUS_IDLE;

      when STATUS_FAIL =>
        if WB_WBS_I.stb_i = '0' then
          sNextState <= STATUS_IDLE;
        end if;

      when others      =>
        sNextState <= cResetState;
        -- synthesis translate_off
        report "wishbone_drp_bridge: Unreachable state, going to RESET"
        severity ERROR;
        -- synthesis translate_on

    end case;
  end process; -- wb_fsm_next_state


  wb_fsm_outputs : process (sCurrentState)
  begin

    WB_WBS_O.ack_o <= '0';
    WB_WBS_O.err_o <= '0';
    DRP_MOSI.den   <= '0';
    DRP_MOSI.dwe   <= '0';

    case sCurrentState is
      when STATUS_RSET =>
        null;
      when STATUS_IDLE =>
        null;
      when STATUS_RDRP =>
        DRP_MOSI.den <= '1';
      when STATUS_WDRP =>
        DRP_MOSI.den <= '1';
        DRP_MOSI.dwe <= '1';
      when STATUS_RWBS =>
        null;
      when STATUS_WWBS =>
        null;
      when STATUS_ACKN =>
        WB_WBS_O.ack_o <= '1';
      when STATUS_FAIL =>
        WB_WBS_O.err_o <= '1';
      when others      =>
        null;
    end case;
  end process; -- wb_fsm_outputs

end architecture; -- structural
