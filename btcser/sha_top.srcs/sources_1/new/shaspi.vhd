--
-- Copyright 2012 www.bitfury.org
--

--
--
-- Used addresses:
--

--
-- 0 .. 18 are used to load tasks, address 19 is not used
-- 30 .. 31 - nonce and midstate report result
--
-- Other addresses could be used for status / purge
--

-- TOP-level component is:

--component SHA_IfCtrl
--	port (
--		Clk		: in  std_logic;
--		ClkFast		: in  std_logic;
--
--		-- Chip identifier (used to parse correctly frame requests)
--		ChipID		: in  std_logic_vector( 2 downto 0);
--		AltChipID	: in  std_logic_vector( 2 downto 0);
--
--		-- DCM interface
--		DCM_Freeze	: out std_logic;
--		DCM_Data_En	: out std_logic;
--		DCM_Data	: out std_logic;
--		DCM_Rst		: out std_logic;
--		DCM_Locked	: in  std_logic;
--
--		-- SPI interface
--		MOSI		: in  std_logic;
--		SCK		: in  std_logic;
--		MISO		: out std_logic;
--		MISO_en		: out std_logic;
--
--		-- Interface with MainControl unit MC_D is 32-bit data bus
--		-- MC_A(5) is write enable, MC_A(4) is lower address part.
--		MC_D		: out std_logic_vector(31 downto 0);
--		MC_A		: out std_logic_vector( 5 downto 0);
--
--		-- Receives edge, when scanning is done.
--		ScanDone_in	: in  std_logic;
--
--		-- Receives data into FIFO when matches arrives.
--		Match_has	: in  std_logic;
--		Match_data	: in  std_logic_vector(31 downto 0)
--	);
--end component;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

-- 32-bit SPI register
-- Transferring data
entity SHA_SPI is
	port (
		Clk			: in  std_logic; -- Fast clock

		-- SPI wires access
		SCK			: in  std_logic; -- Serial transmission clock
		MOSI			: in  std_logic; -- MOSI input
		MISO			: out std_logic; -- MISO
		MISO_en			: out std_logic; -- Enable MISO driver

		-- Data buses
		
		D_in			: in  std_logic_vector(31 downto 0);
		D_in_pulse		: in  std_logic; -- Raise when TX wanted
		D_out			: out std_logic_vector(31 downto 0);
		D_out_pulse		: out std_logic;  -- Raised when data arrived
		D_busy			: out std_logic;  -- In the mid of transmission
		D_rst_pulse		: out std_logic
	);
end SHA_SPI;

architecture RTL of SHA_SPI is

--
-- Every 16384 clock cycles autoreset happens (when no SCK transitions)
-- So to have guaranteed reset we have to not touch SCK for about 32k cycles
-- (that is 100+ microseconds pause on SCK line).
--
-- From time to time we will have to execute line breaks.
--
-- For guaranteed delivery we shall work at least on 14400 bps
-- That is 35 microseconds approximately between SCK transitions.
-- 
signal rst_cnt : std_logic_vector(14 downto 0); -- reset count between SCK pulses
signal spi_rst, rst_rst_cnt : std_logic;
	-- 320 Mhz is the input clock. 32 cycles is bit transmission character.

signal bit_cnt : std_logic_vector(5 downto 0) := (others => '0'); -- Count 32-bit values.
signal Din_reg, Dout_reg : std_logic_vector(31 downto 0) := (others => '0');
signal Dshift_reg : std_logic_vector(32 downto 0) := (others => '0'); -- 33-bit shift register

signal SCK_filter, MOSI_filter : std_logic_vector(3 downto 0);
signal SCK_prev, SCK_filtered, MOSI_filtered, SCK_fall, SCK_rise : std_logic;
signal WR_en, MISO_enr : std_logic := '0';
signal S_busy : std_logic;
signal MISOenrst_cnt : std_logic_vector(3 downto 0);

begin
	-- Filter input using majority filter (MOSI / SCK), so single-pulse error will not disturb it!
	process (Clk) begin
		if rising_edge(Clk) then
			SCK_filter(0) <= SCK;
			SCK_filter(3 downto 1) <= SCK_filter(2 downto 0);
			MOSI_filter(0) <= MOSI;
			MOSI_filter(3 downto 1) <= MOSI_filter(2 downto 0);

			if SCK_filter = "0000" then
				SCK_filtered <= '0';
			elsif SCK_filter = "1111" then
				SCK_filtered <= '1';
			else
				SCK_filtered <= SCK_filtered;
			end if;

			if MOSI_filter = "0000" then
				MOSI_filtered <= '0';
			elsif MOSI_filter = "1111" then
				MOSI_filtered <= '1';
			else
				MOSI_filtered <= MOSI_filtered;
			end if;
		end if;
	end process;

	-- Detect clock edges
	process (Clk) begin
		if rising_edge(Clk) then
			SCK_prev <= SCK_filtered;
			SCK_rise <= (not SCK_prev) and SCK_filtered;
			SCK_fall <= (not SCK_filtered) and SCK_prev;
		end if;
	end process;

	-- Auto-reset counter (reset logics - counts till 4096 on fast clock and then fires reset)
	process (Clk) begin
		if rising_edge(Clk) then
			rst_rst_cnt <= (SCK_prev xor SCK_filtered) or rst_cnt(14);

			if rst_rst_cnt = '1' then
				rst_cnt <= (others => '0');
			else
				rst_cnt <= rst_cnt + 1;
			end if;

			spi_rst <= rst_cnt(14);
		end if;
	end process;
	D_rst_pulse <= spi_rst;

	-- Busy flag
	process (Clk) begin
		if rising_edge(Clk) then
			if spi_rst = '1' or bit_cnt(5) = '1' then
				S_busy <= '0';
			elsif SCK_rise = '1' then
				S_busy <= '1';
			else
				S_busy <= S_busy;
			end if;
		end if;
	end process;
	D_busy <= S_busy; -- "In transmission"

	-- Filling data into input shift register
	process (Clk) begin
		if rising_edge(Clk) then
			if spi_rst = '1' or bit_cnt(5) = '1' then -- Bit counter!
				bit_cnt <= (others => '0');
			elsif SCK_fall = '1' then
				bit_cnt <= bit_cnt + 1;
			else
				bit_cnt <= bit_cnt;
			end if;

			if bit_cnt(5) = '1' then -- Single pulse - output ready!
				D_out_pulse <= '1';
				Dout_reg <= Dshift_reg(31 downto 0);
			else
				Dout_reg <= Dout_reg;
				D_out_pulse <= '0';
		
			end if;
		end if;
	end process;
	D_out <= Dout_reg;

	-- If write enable was rised (i.e. when data was written), perform clocked write!
	process (Clk) begin
		if rising_edge(Clk) then
			if D_in_pulse = '1' then
				Din_reg <= D_in;
			else
				Din_reg <= Din_reg;
			end if;

			if D_in_pulse = '1' then
				WR_en <= '1';
			elsif spi_rst = '1' or bit_cnt(5) = '1' then
				WR_en <= '0';
			else
				WR_en <= WR_en;
			end if;

			if SCK_fall = '1' then
				MISOenrst_cnt <= (others => '0');
			elsif MISOenrst_cnt(3) = '0' then
				MISOenrst_cnt <= MISOenrst_cnt + 1;
			else
				MISOenrst_cnt <= MISOenrst_cnt;
			end if;

			if SCK_rise = '1' and WR_en = '1' then
				MISO_enr <= '1'; -- Enable write when SCK rising
			elsif S_busy = '0' and MISOenrst_cnt(3) = '1' then
				MISO_enr <= '0'; -- Disable write when count passed after falling edge!
			else
				MISO_enr <= MISO_enr;
			end if;

			-- On first rising edge - perform loading (if necessary) and then perform shifting of register
			if SCK_rise = '1' and MISO_enr = '0' and WR_en = '1' then
				Dshift_reg(32 downto 1) <= Din_reg;
			elsif SCK_rise = '1' then
				Dshift_reg(32 downto 1) <= Dshift_reg(31 downto 0);
			else
				Dshift_reg(32 downto 1) <= Dshift_reg(32 downto 1);
			end if;

			-- On falling edge perform sampling
			if SCK_fall = '1' then
				Dshift_reg(0) <= MOSI_filtered;
			else
				Dshift_reg(0) <= Dshift_reg(0);
			end if;
		end if;
	end process;
	MISO_en <= MISO_enr;
	MISO <= Dshift_reg(32);

end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

library UNISIM;
	use UNISIM.VComponents.All;

-- AddrX_in(6) is REQUEST bit.
-- AddrX_in(5) is WRITE ENABLE bit.
-- AddrX_in(4 downto 0) are possible 32 addresses

-- Accesses are prioritized - Addr1 has highest priority, Addr4 has lowest priority.
-- When higher priority access is performed, lower priority access waits!

-- Ack is rised next clock AFTER data was passed through MUX to memory. Valid D_out would appear
-- on next cycle after ACK. But it is _guaranteed_ that it will appear there!

-- D_out and Addr_out are fed with the result of read from memory. This way memory accesses can be monitored

entity SHA_4RAM is
	port (
		Clk			: in  std_logic;
		
		Addr1_in		: in  std_logic_vector( 6 downto 0);
		D1_in			: in  std_logic_vector(31 downto 0);
		Ack1_out		: out std_logic;
		
		Addr2_in		: in  std_logic_vector( 6 downto 0);
		D2_in			: in  std_logic_vector(31 downto 0);
		Ack2_out		: out std_logic;

		Addr3_in		: in  std_logic_vector( 6 downto 0);
		D3_in			: in  std_logic_vector(31 downto 0);
		Ack3_out		: out std_logic;

		Addr4_in		: in  std_logic_vector( 6 downto 0);
		D4_in			: in  std_logic_vector(31 downto 0);
		Ack4_out		: out std_logic;

		D_out			: out std_logic_vector(31 downto 0);
		Addr_out		: out std_logic_vector( 5 downto 0)  -- Output address
	);
end SHA_4RAM;
	
architecture PHY of SHA_4RAM is
	signal s_mux			: std_logic_vector( 1 downto 0);
	signal addr_mux_a, addr_mux	: std_logic_vector( 5 downto 0);
	signal ack_demux_a, ack_demux	: std_logic_vector( 3 downto 0);
	signal d_mux_a, dm, do_a	: std_logic_vector(31 downto 0);
	signal D_out_reg		: std_logic_vector(31 downto 0);
	signal addr_o			: std_logic_vector( 5 downto 0);
begin
	-- 0.25 Slice X usage
	SMUX0: LUT2 generic map (INIT => "1110") port map (O => s_mux(0), I1 => Addr1_in(6), I0 => Addr3_in(6));
	SMUX1: LUT2 generic map (INIT => "1110") port map (O => s_mux(1), I1 => Addr1_in(6), I0 => Addr2_in(6));

	-- We use low-level primitives to make use of SLICE X primitives in Spartan6
	-- 1.5 Slice X usage
	GA: for i in 0 to 5 generate
		AMU: LUT6 generic map (INIT => x"ff00f0f0ccccaaaa") port map (O => addr_mux_a(i), I5 => s_mux(1), I4 => s_mux(0), I3 => Addr1_in(i), I2 => Addr2_in(i), I1 => Addr3_in(i), I0 => Addr4_in(i));
		AMUF: FD port map (C => Clk, D => addr_mux_a(i), Q => addr_mux(i));
		AMUF1: FD port map (C => Clk, D => addr_mux(i), Q => addr_o(i));
	end generate;
	
	Addr_out <= addr_o; -- Output address is delayed correctly!

	-- 8 Slice X usage
	GD: for i in 0 to 31 generate
		AMU: LUT6 generic map (INIT => x"ff00f0f0ccccaaaa") port map (O => d_mux_a(i), I5 => s_mux(1), I4 => s_mux(0), I3 => D1_in(i), I2 => D2_in(i), I1 => D3_in(i), I0 => D4_in(i));
		AMUF: FD port map (C => Clk, D => d_mux_a(i), Q => dm(i));
	end generate;

	-- 0.5 Slice X usage
	ADMU0: LUT3 generic map (INIT => "00010000") port map (O => ack_demux_a(0), I2 => Addr4_in(6), I1 => s_mux(1), I0 => s_mux(0));
	ADMU1: LUT3 generic map (INIT => "00100000") port map (O => ack_demux_a(1), I2 => Addr3_in(6), I1 => s_mux(1), I0 => s_mux(0));
	ADMU2: LUT3 generic map (INIT => "01000000") port map (O => ack_demux_a(2), I2 => Addr2_in(6), I1 => s_mux(1), I0 => s_mux(0));
	ADMU3: LUT3 generic map (INIT => "10000000") port map (O => ack_demux_a(3), I2 => Addr1_in(6), I1 => s_mux(1), I0 => s_mux(0));
	ADMU0F: FD port map (C => Clk, D => ack_demux_a(0), Q => ack_demux(0));
	ADMU1F: FD port map (C => Clk, D => ack_demux_a(1), Q => ack_demux(1));
	ADMU2F: FD port map (C => Clk, D => ack_demux_a(2), Q => ack_demux(2));
	ADMU3F: FD port map (C => Clk, D => ack_demux_a(3), Q => ack_demux(3));

	Ack1_out <= ack_demux(3);
	Ack2_out <= ack_demux(2);
	Ack3_out <= ack_demux(1);
	Ack4_out <= ack_demux(0);

	-- 4 SLICE M usage
	GR: for i in 0 to 3 generate
		constant bs : integer := i*8;
	begin
		RB: RAM32M generic map (INIT_D => (others => '0')) port map (
			DOA => do_a(bs+1 downto bs), DOB => do_a(bs+3 downto bs+2), DOC => do_a(bs+5 downto bs+4), DOD => do_a(bs+7 downto bs+6),
			DIA =>   dm(bs+1 downto bs), DIB =>   dm(bs+3 downto bs+2), DIC =>   dm(bs+5 downto bs+4), DID =>   dm(bs+7 downto bs+6),
			WCLK => Clk, WE => addr_mux(5), ADDRA => addr_mux(4 downto 0), ADDRB => addr_mux(4 downto 0), ADDRC => addr_mux(4 downto 0),
			ADDRD => addr_mux(4 downto 0));
		RB1F: FD port map (C => Clk, D => do_a(bs  ), Q => D_out_reg(bs  ));
		RB2F: FD port map (C => Clk, D => do_a(bs+1), Q => D_out_reg(bs+1));
		RB3F: FD port map (C => Clk, D => do_a(bs+2), Q => D_out_reg(bs+2));
		RB4F: FD port map (C => Clk, D => do_a(bs+3), Q => D_out_reg(bs+3));
		RB5F: FD port map (C => Clk, D => do_a(bs+4), Q => D_out_reg(bs+4));
		RB6F: FD port map (C => Clk, D => do_a(bs+5), Q => D_out_reg(bs+5));
		RB7F: FD port map (C => Clk, D => do_a(bs+6), Q => D_out_reg(bs+6));
		RB8F: FD port map (C => Clk, D => do_a(bs+7), Q => D_out_reg(bs+7));
	end generate;

	D_out <= D_out_reg;

	-- Overall 10.25 Slice X usage + 4 Slice M usage. 14.25 Slices usage. Should fit well in 8 switches (8 S.M + 8 S.X)
end PHY;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

library UNISIM;
	use UNISIM.VComponents.All;

-- MatchFIFO stores MIDSTATE[0] - A and answer NONCE in memory queue (up to 16)
-- And works by uploading data
entity SHA_MatchFIFO is
	port (
		Clk			: in  std_logic;
		Rst			: in  std_logic; -- Reset operation

		-- Monitor avail matches
		Match_has		: in  std_logic;
		Match_data		: in  std_logic_vector(31 downto 0);
		ChipBusy		: in  std_logic;

		-- Monitor task loading
		MC_D			: in  std_logic_vector(31 downto 0);
		MC_A			: in  std_logic_vector( 5 downto 0);

		-- Level 1 when SHA_IfCtrl needs data
		NeedData		: in  std_logic;
		Addr_out		: out std_logic_vector( 6 downto 0);
		D_out			: out std_logic_vector(31 downto 0);
		Ack_in			: in  std_logic;

		-- Rises flag when empty
		IsEmpty			: out std_logic
	);
end SHA_MatchFIFO;

architecture PHY of SHA_MatchFIFO is
	constant MS0_sz   : integer := 11;
	signal MS0_cnt    : std_logic_vector(MS0_sz downto 0); -- 1024 cycles counter
	signal MS0_A, MS0 : std_logic_vector(31 downto 0) := (others => '0');
	signal MS_rst     : std_logic := '0';

	-- Read and write addresses
	signal rd_a, wr_a : std_logic_vector( 4 downto 0) := (others => '0');

	-- Memory access interface
	signal M_in, M_a, M_out : std_logic_vector(31 downto 0);
	signal A_in : std_logic_vector( 5 downto 0) := (others => '0');

	signal empty_flag : std_logic := '1';
	signal read_valid : std_logic := '0';
	signal in_reading : std_logic := '0'; -- In reading flag
begin
	-- (1) Monitor midstate loading, and load MS0 register after number of clocks.
	process (Clk) begin
		if rising_edge(Clk) then
			if MC_A = "100000" then
				MS0_cnt <= (others => '0');
				MS0_A <= MC_D;
			else
				MS0_A <= MS0_A;
				if MS0_cnt(MS0_sz) = '0' then
					MS0_cnt <= MS0_cnt + 1;
				else
					MS0_cnt <= MS0_cnt;
				end if;
			end if;
			if MS0_cnt(MS0_sz) = '1' then
				MS0 <= MS0_A;
			else
				MS0 <= MS0;
			end if;
		end if;
	end process;

	-- (2) If we have has_match, then perform write.
	process (Clk) begin
		if rising_edge(Clk) then
			if Rst = '1' then -- Increment write counter
				wr_a <= (others => '0');
			elsif (ChipBusy = '1' and Match_has = '1') or wr_a(0) = '1' then
				wr_a <= wr_a + 1;
			else
				wr_a <= wr_a;
			end if;
				
			-- Select address to be written
			if (ChipBusy = '1' and Match_has = '1') or wr_a(0) = '1' then
				A_in <= "1" & wr_a; -- Write addr enabled
			else
				A_in <= "0" & rd_a; -- Read  addr enabled
			end if;

			-- Load on memory input either input Match_data or MS0
			if (ChipBusy = '1' and Match_has = '1') and wr_a(0) = '0' then
				M_in <= Match_data;
			else
				M_in <= MS0;
			end if;
		end if;
	end process;

	-- (3) Perform read operations from memory
	Addr_out(6) <= read_valid; -- Raise write request
	Addr_out(5) <= read_valid; -- Raise write enable
	Addr_out(4 downto 1) <= (others => '1');
	D_out <= M_out;

	process (Clk) begin
		if rising_edge(Clk) then
			-- Rise IsEmpty flag
			if rd_a = wr_a or Rst = '1' then
				empty_flag <= '1';
			else
				empty_flag <= '0';
			end if;

			-- Read is valid (no write interfering here)
			if rd_a = A_in(4 downto 0) and in_reading = '1' then
				read_valid <= '1';
			else
				read_valid <= '0';
			end if;

			-- Increment reader, when acked from memory
			if Rst = '1' then
				rd_a <= (others => '0');
			elsif read_valid = '1' and Ack_in = '1' and A_in(0) = rd_a(0) then
				rd_a <= rd_a + 1;
			else
				rd_a <= rd_a;
			end if;
			
			-- Stop reading when rd_a turns to even
			if Rst = '1' or (read_valid = '1' and Ack_in = '1' and rd_a(0) = '1' and A_in(0) = '1') then
				in_reading <= '0';
			elsif empty_flag = '0' and NeedData = '1' then
				in_reading <= '1';
			else
				in_reading <= in_reading;
			end if;
			
			Addr_out(0) <= rd_a(0);
		end if;
	end process;

	IsEmpty <= empty_flag;

	-- 4 Slices M used
	GR: for i in 0 to 3 generate
		constant bs : integer := i*8;
	begin
		RB: RAM32M generic map (INIT_D => (others => '0')) port map (
			DOA =>  M_a(bs+1 downto bs), DOB =>  M_a(bs+3 downto bs+2), DOC =>  M_a(bs+5 downto bs+4), DOD =>  M_a(bs+7 downto bs+6),
			DIA => M_in(bs+1 downto bs), DIB => M_in(bs+3 downto bs+2), DIC => M_in(bs+5 downto bs+4), DID => M_in(bs+7 downto bs+6),
			WCLK => Clk, WE => A_in(5), ADDRA => A_in(4 downto 0), ADDRB => A_in(4 downto 0), ADDRC => A_in(4 downto 0),
			ADDRD => A_in(4 downto 0));
		RB1F: FD port map (C => Clk, D => M_a(bs  ), Q => M_out(bs  ));
		RB2F: FD port map (C => Clk, D => M_a(bs+1), Q => M_out(bs+1));
		RB3F: FD port map (C => Clk, D => M_a(bs+2), Q => M_out(bs+2));
		RB4F: FD port map (C => Clk, D => M_a(bs+3), Q => M_out(bs+3));
		RB5F: FD port map (C => Clk, D => M_a(bs+4), Q => M_out(bs+4));
		RB6F: FD port map (C => Clk, D => M_a(bs+5), Q => M_out(bs+5));
		RB7F: FD port map (C => Clk, D => M_a(bs+6), Q => M_out(bs+6));
		RB8F: FD port map (C => Clk, D => M_a(bs+7), Q => M_out(bs+7));
	end generate;
end PHY;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

entity SHA_DCMLoader is
	port (
		Clk			: in  std_logic;
		Addr			: in  std_logic_vector( 5 downto 0);
		D_in			: in  std_logic_vector(31 downto 0);
		DCM_Loading		: in  std_logic;
		DCM_Done		: out std_logic;
		DCM_Freeze		: out std_logic;
		DCM_Data_En		: out std_logic;
		DCM_Data		: out std_logic;
		DCM_Rst			: out std_logic;
		DCM_Locked		: in  std_logic
	);
end SHA_DCMLoader;

architecture RTL of SHA_DCMLoader is

signal div_val : std_logic_vector(7 downto 0) := "00000000"; -- 1  - default divisor value (0)
signal mul_val : std_logic_vector(7 downto 0) := "00001011"; -- 12 - default multiplier value (11)
signal pc : std_logic_vector(5 downto 0) := "000000";

signal lock_rised, prev_lock_rised, dcm_done_del1, dcm_done_del2, dcm_done_del3, dcm_done_del4 : std_logic := '0';
signal dcm_done_del5, dcm_done_del6, dcm_done_del7, dcm_done_del8 : std_logic := '0';

begin
	-- Monitor address, when address is 24 then load values (low byte is divisor, high byte is multiplier)
	process (Clk) begin
		if rising_edge(Clk) then
			if Addr(4 downto 0) = "11000" and D_in(15 downto 0) = not D_in(31 downto 16) then
				div_val <= D_in(7 downto 0);
				mul_val <= D_in(15 downto 8);
			else
				div_val <= div_val;
				mul_val <= mul_val;
			end if;
		end if;
	end process;

	-- Activate counter when DCM_Loading = 1. 
	-- lock_rised monitors for DCM_Locked after programming was done
	-- prev_lock_rised used to find edge when programming was done
	process (Clk) begin
		if rising_edge(Clk) then
			if DCM_Loading = '0' then
				pc <= "000000"; -- Starting point
				lock_rised <= DCM_Locked;
				prev_lock_rised <= '1';
			elsif conv_integer(pc) < 62 then -- Make delay before monitoring lock status!
				pc <= pc + 1;
				lock_rised <= '0';
				prev_lock_rised <= '0';
			else
				lock_rised <= DCM_Locked;
				prev_lock_rised <= lock_rised;
				pc <= pc;
			end if;
		end if;
	end process;
	DCM_Freeze <= lock_rised; -- Freeze DCM at this point...

	-- When rising edge detected on lock_rised, then we generate done pulse with some delay
	process (Clk) begin
		if rising_edge(Clk) then
			if prev_lock_rised = '0' and lock_rised = '1' then
				dcm_done_del1 <= DCM_Loading;
			else
				dcm_done_del1 <= '0';
			end if;
			dcm_done_del2 <= dcm_done_del1 and DCM_Loading;
			dcm_done_del3 <= dcm_done_del2 and DCM_Loading;
			dcm_done_del4 <= dcm_done_del3 and DCM_Loading; -- This flag rises _later_ so SHA_MCFIFO becomes empty and synchronized!
			dcm_done_del5 <= dcm_done_del4 and DCM_Loading;
			dcm_done_del6 <= dcm_done_del5 and DCM_Loading;
			dcm_done_del7 <= dcm_done_del6 and DCM_Loading;
			dcm_done_del8 <= dcm_done_del7 and DCM_Loading;
		end if;
	end process;
	DCM_Done <= dcm_done_del8;

	-- Generating programming signals
	-- Reset is always low.
	-- PC:  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
	-- EN:  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  1
	-- DT:  0  1  0 d0 d1 d2 d3 d4 d5 d6 d7  0  0  0  0  0  1  1 m0 m1 m2 m3 m4 m5 m6 m7  0  0  0  0  0  0
	DCM_Rst <= '0';
	process (Clk) begin
		if rising_edge(Clk) then
			if (conv_integer(pc) >= 1 and conv_integer(pc) <= 10) or (conv_integer(pc) >= 16 and conv_integer(pc) <= 25) or
			   conv_integer(pc) = 31 then
				DCM_Data_En <= '1';
			else
				DCM_Data_En <= '0';
			end if;

			if conv_integer(pc) = 1 or conv_integer(pc) = 16 or conv_integer(pc) = 17 then
				DCM_Data <= '1';
			elsif conv_integer(pc) >= 3 and conv_integer(pc) <= 10 then
				DCM_Data <= div_val(conv_integer(pc)-3); -- Least significant bit first
			elsif conv_integer(pc) >= 18 and conv_integer(pc) <= 25 then
				DCM_Data <= mul_val(conv_integer(pc)-18); -- Least significant bit first
			else
				DCM_Data <= '0';
			end if;
		end if;
	end process;
end RTL;

-- SHA_TaskLoader - loads first task as soon as it is ready.
-- When it starts - it feeds task immediately. And also rises flag when no task available in a queue
-- It also monitors writes to last entity

-- Copy 0..7 midstate 0 8..15 midstate 3 16,17,18 - W[0] W[1] W[2]

-- Also monitor for DCM register (reg. no 24/25 reads and writes)
-- Validate and load these values into interm. register

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_TaskLoader is
	port (
		Clk			: in  std_logic;

		-- Purge request
		Rst			: in  std_logic;

		-- DCM programming interface - program DCM entry
		DCM_Freeze	: out std_logic;
		DCM_Data_En	: out std_logic;
		DCM_Data	: out std_logic;
		DCM_Rst		: out std_logic;
		DCM_Locked	: in  std_logic;

		-- Connection with SHA_MainControl unit
		MC_D			: out std_logic_vector(31 downto 0);
		MC_A			: out std_logic_vector( 5 downto 0);

		-- IsEmpty flag (when new job would be accepted)
		IsEmpty			: out std_logic;
		
		-- Chip is working flag
		ChipBusy		: out std_logic;

		-- ScanDone raised when previous scan was completed
		ScanDone_in		: in  std_logic;

		-- Interface with RAM (for reading)
		Addr_out		: out std_logic_vector( 6 downto 0);
		Addr_in			: in  std_logic_vector( 5 downto 0);
		D_in			: in  std_logic_vector(31 downto 0);
		Ack_in			: in  std_logic
	);
end SHA_TaskLoader;

architecture RTL of SHA_TaskLoader is
	component SHA_DCMLoader
		port (
			Clk		: in  std_logic;
			Addr		: in  std_logic_vector( 5 downto 0);
			D_in		: in  std_logic_vector(31 downto 0);
			DCM_Loading	: in  std_logic;
			DCM_Done	: out std_logic;
			DCM_Freeze	: out std_logic;
			DCM_Data_En	: out std_logic;
			DCM_Data	: out std_logic;
			DCM_Rst		: out std_logic;
			DCM_Locked	: in  std_logic
		);
	end component;

-- Generic flags
signal task_loaded, task_loaded_rst : std_logic;

signal dcm_loading, dcm_done : std_logic := '0';
signal task_loading	: std_logic := '0';
signal task_loading_pr  : std_logic := '0';
signal sys_empty	: std_logic := '1';

-- Address count for loading purposes
signal addr_cnt		: std_logic_vector(4 downto 0) := (others => '0');

-- Pipelined output to SHA_MainControl
signal MC_D_reg		: std_logic_vector(31 downto 0) := (others => '0');
signal MC_A_reg		: std_logic_vector( 5 downto 0) := (others => '0');
signal chip_wrk_cnt     : std_logic_vector( 7 downto 0) := (others => '0');
signal chip_busy	: std_logic := '0';

signal awmatch : std_logic := '0';

begin
	DCMLoader_inst: SHA_DCMLoader
		port map (
			Clk => Clk, Addr => Addr_in, D_in => D_in,
			DCM_Loading => dcm_loading, DCM_Done => dcm_done,
			DCM_Freeze => DCM_Freeze, DCM_Data_En => DCM_Data_En, DCM_Data => DCM_Data,
			DCM_Rst => DCM_Rst, DCM_Locked => DCM_Locked
		);

	-- Monitor whether chip busy or not ?
	process (Clk) begin
		if rising_edge(Clk) then
			if task_loaded = '1' then
				chip_wrk_cnt <= (others => '0');
			elsif chip_wrk_cnt(chip_wrk_cnt'left) = '0' then
				chip_wrk_cnt <= chip_wrk_cnt + 1;
			else
				chip_wrk_cnt <= chip_wrk_cnt;
			end if;	
			
			if chip_wrk_cnt(chip_wrk_cnt'left) = '1' or Rst = '1' then
				chip_busy <= '0';
			elsif task_loaded = '1' then
				chip_busy <= '1';
			else
				chip_busy <= chip_busy;
			end if;
		end if;
	end process;
	ChipBusy <= chip_busy;

	-- Single asynchronous element with dedicated clock enable!
	-- As ScanDone_in appears at much higher clock rate, it is _important_ to make clear asynchronous!
	task_loaded_rst <= Rst or ScanDone_in;
	TSLFD: FDCE generic map (INIT => '0') port map (D => '1', CE => awmatch, C => Clk, CLR => task_loaded_rst, Q => task_loaded); 
	
	-- Perform dataset loading
	process (Clk) begin
		if rising_edge(Clk) then
			if Rst = '1' then
				sys_empty <= '1';
			elsif Addr_in(4 downto 1) = "1001" then
				sys_empty <= not Addr_in(5);
			else
				sys_empty <= sys_empty;
			end if;
			
			if MC_A_reg(5 downto 0) = "110001" then
				awmatch <= '1';
			else
				awmatch <= '0';
			end if;
			
			if Rst = '1' or dcm_done = '1' then
				dcm_loading <= '0';
			elsif task_loaded = '0' and sys_empty = '0' and task_loading = '0' then
				dcm_loading <= '1';
			else
				dcm_loading <= dcm_loading;
			end if;
			
			if Rst = '1' or awmatch = '1' then
				task_loading <= '0';
			elsif dcm_done = '1' then -- Start loading task after dcm_done pulse arrived!
				task_loading <= '1';
			else
				task_loading <= task_loading;
			end if;
			
			task_loading_pr <= task_loading;
		end if;
	end process;
	IsEmpty <= sys_empty; -- Tell if our queue is empty

	-- Increment address counter on each received acknowledgement
	process (Clk) begin
		if rising_edge(Clk) then
			if task_loading = '1' and task_loading_pr = '0' then
				addr_cnt <= (others => '0');
			elsif task_loading = '1' and Ack_in = '1' then
				addr_cnt <= addr_cnt + 1; -- Increment address counter
			else
				addr_cnt <= addr_cnt;
			end if;
		end if;
	end process;
	Addr_out <= task_loading & '0' & addr_cnt;

	-- Writing to programming register (monitoring output)
	process (Clk) begin
		if rising_edge(Clk) then
			if conv_integer(Addr_in(4 downto 0)) < 19 then
				MC_D_reg <= D_in;
				MC_A_reg(4 downto 0) <= Addr_in(4 downto 0);
			else
				MC_D_reg <= MC_D_reg;
				MC_A_reg(4 downto 0) <= MC_A_reg(4 downto 0);
			end if;
		end if;
	end process;
	MC_A_reg(5) <= task_loading;
	
	MC_D <= MC_D_reg;
	MC_A <= MC_A_reg;
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

library UNISIM;
	use UNISIM.VComponents.All;
	
entity SHA_RegCtrl is
	port (
		Clk			: in  std_logic;
		ChipID			: in  std_logic_vector( 2 downto 0);

		-- MOSI/SCK/MISO with 3-state control (bus)
		MOSI			: in  std_logic;
		SCK			: in  std_logic;
		MISO			: out std_logic;
		MISO_en			: out std_logic;

		-- Communicating with memory (register reads/writes)

		-- We have highest priority here and expect that read/write ops
		-- always happens within 2 clock cycles!

		D_in			: in  std_logic_vector(31 downto 0);
		D_out			: out std_logic_vector(31 downto 0);
		Addr_out		: out std_logic_vector( 6 downto 0)
	);
end SHA_RegCtrl;

architecture RTL of SHA_RegCtrl is
	component SHA_SPI
		port (
			Clk		: in  std_logic; -- Fast clock

			-- SPI wires access
			SCK		: in  std_logic; -- Serial transmission clock
			MOSI		: in  std_logic; -- MOSI input
			MISO		: out std_logic; -- MISO
			MISO_en		: out std_logic; -- Enable MISO driver

			-- Data buses
		
			D_in		: in  std_logic_vector(31 downto 0);
			D_in_pulse	: in  std_logic; -- Raise when TX wanted
			D_out		: out std_logic_vector(31 downto 0);
			D_out_pulse	: out std_logic;  -- Raised when data arrived
			D_busy		: out std_logic;  -- In the mid of transmission
			D_rst_pulse	: out std_logic
		);
	end component;

signal D_addr : std_logic_vector(6 downto 0) := (others => '0');

signal SPI_in, SPI_out : std_logic_vector(31 downto 0);
signal pre_SPI_in_pulse, SPI_in_pulse, SPI_out_pulse, SPI_busy, SPI_rst, SPI_out_pulse_d : std_logic := '0';
signal old_core_ena, core_ena, core_ena_a, recv_cmd_a, recv_cmd : std_logic;

signal lg : std_logic_vector(6 downto 0);
signal lg_a, lg_d, lg_ca, lg_cd : std_logic;

begin
	SHASPIinst: SHA_SPI port map (
		Clk => Clk,
		SCK => SCK,
		MOSI => MOSI,
		MISO => MISO,
		MISO_en => MISO_en,
		D_in => SPI_in,
		D_in_pulse => SPI_in_pulse,
		D_out => SPI_out,
		D_out_pulse => SPI_out_pulse,
		D_busy => SPI_busy,
		D_rst_pulse => SPI_rst
	);

	-- random match probability is 1/(2^26) when desync error happens
	-- this makes parse errors to be extremly unlikely

	-- Command format (with frame synchronization and error checking):
	-- 1010 0CCC 10WA AAAA 0101 1ccc 01wa aaaa
	     
	-- Compare for negations 
	LLG0: LUT6 generic map (INIT => x"0000066006600000") port map (O => lg(0), I5 => SPI_out(0), I4 => SPI_out(16), I3 => SPI_out(1), I2 => SPI_out(17), I1 => SPI_out(2), I0 => SPI_out(18));
	LLG1: LUT6 generic map (INIT => x"0000066006600000") port map (O => lg(1), I5 => SPI_out(3), I4 => SPI_out(19), I3 => SPI_out(4), I2 => SPI_out(20), I1 => SPI_out(5), I0 => SPI_out(21));
	LLG2: LUT6 generic map (INIT => x"0000000000800000") port map (O => lg(2), I5 => SPI_out(15), I4 => SPI_out(14), I3 => SPI_out(13), I2 => SPI_out(12), I1 => SPI_out(11), I0 => SPI_out(31));
	LLG3: LUT6 generic map (INIT => x"0000000000020000") port map (O => lg(3), I5 => SPI_out(30), I4 => SPI_out(29), I3 => SPI_out(28), I2 => SPI_out(27), I1 => SPI_out(7), I0 => SPI_out(6));
	LLG4: LUT5 generic map (INIT => x"00040000") port map (O => lg(4), I4 => SPI_out(23), I3 => SPI_out(22), I2 => recv_cmd, I1 => SPI_out_pulse, I0 => SPI_rst);
	
	-- Compare actual values of SPI_out(26 downto 24) - for inversion
	LLG5: LUT6 generic map (INIT => x"0000066006600000") port map (O => lg(5), I5 => SPI_out(8), I4 => SPI_out(24), I3 => SPI_out(9), I2 => SPI_out(25), I1 => SPI_out(10), I0 => SPI_out(26));
	
	-- Compare with ChipID (3-bit)
	LLG6: LUT6 generic map (INIT => x"0000066006600000") port map (O => lg(6), I5 => SPI_out(8), I4 => ChipID(0), I3 => SPI_out(9), I2 => ChipID(1), I1 => SPI_out(10), I0 => ChipID(2));
	
	LLGA:  LUT6 generic map (INIT => x"8000000000000000") port map (O => lg_a, I5 => lg(5), I4 => lg(4), I3 => lg(3), I2 => lg(2), I1 => lg(1), I0 => lg(0));
	LLGCA: LUT6 generic map (INIT => x"8000000000000000") port map (O => lg_ca,I5 => lg(6), I4 => lg(4), I3 => lg(3), I2 => lg(2), I1 => lg(1), I0 => lg(0));
	
	LGF1: FD port map (C => Clk, D => lg_a, Q => lg_d);
	LGF2: FD port map (C => Clk, D => lg_ca, Q => lg_cd);
	LGFD: FD port map (C => Clk, D => SPI_out_pulse, Q => SPI_out_pulse_d);
	
	LCENA: LUT5 generic map (INIT => x"ff07ff00") port map (O => core_ena_a, I4 => core_ena, I3 => lg_cd, I2 => SPI_rst, I1 => SPI_out_pulse, I0 => recv_cmd);
	LRCVC: LUT4 generic map (INIT => x"ff02") port map (O => recv_cmd_a, I3 => lg_d, I2 => SPI_rst, I1 => SPI_out_pulse, I0 => recv_cmd);
	
	LCENAF: FD port map (C => Clk, D => core_ena_a, Q => core_ena);
	LCENAFD: FD port map (C => Clk, D => core_ena, Q => old_core_ena);
	LRCVCF: FD port map (C => Clk, D => recv_cmd_a, Q => recv_cmd);
	
	-- Place set of sync muxes on address bus (address loading)
	process (Clk) begin
		if rising_edge(Clk) then			
			if lg_d = '1' then
				D_addr(5 downto 0) <= SPI_out(21 downto 16);
			else
				D_addr(5 downto 0) <= D_addr(5 downto 0);
			end if;
		end if;
	end process;

	process (Clk) begin
		if rising_edge(Clk) then
			-- Rise REQ pulse in two conditions. One condition is to make reading immediately,
			-- which happens on next clock after SPI_out_pulse arrival. and would take
			-- additional clock to set REQ and then two clocks to wait response from RAM and send pulse to SPI.
			-- so in 5 clocks solution will be in place.

			-- Second REQ pulse is immediately after SPI_out_pulse to perform write request execution.
			if ((D_addr(5) = '0' and core_ena = '1' and old_core_ena = '0') or
			   (D_addr(5) = '1' and core_ena = '1' and SPI_out_pulse = '1')) and SPI_rst = '0' then
				D_addr(6) <= '1';
			else
				D_addr(6) <= '0';
			end if;

			-- When READ request was forwarded, pre_SPI_in_pulse is delayed one clock cycle
			-- This cycle is actually address loading cycle
			if D_addr(5) = '0' and D_addr(6) = '1' then
				pre_SPI_in_pulse <= '1';
			else
				pre_SPI_in_pulse <= '0';
			end if;

			-- Actualize simultaneously (moment exactly matches read-out from memory)
			SPI_in_pulse <= pre_SPI_in_pulse;
		end if;
	end process;

	-- Connect SHA_SPI registers and address generator with 4-way RAM
	D_out <= SPI_out;
	SPI_in <= D_in;
	Addr_out <= D_addr;
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

entity SHA_MCFIFO is
	port (
		ClkSrc			: in  std_logic;
		ClkDst			: in  std_logic;
		Src			: in  std_logic_vector(37 downto 0);
		Dst			: out std_logic_vector(37 downto 0)
	);
end SHA_MCFIFO;

architecture RTL of SHA_MCFIFO is
	type fmem_type is array (0 to 3) of std_logic_vector(38 downto 0); -- 39-bit memory line
	signal fmem : fmem_type := (others => (others => '0'));

	attribute ram_style : string;
	attribute ram_style of fmem : signal is "distributed";

	signal rdcnt  : std_logic_vector(2 downto 0) := "100";
	signal wrcnt  : std_logic_vector(2 downto 0) := "100";

	signal memdata : std_logic_vector(38 downto 0);
	signal D_read : std_logic := '0';
	signal D_reg : std_logic_vector(37 downto 0) := (others => '0');
begin
	-- Write there without stopping! Ignore any possible overflow conditions!
	process (ClkSrc) begin
		if rising_edge(ClkSrc) then
			fmem(conv_integer(wrcnt(1 downto 0))) <= wrcnt(2) & Src;
			wrcnt <= wrcnt + 1;
		end if;
	end process;

	-- Read asynchronously from memory
	memdata <= fmem(conv_integer(rdcnt(1 downto 0)));

	-- Read on destination (fast clock).
	process (ClkDst) begin
		if rising_edge(ClkDst) then
			-- Ensure that all bits are read (we assume that within ClkDst periods all values in all memory bits are stable)
			if memdata(38) = rdcnt(2) and D_read = '0' then
				D_read <= '1';
			else
				D_read <= '0';
			end if;

			if D_read = '1' then
				D_reg <= memdata(37 downto 0);
				rdcnt <= rdcnt + 1;
			else
				D_reg <= D_reg;
				rdcnt <= rdcnt;
			end if;
		end if;
	end process;

	Dst <= D_reg;
end RTL;

-- Entity - SHA_MatchFIFO (16-level FIFO) with interleaver, internal data monitor and addr gen
-- Entity - SHA_TaskLoader    - performs loading of tasks
-- Entity - SHA_RegCtrl       - Register access controller

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;

-- IfCtrl is interface controller
-- It communicates with SHA_Match primitive, ScanDone primitive and MISO/MISO_en/MOSI/SCK + ID ports (outside world)
-- Core of controller are internal flags and 4-way access RAM
entity SHA_IfCtrl is
	port (
		Clk			: in  std_logic;
		ClkFast			: in  std_logic;

		-- Chip identifier (used to parse correctly frame requests)
		ChipID			: in  std_logic_vector( 2 downto 0);
		AltChipID		: in  std_logic_vector( 2 downto 0);

		-- SPI interface
		MOSI			: in  std_logic;
		SCK			: in  std_logic;
		MISO			: out std_logic;
		MISO_en			: out std_logic;

		-- DCM programming interface
		DCM_Freeze		: out std_logic;
		DCM_Data_En		: out std_logic;
		DCM_Data		: out std_logic;
		DCM_Rst			: out std_logic;
		DCM_Locked		: in  std_logic;

		-- These works on ClkFast speed!
		-- Interface with MainControl unit MC_D is 32-bit data bus
		-- MC_A(5) is write enable, MC_A(4) is lower address part.
		MC_D			: out std_logic_vector(31 downto 0);
		MC_A			: out std_logic_vector( 5 downto 0);

		-- Receives edge, when scanning is done.
		ScanDone_in		: in  std_logic;

		-- Receives data into FIFO when matches arrives.
		Match_has		: in  std_logic;
		Match_data		: in  std_logic_vector(31 downto 0)
	);
end SHA_IfCtrl;

architecture RTL of SHA_IfCtrl is
	component SHA_MCFIFO
		port (
			ClkSrc		: in  std_logic;
			ClkDst		: in  std_logic;
			Src		: in  std_logic_vector(37 downto 0);
			Dst		: out std_logic_vector(37 downto 0)
		);
	end component;

	component SHA_4RAM
		port (
			Clk		: in  std_logic;
			
			Addr1_in	: in  std_logic_vector( 6 downto 0);
			D1_in		: in  std_logic_vector(31 downto 0);
			Ack1_out	: out std_logic;
			
			Addr2_in	: in  std_logic_vector( 6 downto 0);
			D2_in		: in  std_logic_vector(31 downto 0);
			Ack2_out	: out std_logic;

			Addr3_in	: in  std_logic_vector( 6 downto 0);
			D3_in		: in  std_logic_vector(31 downto 0);
			Ack3_out	: out std_logic;

			Addr4_in	: in  std_logic_vector( 6 downto 0);
			D4_in		: in  std_logic_vector(31 downto 0);
			Ack4_out	: out std_logic;

			D_out		: out std_logic_vector(31 downto 0);
			Addr_out	: out std_logic_vector( 5 downto 0)  -- Output address
		);
	end component;
	component SHA_MatchFIFO
		port (
			Clk		: in  std_logic;
			Rst		: in  std_logic; -- Reset operation

			-- Monitor avail matches
			Match_has	: in  std_logic;
			Match_data	: in  std_logic_vector(31 downto 0);
			ChipBusy	: in  std_logic;

			-- Monitor task loading
			MC_D		: in  std_logic_vector(31 downto 0);
			MC_A		: in  std_logic_vector( 5 downto 0);

			-- Level 1 when SHA_IfCtrl needs data
			NeedData	: in  std_logic;
			Addr_out	: out std_logic_vector( 6 downto 0);
			D_out		: out std_logic_vector(31 downto 0);
			Ack_in		: in  std_logic;

			-- Rises flag when empty
			IsEmpty		: out std_logic
		);
	end component;
	component SHA_TaskLoader
		port (
			Clk		: in  std_logic;

			-- Purge request
			Rst		: in  std_logic;

			-- DCM programming interface
			DCM_Freeze	: out std_logic;
			DCM_Data_En	: out std_logic;
			DCM_Data	: out std_logic;
			DCM_Rst		: out std_logic;
			DCM_Locked	: in  std_logic;

			-- Connection with SHA_MainControl unit
			MC_D		: out std_logic_vector(31 downto 0);
			MC_A		: out std_logic_vector( 5 downto 0);

			-- IsEmpty flag (when new job would be accepted)
			IsEmpty		: out std_logic;
			-- Chip is working flag
			ChipBusy	: out std_logic;

			-- ScanDone raised when previous scan was completed
			ScanDone_in	: in  std_logic;

			-- Interface with RAM (for reading)
			Addr_out	: out std_logic_vector( 6 downto 0);
			Addr_in		: in  std_logic_vector( 5 downto 0);
			D_in		: in  std_logic_vector(31 downto 0);
			Ack_in		: in  std_logic
		);
	end component;
	component SHA_RegCtrl
		port (
			Clk		: in  std_logic;
			ChipID		: in  std_logic_vector( 2 downto 0);

			-- MOSI/SCK/MISO with 3-state control (bus)
			MOSI		: in  std_logic;
			SCK		: in  std_logic;
			MISO		: out std_logic;
			MISO_en		: out std_logic;

			-- Communicating with memory (register reads/writes)

			-- We have highest priority here and expect that read/write ops
			-- always happens within 2 clock cycles!

			D_in		: in  std_logic_vector(31 downto 0);
			D_out		: out std_logic_vector(31 downto 0);
			Addr_out	: out std_logic_vector( 6 downto 0)
		);
	end component;

-- memory address access
signal Addr1_in, Addr2_in, Addr3_in, Addr4_in : std_logic_vector( 6 downto 0);
signal MC_D_reg, D_out, D1_in, D2_in, D3_in, D4_in : std_logic_vector(31 downto 0);
signal Ack2_out, Ack3_out : std_logic;
signal MC_A_reg, Addr_out : std_logic_vector( 5 downto 0);

signal OutEmpty : std_logic := '1';

signal MatchEmpty, TaskEmpty, ChipBusy, Rst_pulse : std_logic;
signal AltID_fixed, ChipID_fixed : std_logic_vector( 2 downto 0);

begin
	AltID_fixed <= AltChipID when AltChipID(2) = '0' else (AltChipID(2) & (not AltChipID(1)) & (not AltChipID(0)));
	ChipID_fixed <= ChipID when (ChipID /= "111") else AltID_fixed;

	D3_in <= (others => '0');

	-- Core of functionality is 4-way RAM with one internal pipeline level
	-- Addr1 has highest priority, while Addr4 has lowest
	SHA_4RAM_inst: SHA_4RAM port map (
		Clk => Clk, D_out => D_out, Addr_out => Addr_out,
		Addr1_in => Addr1_in, D1_in => D1_in, Ack1_out => open,
		Addr2_in => Addr2_in, D2_in => D2_in, Ack2_out => Ack2_out,
		Addr3_in => Addr3_in, D3_in => D3_in, Ack3_out => Ack3_out,
		Addr4_in => Addr4_in, D4_in => D4_in, Ack4_out => open );

	-- This component accesses RAM with highest priority from SPI port
	SHA_RegCtrl_inst: SHA_RegCtrl port map (
		Clk => Clk, ChipID => ChipID_fixed,
		MOSI => MOSI, SCK => SCK, MISO => MISO, MISO_en => MISO_en,
		D_in => D_out, D_out => D1_in, Addr_out => Addr1_in );

	-- This component can store up to 16 results obtained from calculations
	-- and feed them to SPI
	SHA_MatchFIFO_inst: SHA_MatchFIFO port map (
		Clk => Clk, Rst => Rst_pulse, Match_has => Match_has, Match_data => Match_data, ChipBusy => ChipBusy,
		MC_D => MC_D_reg, MC_A => MC_A_reg,
		NeedData => OutEmpty, Addr_out => Addr2_in, D_out => D2_in, Ack_in => Ack2_out, IsEmpty => MatchEmpty);

	-- This component performs loading of tasks and monitors new task uploads
	SHA_TaskLoader_inst: SHA_TaskLoader port map (
		Clk => Clk, Rst => Rst_pulse,
		DCM_Freeze => DCM_Freeze,
		DCM_Data_En => DCM_Data_En,
		DCM_Data => DCM_Data,
		DCM_Rst => DCM_Rst,
		DCM_Locked => DCM_Locked,
		MC_D => MC_D_reg, MC_A => MC_A_reg,
		IsEmpty => TaskEmpty, ChipBusy => ChipBusy, ScanDone_in => ScanDone_in,
		Addr_out => Addr3_in, Addr_in => Addr_out, D_in => D_out, Ack_in => Ack3_out);

	-- MC_A and MC_D are sampled on fast clock... needs fifo to be placed there!
	SHA_MCFIFO_inst: SHA_MCFIFO port map (
		ClkSrc => Clk, ClkDst => ClkFast,
		Src(31 downto 0) => MC_D_reg, Src(37 downto 32) => MC_A_reg,
		Dst(31 downto 0) => MC_D, Dst(37 downto 32) => MC_A );

	-- Generate reset pulse, when write to register 28 detected
	process (Clk) begin
		if rising_edge(Clk) then
			if Addr_out = "111100" then
				Rst_pulse <= '1';
			else
				Rst_pulse <= '0';
			end if;
		end if;
	end process;

	-- Monitor updates of output registers (30 and 31)
	process (Clk) begin
		if rising_edge(Clk) then
			if Rst_pulse = '1' or Addr_out = "011111" then -- If reading of 31 reg. performed - mark output as empty
				OutEmpty <= '1';
			elsif Addr_out = "111110" then
				OutEmpty <= '0';
			else
				OutEmpty <= OutEmpty;
			end if;

			D4_in(0) <= OutEmpty;
			D4_in(1) <= TaskEmpty;
			D4_in(2) <= ChipBusy;
			D4_in(3) <= not ( (OutEmpty and TaskEmpty) or (OutEmpty and ChipBusy) or (ChipBusy and TaskEmpty));
		end if;
	end process;

	-- All of idle time used to perform updates of status registers
	Addr4_in <= "1111010"; -- Write status to register 26 and _always_ enabled
	D4_in(31 downto 4) <= "1101111011000000110111100000"; -- dec0de0 marker
end RTL;

