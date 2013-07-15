--
-- Copyright 2012 www.bitfury.org
--

library IEEE;
	use IEEE.STD_LOGIC_1164.All;

package SHASerialCtrl_lib is		
	-- Really small finalizer, implemented using primitives
	component SHA_TinyMatchFinalizer
		generic (
			NONCE_ST	: std_logic_vector(23 downto 0) := "110010110000101101011010";
			HIGH		: std_logic := '1'
		);
		port (
			Clk		: in  std_logic; -- Clocks MUST be related (!).
			ClkTX		: in  std_logic; -- ClkTX is slow, but rising edge matches Clk
			Match_rst	: in  std_logic;
			Match_enable	: in  std_logic;
			Match_in	: in  std_logic_vector( 5 downto 0);
			Match_out	: out std_logic -- Slow serial transmission line
		);
	end component;
	
	component SHA_MatchFinalizer
		generic (
			NONCE_ST	: std_logic_vector(23 downto 0) := "110010110000101101011010";
			HIGH		: std_logic := '1';
			PARITY		: std_logic := '1'
		);
		port (
			Clk		: in  std_logic;
			Match_rst	: in  std_logic; -- Together with match_enable kicks in reset!
			Match_enable	: in  std_logic;
			Match_in	: in  std_logic_vector( 5 downto 0);
			Match_out	: out std_logic_vector(31 downto 0);
			Match_has	: out std_logic
		);
	end component;

	component SHA_DSP_Mux
		port (
			Clk			: in  std_logic;
			W_in			: in  std_logic_vector(31 downto 0); -- W input
			N_in			: in  std_logic_vector(31 downto 0); -- Nonce input
			N_muxsel		: in  std_logic; -- Nonce MUXSEL
			N_muxsel_inv		: in  std_logic;
			W_out			: out std_logic_vector(31 downto 0)
		);
	end component;

	component SHA_FIFO
		port (
			ClkIn		: in  std_logic;
			ClkOut		: in  std_logic;
			D_has		: in  std_logic;
			D_in		: in  std_logic_vector(31 downto 0);
			D_ena		: in  std_logic;
			D_out		: out std_logic_vector(31 downto 0);
			D_has_out	: out std_logic
		);
	end component;

	component SHA_MatchTX
		port (
			Clk		: in  std_logic;
			ClkTX		: in  std_logic;
			Match_has	: in  std_logic;
			Match_in	: in  std_logic_vector(31 downto 0);
			Match_out	: out std_logic
		);
	end component;

	component SHA_MatchRX
		port (
			Clk		: in  std_logic;
			ClkTX		: in  std_logic;
			Match_in	: in  std_logic;
			Match_ena	: in  std_logic := '1';
			Match_out	: out std_logic_vector(31 downto 0);
			Match_has	: out std_logic
		);
	end component;
	
	component SHA_MainControl
		port (
			Clk		: in  std_logic;
			D_in		: in  std_logic_vector(31 downto 0);
			Addr_in		: in  std_logic_vector(4 downto 0);
			Addr_we		: in  std_logic;
			Prog_out	: out std_logic_vector(3 downto 0)
		);
	end component;

	-- In single SLICE.X we fit 6-bit counter (two stages of LOGIC)
	-- This is much better than fitting it into 1.5 SLICE L
	-- As we can fit this counter in horizontal placement, C_out ripples!
	component SHA_SingleSliceCounter
		generic (
			INIT		: std_logic_vector(5 downto 0) := "000000"
		);
		port (
			Clk		: in  std_logic;
			Rst		: in  std_logic;
			C_in		: in  std_logic;
			C_out		: out std_logic;
			R_in		: in  std_logic := '1';
			R_out		: out std_logic ;
			Ctr_out		: out std_logic_vector(5 downto 0)
		);
	end component;

	component SHA_WControl_Corner
		generic (
			NONCE_ST	: std_logic_vector(23 downto 0) := "110010110000101101011010"
		);
		port (
			Clk		: in  std_logic;                     -- Clock input
			Prog_in		: in  std_logic_vector(3 downto 0);  -- Programming input
			W_out		: out std_logic_vector(31 downto 0); -- W output
			C_out		: out std_logic_vector(17 downto 0)  -- Control vector output
		);
	end component;

	component SHA_WControl
		generic (
			NONCE_ST	: std_logic_vector(23 downto 0) := "110010110000101101011010"
		);
		port (
			Clk		: in  std_logic;                     -- Clock input
			Prog_in		: in  std_logic_vector(3 downto 0);  -- Programming input
			ScanDone_out	: out std_logic;
			W_out		: out std_logic_vector(31 downto 0); -- W output
			C_out		: out std_logic_vector(17 downto 0)  -- Control vector output
		);
	end component;

	component SHA_KControl
		port (
			Clk		: in  std_logic;
			Prog_in		: in  std_logic_vector(3 downto 0);
			K_out		: out std_logic_vector(31 downto 0); -- Feeding of constants
			C_out		: out std_logic_vector(10 downto 0)  -- 11 control signals
		);
	end component;
end SHASerialCtrl_lib;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;

package body SHASerialCtrl_lib is
end SHASerialCtrl_lib;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;

entity SHA_MainControl is
	port (
		Clk			: in  std_logic;
		D_in			: in  std_logic_vector(31 downto 0);
		Addr_in			: in  std_logic_vector(4 downto 0);
		Addr_we			: in  std_logic;
		Prog_out		: out std_logic_vector(3 downto 0)
	);
end SHA_MainControl;

-- What MainControl does:

-- It allows from outside to LOAD data using D_in and by specifying addresses
-- Then when loading was done (Addr_we switches from high to low), it
-- performs programming sequence by generating programming signals.
-- These programming signals will drive WControl and KControl units,
-- And will setup correct addresses, etc.

architecture RTL of SHA_MainControl is
	type MainMem_type is array(0 to 31) of std_logic_vector(31 downto 0);
	signal MainMem : MainMem_type :=
		(
			x"0cad7cd1", -- Midstate 0 A -- 00000  0 32
			x"cbe38fd9", -- Midstate 0 B -- 00001  1 33
			x"d14dc164", -- Midstate 0 C -- 00010  2 34
			x"f90eb10b", -- Midstate 0 D -- 00011  3 35
			x"819621cf", -- Midstate 0 E -- 00100  4 36
			x"358d45cd", -- Midstate 0 F -- 00101  5 37
			x"8c14cae3", -- Midstate 0 G -- 00110  6 38
			x"538ef887", -- Midstate 0 H -- 00111  7 39
			x"5ff18cdd", -- Midstate 3 A -- 01000  8 40
			x"8cda24a4", -- Midstate 3 B -- 01001  9 41
			x"180266f9", -- Midstate 3 C -- 01010 10 42
			x"0cad7cd1", -- Midstate 3 D -- 01011 11 43
			x"b0ca39fa", -- Midstate 3 E -- 01100 12 44
			x"dd30b962", -- Midstate 3 F -- 01101 13 45
			x"36d2cbc6", -- Midstate 3 G -- 01110 14 46
			x"819621cf", -- Midstate 3 H -- 01111 15 47
			x"cd3f992c", -- W0           -- 10000 16 48
			x"037f704e", -- W1           -- 10001 17 49
			x"a58e091a", -- W2           -- 10010 18 50 W3 (nonce) is not known / needed here! cb0b5c9d
			x"80000000", -- Leading one  -- 10011 20 52
			x"00000280", -- Trailing size-- 10100 21 53
			x"00000000", -- Zeroes       -- 10101 22 54
			others => x"00000000"        -- xxxxx 24 56
		);

	signal MemLoad, D_in_d : std_logic_vector(31 downto 0);
	signal AddrGen : std_logic_vector(4 downto 0);
	signal Addr_we_dp, Prog_Start, Addr_we_d : std_logic;
	signal ShiftReg : std_logic_vector(31 downto 0);

	signal ProgCnt : std_logic_vector(6 downto 0);        -- 7-bit programming counter
	signal ProgAE, ProgW : std_logic := '1';
	signal ProgWold, ProgNext : std_logic;

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of RTL : architecture is "TRUE";
begin
	-- Multiplexor is built into AddrGen, as it should be _registered_
	-- AddrIn <= AddrGen when Addr_we_d = '0' else Addr_in_d;
 
	process (Clk) begin
		if rising_edge(Clk) then
			if Addr_we_d = '1' then
				MainMem(conv_integer(AddrGen)) <= D_in_d;
			end if;
			MemLoad <= MainMem(conv_integer(AddrGen));
		end if;
	end process;

	-- Generate start of programming signal (that resets programming state machine)
	process (Clk) begin
		if rising_edge(Clk) then
			D_in_d <= D_in;
			Addr_we_d <= Addr_we;
			Addr_we_dp <= Addr_we_d;
			if Addr_we_dp = '1' and Addr_we_d = '0' then
				Prog_Start <= '1';
			else
				Prog_Start <= '0';
			end if;
		end if;
	end process;

	-- Counter initiation
	process (Clk) begin
		if rising_edge(Clk) then
			if Prog_Start = '1' then
				ProgCnt <= "0000000";
			else
				ProgCnt <= ProgCnt + 1;
			end if;
		end if;
	end process;

	-- Addrgen address generation
	process (Clk) begin
		if rising_edge(Clk) then
			if Addr_we = '1' then
				AddrGen <= Addr_in;
				ProgAE <= ProgAE; ProgW <= ProgW; ProgNext <= ProgNext;
			elsif Prog_Start = '1' then
				AddrGen <= "11110"; -- Reading at location 30
				ProgAE <= '0'; ProgW <= '0'; ProgNext <= '0';
			elsif ProgCnt(5 downto 0) = "000000" then
				case AddrGen is
					when "11110" => AddrGen <= "00000"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "00000" => AddrGen <= "00100"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "00100" => AddrGen <= "00001"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "00001" => AddrGen <= "00101"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "00101" => AddrGen <= "00010"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "00010" => AddrGen <= "00110"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "00110" => AddrGen <= "00011"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "00011" => AddrGen <= "00111"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';

					when "00111" => AddrGen <= "01100"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "01100" => AddrGen <= "01000"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "01000" => AddrGen <= "01101"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "01101" => AddrGen <= "01001"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "01001" => AddrGen <= "01110"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "01110" => AddrGen <= "01010"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';
					when "01010" => AddrGen <= "01111"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '1';
					when "01111" => AddrGen <= "01011"; ProgAE <= '1'; ProgW <= '0'; ProgNext <= '0';

					when "01011" => AddrGen <= "10000"; ProgAE <= '0'; ProgW <= '1'; ProgNext <= '0';
					when "10000" => AddrGen <= "10001"; ProgAE <= '0'; ProgW <= '1'; ProgNext <= '1';
					when "10001" => AddrGen <= "10010"; ProgAE <= '0'; ProgW <= '1'; ProgNext <= '1';
					when "10010" => AddrGen <= "10011"; ProgAE <= '0'; ProgW <= '1'; ProgNext <= '1';
					when "10011" => AddrGen <= "10100"; ProgAE <= '0'; ProgW <= '1'; ProgNext <= '1';
					when "10100" => AddrGen <= "10101"; ProgAE <= '0'; ProgW <= '1'; ProgNext <= '1';

					when others  => AddrGen <= "11111"; ProgAE <= '0'; ProgW <= '0'; ProgNext <= '0';
				end case;
			else
				AddrGen <= AddrGen;
				ProgAE <= ProgAE;
				ProgW <= ProgW;
				ProgNext <= '0';
			end if;
		end if;
	end process;

	-- On next stage we perform loading of shift register, and shifting it to output
	-- IMPORTANT moment here, not a bug - we switch ProgW/ProgAE right one cycle before
	-- actual finish of load, this allows us to load last address WITHOUT shifting it one bit
	-- This further allows us to use it as a prototype to read values in!
	process (Clk) begin
		if rising_edge(Clk) then
			if ProgCnt(5 downto 0) = "000010" then
				ShiftReg <= MemLoad;
			elsif ProgCnt(0) = '1' then
				ShiftReg <= ShiftReg;
			else
				ShiftReg <= ShiftReg(30 downto 0) & '0';
			end if;
		end if;
	end process;

	Prog_out(0) <= ProgAE;       -- ProgAE
	Prog_out(1) <= ProgW;        -- ProgW
	Prog_out(2) <= ProgNext;     -- Change address
	Prog_out(3) <= ShiftReg(31); -- Shift register
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_SingleSliceCounter is
	generic (
		INIT			: std_logic_vector(5 downto 0) := "000000"
	);
	port (
		Clk			: in  std_logic;
		Rst			: in  std_logic;
		C_in			: in  std_logic;
		C_out			: out std_logic;
		R_in			: in  std_logic;
		R_out			: out std_logic;
		Ctr_out			: out std_logic_vector(5 downto 0)
	);
end SHA_SingleSliceCounter;

architecture RTL of SHA_SingleSliceCounter is
	signal Ctr, Ctr_async : std_logic_vector(5 downto 0);
	signal C1_async, C2_async : std_logic;
	
--	attribute LOC : string;
	
	function gl(l:integer;b:std_logic) return bit_vector is
	begin
		if l = 3 then
			if b = '1' then
				return x"f6";
			else
				return x"06";
			end if;
		end if;
		if l = 4 then
			if b = '1' then
				return x"ff78";
			else
				return x"0078";
			end if;
		end if;
		if b = '1' then
			return x"ffff7f80";
		end if;
		return x"00007f80";
	end function;
	function gli(b:std_logic_vector(5 downto 0)) return bit_vector is
	begin
		if b = "111111" then return x"ffff8000"; end if;
		return x"00008000";		
	end function;
	
--	constant loc_str : string := "SLICE_X"&itoa(LOC_X)&"Y"&itoa(LOC_Y);
--	attribute LOC of L1, L2, L3, L4, L5, L6, L7, L8 : label is loc_str;
--	attribute LOC of F1, F2, F3, F4, F5, F6, F7, F8 : label is loc_str;
begin
	L1: LUT3 generic map (INIT => gl(3,INIT(0))) port map (O => Ctr_async(0), I2 => Rst, I1 => Ctr(0), I0 => C_in);
	L2: LUT4 generic map (INIT => gl(4,INIT(1))) port map (O => Ctr_async(1), I3 => Rst, I2 => Ctr(1), I1 => Ctr(0), I0 => C_in);
	L3: LUT5 generic map (INIT => gl(5,INIT(2))) port map (O => Ctr_async(2), I4 => Rst, I3 => Ctr(2), I2 => Ctr(1), I1 => Ctr(0), I0 => C_in);
	L4: LUT4 generic map (INIT => x"8000") port map (O => C1_async, I3 => Ctr(2), I2 => Ctr(1), I1 => Ctr(0), I0 => C_in);
	L5: LUT3 generic map (INIT => gl(3,INIT(3))) port map (O => Ctr_async(3), I2 => Rst, I1 => Ctr(3), I0 => C1_async);
	L6: LUT4 generic map (INIT => gl(4,INIT(4))) port map (O => Ctr_async(4), I3 => Rst, I2 => Ctr(4), I1 => Ctr(3), I0 => C1_async);
	L7: LUT5 generic map (INIT => gl(5,INIT(5))) port map (O => Ctr_async(5), I4 => Rst, I3 => Ctr(5), I2 => Ctr(4), I1 => Ctr(3), I0 => C1_async);
	L8: LUT5 generic map (INIT => gli(INIT)) port map (O => C2_async, I4 => Rst, I3 => Ctr(5), I2 => Ctr(4), I1 => Ctr(3), I0 => C1_async);
	
	F1: FD port map (C => Clk, D => Ctr_async(0), Q => Ctr(0));
	F2: FD port map (C => Clk, D => Ctr_async(1), Q => Ctr(1));
	F3: FD port map (C => Clk, D => Ctr_async(2), Q => Ctr(2));
	F4: FD port map (C => Clk, D => R_in, Q => R_out);
	F5: FD port map (C => Clk, D => Ctr_async(3), Q => Ctr(3));
	F6: FD port map (C => Clk, D => Ctr_async(4), Q => Ctr(4));
	F7: FD port map (C => Clk, D => Ctr_async(5), Q => Ctr(5));
	F8: FD port map (C => Clk, D => C2_async, Q => C_out);
	
	Ctr_out <= Ctr;
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_WControl is
	generic (
		NONCE_ST		: std_logic_vector(23 downto 0) := "110010110000101101011010"
	);
	port (
		Clk			: in  std_logic;                     -- Clock input
		Prog_in			: in  std_logic_vector(3 downto 0);  -- Programming input
		ScanDone_out		: out std_logic;
		W_out			: out std_logic_vector(31 downto 0); -- W output
		C_out			: out std_logic_vector(17 downto 0)  -- Control vector output
	);
end SHA_WControl;

architecture RTL of SHA_WControl is
	signal WmemAddrRST : std_logic;
	signal WmemAddrR, WmemAddrRA, WmemAddr, WmemAddrA : std_logic_vector(4 downto 0);
	signal WmemAddrW, WmemAddrWA : std_logic_vector(3 downto 0);
	signal WmemReg, WmemRegA, WmemRegI : std_logic_vector(31 downto 0);
	
	signal Wmuxin, Wmuxouta, Wmuxout : std_logic_vector(31 downto 0);

	signal ProgAE, ProgW, ProgN, ProgD : std_logic;
	signal Nonce_cnt : std_logic_vector(23 downto 0);
	signal PC_cnt, PC_ncnt : std_logic_vector(7 downto 0);
	signal NonceC : std_logic_vector(2 downto 0);
	signal CoutA : std_logic_vector(6 downto 0);
	signal WmemAddrRSTA, WmemAddrRST1 : std_logic;
	
	signal WInjectT, ProgWD, ProgDD : std_logic;

	signal ProgPrev, ProgRST, CtrFlush, PCRST, PcNcnt7, PcNcnt7d, ProgAStore, ProgAED : std_logic;
	signal NMux, NMuxA : std_logic;
		
	signal ProgAStore_async, ProgAStore_sel, ProgAStore_sel_a, C_out_16_sel_a, C_out_17_sel_a, C_out_16_sel, C_out_17_sel, ProgPrev_async, ProgRST_async, CTRFlush_async, PCRST_async, PC_ncnt0_async : std_logic;

	signal paddr_a, paddr : std_logic_vector(2 downto 0);
	signal saddra_a, saddre_a, saddra, saddre : std_logic_vector(5 downto 0);
	signal saveload_mode, Addr_rst, saveload_mode_a, Addr_rst_a, Addr_rst_a1 : std_logic;
	signal C_out_4a, C_out_24a, C_out_24a1 : std_logic;
	signal Addr_muxout, Addr_prog_muxin, Addr_norm_muxin : std_logic_vector(9 downto 0);
begin	
	LPROGPREV: LUT2 generic map (INIT => x"e") port map (O => ProgPrev_async, I1 => ProgAE, I0 => ProgW);
	FPROGPREV: FD port map (C => Clk, D => ProgPrev_async, Q => ProgPrev);
	LPROGRST:  LUT3 generic map (INIT => x"10") port map (O => ProgRST_async, I2 => ProgPrev, I1 => ProgAE, I0 => ProgW);
	FPROGRST:  FD port map (C => Clk, D => ProgRST_async, Q => ProgRST);
	LCTRFLUSH: LUT3 generic map (INIT => "01010100") port map (O => CTRFlush_async, I2 => PcNcnt7d, I1 => PcNcnt7, I0 => PC_ncnt(0));
	FCTRFLUSH: FD port map (C => Clk, D => CTRFlush_async, Q => CtrFlush);
	LPCRST:    LUT6 generic map (INIT => x"10ff10ff10ff1010") port map (O => PCRST_async, I5 => PcNcnt7d, I4 => PcNcnt7, I3 => PC_ncnt(0), I2 => ProgPrev, I1 => ProgAE, I0 => ProgW);
	FPCRST:    FD port map (C => Clk, D => PCRST_async, Q => PCRST);
	LPCNCNT0:  LUT2 generic map (INIT => "0001") port map (O => PC_ncnt0_async, I1 => PCRST, I0 => PC_ncnt(0));
	FPCNCNT0:  FD port map (C => Clk, D => PC_ncnt0_async, Q => PC_ncnt(0));
	FPCCNT0:   FD port map (C => Clk, D => PC_ncnt(0), Q => PC_cnt(0));
	FPCCNT1:   FD port map (C => Clk, D => PC_ncnt(1), Q => PC_cnt(1));
	FPCCNT2:   FD port map (C => Clk, D => PC_ncnt(2), Q => PC_cnt(2));
	FPCCNT3:   FD port map (C => Clk, D => PC_ncnt(3), Q => PC_cnt(3));
	FPCCNT4:   FD port map (C => Clk, D => PC_ncnt(4), Q => PC_cnt(4));
	FPCCNT5:   FD port map (C => Clk, D => PC_ncnt(5), Q => PC_cnt(5));
	FPCCNT6:   FD port map (C => Clk, D => PC_ncnt(6), Q => PC_cnt(6));
	LPCNCNT7:  LUT2 generic map (INIT => "1110") port map (O => PC_ncnt(7), I1 => PcNcnt7, I0 => PcNcnt7d);
	FPCCNT7:   FD port map (C => Clk, D => PC_ncnt(7), Q => PC_cnt(7));
	PCSS: SHA_SingleSliceCounter port map (Clk => Clk, Rst => PCRST,   C_in => PC_ncnt(0), C_out => PcNcnt7, Ctr_out => PC_ncnt(6 downto 1), R_in => PcNcnt7, R_out => PcNcnt7d);
	NON1: SHA_SingleSliceCounter generic map (INIT => NONCE_ST( 5 downto  0)) port map (Clk => Clk, Rst => ProgRST, C_in => CtrFlush, C_out => NonceC(0), Ctr_out=>Nonce_cnt(5 downto 0), R_in => Prog_in(0), R_out => ProgAE);
	NON2: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(11 downto  6)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(0), C_out => NonceC(1), Ctr_out=>Nonce_cnt(11 downto 6), R_in => Prog_in(1), R_out => ProgW);
	NON3: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(17 downto 12)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(1), C_out => NonceC(2), Ctr_out=>Nonce_cnt(17 downto 12), R_in => Prog_in(2), R_out => ProgN);
	NON4: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(23 downto 18)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(2), C_out => ScanDone_out, Ctr_out=>Nonce_cnt(23 downto 18), R_in => Prog_in(3), R_out => ProgD);
  
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LWMAW0:	LUT6 generic map (INIT => "0000000000010001101010101010101000000000000000000000000000000000") port map (O => WmemAddrWA(0), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW1:	LUT6 generic map (INIT => "0000000000010010110011001100110000000000000000000000000000000000") port map (O => WmemAddrWA(1), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW2:	LUT6 generic map (INIT => "1000000000010100111100001111000000000000000000000000000000000000") port map (O => WmemAddrWA(2), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW3:	LUT6 generic map (INIT => "1000000000010000111111110000000000000000000000000000000000000000") port map (O => WmemAddrWA(3), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW0F: FD port map (C => Clk, D => WmemAddrWA(0), Q => WmemAddrW(0));
	LWMAW1F: FD port map (C => Clk, D => WmemAddrWA(1), Q => WmemAddrW(1));
	LWMAW2F: FD port map (C => Clk, D => WmemAddrWA(2), Q => WmemAddrW(2));
	LWMAW3F: FD port map (C => Clk, D => WmemAddrWA(3), Q => WmemAddrW(3));
	
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LWMARST:LUT6 generic map (INIT => "1000000000000000000000000000000000000000000000000000000000000000") port map (O => WmemAddrRSTA, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LWMARSTF: FD port map (C => Clk, D => WmemAddrRSTA, Q => WmemAddrRST);
--                                          3         2         1         0
--	                                  "10987654321098765432109876543210"
	LWMAR0: LUT5 generic map (INIT => "00000000000000000101010101010101") port map (O => WmemAddrRA(0), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR1: LUT5 generic map (INIT => "11101111111111111110011001100110") port map (O => WmemAddrRA(1), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR2: LUT5 generic map (INIT => "11101111111111111111100001111000") port map (O => WmemAddrRA(2), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR3: LUT5 generic map (INIT => "11101111111111111111111110000000") port map (O => WmemAddrRA(3), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR4: LUT5 generic map (INIT => "11101111111111111000000000000000") port map (O => WmemAddrRA(4), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR0F: FDRE port map (CE => PC_cnt(0), R => WmemAddrRST, C => Clk, D => WmemAddrRA(0), Q => WmemAddrR(0));
	LWMAR1F: FDRE port map (CE => PC_cnt(0), R => WmemAddrRST, C => Clk, D => WmemAddrRA(1), Q => WmemAddrR(1));
	LWMAR2F: FDSE port map (CE => PC_cnt(0), S => WmemAddrRST, C => Clk, D => WmemAddrRA(2), Q => WmemAddrR(2));
	LWMAR3F: FDSE port map (CE => PC_cnt(0), S => WmemAddrRST, C => Clk, D => WmemAddrRA(3), Q => WmemAddrR(3));
	LWMAR4F: FDSE port map (CE => PC_cnt(0), S => WmemAddrRST, C => Clk, D => WmemAddrRA(4), Q => WmemAddrR(4));
	
	LMUX0:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(0), I2 => ProgW, I1 => WmemAddrW(0), I0 => WmemAddrR(0));
	LMUX1:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(1), I2 => ProgW, I1 => WmemAddrW(1), I0 => WmemAddrR(1));
	LMUX2:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(2), I2 => ProgW, I1 => WmemAddrW(2), I0 => WmemAddrR(2));
	LMUX3:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(3), I2 => ProgW, I1 => WmemAddrW(3), I0 => WmemAddrR(3));
	LMUX0F: FD port map (C => Clk, D => WmemAddrA(0), Q => WmemAddr(0));
	LMUX1F: FD port map (C => Clk, D => WmemAddrA(1), Q => WmemAddr(1));
	LMUX2F: FD port map (C => Clk, D => WmemAddrA(2), Q => WmemAddr(2));
	LMUX3F: FD port map (C => Clk, D => WmemAddrA(3), Q => WmemAddr(3));
	
	FDPROGDD: FD port map (C => Clk, D => ProgD, Q => ProgDD);
	FDPROGWD: FD port map (C => Clk, D => ProgW, Q => ProgWD);

	WmemAddr(4) <= '1';
	WmemRegI <= WmemReg(30 downto 0) & ProgDD; -- Shifted!
	GRAM: for i in 0 to 3 generate
		LRAM: RAM32M port map (WCLK => Clk, WE => ProgWD, ADDRA => WmemAddr, ADDRB => WmemAddr, ADDRC => WmemAddr, ADDRD => WmemAddr,
			DOA => WmemRegA(i*8+1 downto i*8+0), DIA => WmemRegI(i*8+1 downto i*8+0),
			DOB => WmemRegA(i*8+3 downto i*8+2), DIB => WmemRegI(i*8+3 downto i*8+2),
			DOC => WmemRegA(i*8+5 downto i*8+4), DIC => WmemRegI(i*8+5 downto i*8+4),
			DOD => WmemRegA(i*8+7 downto i*8+6), DID => WmemRegI(i*8+7 downto i*8+6));
	end generate;
	GRAMFD: for i in 0 to 31 generate
		FRAM: FD port map (C => Clk, D => WmemRegA(i), Q => WmemReg(i));
	end generate;

--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LNMUX:  LUT6 generic map (INIT => "0000000000000000000000000000000000000000000000000000000000010000") port map (O => NmuxA, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LNMUXF:  FD port map (C => Clk, D => NMuxA, Q => NMux);

	-- Implement multiplex in slices since there's no DSPs in central region of chip
	Wmuxin(31 downto 8) <= Nonce_cnt; Wmuxin(7 downto 1) <= (others => '1'); Wmuxin(0) <= PC_cnt(0);	
	GDMUX: for i in 0 to 31 generate
		LMU: LUT3 generic map (INIT => "11001010") port map (O => Wmuxouta(i), I2 => NMux, I1 => Wmuxin(i), I0 => WmemReg(i));
		LMUF: FD port map (C => Clk, D => Wmuxouta(i), Q => Wmuxout(i));
	end generate;
	
	W_out <= Wmuxout;

--                                             6         5         4         3         2         1         0
--	                                   "3210987654321098765432109876543210987654321098765432109876543210"
	LCOUT0: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000011111111111111110") port map (O => CoutA(0), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT1: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000000010000") port map (O => WInjectT, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT1S: LUT2 generic map (INIT => "0100") port map (O => CoutA(1), I1 => WInjectT, I0 => PC_ncnt(0)); -- Inject pulse width only 1 clock
	LCOUT2: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000000111100") port map (O => CoutA(2), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT3: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000001111000") port map (O => CoutA(3), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT16S:LUT6 generic map (INIT => "0000011111111000000000000000000000000000000000000000000000000000") port map (O => C_out_16_sel_a, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT17S:LUT6 generic map (INIT => "0111100000000000000000000000000000000000000000000000000000000000") port map (O => C_out_17_sel_a, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LPASSE: LUT6 generic map  (INIT => "0110000000000000000000000000000000000000000000000000000000000000") port map (O => ProgAStore_sel_a, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT6: LUT6 generic map  (INIT => "1110000000000000000000000000000000000000000000000000000000000011") port map (O => CoutA(6), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT4: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000000000010") port map (O => C_out_4a, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));

	LCOUT0F: FD port map (C => Clk, D => CoutA(0), Q => C_out(0));
	LCOUT1F: FD port map (C => Clk, D => CoutA(1), Q => C_out(1));
	LCOUT2F: FD port map (C => Clk, D => CoutA(2), Q => C_out(2));
	LCOUT3F: FD port map (C => Clk, D => CoutA(3), Q => C_out(3));
	LCOUT4F: FD port map (C => Clk, D => C_out_4a, Q => C_out(4));
	LCOUT6F: FD port map (C => Clk, D => CoutA(6), Q => C_out(5));
	
	FPROGAED: FD port map (C => Clk, D => ProgAE, Q => ProgAED);
	LPROGASTORE: LUT3 generic map (INIT => "11001010") port map (O => ProgAStore_async, I2 => ProgAED, I1 => ProgD, I0 => ProgAStore);
	LPROGASTOREF:FD port map (C => Clk, D => ProgAStore_async, Q => ProgAStore);
	
	FPASSE:    FD port map (C => Clk, D => ProgAStore_sel_a, Q => ProgAStore_sel);
	LCOUT16SF: FD port map (C => Clk, D => C_out_16_sel_a, Q => C_out_16_sel);
	LCOUT17SF: FD port map (C => Clk, D => C_out_17_sel_a, Q => C_out_17_sel);
	
	LCOUT16:  LUT5 generic map (INIT => x"ccccaaf0") port map (O => CoutA(4), I4 => ProgAE, I3 => ProgAStore_sel, I2 => C_out_16_sel, I1 => ProgD, I0 => ProgAStore);
	LCOUT17:  LUT2 generic map (INIT => "1110") port map (O => CoutA(5), I1 => ProgAE, I0 => C_out_17_sel);
	LCOUT16F: FD port map (C => Clk, D => CoutA(4), Q => C_out(16));
	LCOUT17F: FD port map (C => Clk, D => CoutA(5), Q => C_out(17));

--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"

	---------------------------- ADDRESS GENERATION STATE MACHINE -----------------------------
	-- Generate programming address (when doing LOAD operation)
--                                        3         2         1         0
--	                                "10987654321098765432109876543210"
	LPA0: LUT5 generic map (INIT => "01010101101010100000000000000000") port map (O => paddr_a(0), I4 => ProgAE, I3 => ProgN, I2 => paddr(2), I1 => paddr(1), I0 => paddr(0));
	LPA1: LUT5 generic map (INIT => "01100110110011000000000000000000") port map (O => paddr_a(1), I4 => ProgAE, I3 => ProgN, I2 => paddr(2), I1 => paddr(1), I0 => paddr(0));
	LPA2: LUT5 generic map (INIT => "01111000111100000000000000000000") port map (O => paddr_a(2), I4 => ProgAE, I3 => ProgN, I2 => paddr(2), I1 => paddr(1), I0 => paddr(0));
	LPA0F: FD port map (C => Clk, D => paddr_a(0), Q => paddr(0));
	LPA1F: FD port map (C => Clk, D => paddr_a(1), Q => paddr(1));
	LPA2F: FD port map (C => Clk, D => paddr_a(2), Q => paddr(2));

	-- Choose either programming address or xferdata address to feed
	Addr_prog_muxin(3 downto 0) <= '0' & paddr;
	Addr_prog_muxin(7 downto 4) <= '0' & paddr;
	Addr_prog_muxin(8) <= '1'; Addr_prog_muxin(9) <= '1';
	Addr_norm_muxin(3 downto 0) <= saddre(4 downto 1);
	Addr_norm_muxin(7 downto 4) <= saddra(4 downto 1);  
	Addr_norm_muxin(8) <= saddre(5); Addr_norm_muxin(9) <= saddra(5);
	GAMUX: for i in 0 to 9 generate
		ADMUX: LUT3 generic map (INIT => "11001010") port map (O => Addr_muxout(i), I2 => ProgAE, I1 => Addr_prog_muxin(i), I0 => Addr_norm_muxin(i));
		CFDOUT: FD port map (C => Clk, D => Addr_muxout(i), Q => C_out(i+6));
	end generate;
	
--	Address generator state machines
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LSADA0: LUT6 generic map (INIT => "1010101010001000110101111111111110101010101010001111111111010101") port map (O => saddra_a(0), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA1: LUT6 generic map (INIT => "1011000100010011101001000000000000010001000100010000000001100110") port map (O => saddra_a(1), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA2: LUT6 generic map (INIT => "0111010000011110110100000000000000010100000100100000000001111000") port map (O => saddra_a(2), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA3: LUT6 generic map (INIT => "0111111111000010111111111111111111111011101010101111111110000000") port map (O => saddra_a(3), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA4: LUT6 generic map (INIT => "1001010101111101110000000000000001010101010100110000000000000000") port map (O => saddra_a(4), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA5: LUT6 generic map (INIT => "1001010101111101110000000000000000000000000000000000000000000000") port map (O => saddra_a(5), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA0F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddra_a(0), Q => saddra(0));
	LSADA1F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(1), Q => saddra(1));
	LSADA2F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(2), Q => saddra(2));
	LSADA3F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(3), Q => saddra(3));
	LSADA4F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddra_a(4), Q => saddra(4));
	LSADA5F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(5), Q => saddra(5));

--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LSADE0: LUT6 generic map (INIT => "0010101010101000110101111111111110101010101011001111111101010101") port map (O => saddre_a(0), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE1: LUT6 generic map (INIT => "0011000100010011101001000000000000010001000100010000000001100110") port map (O => saddre_a(1), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE2: LUT6 generic map (INIT => "0111010000010110110100000000000000010100000100000000000011111000") port map (O => saddre_a(2), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE3: LUT6 generic map (INIT => "0111111111101010111111111111111111111011101011001111111110000000") port map (O => saddre_a(3), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE4: LUT6 generic map (INIT => "1001010101010101110000000000000001010101010100010000000010000000") port map (O => saddre_a(4), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE5: LUT6 generic map (INIT => "1001010101010101110000000000000000000000000000000000000000000000") port map (O => saddre_a(5), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE0F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddre_a(0), Q => saddre(0));
	LSADE1F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(1), Q => saddre(1));
	LSADE2F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(2), Q => saddre(2));
	LSADE3F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(3), Q => saddre(3));
	LSADE4F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddre_a(4), Q => saddre(4));
	LSADE5F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(5), Q => saddre(5));
	
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LSASM:  LUT6 generic map (INIT => "1111100000000000000000000000000000000000000000000000000111111111") port map (O => saveload_mode_a, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	LSADRST:LUT6 generic map (INIT => "0000100000000010000000000000000000000000000000000000000000000000") port map (O => Addr_rst_a1, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	LSASMF: FD port map (C => Clk, D => saveload_mode_a, Q => saveload_mode);
	LSADRST1:LUT3 generic map (INIT => "11000100") port map (O => Addr_rst_a, I2 => PC_cnt(2), I1 => Addr_rst_a1, I0 => PC_cnt(0));
	LSADRSTF: FD port map (C => Clk, D => Addr_rst_a, Q => Addr_rst);
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_WControl_Corner is
	generic (
		NONCE_ST		: std_logic_vector(23 downto 0) := "110010110000101101011010"
	);
	port (
		Clk			: in  std_logic;                     -- Clock input
		Prog_in			: in  std_logic_vector( 3 downto 0); -- Programming input
		W_out			: out std_logic_vector(31 downto 0); -- W output
		C_out			: out std_logic_vector(17 downto 0)  -- Control vector output
	);
end SHA_WControl_Corner;

architecture RTL of SHA_WControl_Corner is
	signal WmemAddrRST : std_logic;
	signal WmemAddrR, WmemAddrRA, WmemAddr, WmemAddrA : std_logic_vector(4 downto 0);
	signal WmemAddrW, WmemAddrWA : std_logic_vector(3 downto 0);
	signal WmemReg, WmemRegA, WmemRegI : std_logic_vector(31 downto 0);

	signal ProgAE, ProgW, ProgN, ProgD : std_logic;
	signal Nonce_cnt : std_logic_vector(23 downto 0);
	signal PC_cnt, PC_ncnt : std_logic_vector(7 downto 0);
	signal NonceC : std_logic_vector(2 downto 0);
	signal CoutA : std_logic_vector(6 downto 0);
	signal WmemAddrRSTA, WmemAddrRST1 : std_logic;
	
	signal WInjectT, ProgWD, ProgDD : std_logic;

	signal ProgPrev, ProgRST, CtrFlush, PCRST, PcNcnt7, PcNcnt7d, ProgAStore, ProgAED : std_logic;
	signal NMux, NMuxA, NMuxI, NMuxIA : std_logic;
		
	signal ProgAStore_async, ProgAStore_sel, ProgAStore_sel_a, C_out_16_sel_a, C_out_17_sel_a, C_out_16_sel, C_out_17_sel, ProgPrev_async, ProgRST_async, CTRFlush_async, PCRST_async, PC_ncnt0_async : std_logic;

	signal paddr_a, paddr : std_logic_vector(2 downto 0);
	signal saddra_a, saddre_a, saddra, saddre : std_logic_vector(5 downto 0);
	signal saveload_mode, Addr_rst, saveload_mode_a, Addr_rst_a, Addr_rst_a1 : std_logic;
	signal C_out_4a, C_out_24a, C_out_24a1 : std_logic;
	signal Addr_muxout, Addr_prog_muxin, Addr_norm_muxin : std_logic_vector(9 downto 0);

begin	
	LPROGPREV: LUT2 generic map (INIT => x"e") port map (O => ProgPrev_async, I1 => ProgAE, I0 => ProgW);
	FPROGPREV: FD port map (C => Clk, D => ProgPrev_async, Q => ProgPrev);
	LPROGRST:  LUT3 generic map (INIT => x"10") port map (O => ProgRST_async, I2 => ProgPrev, I1 => ProgAE, I0 => ProgW);
	FPROGRST:  FD port map (C => Clk, D => ProgRST_async, Q => ProgRST);
	LCTRFLUSH: LUT3 generic map (INIT => "01010100") port map (O => CTRFlush_async, I2 => PcNcnt7d, I1 => PcNcnt7, I0 => PC_ncnt(0));
	FCTRFLUSH: FD port map (C => Clk, D => CTRFlush_async, Q => CtrFlush);
	LPCRST:    LUT6 generic map (INIT => x"10ff10ff10ff1010") port map (O => PCRST_async, I5 => PcNcnt7d, I4 => PcNcnt7, I3 => PC_ncnt(0), I2 => ProgPrev, I1 => ProgAE, I0 => ProgW);
	FPCRST:    FD port map (C => Clk, D => PCRST_async, Q => PCRST);
	LPCNCNT0:  LUT2 generic map (INIT => "0001") port map (O => PC_ncnt0_async, I1 => PCRST, I0 => PC_ncnt(0));
	FPCNCNT0:  FD port map (C => Clk, D => PC_ncnt0_async, Q => PC_ncnt(0));
	FPCCNT0:   FD port map (C => Clk, D => PC_ncnt(0), Q => PC_cnt(0));
	FPCCNT1:   FD port map (C => Clk, D => PC_ncnt(1), Q => PC_cnt(1));
	FPCCNT2:   FD port map (C => Clk, D => PC_ncnt(2), Q => PC_cnt(2));
	FPCCNT3:   FD port map (C => Clk, D => PC_ncnt(3), Q => PC_cnt(3));
	FPCCNT4:   FD port map (C => Clk, D => PC_ncnt(4), Q => PC_cnt(4));
	FPCCNT5:   FD port map (C => Clk, D => PC_ncnt(5), Q => PC_cnt(5));
	FPCCNT6:   FD port map (C => Clk, D => PC_ncnt(6), Q => PC_cnt(6));
	LPCNCNT7:  LUT2 generic map (INIT => "1110") port map (O => PC_ncnt(7), I1 => PcNcnt7, I0 => PcNcnt7d);
	FPCCNT7:   FD port map (C => Clk, D => PC_ncnt(7), Q => PC_cnt(7));
	PCSS: SHA_SingleSliceCounter port map (Clk => Clk, Rst => PCRST,   C_in => PC_ncnt(0), C_out => PcNcnt7, Ctr_out => PC_ncnt(6 downto 1), R_in => PcNcnt7, R_out => PcNcnt7d);
	NON1: SHA_SingleSliceCounter generic map (INIT => NONCE_ST( 5 downto  0)) port map (Clk => Clk, Rst => ProgRST, C_in => CtrFlush, C_out => NonceC(0), Ctr_out=>Nonce_cnt(5 downto 0), R_in => Prog_in(0), R_out => ProgAE);
	NON2: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(11 downto  6)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(0), C_out => NonceC(1), Ctr_out=>Nonce_cnt(11 downto 6), R_in => Prog_in(1), R_out => ProgW);
	NON3: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(17 downto 12)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(1), C_out => NonceC(2), Ctr_out=>Nonce_cnt(17 downto 12), R_in => Prog_in(2), R_out => ProgN);
	NON4: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(23 downto 18)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(2), C_out => open, Ctr_out=>Nonce_cnt(23 downto 18), R_in => Prog_in(3), R_out => ProgD);
  
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LWMAW0:	LUT6 generic map (INIT => "0000000000010001101010101010101000000000000000000000000000000000") port map (O => WmemAddrWA(0), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW1:	LUT6 generic map (INIT => "0000000000010010110011001100110000000000000000000000000000000000") port map (O => WmemAddrWA(1), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW2:	LUT6 generic map (INIT => "1000000000010100111100001111000000000000000000000000000000000000") port map (O => WmemAddrWA(2), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW3:	LUT6 generic map (INIT => "1000000000010000111111110000000000000000000000000000000000000000") port map (O => WmemAddrWA(3), I5 => ProgW, I4 => ProgN, I3 => WmemAddrW(3), I2 => WmemAddrW(2), I1 => WmemAddrW(1), I0 => WmemAddrW(0));
	LWMAW0F: FD port map (C => Clk, D => WmemAddrWA(0), Q => WmemAddrW(0));
	LWMAW1F: FD port map (C => Clk, D => WmemAddrWA(1), Q => WmemAddrW(1));
	LWMAW2F: FD port map (C => Clk, D => WmemAddrWA(2), Q => WmemAddrW(2));
	LWMAW3F: FD port map (C => Clk, D => WmemAddrWA(3), Q => WmemAddrW(3));
	
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LWMARST:LUT6 generic map (INIT => "0100000000000000000000000000000000000000000000000000000000000000") port map (O => WmemAddrRSTA, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LWMARSTF: FD port map (C => Clk, D => WmemAddrRSTA, Q => WmemAddrRST);
--                                          3         2         1         0
--	                                  "10987654321098765432109876543210"
	LWMAR0: LUT5 generic map (INIT => "00000000000000000101010101010101") port map (O => WmemAddrRA(0), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR1: LUT5 generic map (INIT => "11101111111111111110011001100110") port map (O => WmemAddrRA(1), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR2: LUT5 generic map (INIT => "11101111111111111111100001111000") port map (O => WmemAddrRA(2), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR3: LUT5 generic map (INIT => "11101111111111111111111110000000") port map (O => WmemAddrRA(3), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR4: LUT5 generic map (INIT => "11101111111111111000000000000000") port map (O => WmemAddrRA(4), I4 => WmemAddrR(4), I3 => WmemAddrR(3), I2 => WmemAddrR(2), I1 => WmemAddrR(1), I0 => WmemAddrR(0));
	LWMAR0F:FDRE port map (CE => PC_ncnt(0), R => WmemAddrRST, C => Clk, D => WmemAddrRA(0), Q => WmemAddrR(0));
	LWMAR1F:FDRE port map (CE => PC_ncnt(0), R => WmemAddrRST, C => Clk, D => WmemAddrRA(1), Q => WmemAddrR(1));
	LWMAR2F:FDSE port map (CE => PC_ncnt(0), S => WmemAddrRST, C => Clk, D => WmemAddrRA(2), Q => WmemAddrR(2));
	LWMAR3F:FDSE port map (CE => PC_ncnt(0), S => WmemAddrRST, C => Clk, D => WmemAddrRA(3), Q => WmemAddrR(3));
	LWMAR4F:FDSE port map (CE => PC_ncnt(0), S => WmemAddrRST, C => Clk, D => WmemAddrRA(4), Q => WmemAddrR(4));
	
	LMUX0:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(0), I2 => ProgW, I1 => WmemAddrW(0), I0 => WmemAddrR(0));
	LMUX1:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(1), I2 => ProgW, I1 => WmemAddrW(1), I0 => WmemAddrR(1));
	LMUX2:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(2), I2 => ProgW, I1 => WmemAddrW(2), I0 => WmemAddrR(2));
	LMUX3:  LUT3 generic map (INIT => "11001010") port map (O => WmemAddrA(3), I2 => ProgW, I1 => WmemAddrW(3), I0 => WmemAddrR(3));
	LMUX0F: FD port map (C => Clk, D => WmemAddrA(0), Q => WmemAddr(0));
	LMUX1F: FD port map (C => Clk, D => WmemAddrA(1), Q => WmemAddr(1));
	LMUX2F: FD port map (C => Clk, D => WmemAddrA(2), Q => WmemAddr(2));
	LMUX3F: FD port map (C => Clk, D => WmemAddrA(3), Q => WmemAddr(3));
	
	FDPROGDD: FD port map (C => Clk, D => ProgD, Q => ProgDD);
	FDPROGWD: FD port map (C => Clk, D => ProgW, Q => ProgWD);

	WmemAddr(4) <= '1';
	WmemRegI <= WmemReg(30 downto 0) & ProgDD; -- Shifted!
	GRAM: for i in 0 to 3 generate
		LRAM: RAM32M port map (WCLK => Clk, WE => ProgWD, ADDRA => WmemAddr, ADDRB => WmemAddr, ADDRC => WmemAddr, ADDRD => WmemAddr,
			DOA => WmemRegA(i*8+1 downto i*8+0), DIA => WmemRegI(i*8+1 downto i*8+0),
			DOB => WmemRegA(i*8+3 downto i*8+2), DIB => WmemRegI(i*8+3 downto i*8+2),
			DOC => WmemRegA(i*8+5 downto i*8+4), DIC => WmemRegI(i*8+5 downto i*8+4),
			DOD => WmemRegA(i*8+7 downto i*8+6), DID => WmemRegI(i*8+7 downto i*8+6));
	end generate;
	GRAMFD: for i in 0 to 31 generate
		FRAM: FD port map (C => Clk, D => WmemRegA(i), Q => WmemReg(i));
	end generate;

--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LNMUX:  LUT6 generic map (INIT => "0000000000000000000000000000000000000000000000000000000000000100") port map (O => NmuxA, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	LNMUXI: LUT6 generic map (INIT => "1111111111111111111111111111111111111111111111111111111111111011") port map (O => NmuxIA, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	FNMUX:  FD port map (C => Clk, D => NMuxA, Q => NMux);
	FNMUXI: FD port map (C => Clk, D => NMuxIA, Q => NmuxI);
			
	DMUX: SHA_DSP_Mux port map (Clk => Clk, W_in => WmemReg, N_in(31 downto 8) => Nonce_cnt, N_in(7 downto 1) => (others => '1'), N_in(0) => PC_ncnt(0), N_muxsel => Nmux, N_muxsel_inv => NmuxI, W_out => W_out);

--                                             6         5         4         3         2         1         0
--	                                   "3210987654321098765432109876543210987654321098765432109876543210"
	LCOUT0: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000011111111111111110") port map (O => CoutA(0), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT1: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000000010000") port map (O => WInjectT, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT1S: LUT2 generic map (INIT => "0100") port map (O => CoutA(1), I1 => WInjectT, I0 => PC_ncnt(0)); -- Inject pulse width only 1 clock
	LCOUT2: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000000111100") port map (O => CoutA(2), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT3: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000001111000") port map (O => CoutA(3), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT16S:LUT6 generic map (INIT => "0000011111111000000000000000000000000000000000000000000000000000") port map (O => C_out_16_sel_a, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT17S:LUT6 generic map (INIT => "0111100000000000000000000000000000000000000000000000000000000000") port map (O => C_out_17_sel_a, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LPASSE: LUT6 generic map  (INIT => "0110000000000000000000000000000000000000000000000000000000000000") port map (O => ProgAStore_sel_a, I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT6: LUT6 generic map  (INIT => "1110000000000000000000000000000000000000000000000000000000000011") port map (O => CoutA(6), I5 => PC_ncnt(6), I4 => PC_ncnt(5), I3 => PC_ncnt(4), I2 => PC_ncnt(3), I1 => PC_ncnt(2), I0 => PC_ncnt(1));
	LCOUT4: LUT6 generic map  (INIT => "0000000000000000000000000000000000000000000000000000000000000010") port map (O => C_out_4a, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));

	LCOUT0F: FD port map (C => Clk, D => CoutA(0), Q => C_out(0));
	LCOUT1F: FD port map (C => Clk, D => CoutA(1), Q => C_out(1));
	LCOUT2F: FD port map (C => Clk, D => CoutA(2), Q => C_out(2));
	LCOUT3F: FD port map (C => Clk, D => CoutA(3), Q => C_out(3));
	LCOUT4F: FD port map (C => Clk, D => C_out_4a, Q => C_out(4));
	LCOUT6F: FD port map (C => Clk, D => CoutA(6), Q => C_out(5));
	
	FPROGAED: FD port map (C => Clk, D => ProgAE, Q => ProgAED);
	LPROGASTORE: LUT3 generic map (INIT => "11001010") port map (O => ProgAStore_async, I2 => ProgAED, I1 => ProgD, I0 => ProgAStore);
	LPROGASTOREF:FD port map (C => Clk, D => ProgAStore_async, Q => ProgAStore);
	
	FPASSE:    FD port map (C => Clk, D => ProgAStore_sel_a, Q => ProgAStore_sel);
	LCOUT16SF: FD port map (C => Clk, D => C_out_16_sel_a, Q => C_out_16_sel);
	LCOUT17SF: FD port map (C => Clk, D => C_out_17_sel_a, Q => C_out_17_sel);
	
	LCOUT16:  LUT5 generic map (INIT => x"ccccaaf0") port map (O => CoutA(4), I4 => ProgAE, I3 => ProgAStore_sel, I2 => C_out_16_sel, I1 => ProgD, I0 => ProgAStore);
	LCOUT17:  LUT2 generic map (INIT => "1110") port map (O => CoutA(5), I1 => ProgAE, I0 => C_out_17_sel);
	LCOUT16F: FD port map (C => Clk, D => CoutA(4), Q => C_out(16));
	LCOUT17F: FD port map (C => Clk, D => CoutA(5), Q => C_out(17));

--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"

	---------------------------- ADDRESS GENERATION STATE MACHINE -----------------------------
	-- Generate programming address (when doing LOAD operation)
--                                        3         2         1         0
--	                                "10987654321098765432109876543210"
	LPA0: LUT5 generic map (INIT => "01010101101010100000000000000000") port map (O => paddr_a(0), I4 => ProgAE, I3 => ProgN, I2 => paddr(2), I1 => paddr(1), I0 => paddr(0));
	LPA1: LUT5 generic map (INIT => "01100110110011000000000000000000") port map (O => paddr_a(1), I4 => ProgAE, I3 => ProgN, I2 => paddr(2), I1 => paddr(1), I0 => paddr(0));
	LPA2: LUT5 generic map (INIT => "01111000111100000000000000000000") port map (O => paddr_a(2), I4 => ProgAE, I3 => ProgN, I2 => paddr(2), I1 => paddr(1), I0 => paddr(0));
	LPA0F: FD port map (C => Clk, D => paddr_a(0), Q => paddr(0));
	LPA1F: FD port map (C => Clk, D => paddr_a(1), Q => paddr(1));
	LPA2F: FD port map (C => Clk, D => paddr_a(2), Q => paddr(2));

	-- Choose either programming address or xferdata address to feed
	Addr_prog_muxin(3 downto 0) <= '0' & paddr;
	Addr_prog_muxin(7 downto 4) <= '0' & paddr;
	Addr_prog_muxin(8) <= '1'; Addr_prog_muxin(9) <= '1';
	Addr_norm_muxin(3 downto 0) <= saddre(4 downto 1);
	Addr_norm_muxin(7 downto 4) <= saddra(4 downto 1);  
	Addr_norm_muxin(8) <= saddre(5); Addr_norm_muxin(9) <= saddra(5);
	GAMUX: for i in 0 to 9 generate
		ADMUX: LUT3 generic map (INIT => "11001010") port map (O => Addr_muxout(i), I2 => ProgAE, I1 => Addr_prog_muxin(i), I0 => Addr_norm_muxin(i));
		CFDOUT: FD port map (C => Clk, D => Addr_muxout(i), Q => C_out(i+6));
	end generate;
	
--	Address generator state machines
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LSADA0: LUT6 generic map (INIT => "1010101010001000110101111111111110101010101010001111111111010101") port map (O => saddra_a(0), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA1: LUT6 generic map (INIT => "1011000100010011101001000000000000010001000100010000000001100110") port map (O => saddra_a(1), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA2: LUT6 generic map (INIT => "0111010000011110110100000000000000010100000100100000000001111000") port map (O => saddra_a(2), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA3: LUT6 generic map (INIT => "0111111111000010111111111111111111111011101010101111111110000000") port map (O => saddra_a(3), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA4: LUT6 generic map (INIT => "1001010101111101110000000000000001010101010100110000000000000000") port map (O => saddra_a(4), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA5: LUT6 generic map (INIT => "1001010101111101110000000000000000000000000000000000000000000000") port map (O => saddra_a(5), I5 => saveload_mode, I4 => saddra(4), I3 => saddra(3), I2 => saddra(2), I1 => saddra(1), I0 => saddra(0));
	LSADA0F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddra_a(0), Q => saddra(0));
	LSADA1F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(1), Q => saddra(1));
	LSADA2F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(2), Q => saddra(2));
	LSADA3F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(3), Q => saddra(3));
	LSADA4F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddra_a(4), Q => saddra(4));
	LSADA5F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddra_a(5), Q => saddra(5));

--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LSADE0: LUT6 generic map (INIT => "0010101010101000110101111111111110101010101011001111111101010101") port map (O => saddre_a(0), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE1: LUT6 generic map (INIT => "0011000100010011101001000000000000010001000100010000000001100110") port map (O => saddre_a(1), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE2: LUT6 generic map (INIT => "0111010000010110110100000000000000010100000100000000000011111000") port map (O => saddre_a(2), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE3: LUT6 generic map (INIT => "0111111111101010111111111111111111111011101011001111111110000000") port map (O => saddre_a(3), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE4: LUT6 generic map (INIT => "1001010101010101110000000000000001010101010100010000000010000000") port map (O => saddre_a(4), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE5: LUT6 generic map (INIT => "1001010101010101110000000000000000000000000000000000000000000000") port map (O => saddre_a(5), I5 => saveload_mode, I4 => saddre(4), I3 => saddre(3), I2 => saddre(2), I1 => saddre(1), I0 => saddre(0));
	LSADE0F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddre_a(0), Q => saddre(0));
	LSADE1F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(1), Q => saddre(1));
	LSADE2F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(2), Q => saddre(2));
	LSADE3F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(3), Q => saddre(3));
	LSADE4F:FDSE port map (CE => '1', S => Addr_rst, C => Clk, D => saddre_a(4), Q => saddre(4));
	LSADE5F:FDRE port map (CE => '1', R => Addr_rst, C => Clk, D => saddre_a(5), Q => saddre(5));
	
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	LSASM:  LUT6 generic map (INIT => "1111100000000000000000000000000000000000000000000000000111111111") port map (O => saveload_mode_a, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	LSADRST:LUT6 generic map (INIT => "0000100000000010000000000000000000000000000000000000000000000000") port map (O => Addr_rst_a1, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	LSASMF: FD port map (C => Clk, D => saveload_mode_a, Q => saveload_mode);
	LSADRST1:LUT3 generic map (INIT => "11000100") port map (O => Addr_rst_a, I2 => PC_cnt(2), I1 => Addr_rst_a1, I0 => PC_cnt(0));
	LSADRSTF: FD port map (C => Clk, D => Addr_rst_a, Q => Addr_rst);
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;

entity SHA_KControl is
	port (
		Clk			: in  std_logic;
		Prog_in			: in  std_logic_vector(3 downto 0);
		K_out			: out std_logic_vector(31 downto 0); -- Feeding of constants
		C_out			: out std_logic_vector(10 downto 0)  -- 11 control signals
	);
end SHA_KControl;

architecture RTL of SHA_KControl is
	signal ProgN, ProgAE, ProgW : std_logic;

	-- Element number 63 is moved to the beginning in this constant box
	type k_array                is array(integer range 0 to 63) of std_logic_vector(31 downto 0);
	constant K                  : k_array := (x"c67178f2",
		x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
		x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
		x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
		x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
		x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13", x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
		x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3", x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
		x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5", x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
		x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208", x"90befffa", x"a4506ceb", x"bef9a3f7" 
	);
	signal matcher_en, matcher_en_a, C_out_4a, C_out_4a1 : std_logic;
	signal PcNcnt7d, PcNcnt7, PC_ncnt0_async, PCRST, PCRST_async, ProgPrev, ProgPrev_async, CTRFlush_async, CtrFlush : std_logic;
	signal PC_ncnt, PC_cnt : std_logic_vector(7 downto 0);
	signal e_sel, e_sel_a : std_logic_vector(4 downto 0);
	signal K_tmp : std_logic_vector(31 downto 0);
begin
	FDPROGAE: FD port map (C => Clk, D => Prog_in(0), Q => ProgAE);
	FDPROGW: FD port map (C => Clk, D => Prog_in(1), Q => ProgW);
	FDPROGN: FD port map (C => Clk, D => Prog_in(2), Q => ProgN);
	
	LPROGPREV: LUT2 generic map (INIT => x"e") port map (O => ProgPrev_async, I1 => ProgAE, I0 => ProgW);
	FPROGPREV: FD port map (C => Clk, D => ProgPrev_async, Q => ProgPrev);
	LCTRFLUSH: LUT3 generic map (INIT => "01010100") port map (O => CTRFlush_async, I2 => PcNcnt7d, I1 => PcNcnt7, I0 => PC_ncnt(0));
	FCTRFLUSH: FD port map (C => Clk, D => CTRFlush_async, Q => CtrFlush);
	LPCRST:    LUT6 generic map (INIT => x"10ff10ff10ff1010") port map (O => PCRST_async, I5 => PcNcnt7d, I4 => PcNcnt7, I3 => PC_ncnt(0), I2 => ProgPrev, I1 => ProgAE, I0 => ProgW);
	FPCRST:    FD port map (C => Clk, D => PCRST_async, Q => PCRST);
	LPCNCNT0:  LUT2 generic map (INIT => "0001") port map (O => PC_ncnt0_async, I1 => PCRST, I0 => PC_ncnt(0));
	FPCNCNT0:  FD port map (C => Clk, D => PC_ncnt0_async, Q => PC_ncnt(0));
	FPCCNT0:   FD port map (C => Clk, D => PC_ncnt(0), Q => PC_cnt(0));
	FPCCNT1:   FD port map (C => Clk, D => PC_ncnt(1), Q => PC_cnt(1));
	FPCCNT2:   FD port map (C => Clk, D => PC_ncnt(2), Q => PC_cnt(2));
	FPCCNT3:   FD port map (C => Clk, D => PC_ncnt(3), Q => PC_cnt(3));
	FPCCNT4:   FD port map (C => Clk, D => PC_ncnt(4), Q => PC_cnt(4));
	FPCCNT5:   FD port map (C => Clk, D => PC_ncnt(5), Q => PC_cnt(5));
	FPCCNT6:   FD port map (C => Clk, D => PC_ncnt(6), Q => PC_cnt(6));
	LPCNCNT7:  LUT2 generic map (INIT => "1110") port map (O => PC_ncnt(7), I1 => PcNcnt7, I0 => PcNcnt7d);
	FPCCNT7:   FD port map (C => Clk, D => PC_ncnt(7), Q => PC_cnt(7));
	PCSS: SHA_SingleSliceCounter port map (Clk => Clk, Rst => PCRST,   C_in => PC_ncnt(0), C_out => PcNcnt7, Ctr_out => PC_ncnt(6 downto 1), R_in => PcNcnt7, R_out => PcNcnt7d);
	
	-- All constant flip-flops shall be VERY CLOSE to rounds to simplify loading!
	-- 4 slices X BELOW loading column.
	GKLD: for i in 0 to 31 generate
		KFD: FD port map (C => Clk, D => K_tmp(i), Q => K_out(i));
	end generate;
		
	process (Clk) begin -- Load constant (8 slices X)
		if rising_edge(Clk) then
			K_tmp <= K(conv_integer(PC_ncnt(6 downto 1)));
		end if;
	end process;

--                                           3         2         1         0
--	                                   "10987654321098765432109876543210"
	LESEL0:  LUT4 generic map (INIT => x"fff2") port map (O => e_sel_a(0), I3 => ProgAE, I2 => ProgW, I1 => PC_cnt(0), I0 => PC_cnt(7));
	LESEL1:  LUT5 generic map (INIT => "01000100000000010100010001000010") port map (O => e_sel_a(1), I4 => e_sel(4), I3 => e_sel(3), I2 => e_sel(2), I1 => e_sel(1), I0 => e_sel(0));
	LESEL2:  LUT5 generic map (INIT => "00000100000000010100000001000010") port map (O => e_sel_a(2), I4 => e_sel(4), I3 => e_sel(3), I2 => e_sel(2), I1 => e_sel(1), I0 => e_sel(0));
	LESEL3:  LUT5 generic map (INIT => "01000000000000010100010000000010") port map (O => e_sel_a(3), I4 => e_sel(4), I3 => e_sel(3), I2 => e_sel(2), I1 => e_sel(1), I0 => e_sel(0));
	LESEL4:  LUT5 generic map (INIT => "10101010101010101110111011101000") port map (O => e_sel_a(4), I4 => e_sel(4), I3 => e_sel(3), I2 => e_sel(2), I1 => e_sel(1), I0 => e_sel(0));
	LESEL0F: FD port map (C => Clk, D => e_sel_a(0), Q => e_sel(0));
	LESEL1F: FD port map (C => Clk, D => e_sel_a(1), Q => e_sel(1));
	LESEL2F: FD port map (C => Clk, D => e_sel_a(2), Q => e_sel(2));
	LESEL3F: FD port map (C => Clk, D => e_sel_a(3), Q => e_sel(3));
	LESEL4F: FD port map (C => Clk, D => e_sel_a(4), Q => e_sel(4));
	C_out(3 downto 0) <= e_sel(3 downto 0); -- E_sel output
	
	LMENA: LUT4 generic map (INIT => "0000000000001110") port map (O => matcher_en_a, I3 => ProgAE, I2 => ProgW, I1 => PC_cnt(7), I0 => matcher_en);
	LMENAF: FD port map (C => Clk, D => matcher_en_a, Q => matcher_en);
	
	LCOUT41: LUT6 generic map (INIT => x"8000000000000000") port map (O => C_out_4a1, I5 => PC_cnt(6), I4 => PC_cnt(5), I3 => PC_cnt(4), I2 => PC_cnt(3), I1 => PC_cnt(2), I0 => PC_cnt(1));
	LCOUT4: LUT4 generic map (INIT => "1111111011101110") port map (O => C_out_4a, I3 => C_out_4a1, I2 => matcher_en, I1 => ProgAE, I0 => ProgW);
	LCOUT4F: FD port map (C => Clk, D => C_out_4a, Q => C_out(4));

	C_out(10 downto 5) <= "111111"; -- Match output is _always_ constant
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_TinyMatchFinalizer is
	generic (
		NONCE_ST		: std_logic_vector(23 downto 0) := "110010110000101101011010";
		HIGH			: std_logic := '1'
	);
	port (
		Clk			: in  std_logic; -- Clocks MUST be related (!).
		ClkTX			: in  std_logic; -- ClkTX is slow, but rising edge matches Clk
		Match_rst		: in  std_logic;
		Match_enable		: in  std_logic;
		Match_in		: in  std_logic_vector( 5 downto 0);
		Match_out		: out std_logic -- Slow serial transmission line
	);
end SHA_TinyMatchFinalizer;

architecture PHY of SHA_TinyMatchFinalizer is
	signal NonceC : std_logic_vector(2 downto 0);
	signal Nonce_cnt : std_logic_vector(23 downto 0);
	signal ProgRST : std_logic := '1';
	signal Mena_d, Mflip, MflipA : std_logic;
	signal lobita : std_logic;
	signal ctrst_a, ctrst : std_logic_vector(2 downto 0);   
	
	signal Match_in_delay1 : std_logic_vector(5 downto 0) := (others => '1');
	signal Match_in_delay2 : std_logic_vector(5 downto 0) := (others => '1');
	signal rstfallctr : std_logic_vector(1 downto 0);
	signal rstfallctr_a : std_logic_vector(1 downto 0);
	signal ProgRSTA : std_logic;
	
	-- Buffer for dual clocks (eliminating interaction of jitter)
	signal ClkBufCE_0, ClkBufCE : std_logic;
	signal ClkBuf, ClkBufA : std_logic_vector(32 downto 0);
	
	signal SamplerIn, SamplerOut, SamplerOutA : std_logic_vector(32 downto 0);
	signal ShiftRegIn, ShiftRegOutA, ShiftRegOut : std_logic_vector(32 downto 0);
	signal ShiftRegLoadA, ShiftMarker, ShiftRegLoad, SamplerCEA1, SamplerCEA, SamplerCE : std_logic;
begin
	-- Reset counter with a delay
	LRF0: LUT4 generic map (INIT => "0000110111011101") port map (O => rstfallctr_a(0), I3 => Match_rst, I2 => Match_enable, I1 => rstfallctr(1), I0 => rstfallctr(0));
	LRF1: LUT4 generic map (INIT => "0000111011101110") port map (O => rstfallctr_a(1), I3 => Match_rst, I2 => Match_enable, I1 => rstfallctr(1), I0 => rstfallctr(0));
	LRST: LUT4 generic map (INIT => "1111011101110111") port map (O => ProgRSTA, I3 => Match_rst, I2 => Match_enable, I1 => rstfallctr(1), I0 => rstfallctr(0));
	LRF0F: FD port map (C => Clk, D => rstfallctr_a(0), Q => rstfallctr(0));
	LRF1F: FD port map (C => Clk, D => rstfallctr_a(1), Q => rstfallctr(1));
	LRSTF: FD port map (C => Clk, D => ProgRSTA, Q => ProgRST);
	
	FDMENAD: FD port map (C => Clk, D => Match_enable, Q => Mena_d);
	
	-- Derive count enable pulse from match enable signal! Skip several counts to synchronize with source!
--                                            6         5         4         3         2         1         0
--	                                  "3210987654321098765432109876543210987654321098765432109876543210"
	CTRST0: LUT6 generic map (INIT => "0000000000000000000000000000000010101010101010101111110110101010") port map (O => ctrst_a(0), I5 => ProgRst, I4 => Mena_d, I3 => Match_enable, I2 => ctrst(2), I1 => ctrst(1), I0 => ctrst(0));
	CTRST1: LUT6 generic map (INIT => "0000000000000000000000000000000011001100110011001111111011001100") port map (O => ctrst_a(1), I5 => ProgRst, I4 => Mena_d, I3 => Match_enable, I2 => ctrst(2), I1 => ctrst(1), I0 => ctrst(0));
	CTRST2: LUT6 generic map (INIT => "1111111111111111111111111111111100000000000000001111100000000000") port map (O => ctrst_a(2), I5 => ProgRst, I4 => Mena_d, I3 => Match_enable, I2 => ctrst(2), I1 => ctrst(1), I0 => ctrst(0));
	CTRST0F: FD port map (C => Clk, D => ctrst_a(0), Q => ctrst(0));
	CTRST1F: FD port map (C => Clk, D => ctrst_a(1), Q => ctrst(1));
	CTRST2F: FD port map (C => Clk, D => ctrst_a(2), Q => ctrst(2));

	-- Nonce counter, synchronized with source!
	NON1: SHA_SingleSliceCounter generic map (INIT => NONCE_ST( 5 downto  0)) port map (Clk => Clk, Rst => ProgRST, C_in => ctrst(2), C_out => NonceC(0), Ctr_out=>Nonce_cnt(5 downto 0));
	NON2: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(11 downto  6)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(0), C_out => NonceC(1), Ctr_out=>Nonce_cnt(11 downto 6));
	NON3: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(17 downto 12)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(1), C_out => NonceC(2), Ctr_out=>Nonce_cnt(17 downto 12));
	NON4: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(23 downto 18)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(2), C_out => open, Ctr_out=>Nonce_cnt(23 downto 18));
	
	-- Delay match to make sure that nonce counter incremented to correct value
	-- Also this eases taking bits out of round column
	GMDEL: for i in 0 to 5 generate
		MDELFD1: FD generic map (INIT => '1') port map (C => Clk, D => Match_in(i), Q => Match_in_delay1(i));
		MDELFD2: FD generic map (INIT => '1') port map (C => Clk, D => Match_in_delay1(i), Q => Match_in_delay2(i));
	end generate;
	
	-- Calculate flip-bit for last value!
	LMFLIP: LUT2 generic map (INIT => "0001") port map (O => MflipA, I1 => ProgRST, I0 => Mflip);
	LMFLIPF: FD port map (C => Clk, D => MflipA, Q => Mflip);

	SCEA1: LUT6 generic map (INIT => x"8000000000000000") port map (O => SamplerCEA1, I5 => Match_in_delay1(5), I4 => Match_in_delay1(4), I3 => Match_in_delay1(3), I2 => Match_in_delay1(2), I1 => Match_in_delay1(1), I0 => Match_in_delay1(0));
	SCEA2: LUT2 generic map (INIT => "0001") port map (O => SamplerCEA, I1 => ProgRst, I0 => SamplerCEA1);
	SCEAF: FD port map (C => Clk, D => SamplerCEA, Q => SamplerCE);
	
	-- Generate here exact matched value (for each moment of time)!
--	LOBITAG: LUT3 generic map (INIT => "10010110") port map (O => lobita, I2 => Match_in_delay1(0), I1 => Mflip, I0 => Match_in_delay1(1));
--	LOBITAG: LUT2 generic map (INIT => "0110") port map (O => lobita, I1 => Mflip, I0 => Match_in_delay1(0));
	LOBITAG: LUT1 generic map (INIT => "10") port map (O => lobita, I0 => Mflip);
	LOBITAGF: FD port map (C => Clk, D => lobita, Q => SamplerIn(0));
	SamplerIn(6 downto 1) <= Match_in_delay2(5 downto 0);
	SamplerIn(7) <= HIGH;
	SamplerIn(31 downto 8) <= Nonce_cnt;
	SamplerIn(32) <= ShiftMarker; -- Input here MARKER from next part!

	-- Store INVERTED input!
	LSAM32: LUT3 generic map (INIT => "00111010") port map (O => SamplerOutA(32), I2 => SamplerCE, I1 => SamplerIn(32), I0 => SamplerOut(32));
	LSAMF32: FD port map (C => Clk, D => SamplerOutA(32), Q => SamplerOut(32));
	GSAM: for i in 0 to 31 generate
		LSAM: LUT3 generic map (INIT => x"ca") port map (O => SamplerOutA(i), I2 => SamplerCE, I1 => SamplerIn(i), I0 => SamplerOut(i));
		LSAMF: FD port map (C => Clk, D => SamplerOutA(i), Q => SamplerOut(i));
	end generate;
	
	-- Store it one or two clock AFTER ClkTX become ONE, this guarantees correctness of ClkBuf sampling
	-- even when ClkTx is not related with Clk, the required condition is only that
	-- ClkTx is slower at least 4 times than Clk. In practice ClkTx is about 10 times slower than Clk.
	BCE0: FD port map (C => Clk, D => ClkTX, Q => ClkBufCE_0);
	BCE:  FD port map (C => Clk, D => ClkBufCE_0, Q => ClkBufCE);
	GCLKB: for i in 0 to 32 generate
		CLKBLUT: LUT3 generic map (INIT => x"ca") port map (O => ClkBufA(i), I2 => ClkBufCE, I1 => SamplerOut(i), I0 => ClkBuf(i));
		CLKBFD:  FD port map (C => Clk, D => ClkBufA(i), Q => ClkBuf(i));
	end generate;	
	
	SHMFD: FD port map (C => ClkTX, D => ClkBuf(32), Q => ShiftMarker);
	SHMPULSE: LUT2 generic map (INIT => "0110") port map (O => ShiftRegLoadA, I1 => ClkBuf(32), I0 => ShiftMarker);
	SHMPULSEF: FD port map (C => ClkTX, D => ShiftRegLoadA, Q => ShiftRegLoad);
	
	ShiftRegIn(32) <= '0'; -- Start bit!
	ShiftRegIn(31 downto 0) <= ClkBuf(31 downto 0);
	
	GSH: for i in 1 to 32 generate
		LSH: LUT3 generic map (INIT => x"ca") port map (O => ShiftRegOutA(i), I2 => ShiftRegLoad, I1 => ShiftRegIn(i), I0 => ShiftRegOut(i-1));
		LSHF: FD generic map (INIT => '1') port map (C => ClkTX, D => ShiftRegOutA(i), Q => ShiftRegOut(i));
	end generate;
	LSH0: LUT2 generic map (INIT => "1011") port map (O => ShiftRegOutA(0), I1 => ShiftRegLoad, I0 => ShiftRegIn(0));
	LSH0F: FD generic map (INIT => '1') port map (C => ClkTX, D => ShiftRegOutA(0), Q => ShiftRegOut(0));
	
	Match_out <= ShiftRegOut(32); -- Send to output all bits
end PHY;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;

entity SHA_MatchFinalizer is
	generic (
		NONCE_ST		: std_logic_vector(23 downto 0) := "110010110000101101011010";
		HIGH			: std_logic := '1';
		PARITY			: std_logic := '1'
	);
	port (
		Clk			: in  std_logic;
		Match_rst		: in  std_logic;
		Match_enable		: in  std_logic;
		Match_in		: in  std_logic_vector(5 downto 0);
		Match_out		: out std_logic_vector(31 downto 0);
		Match_has		: out std_logic
	);
end SHA_MatchFinalizer;

architecture RTL of SHA_MatchFinalizer is
	attribute keep_hierarchy : string;
	attribute keep_hierarchy of RTL : architecture is "TRUE";

	signal NonceC : std_logic_vector(2 downto 0);
	signal Nonce_cnt : std_logic_vector(23 downto 0);
	signal ProgRST : std_logic := '1';
	signal Mena_d, Mflip : std_logic;
	signal hmatch : std_logic := '0';
	signal ctrst : std_logic_vector(2 downto 0);   
	
	signal Match_in_delay1 : std_logic_vector(5 downto 0) := (others => '1');
	signal Match_in_delay2 : std_logic_vector(5 downto 0) := (others => '1');
	signal rstfallctr : std_logic_vector(1 downto 0);
begin
	-- Put counter in reset condition!
	process (Clk) begin
		if rising_edge(Clk) then
			if Match_rst = '1' and Match_enable = '1' then
				rstfallctr <= "00"; ProgRST <= '1';
			else
				case rstfallctr is
					when "11" => rstfallctr <= "11"; ProgRST <= '0';
					when "10" => rstfallctr <= "11"; ProgRST <= '1';
					when "01" => rstfallctr <= "10"; ProgRST <= '1';
					when others => rstfallctr <= "01"; ProgRST <= '1'; -- "00"
				end case;
			end if;
		end if;
	end process;

	-- When to count ? Derive from match enable signal!
	process (Clk) begin
		if rising_edge(Clk) then
			Mena_d <= Match_enable;
			if ProgRst = '1' then
				ctrst <= "100";
			elsif Mena_d = '0' and Match_enable = '1' then
				case ctrst is
					when "000" => ctrst <= "001";
					when "001" => ctrst <= "010";
					when "010" => ctrst <= "011";
					when others => ctrst <= "111";
				end case;
			else
				ctrst(0) <= ctrst(0);
				ctrst(1) <= ctrst(1);
				ctrst(2) <= '0';
			end if;
		end if;
	end process;

	-- Generate output if match found
	-- Trigger it with delayed input, to make sure that we incremented nonce counter right before!
	process (Clk) begin
		if rising_edge(Clk) then
			Mflip <= not ProgRST and not Mflip;
			Match_in_delay1 <= Match_in;
			Match_in_delay2 <= Match_in_delay1;
			if Match_in_delay2 = "111111" or ProgRst = '1' then
				Match_out <= (others => '0');
				hmatch <= '0';
			else
				Match_out <= Nonce_cnt & HIGH & Match_in_delay2 & (PARITY xor Mflip xor Match_in_delay2(1));
				hmatch <= '1';
			end if;
		end if;
	end process;
	Match_has <= hmatch;

	NON1: SHA_SingleSliceCounter generic map (INIT => NONCE_ST( 5 downto  0)) port map (Clk => Clk, Rst => ProgRST, C_in => ctrst(2), C_out => NonceC(0), Ctr_out=>Nonce_cnt(5 downto 0));
	NON2: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(11 downto  6)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(0), C_out => NonceC(1), Ctr_out=>Nonce_cnt(11 downto 6));
	NON3: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(17 downto 12)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(1), C_out => NonceC(2), Ctr_out=>Nonce_cnt(17 downto 12));
	NON4: SHA_SingleSliceCounter generic map (INIT => NONCE_ST(23 downto 18)) port map (Clk => Clk, Rst => ProgRST, C_in => NonceC(2), C_out => open, Ctr_out=>Nonce_cnt(23 downto 18));

end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;

entity SHA_FIFO is
	port (
		ClkIn			: in  std_logic;
		ClkOut			: in  std_logic;
		D_has			: in  std_logic;
		D_in			: in  std_logic_vector(31 downto 0);
		D_ena			: in  std_logic;
		D_out			: out std_logic_vector(31 downto 0);
		D_has_out		: out std_logic
	);
end entity;

architecture RTL of SHA_FIFO is
	type fmem_type is array (0 to 3) of std_logic_vector(32 downto 0);
	signal fmem : fmem_type := (others => (others => '0'));

	attribute ram_style : string;
	attribute ram_style of fmem : signal is "distributed";

	signal memdata : std_logic_vector(32 downto 0);
	signal D_read : std_logic := '0';
	signal F_has : std_logic := '0';
	signal rdcnt : std_logic_vector(2 downto 0) := "100";
	signal wrcnt : std_logic_vector(2 downto 0) := "100";
	signal D_reg : std_logic_vector(31 downto 0) := x"00000000";
begin
	process (ClkIn) begin
		if rising_edge(ClkIn) then
			if D_has = '1' then
				fmem(conv_integer(wrcnt(1 downto 0))) <= wrcnt(2) & D_in;
				wrcnt <= wrcnt + 1;
			else
				wrcnt <= wrcnt;
			end if;
		end if;
	end process;
	memdata <= fmem(conv_integer(rdcnt(1 downto 0)));

	process (ClkOut) begin
		if rising_edge(ClkOut) then
			-- Make one clock delay before read, to ensure that we get all data correctly!
			if memdata(32) = rdcnt(2) and D_ena = '1' and D_read = '0' then
				D_read <= '1';
			else
				D_read <= '0';
			end if;

			if D_read = '1' then
				D_reg <= memdata(31 downto 0);
				F_has <= '1';
				rdcnt <= rdcnt + 1;
			else
				D_reg <= D_reg;
				F_has <= '0';
				rdcnt <= rdcnt;
			end if;
		end if;
	end process;

	D_has_out <= F_has;
	D_out <= D_reg;
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;

entity SHA_MatchTX is
	port (
		Clk			: in  std_logic;
		ClkTX			: in  std_logic;
		Match_has		: in  std_logic;
		Match_in		: in  std_logic_vector(31 downto 0);
		Match_out		: out std_logic
	);
end SHA_MatchTX;

architecture RTL of SHA_MatchTX is
	attribute keep_hierarchy : string;
	attribute keep_hierarchy of RTL : architecture is "TRUE";

	signal shreg, ddata : std_logic_vector(31 downto 0);
	signal dhas  : std_logic;
	signal txctr : std_logic_vector(5 downto 0) := "111111"; -- Transmission counter
	signal mout : std_logic := '1';
begin
	FIFO: SHA_FIFO port map (ClkIn => Clk, ClkOut => ClkTX, D_has => Match_has, D_in => Match_in, D_out => ddata, D_has_out => dhas, D_ena => txctr(5));

	process (ClkTX) begin
		if rising_edge(ClkTX) then
			if dhas = '1' then
				txctr <= "000000";
				mout <= '0';
				shreg <= ddata;
			elsif txctr(5) = '0' then
				txctr <= txctr + 1;
				mout <= shreg(31);
				shreg <= shreg(30 downto 0) & '0';
			else
				txctr <= txctr;
				shreg <= shreg;
				mout <= '1';
			end if;
		end if;
	end process;
	Match_out <= mout;
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;

entity SHA_MatchRX is
	port (
		Clk			: in  std_logic;
		ClkTX			: in  std_logic;
		Match_in		: in  std_logic;
		Match_ena		: in  std_logic := '1';
		Match_out		: out std_logic_vector(31 downto 0);
		Match_has		: out std_logic
	);
end SHA_MatchRX;

architecture RTL of SHA_MatchRX is
	attribute keep_hierarchy : string;
	attribute keep_hierarchy of RTL : architecture is "TRUE";
	signal rxctr  : std_logic_vector(5 downto 0) := "100000";
	signal shreg  : std_logic_vector(31 downto 0) := (others => '0');
	signal sh_has : std_logic := '0';
begin
	process (ClkTX) begin -- Implement receive counter
		if rising_edge(ClkTX) then
			if Match_in = '0' and rxctr(5) = '1' then -- Received start bit!
				rxctr <= "000000";
			else
				if rxctr(5) = '1' then
					rxctr <= rxctr;
				else
					rxctr <= rxctr + 1;
				end if;
			end if;
		end if;
	end process;

	process (ClkTX) begin -- Activate shift register
		if rising_edge(ClkTX) then
			if rxctr(5) = '0' then
				shreg <= shreg(30 downto 0) & Match_in;
			else
				shreg <= shreg;
			end if;
		end if;
	end process;

	process (ClkTX) begin -- When to perform capture ?
		if rising_edge(ClkTX) then
			if rxctr(4 downto 0) = "11111" then
				sh_has <= '1';
			else
				sh_has <= '0';
			end if;
		end if;
	end process;

	FIFO: SHA_FIFO port map (ClkIn => ClkTX, ClkOut => Clk, D_has => sh_has, D_in => shreg, D_out => Match_out, D_has_out => Match_has, D_ena => Match_ena);
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_DSP_Feed is
	port (
		Clk			: in  std_logic;
		PC_in			: in  std_logic_vector(47 downto 0);
		PC_out			: out std_logic_vector(47 downto 0);
		C_out			: out std_logic_vector(47 downto 0)
	);
end SHA_DSP_Feed;

architecture PHYLOC of SHA_DSP_Feed is
begin
	DSPI: DSP48A1
		generic map (
			A0REG => 0, -- First stage A input pipeline register (0/1)
			A1REG => 0, -- Second stage A input pipeline register (0/1)
			B0REG => 0, -- First stage B input pipeline register (0/1)
			B1REG => 0, -- Second stage B input pipeline register (0/1)
			CARRYINREG => 0, -- CARRYIN input pipeline register (0/1)
			CARRYINSEL => "OPMODE5", -- Specify carry-in source, "CARRYIN" or "OPMODE5"
			CARRYOUTREG => 0, -- CARRYOUT output pipeline register (0/1)
			CREG => 0, -- C input pipeline register (0/1)
			DREG => 0, -- D pre-adder input pipeline register (0/1)
			MREG => 0, -- M pipeline register (0/1)
			OPMODEREG => 0, -- Enable=1/disable=0 OPMODE input pipeline registers
			PREG => 1, -- P output pipeline register (0/1)
			RSTTYPE => "SYNC" -- Specify reset type, "SYNC" or "ASYNC"
			)
		port map (
			-- Cascade Ports: 18-bit (each) output: Ports to cascade from one DSP48 to another
			BCOUT => open, -- 18-bit output: B port cascade output
			PCOUT => PC_out, -- 48-bit output: P cascade output (if used, connect to PCIN of another DSP48A1)
			-- Data Ports: 1-bit (each) output: Data input and output ports
			CARRYOUT => open, -- 1-bit output: carry output (if used, connect to CARRYIN pin of another
			-- DSP48A1)
			CARRYOUTF => open, -- 1-bit output: fabric carry output
			M => open, -- 36-bit output: fabric multiplier data output
			P => C_out, -- 48-bit output: data output
			-- Cascade Ports: 48-bit (each) input: Ports to cascade from one DSP48 to another
			PCIN => PC_in, -- 48-bit input: P cascade input (if used, connect to PCOUT of another DSP48A1)
			-- Control Input Ports: 1-bit (each) input: Clocking and operation mode
			CLK => Clk, -- 1-bit input: clock input
			OPMODE => "00000100", -- 8-bit input: operation mode input (just feed-through PCIN port)
			
			-- Data Ports: 18-bit (each) input: Data input and output ports
			A => (others => '1'), -- 18-bit input: A data input
			B => (others => '1'), -- 18-bit input: B data input (connected to fabric or BCOUT of adjacent DSP48A1)
			C => (others => '1'), -- 48-bit input: C data input
			-- DSP48A1)
			D => (others => '1'), -- 18-bit input: B pre-adder data input
			
			-- Reset/Clock Enable Input Ports: 1-bit (each) input: Reset and enable input ports
			CEA => '0', -- 1-bit input: active high clock enable input for A registers
			CEB => '0', -- 1-bit input: active high clock enable input for B registers
			CEC => '0', -- 1-bit input: active high clock enable input for C registers
			CECARRYIN => '0', -- 1-bit input: active high clock enable input for CARRYIN registers
			CED => '0', -- 1-bit input: active high clock enable input for D registers
			CEM => '0', -- 1-bit input: active high clock enable input for multiplier registers
			CEOPMODE => '1', -- 1-bit input: active high clock enable input for OPMODE registers
			CEP => '1', -- 1-bit input: active high clock enable input for P registers
			RSTA => '0', -- 1-bit input: reset input for A pipeline registers
			RSTB => '0', -- 1-bit input: reset input for B pipeline registers
			RSTC => '0', -- 1-bit input: reset input for C pipeline registers
			RSTCARRYIN => '0', -- 1-bit input: reset input for CARRYIN pipeline registers
			RSTD => '0', -- 1-bit input: reset input for D pipeline registers
			RSTM => '0', -- 1-bit input: reset input for M pipeline registers
			RSTOPMODE => '0', -- 1-bit input: reset input for OPMODE pipeline registers
			RSTP => '0' -- 1-bit input: reset input for P pipeline registers
		);
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_DSP_Mux is
	port (
		Clk			: in  std_logic;
		W_in			: in  std_logic_vector(31 downto 0); -- W input
		N_in			: in  std_logic_vector(31 downto 0); -- Nonce input
		N_muxsel		: in  std_logic; -- Nonce MUXSEL
		N_muxsel_inv		: in  std_logic;
		W_out			: out std_logic_vector(31 downto 0)
	);
end SHA_DSP_Mux;

architecture PHYLOC of SHA_DSP_Mux is
	component SHA_DSP_Feed
		port (
			Clk		: in  std_logic;
			PC_in		: in  std_logic_vector(47 downto 0);
			PC_out		: out std_logic_vector(47 downto 0);
			C_out		: out std_logic_vector(47 downto 0)
		);
	end component;

	signal C_reg : std_logic_vector(47 downto 0);
	signal DAB : std_logic_vector(47 downto 0);
	signal D_reg, A_reg, B_reg : std_logic_vector(17 downto 0);
	signal PC1, PC2 : std_logic_vector(47 downto 0);
	signal Plo_reg, Phi_reg : std_logic_vector(47 downto 0); -- P output after two additional DSPs
	
	type ttab_type is array(0 to 31) of integer;
	constant ttab : ttab_type :=
	
	--  0 .. 11
	-- 12 .. 23
	-- 24 .. 35
	-- 36 .. 47
	
	( 0, 1,12,24, 25,36,37, 6,  7, 8, 9,10, 17,18,19,20,
	  2, 3, 4, 5, 13,14,15,16, 26,27,28,29, 38,39,40,41 );
	
	signal T_in  : std_logic_vector(6 downto 0);
begin
	DAB(11) <= '1'; C_reg(11) <= '1';
	DAB(23 downto 21) <= (others => '1'); C_reg(23 downto 21) <= (others => '1');
	DAB(35 downto 30) <= (others => '1'); C_reg(35 downto 30) <= (others => '1');
	DAB(47 downto 42) <= (others => '1'); C_reg(47 downto 42) <= (others => '1');
	
	GB: for i in 0 to 15 generate
		G1: if i <= 6 generate
			T_in(i) <= Plo_reg(ttab(i));
		end generate;
		G2: if i > 6 generate
			W_out(i) <= Phi_reg(ttab(i));
		end generate;
		
		W_out(i+16) <= Phi_reg(ttab(i+16));
		DAB(ttab(i)) <= N_in(i); DAB(ttab(i+16)) <= N_in(i+16);
		C_reg(ttab(i)) <= W_in(i); C_reg(ttab(i+16)) <= W_in(i+16);
	end generate;

	-- Inject 7 registers to make loading from DSP easier
	FDT0: FD port map (C => Clk, D => T_in(0), Q => W_out(0));
	FDT1: FD port map (C => Clk, D => T_in(1), Q => W_out(1));
	FDT2: FD port map (C => Clk, D => T_in(2), Q => W_out(2));
	FDT3: FD port map (C => Clk, D => T_in(3), Q => W_out(3));
	FDT4: FD port map (C => Clk, D => T_in(4), Q => W_out(4));
	FDT5: FD port map (C => Clk, D => T_in(5), Q => W_out(5));
	FDT6: FD port map (C => Clk, D => T_in(6), Q => W_out(6));
	
	-- Wire DAB to D:A:B registers
	B_reg <= DAB(17 downto 0);
	A_reg <= DAB(35 downto 18);
	D_reg(11 downto 0) <= DAB(47 downto 36);
	D_reg(17 downto 12) <= (others => '1');

	DSPI: DSP48A1
		generic map (
			A0REG => 0, -- First stage A input pipeline register (0/1)
			A1REG => 1, -- Second stage A input pipeline register (0/1)
			B0REG => 0, -- First stage B input pipeline register (0/1)
			B1REG => 1, -- Second stage B input pipeline register (0/1)
			CARRYINREG => 1, -- CARRYIN input pipeline register (0/1)
			CARRYINSEL => "OPMODE5", -- Specify carry-in source, "CARRYIN" or "OPMODE5"
			CARRYOUTREG => 1, -- CARRYOUT output pipeline register (0/1)
			CREG => 1, -- C input pipeline register (0/1)
			DREG => 1, -- D pre-adder input pipeline register (0/1)
			MREG => 1, -- M pipeline register (0/1)
			OPMODEREG => 1, -- Enable=1/disable=0 OPMODE input pipeline registers
			PREG => 1, -- P output pipeline register (0/1)
			RSTTYPE => "SYNC" -- Specify reset type, "SYNC" or "ASYNC"
			)
		port map (
			-- Cascade Ports: 18-bit (each) output: Ports to cascade from one DSP48 to another
			BCOUT => open, -- 18-bit output: B port cascade output
			PCOUT => PC1, -- 48-bit output: P cascade output (if used, connect to PCIN of another DSP48A1)
			-- Data Ports: 1-bit (each) output: Data input and output ports
			CARRYOUT => open, -- 1-bit output: carry output (if used, connect to CARRYIN pin of another
			-- DSP48A1)
			CARRYOUTF => open, -- 1-bit output: fabric carry output
			M => open, -- 36-bit output: fabric multiplier data output
			P => open, -- 48-bit output: data output
			-- Cascade Ports: 48-bit (each) input: Ports to cascade from one DSP48 to another
			PCIN => open, -- 48-bit input: P cascade input (if used, connect to PCOUT of another DSP48A1)
			-- Control Input Ports: 1-bit (each) input: Clocking and operation mode
			CLK => Clk, -- 1-bit input: clock input
			OPMODE(7 downto 4) => "0000",
			OPMODE(3) => N_muxsel_inv,
			OPMODE(2) => N_muxsel_inv,
			OPMODE(1) => N_muxsel,
			OPMODE(0) => N_muxsel,
			
			-- Data Ports: 18-bit (each) input: Data input and output ports
			A => A_reg, -- 18-bit input: A data input
			B => B_reg, -- 18-bit input: B data input (connected to fabric or BCOUT of adjacent DSP48A1)
			C => C_reg, -- 48-bit input: C data input
			CARRYIN => '0', -- 1-bit input: carry input signal (if used, connect to CARRYOUT pin of another
			-- DSP48A1)
			D => D_reg, -- 18-bit input: B pre-adder data input
			
			-- Reset/Clock Enable Input Ports: 1-bit (each) input: Reset and enable input ports
			CEA => '1', -- 1-bit input: active high clock enable input for A registers
			CEB => '1', -- 1-bit input: active high clock enable input for B registers
			CEC => '1', -- 1-bit input: active high clock enable input for C registers
			CECARRYIN => '0', -- 1-bit input: active high clock enable input for CARRYIN registers
			CED => '1', -- 1-bit input: active high clock enable input for D registers
			CEM => '1', -- 1-bit input: active high clock enable input for multiplier registers
			CEOPMODE => '1', -- 1-bit input: active high clock enable input for OPMODE registers
			CEP => '1', -- 1-bit input: active high clock enable input for P registers
			RSTA => '0', -- 1-bit input: reset input for A pipeline registers
			RSTB => '0', -- 1-bit input: reset input for B pipeline registers
			RSTC => '0', -- 1-bit input: reset input for C pipeline registers
			RSTCARRYIN => '0', -- 1-bit input: reset input for CARRYIN pipeline registers
			RSTD => '0', -- 1-bit input: reset input for D pipeline registers
			RSTM => '0', -- 1-bit input: reset input for M pipeline registers
			RSTOPMODE => '0', -- 1-bit input: reset input for OPMODE pipeline registers
			RSTP => '0' -- 1-bit input: reset input for P pipeline registers
		);
	FEED1: SHA_DSP_Feed port map (Clk => Clk, PC_in => PC1, PC_out => PC2, C_out => Plo_reg );
	FEED2: SHA_DSP_Feed port map (Clk => Clk, PC_in => PC2, PC_out => open, C_out => Phi_reg );
end PHYLOC;
