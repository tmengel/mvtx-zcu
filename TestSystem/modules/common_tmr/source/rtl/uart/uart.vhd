-- serial module

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity uart is
	generic(FREQUENCY : integer := 25000000;
		    BAUDRATE  : integer := 115200);
	Port(clk            : in  STD_LOGIC;
		 dbg            : out std_logic_vector(31 downto 0);
		 rst            : in  std_logic;
		 RS232in        : in  STD_LOGIC;
		 RS232out       : out STD_LOGIC;
		 RxD            : out STD_LOGIC_VECTOR(7 downto 0);
		 TxD            : in  STD_LOGIC_VECTOR(7 downto 0);
		 data_available : out STD_LOGIC;
		 data_sent      : out STD_LOGIC;
		 enable_send    : in  STD_LOGIC
	);
end uart;

architecture Behavioral of uart is
	type serdes_states is (idle, capture, capture_done, init_send, syncTick, send, send_done);
	signal cstate, nstate : serdes_states;

	constant BaudCountValue     : integer := FREQUENCY / BAUDRATE; --1736;	--870; --baudrate 115200 at 100MHz internal clock
	constant BaudCountHalfValue : integer := BaudCountValue / 2;

	signal shiftreg_input   : std_logic_vector(10 downto 0);
	signal shiftreg_output  : std_logic_vector(10 downto 0);
	signal baud_tick        : std_logic;
	signal baud_count       : natural range 0 to BaudCountValue;
	signal tick_count       : natural range 0 to 11;
	signal baud_enable      : std_logic;
	signal send_enable      : std_logic;
	signal RS232in_D        : std_logic;
	signal RS232in_Q        : std_logic_vector(7 downto 0);
	signal RS232out_D       : std_logic;
	signal RS232out_Q       : std_logic;
	signal i_data_available : std_logic;
	signal i_data_sent      : std_logic;

	signal RS232in_sync : std_logic;

	signal set_TxData     : std_logic;
	signal capture_enable : std_logic;

begin
	dbg(31)           <= RS232in_sync;
	dbg(30)           <= RS232out_D;
	dbg(29 downto 23) <= RS232in_Q(7 downto 1);
	dbg(22)           <= baud_tick;
	dbg(21 downto 0)  <= shiftreg_output & shiftreg_input;

	--baud-tick generator
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				baud_count <= 0;
			else
				if baud_enable = '1' and baud_count /= BaudCountValue then
					baud_count <= baud_count + 1;
				else
					baud_count <= 0;
				end if;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				baud_tick <= '0';
			else
				if baud_count = BaudCountHalfValue then
					baud_tick <= '1';
				else
					baud_tick <= '0';
				end if;
			end if;
		end if;
	end process;

	--shift-registers
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				shiftreg_input  <= (others => '1');
				shiftreg_output <= (others => '1');
				RS232out_D      <= '1';
			else
				if capture_enable = '1' and baud_tick = '1' then
					shiftreg_input <= shiftreg_input(shiftreg_input'high - 1 downto 0) & RS232in_sync;
				end if;

				if send_enable = '1' and baud_tick = '1' then
					shiftreg_output <= '1' & shiftreg_output(10 downto 1);
				elsif set_TxData = '1' then
					shiftreg_output <= "11" & TxD & '0';
				end if;

				RS232out_D <= shiftreg_output(0);
			end if;
		end if;
	end process;

	--serdes FSM
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				cstate     <= idle;
				tick_count <= 0;
			else
				cstate <= nstate;

				if cstate = capture or cstate = send then
					if baud_tick = '1' then
						tick_count <= tick_count + 1;
					end if;
				else
					tick_count <= 0;
				end if;
			end if;
		end if;
	end process;

	process(cstate, RS232in_sync, tick_count, enable_send, baud_tick, baud_count)
	begin
		nstate           <= cstate;
		baud_enable      <= '0';
		capture_enable   <= '0';
		send_enable      <= '0';
		set_TxData       <= '0';
		i_data_available <= '0';
		i_data_sent      <= '0';

		case cstate is
			when idle =>
				if RS232in_sync = '0' then
					nstate <= capture;
				elsif enable_send = '1' then
					nstate <= syncTick;
				else
					nstate <= idle;
				end if;

			when capture =>
				baud_enable    <= '1';
				capture_enable <= '1';

				if tick_count = 11 then
					nstate <= capture_done;
				else
					nstate <= capture;
				end if;

			when capture_done =>
				i_data_available <= '1';
				nstate           <= idle;

			when syncTick =>
				baud_enable <= '1';

				if baud_tick = '1' then
					nstate <= init_send;
				else
					nstate <= syncTick;
				end if;

			when init_send =>
				baud_enable <= '1';
				set_TxData  <= '1';

				nstate <= send;

			when send =>
				baud_enable <= '1';
				send_enable <= '1';

				if tick_count = 11 then
					nstate <= send_done;
				else
					nstate <= send;
				end if;

			when send_done =>
				i_data_sent <= '1';

				nstate <= idle;

			when others =>
				nstate <= idle;

		end case;

	end process;

	--I/O Registers
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				RS232out_Q   <= '1';
				RS232in_sync <= '1';
				RS232in_Q    <= (others => '1');
			else
				RS232out_Q <= RS232out_D;
				RS232in_Q  <= RS232in_Q(RS232in_Q'high - 1 downto 0) & RS232in_D;
				case RS232in_Q(RS232in_Q'high downto 3) is
					when "00000" => RS232in_sync <= '0';
					when "11111" => RS232in_sync <= '1';
					when others  => null;
				end case;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				--RxD            <= x"aa";
				RxD            <= "00000000";
				data_available <= '0';
				data_sent      <= '1';
			else
				if i_data_available = '1' then
					for i in 0 to 7 loop
						RxD(i) <= shiftreg_input(9 - i);
					end loop;
				end if;
				data_available <= i_data_available;
				data_sent      <= i_data_sent;
			end if;
		end if;
	end process;

	RS232in_D <= RS232in;
	RS232out  <= RS232out_Q;

end Behavioral;
