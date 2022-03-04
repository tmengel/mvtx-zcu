-------------------------------------------------------------------------------
-- Title      : I2C Interface - Top module
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_master_top.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2015-11-13
-- Last update: 2017-06-08
-- Platform   : Xilinx Vivado 2015.3
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Code downloaded from opencores. Original header at the end
--              of the code, description below from original code.
--              modified for formatting
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Wishbone interface package
use work.intercon_pkg.all;

entity i2c_master_top is
  port (
    -- Wishbone interface signals
    -- wishbone signals
    WB_CLK    : in  std_logic;          -- master clock input
    WB_RST    : in  std_logic := '0';   -- synchronous active high reset
    WB_WBS_I  : in  wbs_i_type;
    WB_WBS_O  : out wbs_o_type;
    --
    ARST      : in  std_logic := '0';   -- asynchronous reset, active hi   -- TODO : sync reset?
    WB_INTA_o : out std_logic;          -- interrupt request output signal
    --
    -- i2c lines
    SCL_PAD_i : in  std_logic;          -- i2c clock line input
    SCL_PAD_o : out std_logic;          -- i2c clock line output
    SCL_PAD_T : out std_logic;  -- i2c clock line output enable, active low
    SDA_PAD_i : in  std_logic;          -- i2c data line input
    SDA_PAD_o : out std_logic;          -- i2c data line output
    SDA_PAD_T : out std_logic   -- i2c data line output enable, active low
    );
end entity i2c_master_top;

architecture structural of i2c_master_top is

  -- registers
  signal prer : unsigned(15 downto 0);         -- clock prescale register
  signal ctr  : std_logic_vector(7 downto 0);  -- control register
  signal txr  : std_logic_vector(7 downto 0);  -- transmit register
  signal rxr  : std_logic_vector(7 downto 0);  -- receive register
  signal cr   : std_logic_vector(7 downto 0);  -- command register
  signal sr   : std_logic_vector(7 downto 0);  -- status register


  -- internal wishbone signals
  signal wb_adr_i : std_logic_vector(1 downto 0);   -- lower address bits
  signal wb_dat_i : std_logic_vector(15 downto 0);  -- Databus input
  signal wb_dat_o : std_logic_vector(15 downto 0);  -- Databus output
  signal wb_we_i  : std_logic;          -- Write enable input
  signal wb_stb_i : std_logic;          -- Strobe signals / core select signal
  signal wb_cyc_i : std_logic;          -- Valid bus cycle input
  signal wb_ack_o : std_logic;          -- Bus cycle acknowledge output

  -- wishbone write access
  signal wb_wacc : std_logic;

  -- internal acknowledge signal
  signal iack_o : std_logic;

  -- done signal: command completed, clear command register
  signal done : std_logic;

  -- command register signals
  signal sta, sto, rd, wr, ack, iack : std_logic;

  signal core_en : std_logic;           -- core enable signal
  signal ien     : std_logic;           -- interrupt enable signal

  -- status register signals
  signal irxack, rxack : std_logic;     -- received aknowledge from slave
  signal tip           : std_logic;     -- transfer in progress
  signal irq_flag      : std_logic;     -- interrupt pending flag
  signal i2c_busy      : std_logic;     -- i2c bus busy (start signal detected)
  signal i2c_al, al    : std_logic;     -- arbitration lost

begin
  -- convert our wishbone signals to this module's wishbone signals
  wb_adr_i <= WB_WBS_I.addr_i(1 downto 0);
  wb_dat_i <= WB_WBS_I.dat_i;
  wb_we_i  <= WB_WBS_I.we_i;
  wb_stb_i <= WB_WBS_I.stb_i;
  wb_cyc_i <= WB_WBS_I.cyc_i;

  WB_WBS_O.ack_o <= wb_ack_o;
  WB_WBS_O.dat_o <= wb_dat_o;
  WB_WBS_O.err_o <= '0';

  -- generate acknowledge output signal
  gen_ack_o : process(WB_CLK)
  begin
    if rising_edge(WB_CLK) then
      iack_o <= wb_cyc_i and wb_stb_i and not iack_o;  -- because timing is always honored
    end if;
  end process gen_ack_o;
  wb_ack_o <= iack_o;

  -- generate wishbone write access signal
  wb_wacc <= wb_we_i and iack_o;

  -- assign wb_dat_o
  assign_dato : process(WB_CLK)
  begin
    if rising_edge(WB_CLK) then
      case wb_adr_i is
        when "00"   => wb_dat_o <= std_logic_vector(prer);
        when "01"   => wb_dat_o <= x"00" & ctr;
        when "10"   => wb_dat_o <= x"00" & rxr;  -- write is transmit register TxR
        when "11"   => wb_dat_o <= x"00" & sr;  -- write is command register CR
        when others => wb_dat_o <= (others => '1');
      end case;
    end if;
  end process assign_dato;


  -- generate registers (CR, SR see below)
  gen_regs : process(ARST, WB_CLK)
  begin
    if (ARST = '1') then
      prer <= (others => '1');
      ctr  <= (others => '0');
      txr  <= (others => '0');
    elsif rising_edge(WB_CLK) then
      if (WB_RST = '1') then
        prer <= (others => '1');
        ctr  <= (others => '0');
        txr  <= (others => '0');
      elsif (wb_wacc = '1') then
        case wb_adr_i is
          when "00"   => prer <= unsigned(wb_dat_i);
          when "01"   => ctr  <= wb_dat_i(7 downto 0);
          when "10"   => txr  <= wb_dat_i(7 downto 0);
          when others => null;  --write to CR, avoid executing the others clause
        end case;
      end if;
    end if;
  end process gen_regs;


  -- generate command register
  gen_cr : process(ARST, WB_CLK)
  begin
    if (ARST = '1') then
      cr <= (others => '0');
    elsif rising_edge(WB_CLK) then

      if (WB_RST = '1') then
        cr <= (others => '0');
      elsif (wb_wacc = '1') and (wb_adr_i = "11") and (core_en = '1') then
        -- only take new commands when i2c core enabled
        cr <= wb_dat_i(7 downto 0);
      else
        -- pending commands are finished
        if (done = '1') or (i2c_al = '1') then
          cr(7 downto 4) <= (others => '0');  -- clear command bits when command done or arbitration lost
        end if;

        cr(2 downto 1) <= (others => '0');  -- reserved bits, always '0'
        cr(0)          <= '0';              -- clear IRQ_ACK bit
      end if;

    end if;
  end process gen_cr;

  -- decode command register
  sta  <= cr(7);
  sto  <= cr(6);
  rd   <= cr(5);
  wr   <= cr(4);
  ack  <= cr(3);
  iack <= cr(0);

  -- decode control register
  core_en <= ctr(7);
  ien     <= ctr(6);

  -- hookup byte controller block
  byte_ctrl : entity work.i2c_master_byte_ctrl
    port map (
      clk      => WB_CLK,
      rst      => WB_RST,
      aReset   => ARST,
      ena      => core_en,
      clk_cnt  => prer,
      start    => sta,
      stop     => sto,
      do_read  => rd,
      do_write => wr,
      ack_in   => ack,
      i2c_busy => i2c_busy,
      i2c_al   => i2c_al,
      din      => txr,
      cmd_ack  => done,
      ack_out  => irxack,
      dout     => rxr,
      scl_i    => SCL_PAD_i,
      scl_o    => SCL_PAD_o,
      scl_oen  => SCL_PAD_T,
      sda_i    => SDA_PAD_i,
      sda_o    => SDA_PAD_o,
      sda_oen  => SDA_PAD_T
      );


  -- status register block + interrupt request signal
  st_irq_block : block
  begin
    -- generate status register bits
    gen_sr_bits : process (WB_CLK, ARST)
    begin
      if (ARST = '1') then
        al       <= '0';
        rxack    <= '0';
        tip      <= '0';
        irq_flag <= '0';
      elsif rising_edge(WB_CLK) then
        if (WB_RST = '1') then
          al       <= '0';
          rxack    <= '0';
          tip      <= '0';
          irq_flag <= '0';
        else
          rxack <= irxack;
          tip   <= (rd or wr);

          al       <= i2c_al or (al and not sta);
          -- interrupt request flag is always generated
          irq_flag <= (done or i2c_al or irq_flag) and not iack;
        end if;
      end if;
    end process gen_sr_bits;

    -- generate interrupt request signals
    gen_irq : process (WB_CLK, ARST)
    begin
      if (ARST = '1') then
        WB_INTA_o <= '0';
      elsif rising_edge(WB_CLK) then
        if (WB_RST = '1') then
          WB_INTA_o <= '0';
        else
          -- interrupt signal is only generated when
          -- ien (interrupt enable) bit is set
          WB_INTA_o <= irq_flag and ien;
        end if;
      end if;
    end process gen_irq;

    -- assign status register bits
    sr(7)          <= rxack;
    sr(6)          <= i2c_busy;
    sr(5)          <= al;
    sr(4 downto 2) <= (others => '0');  -- reserved
    sr(1)          <= tip;
    sr(0)          <= irq_flag;
  end block;

end architecture structural;
---------------------------------------------------------------------
----                                                             ----
----  WISHBONE revB2 compl. I2C Master Core; top level           ----
----                                                             ----
----                                                             ----
----  Author: Richard Herveille                                  ----
----          richard@asics.ws                                   ----
----          www.asics.ws                                       ----
----                                                             ----
----  Downloaded from: http://www.opencores.org/projects/i2c/    ----
----                                                             ----
---------------------------------------------------------------------
----                                                             ----
---- Copyright (C) 2000 Richard Herveille                        ----
----                    richard@asics.ws                         ----
----                                                             ----
---- This source file may be used and distributed without        ----
---- restriction provided that this copyright statement is not   ----
---- removed from the file and that any derivative work contains ----
---- the original copyright notice and the associated disclaimer.----
----                                                             ----
----     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ----
---- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ----
---- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ----
---- FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ----
---- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ----
---- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ----
---- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ----
---- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ----
---- BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ----
---- LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ----
---- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ----
---- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ----
---- POSSIBILITY OF SUCH DAMAGE.                                 ----
----                                                             ----
---------------------------------------------------------------------

--  CVS Log
--
--  $Id: i2c_master_top.vhd,v 1.8 2009-01-20 10:38:45 rherveille Exp $
--
--  $Date: 2009-01-20 10:38:45 $
--  $Revision: 1.8 $
--  $Author: rherveille $
--  $Locker:  $
--  $State: Exp $
--
-- Change History:
--               Revision 1.7  2004/03/14 10:17:03  rherveille
--               Fixed simulation issue when writing to CR register
--
--               Revision 1.6  2003/08/09 07:01:13  rherveille
--               Fixed a bug in the Arbitration Lost generation caused by delay on the (external) sda line.
--               Fixed a potential bug in the byte controller's host-acknowledge generation.
--
--               Revision 1.5  2003/02/01 02:03:06  rherveille
--               Fixed a few 'arbitration lost' bugs. VHDL version only.
--
--               Revision 1.4  2002/12/26 16:05:47  rherveille
--               Core is now a Multimaster I2C controller.
--
--               Revision 1.3  2002/11/30 22:24:37  rherveille
--               Cleaned up code
--
--               Revision 1.2  2001/11/10 10:52:44  rherveille
--               Changed PRER reset value from 0x0000 to 0xffff, conform specs.
--
