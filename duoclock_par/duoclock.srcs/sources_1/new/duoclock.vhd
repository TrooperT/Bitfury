--
-- Copyright 2012 www.bitfury.org
--

-- 1
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

package SHADuo_lib is
	type Str10_type is array (0 to 9) of string(1 to 1);
	constant Str10    : Str10_type := ("0","1","2","3","4","5","6","7","8","9");
	type BelNames_type is array(0 to 3) of string(1 to 1);
	constant BelNames : BelNames_type  := ("A", "B", "C", "D");
	constant RBelNames : BelNames_type := ("D", "C", "B", "A");

	type S_array_type is array (0 to 63) of std_logic_vector(255 downto 0);
	type WS_array_type is array (0 to 63) of std_logic_vector(287 downto 0);
	type P_array_type is array(0 to 63) of integer;
	type k_array_type is array(0 to 63) of std_logic_vector(31 downto 0);

	function itoa( x : integer ) return string;

	constant DCBA_const : std_logic_vector(127 downto 0) := x"a54ff53a_3c6ef372_bb67ae85_6a09e667";
	constant HGFE_const : std_logic_vector(127 downto 0) := x"5be0cd19_1f83d9ab_9b05688c_510e527f";

	constant SHA_Consts : k_array_type := (
		x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
		x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
		x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
		x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
		x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13", x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
		x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3", x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
		x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5", x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
		x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208", x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
	);

	component SHA_NonceCtr
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 16;
			NONCE_START	: std_logic_vector(31 downto 0)
		);
		port (
			ClkS		: in  std_logic;
			ProgC		: in  std_logic;
			N_out		: out std_logic_vector(31 downto 0)
		);
	end component;

	component SHA_HalfRound
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 24;
			IS_ABCD		: integer := 1
		);
		port (
			ClkS		: in  std_logic;
			S_in		: in  std_logic_vector(127 downto 0);
			S_out		: out std_logic_vector(127 downto 0);
			ADD1_in		: in  std_logic_vector(31 downto 0);
			ADD2_in		: in  std_logic_vector(31 downto 0)
		);
	end component;

	component SHA_XFastAdd
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 16
		);
		port (
			ClkS		: in  std_logic;
			A_in		: in  std_logic_vector(31 downto 0);
			B_in		: in  std_logic_vector(31 downto 0);
			S_out		: out std_logic_vector(31 downto 0)
		);
	end component;

	component SHA_AUXRound
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 16;
			KVAL		: std_logic_vector(31 downto 0)
		);
		port (
			ClkS		: in  std_logic;
			B_in		: in  std_logic_vector(31 downto 0);
			W_in		: in  std_logic_vector(31 downto 0);
			S_out		: out std_logic_vector(31 downto 0)
		);
	end component;

	component SHA_WRound
		generic (
			LOC_LXI		: integer := 4;
			LOC_MXI		: integer := 2;
			LOC_AUX1	: integer := 1;
			LOC_AUX2	: integer := 7;
			LOC_Y		: integer := 24; -- Y location
			W9_DELAY	: integer := 0;  -- Implement W9 delay (additional)
			W1_DELAY	: integer := 0;  -- Implement W1 delay (additional)
			WTURN		: integer := 0   -- Implement 180-degree turn
		);
		port (
			Clk		: in  std_logic;
			W_mux		: in  std_logic; -- MUX SETTING
			W_mux_out	: out std_logic;
			W_in		: in  std_logic_vector(287 downto 0);
			W_out		: out std_logic_vector(287 downto 0)
		);
	end component;

	-- 45/47-round snake component with U-turn
	-- Polished for routability at 200 / 400 Mhz performance.
	component SHA_Snake
		generic (
			LOC_Y		: integer := 0
		);
		port (
			Clk		: in  std_logic;
			ClkS		: in  std_logic;
			W_mux		: in  std_logic;
			W_in		: in  std_logic_vector(287 downto 0);
			S_in		: in  std_logic_vector(255 downto 0);
			S_out		: out std_logic_vector(255 downto 0)
		);
	end component;

	-- Primary SHA256 core
	component SHA_Primary
		generic (
			LOC_Y		: integer := 1;
			NONCE_START	: std_logic_vector(31 downto 0) := x"12341234"
		);
		port (
			Clk		: in  std_logic;
			ClkS		: in  std_logic;
			ProgC		: in  std_logic;
			ProgD		: in  std_logic;
			S_out		: out std_logic_vector(255 downto 0)
		);
	end component;

	-- Secondary SHA256 core
	component SHA_Secondary
		generic (
			LOC_Y		: integer := 0
		);
		port (
			Clk		: in  std_logic;
			ClkS		: in  std_logic;
			ProgC		: in  std_logic;
			ProgD		: in  std_logic;
			S_in		: in  std_logic_vector(255 downto 0);
			Match		: out std_logic
		);
	end component;

	-- Full big core
	component SHA_FullCore
		generic (
			LOC_Y		: integer := 0;
			NONCE_START	: std_logic_vector(31 downto 0)
		);
		port (
			Clk		: in  std_logic;
			ClkS		: in  std_logic;
			ProgC		: in  std_logic;
			ProgD		: in  std_logic;
			Match		: out std_logic
		);
	end component;

	constant RND_AX_pos : P_array_type := (
	  0,  4,  8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 70, 74, 78, 82, 86, 90, 94, 98,102,106,110,114,118,128,
	122,118,114,110,106,102, 98, 94, 90, 86, 82, 78, 74, 70, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12,  8,  4,  0,
	others => 128 );

	constant RND_EX_pos : P_array_type := (
	  2,  6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, 68, 72, 76, 80, 84, 88, 92, 96,100,104,108,112,116,122,128,
	124,120,116,112,108,104,100, 96, 92, 88, 84, 80, 76, 72, 68, 62, 58, 54, 50, 46, 42, 38, 34, 30, 26, 22, 18, 14, 10,  6,  2,
	others => 128 );

	-- 62 total rounds, correct location preferences
	constant RND_AUX_pos : P_array_type := (
	  0,  6,  8, 14, 16, 22, 24, 30, 32, 38, 40, 46, 48, 54, 56, 62, 64, 72, 74, 80, 82, 88, 90, 96, 98,104,106,112,114,122,128,
	124,122,118,112,110,104,102, 96, 94, 88, 86, 80, 78, 72, 70, 62, 60, 54, 52, 46, 44, 38, 36, 32, 28, 22, 20, 14, 12,  6,  4,
	others => 128 );

	-- 0..7 8 9 .. 23
	constant RND_MW_pos : P_array_type := (
		60, 68, 76, 84, 94,100,108,116,   120,   116, 108, 100, 90, 84, 76, 64, 56, 48, 40, 30, 26, 18, 10,  2, others => 128 );
	constant RND_LW_pos : P_array_type := (
		58, 70, 78, 86, 92,102,110,118,   120,   114, 106,  98, 92, 82, 74, 68, 58, 50, 42, 34, 24, 16,  8,  0, others => 128 );

	constant RND_AX1_pos : P_array_type := (
		56, 64, 74, 82, 90, 98,106,114,   124,   118, 110, 102, 94, 86, 78, 70, 60, 52, 44, 36, 28, 20, 12,  4, others => 128 );
	constant RND_AX2_pos : P_array_type := (
		62, 72, 80, 88, 96,104,112,122,   126,   122, 112, 104, 96, 88, 80, 72, 62, 54, 46, 38, 32, 22, 14,  6, others => 128 );
end SHADuo_lib;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

package body SHADuo_lib is
	function itoa( x : integer ) return string is
		variable n: integer := x; -- needed by some compilers
	begin
		if n < 0 then return "-" & itoa(-n);
		elsif n < 10 then return Str10(n);
		else return itoa(n/10) & Str10(n rem 10);
		end if;
	end function itoa;
end SHADuo_lib;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_XFastAdd is
	generic (
		LOC_X		: integer := 0;
		LOC_Y		: integer := 16
	);
	port (
		ClkS		: in  std_logic;
		A_in		: in  std_logic_vector(31 downto 0);
		B_in		: in  std_logic_vector(31 downto 0);
		S_out		: out std_logic_vector(31 downto 0)
	);
end SHA_XFastAdd;

architecture PHYLOC of SHA_XFastAdd is
	attribute LOC : string;

	constant loc_x1 : string := "SLICE_X"&itoa(LOC_X+1)&"Y";
	constant loc_x2 : string := "SLICE_X"&itoa(LOC_X+3)&"Y";

	constant loc_x1r : string := "SLICE_X"&itoa(LOC_X+1)&"Y"&itoa(LOC_Y)&":SLICE_X"&itoa(LOC_X+3)&"Y"&itoa(LOC_Y+7);
	constant loc_x2r : string := "SLICE_X"&itoa(LOC_X+3)&"Y"&itoa(LOC_Y)&":SLICE_X"&itoa(LOC_X+3)&"Y"&itoa(LOC_Y+7);

	signal Y0, N0, Y1,N1, Y2,N2, Y3,N3, C_in : std_logic_vector(9 downto 0);
	signal Yy, Nn, Cc : std_logic_vector(10 downto 0);
	signal Sa, Sc : std_logic_vector(31 downto 0);

	attribute LOC of GYN0C, GYN1C, GYN3C : label is loc_x1r;
begin
	-- Y0 / N0 - first stage of carry line
	GYN0: for i in 1 to 9 generate -- 10 elements, 4.5 slices X, fully-asynchronous!
		attribute LOC of LPY, LPN : label is loc_x1r;
	begin
		LPY: LUT6 generic map (INIT => x"fffffee0fee00000") port map (O => Y0(i), I5 => A_in(3*i+2), I4 => B_in(3*i+2), I3 => A_in(3*i+1), I2 => B_in(3*i+1), I1 => A_in(3*i), I0 => B_in(3*i));
		LPN: LUT6 generic map (INIT => x"fffff880f8800000") port map (O => N0(i), I5 => A_in(3*i+2), I4 => B_in(3*i+2), I3 => A_in(3*i+1), I2 => B_in(3*i+1), I1 => A_in(3*i), I0 => B_in(3*i));
	end generate;

	-- 1/4 SLICE.X
	GYN0C: LUT6 generic map (INIT => x"fffff880f8800000") port map (O => N0(0), I5 => A_in(2), I4 => B_in(2), I3 => A_in(1), I2 => B_in(1),I1 => A_in(0),I0 => B_in(0));
	Y0(0) <= N0(0);

	-- Y1/N1 - second stage of carry line!
	GYN1: for i in 2 to 9 generate -- 2 SLICE X
		attribute LOC of LPY, LPN : label is loc_x1r;
	begin
		LPY: LUT4 generic map (INIT => "1100101011001010") port map (O => Y1(i), I3 => N0(i-1), I2 => Y0(i-1), I1 => Y0(i), I0 => N0(i));
		LPN: LUT4 generic map (INIT => "1100110010101010") port map (O => N1(i), I3 => N0(i-1), I2 => Y0(i-1), I1 => Y0(i), I0 => N0(i));
	end generate;
	-- 1/4 SLICE.X
	GYN1C: LUT3 generic map (INIT => "11001010") port map (O => Y1(1), I2 => Y0(0), I1 => Y0(1), I0 => N0(1));
	N1(1) <= Y1(1); N1(0) <= N0(0); Y1(0) <= Y0(0);

	GYN3H: for i in 8 to 9 generate -- 1 SLICE X
		attribute LOC of LPY,LPN : label is loc_x1r;
	begin
		LPY: LUT5 generic map (INIT => x"ffe41b00") port map (O => Y3(i), I4 => Y1(i), I3 => N1(i), I2 => Y1(i-2), I1 => N1(i-2), I0 => Y2(i-4));
		LPN: LUT5 generic map (INIT => x"ffe41b00") port map (O => N3(i), I4 => Y1(i), I3 => N1(i), I2 => Y1(i-2), I1 => N1(i-2), I0 => N2(i-4));
	end generate;

	GYN3L: for i in 4 to 7 generate -- 1 SLICE X
		attribute LOC of LPY, LPN : label is loc_x1r;
	begin
		LPY: LUT4 generic map (INIT => "1100101011001010") port map (O => Y2(i), I3 => N1(i-2), I2 => Y1(i-2), I1 => Y1(i), I0 => N1(i));
		LPN: LUT4 generic map (INIT => "1100110010101010") port map (O => N2(i), I3 => N1(i-2), I2 => Y1(i-2), I1 => Y1(i), I0 => N1(i));
	end generate;
	-- 1/4 SLICE.X
	GYN3C: LUT3 generic map (INIT => "11001010") port map (O => Y2(3), I2 => Y1(1), I1 => Y1(3), I0 => N1(3));
	N2(3) <= Y2(3); Y2(2 downto 0) <= Y1(2 downto 0); N2(2 downto 0) <= N1(2 downto 0);
	N3(7 downto 0) <= N2(7 downto 0); Y3(7 downto 0) <= Y2(7 downto 0);

	-- TOTAL: 1+1+2+4.5+0.25+0.25+0.25 = 9.25 SLICES X to prepare Y/N pairs and carries
	-- We do not do further optimizations as (3..0) carries are already prepared
	-- And for simplicity we'll implement later stage using more generic approach
	C_in(3 downto 0) <= (others => '0'); -- These carries are always zero
	C_in(7 downto 4) <= Y3(3 downto 0);  -- This is _important_
	C_in(4) <= Y3(0);

	Yy <= Y3 & '0';
	Nn <= N3 & '0';
	Cc <= C_in & '0';

	-- 6 bits of output packaged into single slice
	-- Y2/N2 - third stage of carry line!
	GFB: for i in 0 to 10 generate -- 5.5 SLICE.X consumed
		attribute LOC of LCAR, LSUM, LSUMF, LO1, LO1F : label is loc_x2r;
	begin
		-- LCAR is placed into O6 LUT
		LCAR: LUT5 generic map (INIT => x"eee88e88") port map (O => Sc(3*i), I4 => Yy(i), I3 => Nn(i), I2 => Cc(i), I1 => A_in(3*i), I0 => B_in(3*i));

		LSUM: LUT5 generic map (INIT => x"99966966") port map (O => Sa(3*i), I4 => Yy(i), I3 => Nn(i), I2 => Cc(i), I1 => A_in(3*i), I0 => B_in(3*i));
		LSUMF: FD port map (C => ClkS, D => Sa(3*i), Q => S_out(3*i));

		LO1:  LUT3 generic map (INIT => "10010110") port map (O => Sa(3*i+1), I2 => Sc(3*i), I1 => A_in(3*i+1), I0 => B_in(3*i+1));
		LO1F: FD port map (C => ClkS, D => Sa(3*i+1), Q => S_out(3*i+1));
	end generate;

	GFM: for i in 0 to 9 generate -- These do not consume any additional cells as LO2 coupled with LO1 inside of slice
		attribute LOC of LO2, LO2F : label is loc_x2r;
	begin
		LO2:  LUT5 generic map (INIT => x"e11e8778") port map (O => Sa(3*i+2), I4 => Sc(3*i), I3 => A_in(3*i+2), I2 => B_in(3*i+2), I1 => A_in(3*i+1), I0 => B_in(3*i+1));
		LO2F: FD port map (C => ClkS, D => Sa(3*i+2), Q => S_out(3*i+2));
	end generate;

	-- TOTAL consumption: 5.5 + 9.25 = 14.75 SLICES X with 5 logic delays and 5 net delays for 32-bit adder not using dedicated carry chain.
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_NonceCtr is
	generic (
		LOC_X			: integer := 0;
		LOC_Y			: integer := 16;
		NONCE_START		: std_logic_vector(31 downto 0)
	);
	port (
		ClkS			: in  std_logic;
		ProgC			: in  std_logic;
		N_out			: out std_logic_vector(31 downto 0)
	);
end SHA_NonceCtr;

architecture PHYLOC of SHA_NonceCtr is
	attribute LOC : string;
	attribute BEL : string;

	signal o6, o5, sum, sum_reg     : std_logic_vector(31 downto 0);
	signal carries    : std_logic_vector(32 downto 0);
	signal IProgC, IProgC1, IProgCA, IProgSW : std_logic;

	function finit(i : integer) return bit_vector is
		variable rv : bit_vector(3 downto 0);
	begin
		if i /= 1 and NONCE_START(i) = '1' then
			rv := "1110";
		elsif i /= 1 and NONCE_START(i) = '0' then
			rv := "0010";
		elsif i = 1 and NONCE_START(i) = '1' then
			rv := "1101";
		else
			rv := "0001";
		end if;

		return rv;
	end function finit;

--	attribute BEL of LF3 : label is "C5LUT";
--	attribute BEL of LU5 : label is "B5LUT";
--	attribute LOC of LF3, LU5, FDF1, FDF2, FDF3 : label is "SLICE_X" & itoa(LOC_X) & "Y" & itoa(LOC_Y);

	signal ProgCP, ProgCND, ProgCPD, ProgCS : std_logic;
begin
	-- This OR required to capture properly IProgSW on ProgC / Clk mismatch!
	-- So all nonce counters will start counting synchronously

	-- Get rid of CLOCK-TO-DATA PATH
	LUCLKSP: LUT1 generic map (INIT => "01") port map (O => ProgCP, I0 => ProgCND);
	FDCLKSP: FD generic map (INIT => '0') port map (C => ProgC, D => ProgCP, Q => ProgCPD);
	FDCLKSN: FD_1 generic map (INIT => '0') port map (C => ProgC, D => ProgCPD, Q => ProgCND);
	LUCLKSS: LUT2 generic map (INIT => "0110") port map (O => ProgCS, I0 => ProgCND, I1 => ProgCPD);

	FDF1: FD port map (C => ClkS, D => ProgCS, Q => IProgC);   -- Sample ProgC signal on Clk edge!
	FDF2: FD port map (C => ClkS, D => IProgC, Q => IProgC1);
	LF3:  LUT2 generic map (INIT => "1110") port map (O => IProgCA, I1 => IProgC, I0 => IProgC1);
	FDF3: FD port map (C => ClkS, D => IProgCA, Q => IProgSW);

	-- Generate LUT5 entries!
	o5(0) <= '0'; o5(31 downto 2) <= (others => '0');
	LU5:  LUT1 generic map (INIT => "01") port map (O => o5(1), I0 => IProgSW);
	carries(0) <= '0';

	BG: for i in 0 to 31 generate
		constant loc_str : string := "SLICE_X" & itoa(LOC_X) & "Y" & itoa(LOC_Y + i/4);

		attribute LOC of L6, IFF : label is loc_str;
		attribute BEL of L6 : label is BelNames(i rem 4) & "6LUT";
	begin
		L6: LUT2        generic map (INIT => finit(i))
		                port map (O => o6(i), I1 => IProgSW, I0 => sum_reg(i));
		IFF: FD	port map (C => ClkS, D => sum(i), Q => sum_reg(i));

		GC4: if (i rem 4) = 0 generate
			attribute LOC of C4 : label is loc_str;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => o6(i+3 downto i), DI => o5(i+3 downto i),
					  CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;
	N_out <= sum_reg;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;


entity SHA_HalfRound is
	generic (
		LOC_X			: integer := 82;
		LOC_Y			: integer := 164;
		IS_ABCD			: integer := 1
	);
	port (
		ClkS			: in  std_logic;
		S_in			: in  std_logic_vector(127 downto 0);
		S_out			: out std_logic_vector(127 downto 0);
		ADD1_in			: in  std_logic_vector(31 downto 0);
		ADD2_in			: in  std_logic_vector(31 downto 0)
	);
end SHA_HalfRound;

architecture PHYLOC of SHA_HalfRound is
	attribute LOC : string;
	attribute BEL : string;
	constant loc_ll : string := "SLICE_X"&itoa(LOC_X)&"Y"; -- L slice
	constant loc_lx : string := "SLICE_X"&itoa(LOC_X + 1)&"Y"; -- X slice

	signal A_in, B_in, C_in, D_in : std_logic_vector(31 downto 0);
	signal A_out : std_logic_vector(31 downto 0);

	signal A_ror1, A_ror2, A_ror3 : std_logic_vector(31 downto 0);

	signal addl6o, sum : std_logic_vector(31 downto 0);
	signal csa1c, csa2c, carries : std_logic_vector(32 downto 0);

	constant fdxorcsa_loc : string := loc_lx & itoa(LOC_Y+2) & ":" & loc_lx & itoa(LOC_Y + 9);

	function BitLocs(i : integer) return string is
	begin
		if i < 4  then return loc_ll & itoa(LOC_Y);   end if;
		if i < 8  then return loc_ll & itoa(LOC_Y+1); end if;
		if i < 12 then return loc_lx & itoa(LOC_Y);   end if;
		if i < 16 then return loc_lx & itoa(LOC_Y+1); end if;
		if i < 20 then return loc_ll & itoa(LOC_Y+10); end if;
		if i < 24 then return loc_ll & itoa(LOC_Y+11); end if;
		if i < 28 then return loc_lx & itoa(LOC_Y+10); end if;
		return loc_lx & itoa(LOC_Y+11);
	end function BitLocs;
begin
	-- Rounds only differ with RORs!
	GROR_ABCD: if IS_ABCD = 1 generate -- ROR data set is different
		A_ror1 <= A_in( 1 downto 0) & A_in(31 downto  2);
		A_ror2 <= A_in(12 downto 0) & A_in(31 downto 13);
		A_ror3 <= A_in(21 downto 0) & A_in(31 downto 22);
		csa1c(0) <= '1';
	end generate;

	GROR_EFGH: if IS_ABCD = 0 generate
		A_ror1 <= A_in( 5 downto 0) & A_in(31 downto  6);
		A_ror2 <= A_in(10 downto 0) & A_in(31 downto 11);
		A_ror3 <= A_in(24 downto 0) & A_in(31 downto 25);
		csa1c(0) <= '0';
	end generate;
	carries(0) <= '0'; csa2c(0) <= '0';

	A_in <= S_in(31 downto  0); -- Load A there!

	BG: for i in 31 downto 0 generate -- Generate bit by bit
		signal rfunc, addl5o, csa1s, csa2s, csa2sa : std_logic;

		constant loc_y4 : string := itoa(LOC_Y + i/4 + 2);
		constant blocs : string := BitLocs(i);

		attribute LOC of FD_BR, FD_CR : label is blocs;
		attribute LOC of ADDL5, ADDL6, FD_AR : label is loc_ll & loc_y4;
	begin
		-- 3 input registers!
		FD_AR: FD port map ( C => ClkS, D => sum(i),     Q => A_out(i) );
		FD_BR: FD port map ( C => ClkS, D => S_in(32+i), Q => B_in(i)  ); 
		FD_CR: FD port map ( C => ClkS, D => S_in(64+i), Q => C_in(i)  );

		GABCD: if IS_ABCD = 1 generate
			attribute LOC of CSA1L6, CSA1L5 : label is loc_lx & loc_y4;
			attribute BEL of CSA1L5 : label is RBelNames(i rem 4) & "5LUT";
			attribute BEL of CSA1L6 : label is RBelNames(i rem 4) & "6LUT";
			attribute LOC of ABCF : label is blocs;
			attribute BEL of ABCF : label is BelNames(i rem 4) & "6LUT";

			attribute LOC of FD_DR : label is fdxorcsa_loc; -- D register is used only in ABCD round!
		begin
			FD_DR: FD port map ( C => ClkS, D => S_in(96+i), Q => D_in(i) );
			-- First carry save adder is producing XOR-CSA
			CSA1L6: LUT5 generic map (INIT => x"9600ff96")
				port map (O => csa1c(i+1), I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => ADD1_in(i), I4 => D_in(i));
			CSA1L5: LUT5 generic map (INIT => x"69969669")
				port map (O => csa1s, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => ADD1_in(i), I4 => D_in(i));
			ABCF: LUT3 generic map (INIT => "11101000")
				port map (O => rfunc, I0 => A_in(i), I1 => B_in(i), I2 => C_in(i));
		end generate;

		GEFGH: if IS_ABCD = 0 generate
			attribute LOC of CSA1L6, CSA1L5 : label is loc_lx & loc_y4;
			attribute BEL of CSA1L5 : label is RBelNames(i rem 4) & "5LUT";
			attribute BEL of CSA1L6 : label is RBelNames(i rem 4) & "6LUT";
			attribute LOC of EFGF : label is blocs;
			attribute BEL of EFGF : label is BelNames(i rem 4) & "6LUT";
		begin
			-- First carry save adder is producing XOR-CSA
			CSA1L6: LUT5 generic map (INIT => x"ff969600")
				port map (O => csa1c(i+1), I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => ADD1_in(i), I4 => ADD2_in(i));
			CSA1L5: LUT5 generic map (INIT => x"96696996")
				port map (O => csa1s, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => ADD1_in(i), I4 => ADD2_in(i));
			EFGF: LUT3 generic map (INIT => "11001010")
				port map (O => rfunc, I0 => C_in(i), I1 => B_in(i), I2 => A_in(i));
		end generate;

		ADDL6: LUT4 generic map (INIT => "0110100110010110")
				port map (O => addl6o(i), I0 => csa1c(i), I1 => csa1s, I2 => rfunc, I3 => csa2c(i));
		ADDL5: LUT3 generic map (INIT => "11101000")
				port map (O => csa2c(i+1), I0 => csa1c(i), I1 => csa1s, I2 => rfunc);

		GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
			attribute LOC of C4 : label is loc_ll & loc_y4;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csa2c(i+3 downto i),
			                     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;

	-- Outputs
	S_out(31 downto  0) <= A_out;
	S_out(63 downto 32) <= A_in;
	S_out(95 downto 64) <= B_in;
	S_out(127 downto 96)<= C_in;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_AUXRound is
	generic (
		LOC_X			: integer := 0;
		LOC_Y			: integer := 16;
		KVAL			: std_logic_vector(31 downto 0)
	);
	port (
		ClkS			: in  std_logic;
		B_in			: in  std_logic_vector(31 downto 0);
		W_in			: in  std_logic_vector(31 downto 0);
		S_out			: out std_logic_vector(31 downto 0)
	);
end SHA_AUXRound;

architecture PHY of SHA_AUXRound is
	-- TODO - test these LUT init string generations
	function initlut_o5(kp : std_logic) return bit_vector is
	begin
		if kp = '1' then return x"eeee"; end if; -- Majority is OR function
		return x"8888";                          -- Majority is converted to AND function
	end function;

	function initlut_o6(kp : std_logic; kc : std_logic) return bit_vector is
	begin
		if kp = '1' then
			if kc = '0' then
				return x"e11e"; -- function is I3 xor I2 xor (I0 or I1)
			end if;
			return x"1ee1"; -- function is not (I3 xor I2 xor (I0 or I1))
		end if;
		if kc = '1' then
			return x"7887"; -- not (I2 xor I3 xor (I0 and I1))
		end if;
		return x"8778"; -- I2 xor I3 xor (I0 and I1)
	end function;

	attribute LOC : string;
	attribute BEL : string;

	signal o6, o5, sum           : std_logic_vector(31 downto 0);
	signal ae_in, be_in, carries : std_logic_vector(32 downto 0);
	constant KVALE : std_logic_vector(32 downto 0) := KVAL & '0';
begin
	carries(0) <= '0';
	ae_in <= B_in & '0';
	be_in <= W_in & '0';

	BG: for i in 0 to 31 generate
		constant loc_str : string := "SLICE_X" & itoa(LOC_X) & "Y" & itoa(LOC_Y + i/4);
		constant kp : std_logic := KVALE(i);
		constant kc : std_logic := KVALE(i+1);

		attribute LOC of L6, L5, IFF : label is loc_str;
		attribute BEL of L6 : label is BelNames(i rem 4) & "6LUT";
		attribute BEL of L5 : label is BelNames(i rem 4) & "5LUT";
	begin
		L6: LUT4	generic map (INIT => initlut_o6(kp,kc))
				port map (O => o6(i), I0 => ae_in(i), I1 => be_in(i), I2 => ae_in(i+1), I3 => be_in(i+1));
		L5: LUT4	generic map (INIT => initlut_o5(kp))
				port map (O => o5(i), I0 => ae_in(i), I1 => be_in(i), I2 => ae_in(i+1), I3 => be_in(i+1));
		IFF: FD	port map (C => ClkS, D => sum(i), Q => s_out(i));

		GC4: if (i rem 4) = 0 generate
			attribute LOC of C4 : label is loc_str;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => o6(i+3 downto i), DI => o5(i+3 downto i),
					  CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;
end PHY;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

-- Primary SHA256 core
-- Distinct inputs for values near beginning and near middle-to-end (to feed data into SHA_Snake)
entity SHA_Primary is
	generic (
		LOC_Y			: integer := 1;
		NONCE_START		: std_logic_vector(31 downto 0) := x"12341234"
	);
	port (
		Clk			: in  std_logic;
		ClkS			: in  std_logic;
		ProgC			: in  std_logic;
		ProgD			: in  std_logic;
		S_out			: out std_logic_vector(255 downto 0)
	);
end SHA_Primary;

architecture PHYLOC of SHA_Primary is
	signal S : S_array_type;
	signal Wfeed : k_array_type;
	signal Nonce1 : std_logic_vector(31 downto 0) := (others => '0');
	signal Nonce2 : std_logic_vector(31 downto 0) := (others => '0');
	signal ASumLast : std_logic_vector(31 downto 0);
	signal Wfeed_in : std_logic_vector(287 downto 0);

	attribute LOC : string;

	constant yse : integer := (LOC_Y-1)/2*14;

	constant AUX_x : P_array_type := (
		  2,  4, 10, 14, 18, 22,   26, 30, 34, 38, 42, 46, 48,   54,
		 24, 20, 16, 12,  8,  4,    6, 10, 14, 18, 22, 26, 30,   54, others => 128 );
	constant AUX_y : P_array_type := (
		 76, 76, 76, 76, 76, 76,   76, 76, 76, 76, 76, 76, 76,   76,
		168,168,168,168,168,168,  168,168,168,168,168,168,168,  156, others => 128 );

	constant EFG_x : P_array_type := (
		  2,  6, 10, 14, 18, 22,   26, 30, 34, 38, 42, 46, 50,   54,
		 24, 20, 16, 12,  8,  4,    6, 10, 14, 18, 22, 26, 30,   54, others => 128 );
	constant EFG_y : P_array_type := (
		 84, 84, 84, 84, 84, 84,   84, 84, 84, 84, 84, 84, 84,   84,
		176,176,176,176,176,176,  156,156,156,156,156,156,156,  164, others => 128 );

	constant ABC_x : P_array_type := (
		  0,  4,  8, 12, 16, 20,   24, 28, 32, 36, 40, 44, 48,   52,
		 26, 22, 18, 14, 10,  6,    4,  8, 12, 16, 20, 24, 28,   52, others => 128 );
	constant ABC_y : P_array_type := (
		 84, 84, 84, 84, 84, 84,   84, 84, 84, 84, 84, 84, 84,   84,
		176,176,176,176,176,176,  156,156,156,156,156,156,156,  164, others => 128 );

	signal ps1 : std_logic_vector(7 downto 0);
	signal ps2 : std_logic_vector(15 downto 0);
	signal W_in : std_logic_vector(95 downto 0);
	signal MS3_in : std_logic_vector(255 downto 0);

	constant WFHiBits : std_logic_vector(31 downto 0) := x"00000280";

	function muxstr(s1 : string; s2 : string) return string is
	begin
		if LOC_Y = 1 then return s2; end if;
		return s1;
	end function muxstr;

	constant MS3_loc : string := muxstr("SLICE_X28Y176:SLICE_X31Y187","SLICE_X1Y76:SLICE_X9Y83");
	constant WIN_loc : string := muxstr("SLICE_X52Y156:SLICE_X53Y163","SLICE_X52Y76:SLICE_X53Y83");
	attribute LOC of S1B, S1E, FDMS3 : label is MS3_loc;
	attribute LOC of S2B, S2E, FDWIN : label is WIN_loc;

	signal ClkSP, ClkSPD, ClkSND, W_mux, ClkE_n, ClkSS, ClkSSD : std_logic;
	attribute LOC of LUCLKSP, LUCLKSS, FDCLKSS : label is "SLICE_X67Y"&itoa(36+LOC_Y*40+5);
	attribute LOC of FDCLKEN : label is "SLICE_X66Y"&itoa(36+LOC_Y*40+5);
begin
	-- ProgD input shifter
	S1B: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps1(0), A => "11111", CE => '1', Clk => ProgC, D => ProgD);
	S2B: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps2(0), A => "11111", CE => '1', Clk => ProgC, D => ProgD);
	GS1: for i in 1 to 6 generate
		attribute LOC of S1M : label is MS3_loc;
	begin
		S1M: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps1(i), A => "11111", CE => '1', Clk => ProgC, D => ps1(i-1));
	end generate;
	GS2: for i in 1 to 14 generate
		attribute LOC of S2M : label is WIN_loc;
	begin
		S2M: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps2(i), A => "11111", CE => '1', Clk => ProgC, D => ps2(i-1));
	end generate;
	S1E: SRLC32E generic map (INIT => x"00000000") port map (Q => ps1(7), Q31 => open, A => "11111", CE => '1', Clk => ProgC, D => ps1(6));
	S2E: SRLC32E generic map (INIT => x"00000000") port map (Q => ps2(15), Q31 => open, A => "11111", CE => '1', Clk => ProgC, D => ps2(14));

	FDMS3: FD port map (C => ProgC, D => ps1(7), Q => MS3_in(0));
	FDWIN: FD port map (C => ProgC, D => ps2(15), Q => W_in(0));
	GFWIN: for i in 0 to 94 generate
		attribute LOC of FWIN : label is WIN_loc;
	begin
		FWIN: FD port map (C => ProgC, D => W_in(i), Q => W_in(i+1));
	end generate;
	GFMS3: for i in 0 to 254 generate
		attribute LOC of GFMS3 : label is MS3_loc;
	begin
		GFMS3: FD port map (C => ProgC, D => MS3_in(i), Q => MS3_in(i+1));
	end generate;

	N1G: SHA_NonceCtr generic map (LOC_X => 14*(LOC_Y-1), LOC_Y => 76 + 46*(LOC_Y-1), NONCE_START => NONCE_START)
		port map (ClkS => ClkS, ProgC => ProgC, N_out => Nonce1);

	N2G: SHA_NonceCtr generic map (LOC_X => 50, LOC_Y => 76 + 40*(LOC_Y-1), NONCE_START => (NONCE_START - 10- 8*((LOC_Y-1)/2)) )
		port map (ClkS => ClkS, ProgC => ProgC, N_out => Nonce2);

	S(0) <= MS3_in;

	-- Feed initial rounds - only with NONCE counter and constants!
	Wfeed(0) <= Nonce1; Wfeed(1)  <= x"80000000"; Wfeed(2)  <= x"00000000"; Wfeed(3)  <= x"00000000";
	Wfeed(4)  <= x"00000000"; Wfeed(5)  <= x"00000000"; Wfeed(6)  <= x"00000000"; Wfeed(7) <= x"00000000";
	Wfeed(8) <= x"00000000";  Wfeed(9) <= x"00000000"; Wfeed(10) <= x"00000000"; Wfeed(11) <= x"00000000";
	Wfeed(12) <= x"00000280";

	RNDUP: for i in 0 to 5 generate
		signal AuxSum : std_logic_vector(31 downto 0);
	begin
		AUX: SHA_AUXRound generic map (LOC_X => AUX_x(i+yse), LOC_Y => AUX_y(i+yse), KVAL => SHA_Consts(3+i))
			port map (ClkS => ClkS, B_in => S(i)(255 downto 224), W_in => Wfeed(i), S_out => AuxSum);

		EFGH: SHA_HalfRound generic map (LOC_X => EFG_x(i+yse), LOC_Y => EFG_y(i+yse), IS_ABCD => 0)
			port map (ClkS => ClkS, S_in => S(i)(255 downto 128), S_out => S(i+1)(255 downto 128), ADD1_in => S(i)(127 downto 96), ADD2_in => AuxSum);

		ABCD: SHA_HalfRound generic map (LOC_X => ABC_x(i+yse), LOC_Y => EFG_y(i+yse), IS_ABCD => 1)
			port map (ClkS => ClkS, S_in => S(i)(127 downto 0), S_out => S(i+1)(127 downto 0), ADD1_in => S(i+1)(159 downto 128), ADD2_in => (others => '0'));
	end generate;

	RNDBOT: for i in 6 to 12 generate
		signal AuxSum : std_logic_vector(31 downto 0);
	begin
		AUX: SHA_AUXRound generic map (LOC_X => AUX_x(i+yse), LOC_Y => AUX_y(i+yse), KVAL => SHA_Consts(3+i))
			port map (ClkS => ClkS, B_in => S(i+1)(255 downto 224), W_in => Wfeed(i), S_out => AuxSum);

		EFGH: SHA_HalfRound generic map (LOC_X => EFG_x(i+yse), LOC_Y => EFG_y(i+yse), IS_ABCD => 0)
			port map (ClkS => ClkS, S_in => S(i+1)(255 downto 128), S_out => S(i+2)(255 downto 128), ADD1_in => S(i+1)(127 downto 96), ADD2_in => AuxSum);

		ABCD: SHA_HalfRound generic map (LOC_X => ABC_x(i+yse), LOC_Y => ABC_y(i+yse), IS_ABCD => 1)
			port map (ClkS => ClkS, S_in => S(i+1)(127 downto 0), S_out => S(i+2)(127 downto 0), ADD1_in => S(i+2)(159 downto 128), ADD2_in => (others => '0'));
	end generate;

	AUXL: SHA_AUXRound generic map (LOC_X => AUX_x(13+yse), LOC_Y => AUX_y(13+yse), KVAL => SHA_Consts(16))
		port map (ClkS => ClkS, B_in => S(17)(255 downto 224), W_in => W_in(95 downto 64), S_out => ASumLast);

	EFGH: SHA_HalfRound generic map (LOC_X => EFG_x(13+yse), LOC_Y => EFG_y(13+yse), IS_ABCD => 0)
		port map (ClkS => ClkS, S_in => S(17)(255 downto 128), S_out => S(18)(255 downto 128), ADD1_in => S(17)(127 downto 96), ADD2_in => ASumLast);

	ABCD: SHA_HalfRound generic map (LOC_X => ABC_x(13+yse), LOC_Y => ABC_y(13+yse), IS_ABCD => 1)
		port map (ClkS => ClkS, S_in => S(17)(127 downto 0), S_out => S(18)(127 downto 0), ADD1_in => S(18)(159 downto 128), ADD2_in => (others => '0'));

	-- Additional round stages for turn-arounds.
	GPASS: if LOC_Y /= 3 generate
		S(15) <= S(14);
		S(16) <= S(15);
		S(17) <= S(16);
		S(7)  <= S(6);
	end generate;

	-- Generate additional set of flip-flops for turn-arounds!
	GPFD: if LOC_Y = 3 generate
		LTF: for i in 0 to 255 generate
			attribute LOC of LTFD : label is "SLICE_X0Y156:SLICE_X3Y189";
		begin
			LTFD: FD port map (C => ClkS, D => S(6)(i), Q => S(7)(i));
		end generate;
		FTF: for i in 0 to 255 generate
			attribute LOC of FTFD : label is "SLICE_X32Y156:SLICE_X37Y167";
		begin
			FTFD: FD port map (C => ClkS, D => S(14)(i), Q => S(15)(i));
		end generate;
		MTF: for i in 0 to 255 generate
			attribute LOC of MTFD : label is "SLICE_X38Y156:SLICE_X50Y159";
		begin
			MTFD: FD port map (C => ClkS, D => S(15)(i), Q => S(16)(i));
		end generate;

		STF: for i in 0 to 255 generate
			attribute LOC of STFD : label is "SLICE_X48Y164:SLICE_X51Y175";
		begin
			STFD: FD port map (C => ClkS, D => S(16)(i), Q => S(17)(i));
		end generate;
	end generate;

	ClkSP <= ClkS after 100 ps;
	LUCLKSP: LUT1 generic map (INIT => "10") port map (O => ClkSPD, I0 => ClkSP);
	LUCLKSS: LUT1 generic map (INIT => "10") port map (O => ClkSS, I0 => ClkSPD);
	FDCLKSS: FD port map (C => Clk, D => ClkSS, Q => ClkSSD);
	FDCLKEN: FD port map (C => Clk, D => ClkSSD, Q => ClkE_n);

	FDWMUX:  FD generic map (INIT => '0') port map (C => Clk, D => ClkE_n, Q => W_mux);

	-- Pre-fill round expander, only 98 bits transferred!
	WFBG: for i in 0 to 31 generate
		signal wf0, wf1, wf2 : std_logic;
		constant w1_loc : string := "SLICE_X51Y" & itoa(76 + (LOC_Y-1)*40 + i/8+2);
		constant w2_loc : string := "SLICE_X55Y" & itoa(76 + (LOC_Y-1)*40 + i/4);
		attribute LOC of LW0W1, FW0W1: label is w1_loc;
		attribute LOC of LW1W2, LW15W16, FW1W2, FW15W16 : label is w2_loc;
	begin
		LW0W1:   LUT3 generic map (INIT => "11001010") port map (O => wf0, I2 => ClkE_n, I1 => W_in(i),     I0 => W_in(32+i));
		LW1W2:   LUT3 generic map (INIT => "11001010") port map (O => wf1, I2 => ClkE_n, I1 => W_in(32+i),  I0 => Nonce2(i));
		LW15W16: LUT3 generic map (INIT => "11001010") port map (O => wf2, I2 => ClkE_n, I1 => WFHiBits(i), I0 => W_in(64+i));
		FW0W1:   FD port map (C => Clk, D => wf0, Q => Wfeed_in(i));
		FW1W2:   FD port map (C => Clk, D => wf1, Q => Wfeed_in(32+i));
		FW15W16: FD port map (C => Clk, D => wf2, Q => Wfeed_in(256+i));
	end generate;

	Wfeed_in(95) <= W_mux; Wfeed_in(94 downto 64) <= (others => '0');
	Wfeed_in(255 downto 224) <= x"00000"&"00"&ClkE_n&"0"&ClkE_n&"0000000";
	Wfeed_in(223 downto 96) <= (others => '0'); -- Zeroes for intermediate inputs

	SNAK: SHA_Snake generic map (LOC_Y => LOC_Y)
		port map (Clk => Clk, ClkS => ClkS, W_mux => W_mux, W_in => Wfeed_in, S_in => S(18), S_out => S(19));
	S_out <= S(19);
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_Snake is
	generic (
		LOC_Y			: integer := 0
	);
	port (
		Clk			: in  std_logic;
		ClkS			: in  std_logic;
		W_mux			: in  std_logic;
		W_in			: in  std_logic_vector(287 downto 0);
		S_in			: in  std_logic_vector(255 downto 0);
		S_out			: out std_logic_vector(255 downto 0)
	);
end SHA_Snake;

architecture PHY of SHA_Snake is
	attribute LOC : string;

	-- When LOC_Y = 0 or LOC_Y = 2 then we put 45-round snake
	-- When LOC_Y = 1 or LOC_Y = 3 then we put 47-round snake (additional W-expander round added)

	constant W_start : integer := (LOC_Y+1) rem 2;
	constant S_start : integer := W_start * 2;
	constant S_end   : integer := 47; -- Last entry!

	-- LOC_Y = 1, LOC_Y == 3 ==> kidxbase(1)+47-1 == 63
	constant Y_basis : integer := 16 + LOC_Y*40;
	constant kidxbase : P_array_type := (14,17,14,17,others => 14);
	signal S : S_array_type;
	signal W : WS_array_type;

	--	attribute LOC of MTURN : label is "SLICE_X126Y"&itoa(Y_basis)&":SLICE_X127Y"&itoa(Y_basis+39);

	signal Wmu, WtM, AuxSumMT, AuxSumMB : std_logic_vector(31 downto 0);
	signal SInTurn : std_logic_vector(255 downto 0);
begin
	-- Lay down round expander snake! (for both rounds)
	W(W_start) <= W_in;
	S(S_start) <= S_in;
	Wmu(W_start) <= W_mux;

	-- Place initial 8x2 = 16 rounds
	GWRT: for i in W_start to 7 generate
		WRT: SHA_WRound generic map (LOC_MXI => RND_MW_pos(i), LOC_LXI => RND_LW_pos(i), LOC_AUX1 => RND_AX1_pos(i), LOC_AUX2 => RND_AX2_pos(i), LOC_Y => Y_basis+20, W9_DELAY => 0, W1_DELAY => 0, WTURN => 0)
		port map (Clk => Clk, W_mux => Wmu(i), W_mux_out => Wmu(i+1), W_in => W(i), W_out => W(i+1));
	end generate;

	WRM: SHA_WRound generic map (LOC_MXI => RND_MW_pos(8), LOC_LXI => RND_LW_pos(8), LOC_AUX1 => 116, LOC_AUX2 => 126, LOC_Y => Y_basis, W9_DELAY => 1, W1_DELAY => 1, WTURN => 1)
			port map (Clk => Clk, W_mux => Wmu(8), W_mux_out => Wmu(9), W_in => W(8), W_out => W(9));

	GWRD1: for i in 9 to 10 generate
		WRB: SHA_WRound generic map (LOC_MXI => RND_MW_pos(i), LOC_LXI => RND_LW_pos(i), LOC_AUX1 => RND_AX1_pos(i), LOC_AUX2 => RND_AX2_pos(i), LOC_Y => Y_basis+12, W9_DELAY => 1, W1_DELAY => 1, WTURN => 0)
		port map (Clk => Clk, W_mux => Wmu(i), W_mux_out => Wmu(i+1), W_in => W(i), W_out => W(i+1));
	end generate;

	GWRD2: SHA_WRound generic map (LOC_MXI => RND_MW_pos(11), LOC_LXI => RND_LW_pos(11), LOC_AUX1 => RND_AX1_pos(11), LOC_AUX2 => RND_AX2_pos(11), LOC_Y => Y_basis+12, W9_DELAY => 0, W1_DELAY => 1, WTURN => 0)
		port map (Clk => Clk, W_mux => Wmu(11), W_mux_out => Wmu(12), W_in => W(11), W_out => W(12));

	GWRB: for i in 12 to 23 generate
		WRB: SHA_WRound generic map (LOC_MXI => RND_MW_pos(i), LOC_LXI => RND_LW_pos(i), LOC_AUX1 => RND_AX1_pos(i), LOC_AUX2 => RND_AX2_pos(i), LOC_Y => Y_basis+12, W9_DELAY => 0, W1_DELAY => 0, WTURN => 0)
		port map (Clk => Clk, W_mux => Wmu(i), W_mux_out => Wmu(i+1), W_in => W(i), W_out => W(i+1));
	end generate;

	-- 0..15 (16) [1] - skip
	--
	-- Place upper rounds!
	RNDUP: for i in S_start to 15 generate
		constant pidx : integer := 14 + i;
		signal Wt, AuxSum : std_logic_vector(31 downto 0);
	begin
		AG1: if (i rem 2) = 1 and i /= 15 generate
			Wt <= W(i/2+2)(255 downto 224);
		end generate;
		AG2: if i = 15 generate -- Put additional 32-bit register for routability!
			BG: for j in 0 to 31 generate
			begin
				FDW: FD port map (C => Clk, D => W(i/2+1)(256+j), Q => Wt(j));
			end generate;
		end generate;

		AG0: if (i rem 2) = 0 generate
			Wt <= W(i/2+1)(287 downto 256);
		end generate;

		AUX: SHA_AUXRound generic map (LOC_X => RND_AUX_pos(pidx), LOC_Y => Y_basis+20, KVAL => SHA_Consts(kidxbase(LOC_Y)+i))
			port map (ClkS => ClkS, B_in => S(i)(255 downto 224), W_in => Wt, S_out => AuxSum);

		EFGH: SHA_HalfRound generic map (LOC_X => RND_EX_pos(pidx), LOC_Y => Y_basis+28, IS_ABCD => 0)
			port map (ClkS => ClkS, S_in => S(i)(255 downto 128), S_out => S(i+1)(255 downto 128), ADD1_in => S(i)(127 downto 96), ADD2_in => AuxSum);

		ABCD: SHA_HalfRound generic map (LOC_X => RND_AX_pos(pidx), LOC_Y => Y_basis+28, IS_ABCD => 1)
			port map (ClkS => ClkS, S_in => S(i)(127 downto 0), S_out => S(i+1)(127 downto 0), ADD1_in => S(i+1)(159 downto 128), ADD2_in => (others => '0'));
	end generate;

	-- Add registers glue!
	PRG: for i in 0 to 255 generate
		FPRS: FD port map (C => ClkS, D => S(16)(i), Q => S(17)(i));
	end generate;

	RNDBT: for i in 17 to S_end generate
		constant pidx : integer := 14 + i;
		signal Wt, AuxSum : std_logic_vector(31 downto 0);
	begin
		AG1: if (i rem 2) = 0 generate
			Wt <= W((i-1)/2+2)(255 downto 224);
		end generate;
		AG0: if (i rem 2) = 1 generate
			Wt <= W((i-1)/2+1)(287 downto 256);
		end generate;

		AUX: SHA_AUXRound generic map (LOC_X => RND_AUX_pos(pidx), LOC_Y => Y_basis+12, KVAL => SHA_Consts(kidxbase(LOC_Y)+i-1))
			port map (ClkS => ClkS, B_in => S(i)(255 downto 224), W_in => Wt, S_out => AuxSum);
		EFGH: SHA_HalfRound generic map (LOC_X => RND_EX_pos(pidx), LOC_Y => Y_basis, IS_ABCD => 0)
			port map (ClkS => ClkS, S_in => S(i)(255 downto 128), S_out => S(i+1)(255 downto 128), ADD1_in => S(i)(127 downto 96), ADD2_in => AuxSum);
		-- For last SHA_Snake output is not required! There will be Match function!
		ABCDG: if i /= S_end or (LOC_Y = 1 or LOC_Y = 3) generate 
			ABCD: SHA_HalfRound generic map (LOC_X => RND_AX_pos(pidx), LOC_Y => Y_basis, IS_ABCD => 1)
				port map (ClkS => ClkS, S_in => S(i)(127 downto 0), S_out => S(i+1)(127 downto 0), ADD1_in => S(i+1)(159 downto 128), ADD2_in => (others => '0'));
		end generate;
		ABCDNG: if i = S_end and not (LOC_Y = 1 or LOC_Y = 3) generate
			S(i+1)(127 downto 0) <= (others => '0');
		end generate;
	end generate;

	S_out(255 downto 224) <= S(S_end-2)(159 downto 128); -- H
	S_out(223 downto 192) <= S(S_end-1)(159 downto 128); -- G
	S_out(191 downto 160) <= S(S_end  )(159 downto 128); -- F
	S_out(159 downto 128) <= S(S_end+1)(159 downto 128); -- E
	S_out(127 downto  96) <= S(S_end-2)(31 downto 0);    -- D
	S_out( 95 downto  64) <= S(S_end-1)(31 downto 0);    -- C
	S_out( 63 downto  32) <= S(S_end  )(31 downto 0);    -- B
	S_out( 31 downto   0) <= S(S_end+1)(31 downto 0);    -- A
end PHY;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_WRound is
	generic (
		LOC_LXI			: integer := 4;
		LOC_MXI			: integer := 2;
		LOC_AUX1		: integer := 1;
		LOC_AUX2		: integer := 7;
		LOC_Y			: integer := 24; -- Y location
		W9_DELAY		: integer := 0;  -- Implement W9 delay (additional)
		W1_DELAY		: integer := 0;  -- Implement W1 delay (additional)
		WTURN			: integer := 0   -- Implement 180-degree turn
	);
	port (
		Clk			: in  std_logic;
		W_mux			: in  std_logic; -- MUX SETTING
		W_mux_out		: out std_logic;
		W_in			: in  std_logic_vector(287 downto 0);
		W_out			: out std_logic_vector(287 downto 0)
	);
end SHA_WRound;

architecture PHYLOC of SHA_WRound is
	attribute LOC : string;
	attribute BEL : string;

	constant loc_mx    : string := "SLICE_X"&itoa(LOC_MXI  )&"Y";
	constant loc_mx1   : string := "SLICE_X"&itoa(LOC_MXI+1)&"Y";
	constant loc_lx    : string := "SLICE_X"&itoa(LOC_LXI  )&"Y";
	constant loc_lx1   : string := "SLICE_X"&itoa(LOC_LXI+1)&"Y";
	constant loc_ax2   : string := "SLICE_X"&itoa(LOC_AUX2+1)&"Y";
	constant loc_ax1   : string := "SLICE_X"&itoa(LOC_AUX1+1)&"Y";
	constant loc_wh    : string := "SLICE_X"&itoa(LOC_AUX1)&"Y"&itoa(LOC_Y)&":SLICE_X"&itoa(LOC_AUX2)&"Y"&itoa(LOC_Y+39);

	signal aws9 : std_logic_vector(3 downto 0);
	constant aws1 : std_logic_vector(3 downto 0) := "1110" + W1_DELAY;

	function muxstr(s1 : string; s2 : string) return string is
	begin
		if WTURN = 1 then return s2; end if;
		return s1;
	end function muxstr;

	signal w0_in : std_logic_vector(31 downto 0);
	signal t1, t2, t3 : std_logic_vector(7 downto 0);

	signal w14, w14_ror17, w14_ror19, w14_shr10 : std_logic_vector(31 downto 0);
	signal w0, w9, w1, w1_ror7, w1_ror18, w1_shr3 : std_logic_vector(31 downto 0);
	signal w1_in : std_logic_vector(31 downto 0);

	signal w9mux, W14s_in, Wout_reg : std_logic_vector(31 downto 0);
	signal csa1s, csa2s, sum, addl6o : std_logic_vector(31 downto 0);
	signal csa1c, csa2c, carries : std_logic_vector(32 downto 0);

	signal W_nmux : std_logic;
	signal W_nnmux : std_logic;

	-- Place it in top area! Where unused carry bit is placed!
	attribute LOC of FDNMUX : label is loc_mx1 & itoa(LOC_Y + 20*WTURN + 7);
	attribute LOC of FDNNMUX : label is loc_lx1 & itoa(LOC_Y + 12*WTURN + 7);
begin
	-- Implement additional delay on roundabout (for w0 and w14 input!)
	GTURN: if WTURN = 1 generate
		signal w0_t, w14_t : std_logic_vector(31 downto 0);
	begin
		BG: for i in 0 to 31 generate
			attribute LOC of FDW14T, FDW14, FDW0T, FDW0 : label is loc_wh;
		begin
			FDW14T: FD port map (C => Clk, D => W_in(256+i), Q => w14_t(i));
			FDW14:  FD port map (C => Clk, D => w14_t(i),    Q => w14(i));
			FDW0T:  FD port map (C => Clk, D => W_in(i),     Q => w0_t(i));
			FDW0:   FD port map (C => Clk, D => w0_t(i),     Q => w0_in(i));
		end generate;
	end generate;

	-- No delay implementation - take raw arguments
	GNTURN: if WTURN /= 1 generate
		-- Take w14 as INPUT! (raw without additional registers)
		w14   <= W_in(287 downto 256);
		w0_in <= W_in( 31 downto   0);
	end generate;

	-- Not enough registers to add delay, so separate registers shall be added!
	W1DG: if W1_DELAY = 1 generate
		BG: for i in 0 to 31 generate
		begin
			FDW1D: FD port map (C => Clk, D => W_in(32+i), Q => w1_in(i));
		end generate;
	end generate;
	W1DNG: if W1_DELAY /= 1 generate
		w1_in <= W_in(63 downto 32);
	end generate;

	W9DG: if W9_DELAY = 1 generate
		aws9(3) <= '1'; aws9(2) <= '0'; aws9(1) <= W_nnmux; aws9(0) <= '1';
	end generate;
	W9DNG: if W9_DELAY /= 1 generate
		aws9(3) <= W_nnmux; aws9(2) <= W_nmux; aws9(1) <= W_nmux; aws9(0) <= '1';
	end generate;
	
	-- Generating NOT W_mux is as simple as delaying it one clock cycle!
	FDNMUX: FD port map (C => Clk, D => W_mux, Q => W_nmux);
	FDNNMUX: FD port map (C => Clk, D => W_nmux, Q => W_nnmux);

	W_mux_out <= W_nnmux;

	carries(0) <= '0'; csa2c(0) <= '0'; csa1c(0) <= '0';

	w1_ror7   <=  w1( 6 downto 0) & w1(31 downto  7);
	w1_ror18  <=  w1(17 downto 0) & w1(31 downto 18);
	w1_shr3   <=            "000" & w1(31 downto  3);
	w14_ror17 <= w14(16 downto 0) & w14(31 downto 17);
	w14_ror19 <= w14(18 downto 0) & w14(31 downto 19);
	w14_shr10 <=     "0000000000" & w14(31 downto 10);

	BG: for i in 0 to 31 generate
		constant loc_y4b : string := itoa(LOC_Y + 12*WTURN + i/4);
		constant loc_y4t : string := itoa(LOC_Y + 20*WTURN + i/4);

		attribute LOC of XOR14, XOR14FD, W0FD : label is muxstr(loc_ax1 & loc_y4t, loc_wh);
		attribute LOC of SRLW9, SRLW1, SRLW9FD, SRLW1FD : label is loc_mx & loc_y4t;
		attribute LOC of CSA1L6, CSA1L5, CSA1L6FD, CSA1L5FD : label is loc_mx1 & loc_y4t;

		attribute LOC of FDWOUT, ADDL6 : label is loc_lx & loc_y4b;
		attribute LOC of W1PASSFD : label is muxstr(loc_lx & loc_y4b, loc_wh);
		attribute LOC of CSA2L6, CSA2L5, CSA2L6FD, CSA2L5FD : label is loc_lx1 & loc_y4b;
		attribute LOC of W9MUL, W9MULFD, W0FDOUT : label is muxstr(loc_ax2 & loc_y4b, loc_wh);

		attribute BEL of ADDL6 : label is BelNames(i rem 4) & "6LUT";

		signal w9mua, w0mua : std_logic;
		signal w9a, w1a, csa1l6a, csa1l5a, csa2l6a, csa2l5a : std_logic;

		signal w14xa, w14x : std_logic;
	begin
		-- LEFT TO RIGHT (8 SLICES X):
		XOR14: LUT3 generic map (INIT => "10010110") port map (O => w14xa, I0 => w14_shr10(i), I1 => w14_ror17(i), I2 => w14_ror19(i));
		XOR14FD: FD port map (C => Clk, D => w14xa, Q => w14x);
		W0FD:    FD port map (C => Clk, D => w0_in(i), Q => w0(i));

		-- AWS9 is programmable delay, while AWS1 is hard-coded delay
		SRLW9:  SRL16 port map (CLK => Clk, D => W_in(160+i), Q => w9a, A0 => aws9(0), A1 => aws9(1), A2 => aws9(2), A3 => aws9(3));
		SRLW1:  SRL16 port map (CLK => Clk, D => w1_in(i), Q => w1a, A0 => aws1(0), A1 => aws1(1), A2 => aws1(2), A3 => aws1(3));
		SRLW9FD: FD port map (C => Clk, D => w9a, Q => w9(i));
		SRLW1FD: FD port map (C => Clk, D => w1a, Q => w1(i));

		-- FIRST CSA STAGE (WITH BUILT-IN W0 MUX)
		CSA1L6: LUT5 generic map (INIT => x"ca3535ca")
			port map (O => csa1l6a, I0 => w0(i), I1 => w1(i), I2 => W_nnmux, I3 => w14x, I4 => w9(i));
		CSA1L5: LUT5 generic map (INIT => x"ffcaca00")
			port map (O => csa1l5a, I0 => w0(i), I1 => w1(i), I2 => W_nnmux, I3 => w14x, I4 => w9(i));
		CSA1L6FD: FD port map (C => Clk, D => csa1l6a, Q => csa1s(i));
		CSA1L5FD: FD port map (C => Clk, D => csa1l5a, Q => csa1c(i+1));

		-- SECOND CSA STAGE
		CSA2L6: LUT5 generic map (INIT => x"96696996")
			port map (O => csa2l6a, I0 => w1_ror7(i), I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => csa1s(i), I4 => csa1c(i));
		CSA2L5: LUT5 generic map (INIT => x"ff969600")
			port map (O => csa2l5a, I0 => w1_ror7(i), I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => csa1s(i), I4 => csa1c(i));
		CSA2L6FD: FD port map (C => Clk, D => csa2l6a, Q => csa2s(i));
		CSA2L5FD: FD port map (C => Clk, D => csa2l5a, Q => csa2c(i+1));

		-- ADDER STAGE
		FDWOUT:  FD port map (C => Clk, D => sum(i), Q => Wout_reg(i));
		ADDL6: LUT2 generic map (INIT => "0110") port map (O => addl6o(i), I0 => csa2c(i), I1 => csa2s(i));
		W1PASSFD: FD port map (C => Clk, D => W_in(96+i), Q => W_out(64+i)); -- W(95..64) <- W(127..96)

		-- OUTPUT STAGE (NON-EXISTING FOR LAST STAGE!)
		W9MUL: LUT3 generic map (INIT => "11001010") port map (O => w9mua, I1 => Wout_reg(i), I0 => w14(i), I2 => W_nnmux);
		W9MULFD: FD port map (C => Clk, D => w9mua, Q => w9mux(i));
		W0FDOUT: FD port map (C => Clk, D => w1(i), Q => W_out(i));

		GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
			attribute LOC of C4 : label is loc_lx & loc_y4b;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csa2c(i+3 downto i),
			                     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;

	W_out( 63 downto  32) <= W_in( 95 downto  64);
	W_out(127 downto  96) <= W_in(159 downto 128);
	W_out(159 downto 128) <= w9;
	W_out(191 downto 160) <= W_in(223 downto 192);
	W_out(223 downto 192) <= W_in(255 downto 224);
	W_out(255 downto 224) <= w9mux;
	W_out(287 downto 256) <= Wout_reg; -- Put _output_
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_FullCore is
	generic (
		LOC_Y			: integer := 0;
		NONCE_START		: std_logic_vector(31 downto 0)
	);
	port (
		Clk			: in  std_logic;
		ClkS			: in  std_logic;
		ProgC			: in  std_logic;
		ProgD			: in  std_logic;
		Match			: out std_logic
	);
end SHA_FullCore;

architecture RTL of SHA_FullCore is
	signal S_mid : std_logic_vector(255 downto 0);
begin
	SP: SHA_Primary generic map (LOC_Y => LOC_Y*2+1, NONCE_START => NONCE_START) -- x"0ccccccc" or x"00000020"
		port map (Clk => Clk, ClkS => ClkS, ProgC => ProgC, ProgD => ProgD, S_out => S_mid);

--	Match <= S_mid(31);

	SS: SHA_Secondary generic map (LOC_Y => LOC_Y*2)
		port map (Clk => Clk, ClkS => ClkS, ProgC => ProgC, ProgD => ProgD, S_in => S_mid, Match => Match);
end RTL;

-- This is SHA_SECONDARY system
-- That will generate exact matches!
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHADuo_lib.All;

entity SHA_Secondary is
	generic (
		LOC_Y			: integer := 2
	);
	port (
		Clk			: in  std_logic;
		ClkS			: in  std_logic;
		ProgC			: in  std_logic;
		ProgD			: in  std_logic;
		S_in			: in  std_logic_vector(255 downto 0);
		Match			: out std_logic
	);
end SHA_Secondary;

architecture PHYLOC of SHA_Secondary is
	signal S : S_array_type;

	attribute LOC : string;
	attribute BEL : string;

	constant ybs : integer := 36+LOC_Y*40;

	constant AUX_x : P_array_type := (  0,  4,  8, 12, 18, 22, 26, 30, 34, 38, 42, 44, 48, 52, 58, 62, others => 128);
	constant EFG_x : P_array_type := (  2,  6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, others => 128);
	constant ABC_x : P_array_type := (  0,  4,  8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, others => 128);
	constant AUX_y : P_array_type := ( ybs+12,ybs+12,ybs+12,ybs+12,ybs+12,ybs+12,ybs+12,ybs+12, ybs+12,ybs+12,ybs+12,ybs, ybs,ybs,ybs,ybs, others => 128 );
	constant EFG_y : P_array_type := ( ybs,ybs,ybs,ybs,ybs,ybs,ybs,ybs,    ybs,ybs,ybs,ybs+2,    ybs+4,ybs+6,ybs+8,ybs+8, others => 128 );
	constant ABC_y : P_array_type := ( ybs,ybs,ybs,ybs,ybs,ybs,ybs,ybs, ybs+2,ybs+4,ybs+6,ybs+8, ybs+8,ybs+8,ybs+8,ybs+8, others => 128 );

	constant HBits : std_logic_vector(31 downto 0) := x"80000000";

	signal W, Wi : k_array_type;

	signal Wfeed : std_logic_vector(287 downto 0);
	signal Wfeed1, Wfeed2 : std_logic_vector(287 downto 0);
	signal m1,m2,m3,m4,m5,m6, Wft_bit : std_logic;
	signal H : std_logic_vector(31 downto 0);

	-- IF LOC_Y == 0 then added delay is 4 if LOC_Y == 2 then added delay is 0
	-- (2-LOC_Y)*2
	constant m_shf_sz : integer := 24+(2-LOC_Y)*2;
	signal m_shf : std_logic_vector(m_shf_sz downto 0); -- m shifter

	function mfd_place(iin : integer) return string is
		variable i : integer;
	begin
		i := m_shf_sz - iin;
		if LOC_Y = 0 then
			if i < 2 then return "SLICE_X67Y"&itoa(10+8*i); end if;
			i := i - 2;
			if i < 16 then return "SLICE_X"&itoa(RND_EX_pos(i+46) + 1)&"Y"&itoa(ybs-20+9); end if;
		else
			if i < 12 then return "SLICE_X67Y"&itoa(11+8*i); end if;
			i := i - 12;
			if i < 8  then return "SLICE_X"&itoa(RND_EX_pos(i*2+46) + 1)&"Y"&itoa(ybs-20+9); end if;
		end if;
		return "SLICE_X0Y"&itoa(ybs-20)&":SLICE_X1Y"&itoa(ybs-20+11); -- Place rest there
	end function mfd_place;

	signal MS0_in : std_logic_vector(255 downto 0);
	signal ClkSP, ClkSPD, ClkSND, W_mux, ClkE_n, ClkSS, ClkSSD : std_logic;

	attribute LOC of FDMS0 : label is "SLICE_X1Y"&itoa(ybs+12);
	attribute LOC of LM1,LM2,LM3,LM4,LM5,LM6,LM7 : label is "SLICE_X0Y"&itoa(ybs-20)&":SLICE_X1Y"&itoa(ybs-20+11);

	attribute LOC of LUCLKSP, LUCLKSS, FDCLKSS : label is "SLICE_X67Y"&itoa(ybs+5);
	attribute LOC of FDCLKEN : label is "SLICE_X66Y"&itoa(ybs+5);
begin
	FDMS0: FD port map (C => ProgC, D => ProgD, Q => MS0_in(0));
	BGMS0: for i in 0 to 254 generate
		attribute LOC of FMS0 : label is "SLICE_X"&itoa(((i+1)/32)*4+1)&"Y"&itoa(((i+1) rem 32)/4+ybs+12);
	begin
		FMS0: FD port map (C => ProgC, D => MS0_in(i), Q => MS0_in(i+1));
	end generate;

	-- Basically we have W(i) = S(31+32*i downto 32*i)
	-- Delays to align: i: 0=0+0=0  1=1+1=2  2=2+2=4  3=3+3=6  4=1+4=5  5=2+5=7  6=3+6=9  7=4+7=11
	BG: for i in 0 to 31 generate
		signal At, Bt, Ct, Dt, Et, Ft, Gt, Ht : std_logic;
		constant y_loc : string := itoa(ybs+12+i/4);
		attribute LOC of SRLA,SRLAF,SRLE,SRLEF : label is  "SLICE_X2Y"&y_loc;
		attribute LOC of SRLB,SRLBF,SRLF,SRLFF : label is  "SLICE_X6Y"&y_loc;
		attribute LOC of SRLC,SRLCF,SRLG,SRLGF : label is "SLICE_X10Y"&y_loc;
		attribute LOC of SRLD,SRLDF,SRLH,SRLHF : label is "SLICE_X14Y"&y_loc;
	begin
		SRLA: SRL16 port map (Q => At, CLK => ClkS, A3 => '0', A2 => '0', A1=> '0', A0 => '0', D => S_in(i));
		SRLAF: FD port map (D => At, Q => Wi(0)(i), C => ClkS);
		SRLE: SRL16 port map (Q => Et, CLK => ClkS, A3 => '0', A2 => '1', A1=> '0', A0 => '1', D => S_in(128+i));
		SRLEF: FD port map (D => Et, Q => Wi(4)(i), C => ClkS);

		SRLB: SRL16 port map (Q => Bt, CLK => ClkS, A3 => '0', A2 => '0', A1=> '1', A0 => '0', D => S_in(32+i));
		SRLBF: FD port map (D => Bt, Q => Wi(1)(i), C => ClkS);
		SRLF: SRL16 port map (Q => Ft, CLK => ClkS, A3 => '0', A2 => '1', A1=> '1', A0 => '1', D => S_in(160+i));
		SRLFF: FD port map (D => Ft, Q => Wi(5)(i), C => ClkS);

		SRLC: SRL16 port map (Q => Ct, CLK => ClkS, A3 => '0', A2 => '1', A1=> '0', A0 => '0', D => S_in(64+i));
		SRLCF: FD port map (D => Ct, Q => Wi(2)(i), C => ClkS);
		SRLG: SRL16 port map (Q => Gt, CLK => ClkS, A3 => '1', A2 => '0', A1=> '0', A0 => '1', D => S_in(192+i));
		SRLGF: FD port map (D => Gt, Q => Wi(6)(i), C => ClkS);

		SRLD: SRL16 port map (Q => Dt, CLK => ClkS, A3 => '0', A2 => '1', A1=> '1', A0 => '0', D => S_in(96+i));
		SRLDF: FD port map (D => Dt, Q => Wi(3)(i), C => ClkS);
		SRLH: SRL16 port map (Q => Ht, CLK => ClkS, A3 => '1', A2 => '0', A1=> '1', A0 => '1', D => S_in(224+i));
		SRLHF: FD port map (D => Ht, Q => Wi(7)(i), C => ClkS);
	end generate;

	-- Adders that derive W-rounds
	WA0: SHA_XFastAdd generic map (LOC_X => 0,  LOC_Y => ybs+12) port map (ClkS => ClkS, A_in => Wi(0), B_in => MS0_in(0*32+31 downto 0*32+0),S_out => W(0));
	WA1: SHA_XFastAdd generic map (LOC_X => 4,  LOC_Y => ybs+12) port map (ClkS => ClkS, A_in => Wi(1), B_in => MS0_in(1*32+31 downto 1*32+0),S_out => W(1));
	WA2: SHA_XFastAdd generic map (LOC_X => 8,  LOC_Y => ybs+12) port map (ClkS => ClkS, A_in => Wi(2), B_in => MS0_in(2*32+31 downto 2*32+0),S_out => W(2));
	WA3: SHA_XFastAdd generic map (LOC_X => 12, LOC_Y => ybs+12) port map (ClkS => ClkS, A_in => Wi(3), B_in => MS0_in(3*32+31 downto 3*32+0),S_out => W(3));
	WA4: SHA_AUXRound generic map (LOC_X => 16, LOC_Y => ybs+12, KVAL => x"00000000") 
		port map (ClkS => ClkS, W_in => Wi(4), B_in => MS0_in(4*32+31 downto 4*32+0), S_out => W(4));
	WA5: SHA_AUXRound generic map (LOC_X => 20, LOC_Y => ybs+12, KVAL => x"00000000") 
		port map (ClkS => ClkS, W_in => Wi(5), B_in => MS0_in(5*32+31 downto 5*32+0), S_out => W(5));
	WA6: SHA_AUXRound generic map (LOC_X => 24, LOC_Y => ybs+12, KVAL => x"00000000") 
		port map (ClkS => ClkS, W_in => Wi(6), B_in => MS0_in(6*32+31 downto 6*32+0), S_out => W(6));
	WA7: SHA_AUXRound generic map (LOC_X => 28, LOC_Y => ybs+12, KVAL => x"00000000") 
		port map (ClkS => ClkS, W_in => Wi(7), B_in => MS0_in(7*32+31 downto 7*32+0), S_out => W(7));

	-- Setup constants inputs!
	S(0) <= HGFE_const & DCBA_const;

	-- Prepare for feed-in!
	W(8)  <= x"80000000"; W(9)  <= x"00000000"; W(10) <= x"00000000"; W(11) <= x"00000000";
	W(12) <= x"00000000"; W(13) <= x"00000000"; W(14) <= x"00000000"; W(15) <= x"00000100";

	-- Continuation with simpler rounds (only AUX + rounds themselves)
	RNDBT: for i in 0 to 15 generate
		signal AuxSum : std_logic_vector(31 downto 0);
	begin
		AUX: SHA_AUXRound generic map (LOC_X => AUX_x(i), LOC_Y => AUX_y(i), KVAL => SHA_Consts(i))
			port map (ClkS => ClkS, B_in => S(i)(255 downto 224), W_in => W(i), S_out => AuxSum);

		EFGH: SHA_HalfRound generic map (LOC_X => EFG_x(i), LOC_Y => EFG_y(i), IS_ABCD => 0)
			port map (ClkS => ClkS, S_in => S(i)(255 downto 128), S_out => S(i+1)(255 downto 128),ADD1_in => S(i)(127 downto 96), ADD2_in => AuxSum);

		ABCD: SHA_HalfRound generic map (LOC_X => ABC_x(i), LOC_Y => ABC_y(i), IS_ABCD => 1)
			port map (ClkS => ClkS, S_in => S(i)(127 downto 0), S_out => S(i+1)(127 downto 0), ADD1_in => S(i+1)(159 downto 128), ADD2_in => (others => '0'));
	end generate;

	-- w0/w1 w1/w2 w3/w4 w5/w6 w7/w8 w9/w10 w11/w12 w13,w14
	-- Place two register sets for W(0..7), muxer and shift registers line

	-- This register is specific to LUT set and provides inverted input
	-- To reduce delay from ClkE_n front to Clk front

	ClkSP <= ClkS after 100 ps;
	LUCLKSP: LUT1 generic map (INIT => "10") port map (O => ClkSPD, I0 => ClkSP);
	LUCLKSS: LUT1 generic map (INIT => "10") port map (O => ClkSS, I0 => ClkSPD);
	FDCLKSS: FD port map (C => Clk, D => ClkSS, Q => ClkSSD);
	FDCLKEN: FD port map (C => Clk, D => ClkSSD, Q => ClkE_n);
	FDWMUX:  FD generic map (INIT => '0') port map (C => Clk, D => ClkE_n, Q => W_mux);

	RSET: for i in 0 to 31 generate
		attribute LOC of FSW3W4, FSW7W8, SRW7W8, SRW3W4 : label is "SLICE_X60Y"&itoa((i/4)+ybs); -- Place it _closer_ to destination sampling
		attribute LOC of FMW3W4, FMW7W8, LMW7W8, LMW3W4 : label is "SLICE_X61Y"&itoa((i/4)+ybs);
		attribute LOC of SRW1W2, FSW1W2, SRW5W6, FSW5W6 : label is "SLICE_X56Y"&itoa((i/4)+ybs); -- Hits to next element
		attribute LOC of LMW1W2, FMW1W2, LMW5W6, FMW5W6 : label is "SLICE_X57Y"&itoa((i/4)+ybs);
		attribute LOC of FSW0W1, SRW0W1 : label is "SLICE_X"&itoa(36+(i/16)*4)&"Y"&itoa( (i/4) rem 4 + ybs);
		attribute LOC of LMW0W1, FMW0W1 : label is "SLICE_X45Y"&itoa( ybs + i/8 );
		attribute LOC of FDO0, FDO1, FDO2, FDO3, FDO4, FDO5, FDO6, FDO7 : label is "SLICE_X32Y"&itoa(ybs)&":SLICE_X55Y"&itoa(ybs+19);
		attribute LOC of W0FDA : label is "SLICE_X63Y"&itoa(ybs + i/4);
		attribute LOC of FDW0, FDW1 : label is "SLICE_X19Y"&itoa(ybs + 12 + i/4);
		attribute LOC of FDW2, FDW3 : label is "SLICE_X23Y"&itoa(ybs + 12 + i/4);
		attribute LOC of FDW4, FDW5 : label is "SLICE_X27Y"&itoa(ybs + 12 + i/4);
		attribute LOC of FDW6, FDW7 : label is "SLICE_X31Y"&itoa(ybs + 12 + i/4);

		signal w0fdp : std_logic;
	begin
		FDW0: FD port map (C => ClkS, D => W(0)(i),  Q => W(16)(i));
		FDW1: FD port map (C => ClkS, D => W(1)(i),  Q => W(17)(i));
		FDW2: FD port map (C => ClkS, D => W(2)(i),  Q => W(18)(i));
		FDW3: FD port map (C => ClkS, D => W(3)(i),  Q => W(19)(i));
		FDW4: FD port map (C => ClkS, D => W(4)(i),  Q => W(20)(i));
		FDW5: FD port map (C => ClkS, D => W(5)(i),  Q => W(21)(i));
		FDW6: FD port map (C => ClkS, D => W(6)(i),  Q => W(22)(i));
		FDW7: FD port map (C => ClkS, D => W(7)(i),  Q => W(23)(i));

		FDO0: FD port map (C => ClkS, D => W(16)(i), Q => W(24)(i));
		FDO1: FD port map (C => ClkS, D => W(17)(i), Q => W(25)(i));
		FDO2: FD port map (C => ClkS, D => W(18)(i), Q => W(26)(i));
		FDO3: FD port map (C => ClkS, D => W(19)(i), Q => W(27)(i));
		FDO4: FD port map (C => ClkS, D => W(20)(i), Q => W(28)(i));
		FDO5: FD port map (C => ClkS, D => W(21)(i), Q => W(29)(i));
		FDO6: FD port map (C => ClkS, D => W(22)(i), Q => W(30)(i));
		FDO7: FD port map (C => ClkS, D => W(23)(i), Q => W(31)(i));

		LMW0W1: LUT3 generic map (INIT => "11001010") port map (O => W(32)(i), I2 => ClkE_n, I0 => W(24)(i), I1 => W(25)(i));
		LMW1W2: LUT3 generic map (INIT => "11001010") port map (O => W(33)(i), I2 => ClkE_n, I0 => W(25)(i), I1 => W(26)(i));
		LMW3W4: LUT3 generic map (INIT => "11001010") port map (O => W(34)(i), I2 => ClkE_n, I0 => W(27)(i), I1 => W(28)(i));
		LMW5W6: LUT3 generic map (INIT => "11001010") port map (O => W(35)(i), I2 => ClkE_n, I0 => W(29)(i), I1 => W(30)(i));
		LMW7W8: LUT3 generic map (INIT => "11001010") port map (O => W(36)(i), I2 => ClkE_n, I0 => W(31)(i), I1 => HBits(i));

		FMW0W1: FD port map (C => Clk, D => W(32)(i), Q => W(37)(i));
		FMW1W2: FD port map (C => Clk, D => W(33)(i), Q => W(38)(i));
		FMW3W4: FD port map (C => Clk, D => W(34)(i), Q => W(39)(i));
		FMW5W6: FD port map (C => Clk, D => W(35)(i), Q => W(40)(i));
		FMW7W8: FD port map (C => Clk, D => W(36)(i), Q => W(41)(i));

		SRW0W1: SRLC32E port map (CLK => Clk, D => W(37)(i), Q => W(42)(i), CE => '1', A => "10100", Q31 => open);
		SRW1W2: SRL16 port map (CLK => Clk, D => W(38)(i), Q => W(43)(i), A3 => '0', A2 => '1', A1 => '0', A0 => '1'); -- delay 5
		SRW3W4: SRL16 port map (CLK => Clk, D => W(39)(i), Q => W(44)(i), A3 => '0', A2 => '1', A1 => '0', A0 => '1'); -- delay 5
		SRW5W6: SRL16 port map (CLK => Clk, D => W(40)(i), Q => W(45)(i), A3 => '0', A2 => '1', A1 => '0', A0 => '0'); -- delay 4
		SRW7W8: SRL16 port map (CLK => Clk, D => W(41)(i), Q => W(46)(i), A3 => '0', A2 => '1', A1 => '0', A0 => '0'); -- delay 4

		FSW0W1: FD port map (C => Clk, D => W(42)(i), Q => w0fdp);
		FSW1W2: FD port map (C => Clk, D => W(43)(i), Q => W(48)(i));
		FSW3W4: FD port map (C => Clk, D => W(44)(i), Q => W(49)(i));
		FSW5W6: FD port map (C => Clk, D => W(45)(i), Q => W(50)(i));
		FSW7W8: FD port map (C => Clk, D => W(46)(i), Q => W(51)(i));

		W0FDA: FD port map (C => Clk, D => w0fdp, Q => W(47)(i));
	end generate;

	W(52) <= W(47); W(53) <= W(48); W(54) <= W(49); W(55) <= W(50); W(56) <= W(51);
--	W(52) <= W(47) when W(47) = x"a5400c65" or W(47) = x"d9562f8b" else x"00000000";
--	W(53) <= W(48) when W(48) = x"9e307f5f" or W(48) = x"d9562f8b" else x"00000000";
--	W(54) <= W(49) when W(49) = x"45c81d7c" or W(49) = x"d06f87d0" else x"00000000";
--	W(55) <= W(50) when W(50) = x"c48a3924" or W(50) = x"5879574d" else x"00000000";
--	W(56) <= W(51) when W(51) = x"96e4ff73" or W(51) = x"80000000" else x"00000000";

	-- Two registers to produce highmost bit (this is _autoplaced_)
--	WFTB: FD port map (C => Clk, D => ClkE, Q => Wft_bit);

	Wfeed <= x"00000" & "000" & ClkE_n & x"00_00000000_00000000_00000000" & W(56) & W(55) & W(54) & W(53) & W(52);

	S(17) <= S(16);
-- Pass only correct values in there! To make hunting for correct W inputs easier!
--	S(17)(0*32+31 downto 0*32) <= S(16)(0*32+31 downto 0*32) when S(16)(0*32+31 downto 0*32) = x"7afb277d" else x"00000000";
--	S(17)(1*32+31 downto 1*32) <= S(16)(1*32+31 downto 1*32) when S(16)(1*32+31 downto 1*32) = x"1639a4dc" else x"00000000";
--	S(17)(2*32+31 downto 2*32) <= S(16)(2*32+31 downto 2*32) when S(16)(2*32+31 downto 2*32) = x"10d183a3" else x"00000000";
--	S(17)(3*32+31 downto 3*32) <= S(16)(3*32+31 downto 3*32) when S(16)(3*32+31 downto 3*32) = x"652fe00d" else x"00000000";
--	S(17)(4*32+31 downto 4*32) <= S(16)(4*32+31 downto 4*32) when S(16)(4*32+31 downto 4*32) = x"b5af8d6e" else x"00000000";
--	S(17)(5*32+31 downto 5*32) <= S(16)(5*32+31 downto 5*32) when S(16)(5*32+31 downto 5*32) = x"b303450d" else x"00000000";
--	S(17)(6*32+31 downto 6*32) <= S(16)(6*32+31 downto 6*32) when S(16)(6*32+31 downto 6*32) = x"19ab8acf" else x"00000000";
--	S(17)(7*32+31 downto 7*32) <= S(16)(7*32+31 downto 7*32) when S(16)(7*32+31 downto 7*32) = x"ef80d66a" else x"00000000";

	SNK: SHA_Snake generic map (LOC_Y => LOC_Y) port map (Clk => Clk, ClkS => ClkS, W_mux => W_mux, W_in => Wfeed, S_in => S(17), S_out => S(18));

	-- Place comparision operation for S(18)(159 downto 128) - two layers of LUT6 to compare!
	H <= S(18)(159 downto 128);

	LM1: LUT6 generic map (INIT => x"0000008000000000") port map (O => m1, I5 => H(5), I4 => H(4), I3 => H(3), I2 => H(2), I1 => H(1), I0 => H(0));
	LM2: LUT6 generic map (INIT => x"0000000000000800") port map (O => m2, I5 => H(11), I4 => H(10), I3 => H(9), I2 => H(8),  I1 => H(7),  I0 => H(6));
	LM3: LUT6 generic map (INIT => x"0008000000000000") port map (O => m3, I5 => H(17), I4 => H(16), I3 => H(15), I2 => H(14), I1 => H(13), I0 => H(12));
	LM4: LUT6 generic map (INIT => x"0000000000000080") port map (O => m4, I5 => H(23), I4 => H(22), I3 => H(21), I2 => H(20), I1 => H(19), I0 => H(18));
	LM5: LUT6 generic map (INIT => x"0000001000000000") port map (O => m5, I5 => H(29), I4 => H(28), I3 => H(27), I2 => H(26), I1 => H(25), I0 => H(24));
	LM6: LUT2 generic map (INIT => "0100") port map (O => m6, I1 => H(31), I0 => H(30));
	LM7: LUT6 generic map (INIT => x"8000000000000000") port map (O => m_shf(0), I5 => m6, I4 => m5, I3 => m4, I2 => m3, I1 => m2, I0 => m1);
	
	-- Place all of these registers!
	MBG: for i in 0 to m_shf'left-1 generate
		attribute LOC of MFD : label is mfd_place(i+1);
	begin
		MFD: FD port map (C => ClkS, D => m_shf(i), Q => m_shf(i+1));
	end generate;
	Match <= m_shf(m_shf'left);
end PHYLOC;

