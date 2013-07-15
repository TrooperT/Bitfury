--
-- Copyright 2012 www.bitfury.org
--
-- Single-phase design of sha_top unit
--

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
	use WORK.SHASerialLOC_lib.All;

-- Kernel positioning
entity SHA_DummyKernel is
	generic (
		IDX			: integer := 0;
		LOC_X			: integer := 3;
		LOC_Y			: integer := 24
	);
	port (
		Clk			: in  std_logic;
		Imatch_in		: in  std_logic;
		Imatch_out		: out std_logic;
		K_in			: in  std_logic_vector(31 downto 0);
		K_out			: out std_logic_vector(31 downto 0);
		W_in			: in  std_logic_vector(31 downto 0);
		W_out			: out std_logic_vector(31 downto 0);
		Wl_out			: out std_logic_vector(31 downto 0);
		C_in			: in  std_logic_vector(28 downto 0);
		C_out			: out std_logic_vector(28 downto 0)
	);
end SHA_DummyKernel;

architecture RTL of SHA_DummyKernel is
	type xposes_type is array(0 to 4) of integer;
	constant xposes_begin : xposes_type := ( 9, 39, 69, 99, 5 );
	constant xposes_end : xposes_type := ( 37, 67, 97, 126, 33 );
	attribute LOC : string;
	constant loc_st : string := "SLICE_X"&itoa(xposes_begin(LOC_X))&"Y"&itoa(LOC_Y+1)&":SLICE_X"&itoa(xposes_end(LOC_X))&"Y"&itoa(LOC_Y+6);
	signal W0 : std_logic_vector(31 downto 0);
begin
	Imatch_out <= '0';
	
	G1: for i in 0 to 31 generate
		attribute LOC of GFDW, GFDK : label is loc_st;
	begin
		GFDW: FD port map (C => Clk, D => W_in(i), Q => W0(i));
		GFDK: FD port map (C => Clk, D => K_in(i), Q => K_out(i));
	end generate;

	W_out <= W0; Wl_out <= W0;

	G2: for i in 0 to 28 generate
		attribute LOC of GFDC : label is loc_st;
	begin
		GFDC: FD port map (C => Clk, D => C_in(i), Q => C_out(i));
	end generate;
end RTL;

-- LOC_X = 4, 4
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
	use WORK.SHASerialLOC_lib.All;

entity clkrounds is
	port (
		Clk			: in  std_logic;
		ClkTX			: in  std_logic;
		Prog_l			: in  std_logic_vector(3 downto 0);
		Prog_r			: in  std_logic_vector(3 downto 0);
		Match_l			: out std_logic;
		Match_r			: out std_logic;
		ScanDone_out		: out std_logic
	);
end clkrounds;

architecture RTL of clkrounds is
	component SHA_DummyKernel
		generic (
			IDX		: integer := 0;
			LOC_X		: integer := 3;
			LOC_Y		: integer := 24
		);
		port (
			Clk		: in  std_logic;
			Imatch_in	: in  std_logic;
			Imatch_out	: out std_logic;
			K_in		: in  std_logic_vector(31 downto 0);
			K_out		: out std_logic_vector(31 downto 0);
			W_in		: in  std_logic_vector(31 downto 0);
			W_out		: out std_logic_vector(31 downto 0);
			Wl_out		: out std_logic_vector(31 downto 0);
			C_in		: in  std_logic_vector(28 downto 0);
			C_out		: out std_logic_vector(28 downto 0)
		);
	end component;

	type C_ypos_type is array (0 to 22) of std_logic_vector(28 downto 0);
	type WK_ypos_type is array (0 to 22) of std_logic_vector(31 downto 0);
	type IM_ypos_type is array (0 to 22) of std_logic;
	type IM_all_type is array (0 to 3) of IM_ypos_type;
	type C_all_type is array (0 to 3) of C_ypos_type;
	type WK_all_type is array (0 to 3) of WK_ypos_type;
	type int_ypos_type is array (0 to 22) of integer;
	type int_all_type is array (0 to 3) of int_ypos_type;

	-- Rounds positions!
	constant xpos : int_all_type := (
		(4, 4, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 4, 4),
		(1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1),
		(2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2, 2,  2, 2, 2),
		(3, 3, 3, 3,  3, 3, 3, 3,  3, 3, 3, 3,  3, 3, 3, 3,  3, 3, 3, 3,  3, 3, 3)  );

	constant ypos : int_all_type := (
		(  4, 12, 20, 28,  36, 44, 52, 60,  68, 76, 84, 92, 100,108,116,124, 132,140,148,156, 164,172,180),
		(  0, 16, 24, 32,  40, 48, 56, 64,  72, 80, 88, 96, 104,112,120,128, 136,144,152,  0,   0,  0,  0),
		(  0, 16, 24, 32,  40, 48, 56, 64,  72, 80, 88, 96, 104,112,120,128, 136,144,152,160, 168,  0,  0),
		(  4, 12, 20, 28,  36, 44, 52, 60,  68, 76, 84, 92, 100,108,116,124, 132,140,148,156, 164,172,180) );

	constant idxpos : int_all_type := (
		( 64, 66, 68, 70,  72, 74, 76, 78,  80, 82, 84, 86,  88, 90, 92, 94,  96, 98,100,102, 104,106,108),
		(  0, 67, 69, 71,  73, 75, 77, 79,  81, 83, 85, 87,  89, 91, 93, 95,  97, 99,101,  0,   0,  0,  0),
		(  0,  3,  5,  7,   9, 11, 13, 15,  17, 19, 21, 23,  25, 27, 29, 31,  33, 35, 37, 39,  41,  0,  0),
		(  0,  2,  4,  6,   8, 10, 12, 14,  16, 18, 20, 22,  24, 26, 28, 30,  32, 34, 36, 38,  40, 42, 44) );

	-- Activate 8 rounds only, they all should respond correctly!
--	constant dpos : int_all_type := (
--		(0, 0, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 0),
--		(0, 0, 1, 1,  1, 1, 1, 1,  1, 1, 1, 2,  1, 1, 1, 1,  1, 1, 1, 0,  0, 0, 0),
--		(0, 0, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 0, 0),
--		(0, 0, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 0)  );
	constant dpos : int_all_type := (
		(0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0),
		(0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 2,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0),
		(0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0),
		(0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0)  );
--	constant dpos : int_all_type := (
--		(0, 0, 0, 1,  1, 1, 1, 1,  1, 1, 0, 1,  0, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0),
--		(0, 0, 1, 1,  1, 1, 1, 1,  1, 1, 0, 2,  0, 1, 1, 1,  1, 1, 1, 0,  0, 0, 0),
--		(0, 0, 1, 1,  1, 1, 1, 1,  1, 1, 0, 1,  0, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0),
--		(0, 0, 0, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  0, 0, 0)  );

	signal C_in, C_out : C_all_type;
	signal K_in, K_out, W_in, W_out, Wl_in, Wl_out : WK_all_type;
	signal Im_in, Im_out : IM_all_type;
	signal Prog_lk, Prog_lw, Prog_m0, Prog_m1, Prog_m : std_logic_vector(3 downto 0);
	signal ScanDone : std_logic;
begin
	LKCF0: FD port map (C => Clk, D => Prog_l(0), Q => Prog_lk(0));
	LKCF1: FD port map (C => Clk, D => Prog_l(1), Q => Prog_lk(1));
	LKCF2: FD port map (C => Clk, D => Prog_l(2), Q => Prog_lk(2));
	LKCF3: FD port map (C => Clk, D => Prog_l(3), Q => Prog_lk(3));

	LWCF0: FD port map (C => Clk, D => Prog_l(0), Q => Prog_lw(0));
	LWCF1: FD port map (C => Clk, D => Prog_l(1), Q => Prog_lw(1));
	LWCF2: FD port map (C => Clk, D => Prog_l(2), Q => Prog_lw(2));
	LWCF3: FD port map (C => Clk, D => Prog_l(3), Q => Prog_lw(3));

	LKC: SHA_KControl	 port map (Clk => Clk, Prog_in => Prog_lk, K_out => K_in(0)(0), C_out => C_in(0)(0)(28 downto 18));
	LWC: SHA_WControl_Corner generic map (NONCE_ST => (others => '0'))
				 port map (Clk => Clk, Prog_in => Prog_lw, W_out => W_in(0)(0), C_out => C_in(0)(0)(17 downto 0));

	MFD00: FD port map (C => Clk, D => Prog_r(0), Q => Prog_m0(0));
	MFD01: FD port map (C => Clk, D => Prog_r(1), Q => Prog_m0(1));
	MFD02: FD port map (C => Clk, D => Prog_r(2), Q => Prog_m0(2));
	MFD03: FD port map (C => Clk, D => Prog_r(3), Q => Prog_m0(3));
	MFD10: FD port map (C => Clk, D => Prog_m0(0), Q => Prog_m1(0));
	MFD11: FD port map (C => Clk, D => Prog_m0(1), Q => Prog_m1(1));
	MFD12: FD port map (C => Clk, D => Prog_m0(2), Q => Prog_m1(2));
	MFD13: FD port map (C => Clk, D => Prog_m0(3), Q => Prog_m1(3));
	MFD20: FD port map (C => Clk, D => Prog_m1(0), Q => Prog_m(0));
	MFD21: FD port map (C => Clk, D => Prog_m1(1), Q => Prog_m(1));
	MFD22: FD port map (C => Clk, D => Prog_m1(2), Q => Prog_m(2));
	MFD23: FD port map (C => Clk, D => Prog_m1(3), Q => Prog_m(3));

	MWC: SHA_WControl generic map (NONCE_ST => (others => '0'))
		port map (Clk => Clk, Prog_in => Prog_m, W_out => W_in(2)(1), C_out => C_in(2)(1)(17 downto 0), ScanDone_out => ScanDone);
	MSCFD: FD port map (C => Clk, D => ScanDone, Q => ScanDone_out);

	-- Place some registers there!
	MCG: for i in 2 to 17 generate
		MCFD: FD port map (C => Clk, D => C_in(2)(1)(i), Q => C_in(1)(1)(i));
	end generate;
	K_in(1)(1) <= K_out(0)(2);
	W_in(1)(1) <= Wl_out(2)(1);

	C_in(1)(1)(1 downto 0) <= C_out(2)(1)(1 downto 0);
	C_in(1)(1)(22 downto 18) <= C_out(0)(2)(22 downto 18);
	C_in(1)(1)(28 downto 23) <= "111111";

	K_in(2)(1) <= K_out(3)(2);
	C_in(2)(1)(22 downto 18) <= C_out(3)(2)(22 downto 18);
	C_in(2)(1)(28 downto 23) <= "111111";

	RKC: SHA_KControl port map (Clk => Clk, Prog_in => Prog_r, K_out => K_in(3)(0), C_out => C_in(3)(0)(28 downto 18));
	RWC: SHA_WControl_Corner generic map (NONCE_ST => (others => '0'))
		port map (Clk => Clk, Prog_in => Prog_r, W_out => W_in(3)(0), C_out => C_in(3)(0)(17 downto 0));

	-- Imatch connections
	Im_in(0) <= Im_out(1); Im_in(1) <= (others => '0'); Im_in(2) <= (others => '0'); Im_in(3) <= Im_out(2);

	-- Place all kernels here
	GK: for i in 0 to 91 generate
		constant xp : integer := i / 23;
		constant yp : integer := i - xp * 23;
	begin
		GK: if ypos(xp)(yp) /= 0 and dpos(xp)(yp) = 0 generate
			KR: SHA_Kernel generic map (IDX => idxpos(xp)(yp), LOC_X => xpos(xp)(yp), LOC_Y => ypos(xp)(yp))
				port map (Clk => Clk, Imatch_in => Im_in(xp)(yp), Imatch_out => Im_out(xp)(yp),
				K_in => K_in(xp)(yp), K_out => K_out(xp)(yp),
				W_in => W_in(xp)(yp), W_out => W_out(xp)(yp), Wl_out => Wl_out(xp)(yp),
				C_in => C_in(xp)(yp), C_out => C_out(xp)(yp) );
		end generate;
		GD: if ypos(xp)(yp) /= 0 and dpos(xp)(yp) /= 0 generate
			KR: SHA_DummyKernel generic map (IDX => idxpos(xp)(yp), LOC_X => xpos(xp)(yp), LOC_Y => ypos(xp)(yp))
				port map (Clk => Clk, Imatch_in => Im_in(xp)(yp), Imatch_out => Im_out(xp)(yp),
				K_in => K_in(xp)(yp), K_out => K_out(xp)(yp),
				W_in => W_in(xp)(yp), W_out => W_out(xp)(yp), Wl_out => Wl_out(xp)(yp),
				C_in => C_in(xp)(yp), C_out => C_out(xp)(yp) );
		end generate;

		GN: if ypos(xp)(yp) = 0 generate
			K_out(xp)(yp) <= (others => '0');
			W_out(xp)(yp) <= (others => '0');
			Wl_out(xp)(yp) <= (others => '0');
			C_out(xp)(yp) <= (others => '0');
			Im_out(xp)(yp) <= '0';
		end generate;

		-- Connect to previous round directly!
		GX0: if (xp = 0 or xp = 3) and yp > 0 generate
			K_in(xp)(yp) <= K_out(xp)(yp-1);
			W_in(xp)(yp) <= W_out(xp)(yp-1);
			C_in(xp)(yp) <= C_out(xp)(yp-1);
		end generate;

		GML: if xp = 1 and yp > 1 generate
			K_in(xp)(yp) <= K_out(xp)(yp-1);
			W_in(xp)(yp) <= Wl_out(2)(yp);
			C_in(xp)(yp)(22 downto 2) <= C_out(xp)(yp-1)(22 downto 2);
			C_in(xp)(yp)(1 downto 0) <= C_out(2)(yp)(1 downto 0);
			C_in(xp)(yp)(28 downto 23) <= "111111";
		end generate;

		GMR: if xp = 2 and yp > 1 generate
			K_in(xp)(yp) <= K_out(xp)(yp-1);
			W_in(xp)(yp) <= Wl_out(xp)(yp-1);
			C_in(xp)(yp)(22 downto 0) <= C_out(xp)(yp-1)(22 downto 0);
			C_in(xp)(yp)(28 downto 23) <= "111111";
		end generate;
	end generate;

	-- Left and right column finalizers
	LFIN: SHA_TinyMatchFinalizer generic map (HIGH => '1', NONCE_ST => (others => '0'))
		port map (Clk => Clk, ClkTX => ClkTX, Match_rst => C_out(0)(22)(18), Match_in => C_out(0)(22)(28 downto 23),
			Match_enable => C_out(0)(22)(22), Match_out => Match_l );

	RFIN: SHA_TinyMatchFinalizer generic map (HIGH => '0', NONCE_ST => (others => '0'))
		port map (Clk => Clk, ClkTX => ClkTX, Match_rst => C_out(3)(22)(18), Match_in => C_out(3)(22)(28 downto 23),
			Match_enable => C_out(3)(22)(22), Match_out => Match_r );
end RTL;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialCtrl_lib.All;
	use WORK.SHASerialLOC_lib.All;

entity sha_top is
	port (
		GClk_in			: in  std_logic;
		SCK_in			: in  std_logic;
		MISO_out		: out std_logic;
		MISO_EN_out		: out std_logic;
		MOSI_in			: in  std_logic;
		IO0_in			: in  std_logic;
		IO2_in			: in  std_logic;
		IO3_in			: in  std_logic;
		OA10			: out std_logic;
		OA11			: out std_logic;
		OA12			: out std_logic;
		OA13			: out std_logic;
		OA14			: out std_logic;
		OA15			: out std_logic;
		OA16			: out std_logic;
		OA17			: out std_logic;
		OA18			: out std_logic;
		OA2			: out std_logic;
		OA20			: out std_logic;
		OA21			: out std_logic;
		OA3			: out std_logic;
		OA4			: out std_logic;
		OA5			: out std_logic;
		OA6			: out std_logic;
		OA7			: out std_logic;
		OA8			: out std_logic;
		OA9			: out std_logic;
		OAA10			: out std_logic;
		OAA14			: out std_logic;
		OAA16			: out std_logic;
		OAA18			: out std_logic;
		OAA2			: out std_logic;
		OAA21			: out std_logic;
		OAA4			: out std_logic;
		OAA6			: out std_logic;
		OAB10			: out std_logic;
		OAB14			: out std_logic;
		OAB15			: out std_logic;
		OAB16			: out std_logic;
		OAB17			: out std_logic;
		OAB18			: out std_logic;
		OAB19			: out std_logic;
		OAB2			: out std_logic;
		OAB20			: out std_logic;
		OAB21			: out std_logic;
		OAB3			: out std_logic;
		OAB4			: out std_logic;
		OAB5			: out std_logic;
		OAB6			: out std_logic;
		OAB7			: out std_logic;
		OAB8			: out std_logic;
		OB1			: out std_logic;
		OB10			: out std_logic;
		OB12			: out std_logic;
		OB14			: out std_logic;
		OB16			: out std_logic;
		OB18			: out std_logic;
		OB2			: out std_logic;
		OB20			: out std_logic;
		OB21			: out std_logic;
		OB22			: out std_logic;
		OB3			: out std_logic;
		OB6			: out std_logic;
		OB8			: out std_logic;
		OC1			: out std_logic;
		OC10			: out std_logic;
		OC11			: out std_logic;
		OC12			: out std_logic;
		OC13			: out std_logic;
		OC14			: out std_logic;
		OC15			: out std_logic;
		OC16			: out std_logic;
		OC17			: out std_logic;
		OC19			: out std_logic;
		OC20			: out std_logic;
		OC22			: out std_logic;
		OC3			: out std_logic;
		OC4			: out std_logic;
		OC5			: out std_logic;
		OC6			: out std_logic;
		OC7			: out std_logic;
		OC9			: out std_logic;
		OD1			: out std_logic;
		OD10			: out std_logic;
		OD11			: out std_logic;
		OD12			: out std_logic;
		OD13			: out std_logic;
		OD14			: out std_logic;
		OD15			: out std_logic;
		OD17			: out std_logic;
		OD19			: out std_logic;
		OD2			: out std_logic;
		OD20			: out std_logic;
		OD21			: out std_logic;
		OD22			: out std_logic;
		OD3			: out std_logic;
		OD5			: out std_logic;
		OD6			: out std_logic;
		OD7			: out std_logic;
		OD8			: out std_logic;
		OD9			: out std_logic;
		OE1			: out std_logic;
		OE10			: out std_logic;
		OE12			: out std_logic;
		OE14			: out std_logic;
		OE16			: out std_logic;
		OE20			: out std_logic;
		OE22			: out std_logic;
		OE3			: out std_logic;
		OE4			: out std_logic;
		OE5			: out std_logic;
		OE6			: out std_logic;
		OE8			: out std_logic;
		OF1			: out std_logic;
		OF10			: out std_logic;
		OF12			: out std_logic;
		OF13			: out std_logic;
		OF14			: out std_logic;
		OF15			: out std_logic;
		OF16			: out std_logic;
		OF17			: out std_logic;
		OF18			: out std_logic;
		OF19			: out std_logic;
		OF2			: out std_logic;
		OF20			: out std_logic;
		OF21			: out std_logic;
		OF22			: out std_logic;
		OF3			: out std_logic;
		OF5			: out std_logic;
		OF7			: out std_logic;
		OF8			: out std_logic;
		OF9			: out std_logic;
		OG1			: out std_logic;
		OG11			: out std_logic;
		OG13			: out std_logic;
		OG16			: out std_logic;
		OG17			: out std_logic;
		OG19			: out std_logic;
		OG20			: out std_logic;
		OG22			: out std_logic;
		OG3			: out std_logic;
		OG4			: out std_logic;
		OG6			: out std_logic;
		OG7			: out std_logic;
		OG8			: out std_logic;
		OG9			: out std_logic;
		OH1			: out std_logic;
		OH10			: out std_logic;
		OH11			: out std_logic;
		OH12			: out std_logic;
		OH13			: out std_logic;
		OH14			: out std_logic;
		OH16			: out std_logic;
		OH17			: out std_logic;
		OH18			: out std_logic;
		OH19			: out std_logic;
		OH2			: out std_logic;
		OH20			: out std_logic;
		OH21			: out std_logic;
		OH22			: out std_logic;
		OH3			: out std_logic;
		OH4			: out std_logic;
		OH5			: out std_logic;
		OH6			: out std_logic;
		OH8			: out std_logic;
		OJ1			: out std_logic;
		OJ16			: out std_logic;
		OJ17			: out std_logic;
		OJ19			: out std_logic;
		OJ20			: out std_logic;
		OJ22			: out std_logic;
		OJ3			: out std_logic;
		OJ4			: out std_logic;
		OJ6			: out std_logic;
		OJ7			: out std_logic;
		OK1			: out std_logic;
		OK16			: out std_logic;
		OK17			: out std_logic;
		OK18			: out std_logic;
		OK19			: out std_logic;
		OK2			: out std_logic;
		OK20			: out std_logic;
		OK21			: out std_logic;
		OK22			: out std_logic;
		OK3			: out std_logic;
		OK4			: out std_logic;
		OK5			: out std_logic;
		OK6			: out std_logic;
		OK7			: out std_logic;
		OK8			: out std_logic;
		OL1			: out std_logic;
		OL15			: out std_logic;
		OL17			: out std_logic;
		OL19			: out std_logic;
		OL20			: out std_logic;
		OL22			: out std_logic;
		OL3			: out std_logic;
		OL4			: out std_logic;
		OL6			: out std_logic;
		OM1			: out std_logic;
		OM16			: out std_logic;
		OM17			: out std_logic;
		OM18			: out std_logic;
		OM19			: out std_logic;
		OM2			: out std_logic;
		OM20			: out std_logic;
		OM21			: out std_logic;
		OM22			: out std_logic;
		OM3			: out std_logic;
		OM4			: out std_logic;
		OM5			: out std_logic;
		OM6			: out std_logic;
		OM7			: out std_logic;
		OM8			: out std_logic;
		ON1			: out std_logic;
		ON16			: out std_logic;
		ON19			: out std_logic;
		ON20			: out std_logic;
		ON22			: out std_logic;
		ON3			: out std_logic;
		ON4			: out std_logic;
		ON6			: out std_logic;
		ON7			: out std_logic;
		OP1			: out std_logic;
		OP17			: out std_logic;
		OP18			: out std_logic;
		OP19			: out std_logic;
		OP2			: out std_logic;
		OP20			: out std_logic;
		OP21			: out std_logic;
		OP22			: out std_logic;
		OP3			: out std_logic;
		OP4			: out std_logic;
		OP5			: out std_logic;
		OP6			: out std_logic;
		OP7			: out std_logic;
		OP8			: out std_logic;
		OR1			: out std_logic;
		OR11			: out std_logic;
		OR13			: out std_logic;
		OR15			: out std_logic;
		OR16			: out std_logic;
		OR19			: out std_logic;
		OR20			: out std_logic;
		OR22			: out std_logic;
		OR3			: out std_logic;
		OR4			: out std_logic;
		OR7			: out std_logic;
		OR8			: out std_logic;
		OR9			: out std_logic;
		OT1			: out std_logic;
		OT10			: out std_logic;
		OT11			: out std_logic;
		OT12			: out std_logic;
		OT14			: out std_logic;
		OT15			: out std_logic;
		OT16			: out std_logic;
		OT17			: out std_logic;
		OT18			: out std_logic;
		OT19			: out std_logic;
		OT2			: out std_logic;
		OT20			: out std_logic;
		OT21			: out std_logic;
		OT22			: out std_logic;
		OT3			: out std_logic;
		OT4			: out std_logic;
		OT5			: out std_logic;
		OT7			: out std_logic;
		OT8			: out std_logic;
		OU1			: out std_logic;
		OU10			: out std_logic;
		OU12			: out std_logic;
		OU13			: out std_logic;
		OU14			: out std_logic;
		OU16			: out std_logic;
		OU17			: out std_logic;
		OU19			: out std_logic;
		OU20			: out std_logic;
		OU22			: out std_logic;
		OU3			: out std_logic;
		OU4			: out std_logic;
		OU6			: out std_logic;
		OU8			: out std_logic;
		OV1			: out std_logic;
		OV13			: out std_logic;
		OV15			: out std_logic;
		OV17			: out std_logic;
		OV18			: out std_logic;
		OV19			: out std_logic;
		OV2			: out std_logic;
		OV20			: out std_logic;
		OV21			: out std_logic;
		OV22			: out std_logic;
		OV3			: out std_logic;
		OV5			: out std_logic;
		OV7			: out std_logic;
		OV9			: out std_logic;
		OW1			: out std_logic;
		OW13			: out std_logic;
		OW14			: out std_logic;
		OW15			: out std_logic;
		OW17			: out std_logic;
		OW18			: out std_logic;
		OW20			: out std_logic;
		OW22			: out std_logic;
		OW3			: out std_logic;
		OW4			: out std_logic;
		OW6			: out std_logic;
		OW8			: out std_logic;
		OW9			: out std_logic;
		OY1			: out std_logic;
		OY11			: out std_logic;
		OY14			: out std_logic;
		OY15			: out std_logic;
		OY16			: out std_logic;
		OY17			: out std_logic;
		OY18			: out std_logic;
		OY19			: out std_logic;
		OY2			: out std_logic;
		OY3			: out std_logic;
		OY4			: out std_logic;
		OY5			: out std_logic;
		OY6			: out std_logic;
		OY7			: out std_logic;
		OY8			: out std_logic;
		ID0_in			: in  std_logic;
		ID1_in			: in  std_logic;
		ID2_in			: in  std_logic
	);
end sha_top;

architecture PHY of sha_top is
	component SHA_IfCtrl
		port (
			Clk		: in  std_logic;
			ClkFast		: in  std_logic;

			-- Chip identifier (used to parse correctly frame requests)
			ChipID		: in  std_logic_vector( 2 downto 0);
			AltChipID	: in  std_logic_vector( 2 downto 0);

			-- SPI interface
			MOSI		: in  std_logic;
			SCK			: in  std_logic;
			MISO		: out std_logic;
			MISO_en		: out std_logic;

			-- DCM programming interface
			DCM_Freeze	: out std_logic;
			DCM_Data_En	: out std_logic;
			DCM_Data	: out std_logic;
			DCM_Rst		: out std_logic;
			DCM_Locked	: in  std_logic;

			-- Interface with MainControl unit MC_D is 32-bit data bus
			-- MC_A(5) is write enable, MC_A(4) is lower address part.
			-- Goes at fast clock
			MC_D		: out std_logic_vector(31 downto 0);
			MC_A		: out std_logic_vector( 5 downto 0);

			-- Receives edge, when scanning is done. on fast clock!
			ScanDone_in	: in  std_logic;

			-- Receives data into FIFO when matches arrives.
			Match_has	: in  std_logic;
			Match_data	: in  std_logic_vector(31 downto 0)
		);
	end component;

	component clkrounds
		port (
			Clk		: in  std_logic;
			ClkTX		: in  std_logic;
			Prog_l		: in  std_logic_vector(3 downto 0);
			Prog_r		: in  std_logic_vector(3 downto 0);
			Match_l		: out std_logic;
			Match_r		: out std_logic;
			ScanDone_out	: out std_logic
		);
	end component;

	signal GClk, SCK, MISO, MOSI, MISO_en, nMISO_en : std_logic;
	signal ID_in, IDIO_in : std_logic_vector(2 downto 0);
	signal tProg_out, Prog_out, Prog_hr, tProg_hr, Prog_hl : std_logic_vector(3 downto 0);

	signal tScanDone_in, ScanDone_in : std_logic;
	signal LMatch_in, RMatch_in : std_logic;

	signal clkfbout, Clk, Clk_l, ClkTX_l, ClkTX : std_logic;

	signal Match_has, Match_wire : std_logic;
	signal MC_D, Match_data : std_logic_vector(31 downto 0);
	signal MC_A : std_logic_vector( 5 downto 0);

	signal C_in, C_out : std_logic_vector(28 downto 0);
	signal W_in, K_in : std_logic_vector(31 downto 0);

	signal DCM_Freeze, DCM_Data, DCM_Data_En, DCM_Rst, DCM_Locked, DCM_Locked_int : std_logic;
	signal DCM_Status : std_logic_vector(1 downto 0);
begin
	IBUF_SCK:  IBUF  port map (O => SCK,      I => SCK_in);
	nMISO_en <= not MISO_en;
	OBUF_MISO_EN: OBUF port map (O => MISO_EN_out, I => nMISO_en);
	OBUF_MISO: OBUFT port map (T => nMISO_en, O => MISO_out, I => MISO);
	IBUF_MOSI: IBUF  port map (O => MOSI,     I => MOSI_in);
	IBUF_ID0:  IBUF  port map (O => ID_in(0),    I => ID0_in);
	IBUF_ID1:  IBUF  port map (O => ID_in(1),    I => ID1_in);
	IBUF_ID2:  IBUF  port map (O => ID_in(2),    I => ID2_in);
	IBUF_IO3:  IBUF  port map (O => IDIO_in(0),  I => IO3_in);
	IBUF_IO0:  IBUF  port map (O => IDIO_in(1),  I => IO0_in);
	IBUF_IO2:  IBUF  port map (O => IDIO_in(2),  I => IO2_in);

	-- Fix and get ID, depending on its source
--	IDIO_fixed <= IDIO_in when IDIO_in(2) = '0' else (IDIO_in(2) & (not IDIO_in(1)) & (not IDIO_in(0)));
--	ID <= ID_in when (ID_in /= "111") else IDIO_fixed;

	-- SPI CONTROLLER
	SHASPIinst: SHA_IfCtrl port map (
		Clk => ClkTX, ClkFast => Clk, ChipID => ID_in, AltChipID => IDIO_in,
		SCK => SCK, MOSI => MOSI, MISO => MISO, MISO_en => MISO_en,
		DCM_Freeze => DCM_Freeze, DCM_Data_En => DCM_Data_En, DCM_Data => DCM_Data, DCM_Rst => DCM_Rst, DCM_Locked => DCM_Locked,
		MC_D => MC_D, MC_A => MC_A,
		ScanDone_in => ScanDone_in, -- Scan done flag!
		Match_has => Match_has, Match_data => Match_data
	);

	-- Match Receiver
	Match_wire <= LMatch_in and RMatch_in;

	SHAMRX: SHA_MatchRX port map (
		Clk => ClkTX, ClkTX => ClkTX,
		Match_in => Match_wire, Match_ena => '1',
		Match_out => Match_data, Match_has => Match_has );

	-- Main Control unit - when it is loaded, calculation will be started!
	SHAMC: SHA_MainControl port map (Clk => Clk, D_in => MC_D, Addr_in => MC_A(4 downto 0), Addr_we => MC_A(5),
		Prog_out => tProg_out);

	-- Main inputs
	process (Clk) begin
		if rising_edge(Clk) then
			ScanDone_in <= tScanDone_in;
			Prog_out <= tProg_out; -- Additional registers buffer, so they all are NEAR BUFH distribution point!
		end if;
	end process;

	BUFHR0: BUFH port map (O => Prog_hr(0), I => Prog_out(0));
	BUFHR1: BUFH port map (O => Prog_hr(1), I => Prog_out(1));
	BUFHR2: BUFH port map (O => Prog_hr(2), I => Prog_out(2));
	BUFHR3: BUFH port map (O => Prog_hr(3), I => Prog_out(3));

	BUFHL0: BUFH port map (O => Prog_hl(0), I => Prog_out(0));
	BUFHL1: BUFH port map (O => Prog_hl(1), I => Prog_out(1));
	BUFHL2: BUFH port map (O => Prog_hl(2), I => Prog_out(2));
	BUFHL3: BUFH port map (O => Prog_hl(3), I => Prog_out(3));

	-- We first multiply 20 Mhz x 48 to 960 Mhz clock and then divide it by 3!
	-- As we have 360/(CLKFBOUT_MULT * 8) avail phase angles, we take nearest angles
	-- to what PLL can synthesize

 	-- HIGH BANDWIDTH - Minimize output jitter
--	MPLL: PLL_BASE generic map (
--			BANDWIDTH => "HIGH",
--			CLK_FEEDBACK => "CLKFBOUT", DIVCLK_DIVIDE => 1, CLKFBOUT_MULT => 32,
--			CLKFBOUT_PHASE => 0.000,
--			CLKOUT0_DIVIDE => 2, CLKOUT0_PHASE => 0.000, CLKOUT0_DUTY_CYCLE => 0.5,
--			CLKOUT1_DIVIDE => 64, CLKOUT1_PHASE => 0.000, CLKOUT1_DUTY_CYCLE => 0.5,
--			CLKIN_PERIOD => 50.0 )
--		port map (
--			CLKFBOUT => clkfbout, CLKFBIN => clkfbout, CLKIN => GClk_in,
--			LOCKED => open, RST => '0',
--			CLKOUT0 => Clk_l,
--			CLKOUT1 => ClkTX_l );

	-- Programmable DCM clock generator, which uses programmed frequency
	DCMCI: DCM_CLKGEN generic map (
			CLKFXDV_DIVIDE => 2,
			CLKFX_DIVIDE => 1,
			CLKFX_MD_MAX => 16.0, -- Maximal clock is 320 Mhz!
			CLKFX_MULTIPLY => 10, -- Multiply by default at 200 Mhz clock!
			CLKIN_PERIOD => 50.0,
			SPREAD_SPECTRUM => "NONE",
			STARTUP_WAIT => FALSE
		) port map (
			CLKFX => Clk_l,
			CLKFX180 => open,
			CLKFXDV => open,
			LOCKED => DCM_Locked_int,
			STATUS => DCM_Status,
			CLKIN => GClk_in,
			FREEZEDCM => DCM_Freeze,
			PROGCLK => ClkTX,
			PROGDATA => DCM_Data,
			PROGEN => DCM_Data_En,
			RST => DCM_Rst
		);
	DCM_Locked <= (not DCM_Status(1)) and DCM_Locked_int; -- Only when CLKFX IS NOT STOPPED!

	-- Static slow system clock generator
	DCMBI: DCM_CLKGEN generic map (
			CLKFXDV_DIVIDE => 2,
			CLKFX_DIVIDE => 2,
			CLKFX_MD_MAX => 3.0,
			CLKFX_MULTIPLY => 3,
			CLKIN_PERIOD => 50.0,
			SPREAD_SPECTRUM => "NONE",
			STARTUP_WAIT => FALSE
		) port map (
			CLKFX => ClkTX_l,
			CLKFX180 => open,
			CLKFXDV => open,
			LOCKED => clkfbout,
			STATUS => open,
			CLKIN => GClk_in,
			FREEZEDCM => clkfbout,
			PROGCLK => '0',
			PROGDATA => '0',
			PROGEN => '0',
			RST => '0'
		);

	BUFGCLK:    BUFG port map (O => Clk, I => Clk_l);
	BUFGCLKTX:  BUFG port map (O => ClkTX, I => ClkTX_l);

	-- Place all rounds!
	RNDS: clkrounds port map (
		Clk => Clk, ClkTX => ClkTX,
		Prog_l => Prog_hl, Prog_r => Prog_hr,
		Match_l => LMatch_in, Match_r => RMatch_in,
		ScanDone_out => tScanDone_in
	);


	OBUF_OA10: OBUF	port map (O => OA10,	I => '0');
	OBUF_OA11: OBUF	port map (O => OA11,	I => '0');
	OBUF_OA12: OBUF	port map (O => OA12,	I => '0');
	OBUF_OA13: OBUF	port map (O => OA13,	I => '0');
	OBUF_OA14: OBUF	port map (O => OA14,	I => '0');
	OBUF_OA15: OBUF	port map (O => OA15,	I => '0');
	OBUF_OA16: OBUF	port map (O => OA16,	I => '0');
	OBUF_OA17: OBUF	port map (O => OA17,	I => '0');
	OBUF_OA18: OBUF	port map (O => OA18,	I => '0');
	OBUF_OA2: OBUF	port map (O => OA2,	I => '0');
	OBUF_OA20: OBUF	port map (O => OA20,	I => '0');
	OBUF_OA21: OBUF	port map (O => OA21,	I => '0');
	OBUF_OA3: OBUF	port map (O => OA3,	I => '0');
	OBUF_OA4: OBUF	port map (O => OA4,	I => '0');
	OBUF_OA5: OBUF	port map (O => OA5,	I => '0');
	OBUF_OA6: OBUF	port map (O => OA6,	I => '0');
	OBUF_OA7: OBUF	port map (O => OA7,	I => '0');
	OBUF_OA8: OBUF	port map (O => OA8,	I => '0');
	OBUF_OA9: OBUF	port map (O => OA9,	I => '0');
	OBUF_OAA10:OBUF	port map (O => OAA10,	I => '0');
	OBUF_OAA14:OBUF	port map (O => OAA14,	I => '0');
	OBUF_OAA16:OBUF	port map (O => OAA16,	I => '0');
	OBUF_OAA18:OBUF	port map (O => OAA18,	I => '0');
	OBUF_OAA2: OBUF	port map (O => OAA2,	I => '0');
	OBUF_OAA21:OBUF	port map (O => OAA21,	I => '0');
	OBUF_OAA4: OBUF	port map (O => OAA4,	I => '0');
	OBUF_OAA6: OBUF	port map (O => OAA6,	I => '0');
	OBUF_OAB10:OBUF	port map (O => OAB10,	I => '0');
	OBUF_OAB14:OBUF	port map (O => OAB14,	I => '0');
	OBUF_OAB15:OBUF	port map (O => OAB15,	I => '0');
	OBUF_OAB16:OBUF	port map (O => OAB16,	I => '0');
	OBUF_OAB17:OBUF	port map (O => OAB17,	I => '0');
	OBUF_OAB18:OBUF	port map (O => OAB18,	I => '0');
	OBUF_OAB19:OBUF	port map (O => OAB19,	I => '0');
	OBUF_OAB2: OBUF	port map (O => OAB2,	I => '0');
	OBUF_OAB20:OBUF	port map (O => OAB20,	I => '0');
	OBUF_OAB21:OBUF	port map (O => OAB21,	I => '0');
	OBUF_OAB3: OBUF	port map (O => OAB3,	I => '0');
	OBUF_OAB4: OBUF	port map (O => OAB4,	I => '0');
	OBUF_OAB5: OBUF	port map (O => OAB5,	I => '0');
	OBUF_OAB6: OBUF	port map (O => OAB6,	I => '0');
	OBUF_OAB7: OBUF	port map (O => OAB7,	I => '0');
	OBUF_OAB8: OBUF	port map (O => OAB8,	I => '0');
	OBUF_OB1: OBUF	port map (O => OB1,	I => '0');
	OBUF_OB10: OBUF	port map (O => OB10,	I => '0');
	OBUF_OB12: OBUF	port map (O => OB12,	I => '0');
	OBUF_OB14: OBUF	port map (O => OB14,	I => '0');
	OBUF_OB16: OBUF	port map (O => OB16,	I => '0');
	OBUF_OB18: OBUF	port map (O => OB18,	I => '0');
	OBUF_OB2: OBUF	port map (O => OB2,	I => '0');
	OBUF_OB20: OBUF	port map (O => OB20,	I => '0');
	OBUF_OB21: OBUF	port map (O => OB21,	I => '0');
	OBUF_OB22: OBUF	port map (O => OB22,	I => '0');
	OBUF_OB3: OBUF	port map (O => OB3,	I => '0');
	OBUF_OB6: OBUF	port map (O => OB6,	I => '0');
	OBUF_OB8: OBUF	port map (O => OB8,	I => '0');
	OBUF_OC1: OBUF	port map (O => OC1,	I => '0');
	OBUF_OC10: OBUF	port map (O => OC10,	I => '0');
	OBUF_OC11: OBUF	port map (O => OC11,	I => '0');
	OBUF_OC12: OBUF	port map (O => OC12,	I => '0');
	OBUF_OC13: OBUF	port map (O => OC13,	I => '0');
	OBUF_OC14: OBUF	port map (O => OC14,	I => '0');
	OBUF_OC15: OBUF	port map (O => OC15,	I => '0');
	OBUF_OC16: OBUF	port map (O => OC16,	I => '0');
	OBUF_OC17: OBUF	port map (O => OC17,	I => '0');
	OBUF_OC19: OBUF	port map (O => OC19,	I => '0');
	OBUF_OC20: OBUF	port map (O => OC20,	I => '0');
	OBUF_OC22: OBUF	port map (O => OC22,	I => '0');
	OBUF_OC3: OBUF	port map (O => OC3,	I => '0');
	OBUF_OC4: OBUF	port map (O => OC4,	I => '0');
	OBUF_OC5: OBUF	port map (O => OC5,	I => '0');
	OBUF_OC6: OBUF	port map (O => OC6,	I => '0');
	OBUF_OC7: OBUF	port map (O => OC7,	I => '0');
	OBUF_OC9: OBUF	port map (O => OC9,	I => '0');
	OBUF_OD1: OBUF	port map (O => OD1,	I => '0');
	OBUF_OD10: OBUF	port map (O => OD10,	I => '0');
	OBUF_OD11: OBUF	port map (O => OD11,	I => '0');
	OBUF_OD12: OBUF	port map (O => OD12,	I => '0');
	OBUF_OD13: OBUF	port map (O => OD13,	I => '0');
	OBUF_OD14: OBUF	port map (O => OD14,	I => '0');
	OBUF_OD15: OBUF	port map (O => OD15,	I => '0');
	OBUF_OD17: OBUF	port map (O => OD17,	I => '0');
	OBUF_OD19: OBUF	port map (O => OD19,	I => '0');
	OBUF_OD2: OBUF	port map (O => OD2,	I => '0');
	OBUF_OD20: OBUF	port map (O => OD20,	I => '0');
	OBUF_OD21: OBUF	port map (O => OD21,	I => '0');
	OBUF_OD22: OBUF	port map (O => OD22,	I => '0');
	OBUF_OD3: OBUF	port map (O => OD3,	I => '0');
	OBUF_OD5: OBUF	port map (O => OD5,	I => '0');
	OBUF_OD6: OBUF	port map (O => OD6,	I => '0');
	OBUF_OD7: OBUF	port map (O => OD7,	I => '0');
	OBUF_OD8: OBUF	port map (O => OD8,	I => '0');
	OBUF_OD9: OBUF	port map (O => OD9,	I => '0');
	OBUF_OE1: OBUF	port map (O => OE1,	I => '0');
	OBUF_OE10: OBUF	port map (O => OE10,	I => '0');
	OBUF_OE12: OBUF	port map (O => OE12,	I => '0');
	OBUF_OE14: OBUF	port map (O => OE14,	I => '0');
	OBUF_OE16: OBUF	port map (O => OE16,	I => '0');
	OBUF_OE20: OBUF	port map (O => OE20,	I => '0');
	OBUF_OE22: OBUF	port map (O => OE22,	I => '0');
	OBUF_OE3: OBUF	port map (O => OE3,	I => '0');
	OBUF_OE4: OBUF	port map (O => OE4,	I => '0');
	OBUF_OE5: OBUF	port map (O => OE5,	I => '0');
	OBUF_OE6: OBUF	port map (O => OE6,	I => '0');
	OBUF_OE8: OBUF	port map (O => OE8,	I => '0');
	OBUF_OF1: OBUF	port map (O => OF1,	I => '0');
	OBUF_OF10: OBUF	port map (O => OF10,	I => '0');
	OBUF_OF12: OBUF	port map (O => OF12,	I => '0');
	OBUF_OF13: OBUF	port map (O => OF13,	I => '0');
	OBUF_OF14: OBUF	port map (O => OF14,	I => '0');
	OBUF_OF15: OBUF	port map (O => OF15,	I => '0');
	OBUF_OF16: OBUF	port map (O => OF16,	I => '0');
	OBUF_OF17: OBUF	port map (O => OF17,	I => '0');
	OBUF_OF18: OBUF	port map (O => OF18,	I => '0');
	OBUF_OF19: OBUF	port map (O => OF19,	I => '0');
	OBUF_OF2: OBUF	port map (O => OF2,	I => '0');
	OBUF_OF20: OBUF	port map (O => OF20,	I => '0');
	OBUF_OF21: OBUF	port map (O => OF21,	I => '0');
	OBUF_OF22: OBUF	port map (O => OF22,	I => '0');
	OBUF_OF3: OBUF	port map (O => OF3,	I => '0');
	OBUF_OF5: OBUF	port map (O => OF5,	I => '0');
	OBUF_OF7: OBUF	port map (O => OF7,	I => '0');
	OBUF_OF8: OBUF	port map (O => OF8,	I => '0');
	OBUF_OF9: OBUF	port map (O => OF9,	I => '0');
	OBUF_OG1: OBUF	port map (O => OG1,	I => '0');
	OBUF_OG11: OBUF	port map (O => OG11,	I => '0');
	OBUF_OG13: OBUF	port map (O => OG13,	I => '0');
	OBUF_OG16: OBUF	port map (O => OG16,	I => '0');
	OBUF_OG17: OBUF	port map (O => OG17,	I => '0');
	OBUF_OG19: OBUF	port map (O => OG19,	I => '0');
	OBUF_OG20: OBUF	port map (O => OG20,	I => '0');
	OBUF_OG22: OBUF	port map (O => OG22,	I => '0');
	OBUF_OG3: OBUF	port map (O => OG3,	I => '0');
	OBUF_OG4: OBUF	port map (O => OG4,	I => '0');
	OBUF_OG6: OBUF	port map (O => OG6,	I => '0');
	OBUF_OG7: OBUF	port map (O => OG7,	I => '0');
	OBUF_OG8: OBUF	port map (O => OG8,	I => '0');
	OBUF_OG9: OBUF	port map (O => OG9,	I => '0');
	OBUF_OH1: OBUF	port map (O => OH1,	I => '0');
	OBUF_OH10: OBUF	port map (O => OH10,	I => '0');
	OBUF_OH11: OBUF	port map (O => OH11,	I => '0');
	OBUF_OH12: OBUF	port map (O => OH12,	I => '0');
	OBUF_OH13: OBUF	port map (O => OH13,	I => '0');
	OBUF_OH14: OBUF	port map (O => OH14,	I => '0');
	OBUF_OH16: OBUF	port map (O => OH16,	I => '0');
	OBUF_OH17: OBUF	port map (O => OH17,	I => '0');
	OBUF_OH18: OBUF	port map (O => OH18,	I => '0');
	OBUF_OH19: OBUF	port map (O => OH19,	I => '0');
	OBUF_OH2: OBUF	port map (O => OH2,	I => '0');
	OBUF_OH20: OBUF	port map (O => OH20,	I => '0');
	OBUF_OH21: OBUF	port map (O => OH21,	I => '0');
	OBUF_OH22: OBUF	port map (O => OH22,	I => '0');
	OBUF_OH3: OBUF	port map (O => OH3,	I => '0');
	OBUF_OH4: OBUF	port map (O => OH4,	I => '0');
	OBUF_OH5: OBUF	port map (O => OH5,	I => '0');
	OBUF_OH6: OBUF	port map (O => OH6,	I => '0');
	OBUF_OH8: OBUF	port map (O => OH8,	I => '0');
	OBUF_OJ1: OBUF	port map (O => OJ1,	I => '0');
	OBUF_OJ16: OBUF	port map (O => OJ16,	I => '0');
	OBUF_OJ17: OBUF	port map (O => OJ17,	I => '0');
	OBUF_OJ19: OBUF	port map (O => OJ19,	I => '0');
	OBUF_OJ20: OBUF	port map (O => OJ20,	I => '0');
	OBUF_OJ22: OBUF	port map (O => OJ22,	I => '0');
	OBUF_OJ3: OBUF	port map (O => OJ3,	I => '0');
	OBUF_OJ4: OBUF	port map (O => OJ4,	I => '0');
	OBUF_OJ6: OBUF	port map (O => OJ6,	I => '0');
	OBUF_OJ7: OBUF	port map (O => OJ7,	I => '0');
	OBUF_OK1: OBUF	port map (O => OK1,	I => '0');
	OBUF_OK16: OBUF	port map (O => OK16,	I => '0');
	OBUF_OK17: OBUF	port map (O => OK17,	I => '0');
	OBUF_OK18: OBUF	port map (O => OK18,	I => '0');
	OBUF_OK19: OBUF	port map (O => OK19,	I => '0');
	OBUF_OK2: OBUF	port map (O => OK2,	I => '0');
	OBUF_OK20: OBUF	port map (O => OK20,	I => '0');
	OBUF_OK21: OBUF	port map (O => OK21,	I => '0');
	OBUF_OK22: OBUF	port map (O => OK22,	I => '0');
	OBUF_OK3: OBUF	port map (O => OK3,	I => '0');
	OBUF_OK4: OBUF	port map (O => OK4,	I => '0');
	OBUF_OK5: OBUF	port map (O => OK5,	I => '0');
	OBUF_OK6: OBUF	port map (O => OK6,	I => '0');
	OBUF_OK7: OBUF	port map (O => OK7,	I => '0');
	OBUF_OK8: OBUF	port map (O => OK8,	I => '0');
	OBUF_OL1: OBUF	port map (O => OL1,	I => '0');
	OBUF_OL15: OBUF	port map (O => OL15,	I => '0');
	OBUF_OL17: OBUF	port map (O => OL17,	I => '0');
	OBUF_OL19: OBUF	port map (O => OL19,	I => '0');
	OBUF_OL20: OBUF	port map (O => OL20,	I => '0');
	OBUF_OL22: OBUF	port map (O => OL22,	I => '0');
	OBUF_OL3: OBUF	port map (O => OL3,	I => '0');
	OBUF_OL4: OBUF	port map (O => OL4,	I => '0');
	OBUF_OL6: OBUF	port map (O => OL6,	I => '0');
	OBUF_OM1: OBUF	port map (O => OM1,	I => '0');
	OBUF_OM16: OBUF	port map (O => OM16,	I => '0');
	OBUF_OM17: OBUF	port map (O => OM17,	I => '0');
	OBUF_OM18: OBUF	port map (O => OM18,	I => '0');
	OBUF_OM19: OBUF	port map (O => OM19,	I => '0');
	OBUF_OM2: OBUF	port map (O => OM2,	I => '0');
	OBUF_OM20: OBUF	port map (O => OM20,	I => '0');
	OBUF_OM21: OBUF	port map (O => OM21,	I => '0');
	OBUF_OM22: OBUF	port map (O => OM22,	I => '0');
	OBUF_OM3: OBUF	port map (O => OM3,	I => '0');
	OBUF_OM4: OBUF	port map (O => OM4,	I => '0');
	OBUF_OM5: OBUF	port map (O => OM5,	I => '0');
	OBUF_OM6: OBUF	port map (O => OM6,	I => '0');
	OBUF_OM7: OBUF	port map (O => OM7,	I => '0');
	OBUF_OM8: OBUF	port map (O => OM8,	I => '0');
	OBUF_ON1: OBUF	port map (O => ON1,	I => '0');
	OBUF_ON16: OBUF	port map (O => ON16,	I => '0');
	OBUF_ON19: OBUF	port map (O => ON19,	I => '0');
	OBUF_ON20: OBUF	port map (O => ON20,	I => '0');
	OBUF_ON22: OBUF	port map (O => ON22,	I => '0');
	OBUF_ON3: OBUF	port map (O => ON3,	I => '0');
	OBUF_ON4: OBUF	port map (O => ON4,	I => '0');
	OBUF_ON6: OBUF	port map (O => ON6,	I => '0');
	OBUF_ON7: OBUF	port map (O => ON7,	I => '0');
	OBUF_OP1: OBUF	port map (O => OP1,	I => '0');
	OBUF_OP17: OBUF	port map (O => OP17,	I => '0');
	OBUF_OP18: OBUF	port map (O => OP18,	I => '0');
	OBUF_OP19: OBUF	port map (O => OP19,	I => '0');
	OBUF_OP2: OBUF	port map (O => OP2,	I => '0');
	OBUF_OP20: OBUF	port map (O => OP20,	I => '0');
	OBUF_OP21: OBUF	port map (O => OP21,	I => '0');
	OBUF_OP22: OBUF	port map (O => OP22,	I => '0');
	OBUF_OP3: OBUF	port map (O => OP3,	I => '0');
	OBUF_OP4: OBUF	port map (O => OP4,	I => '0');
	OBUF_OP5: OBUF	port map (O => OP5,	I => '0');
	OBUF_OP6: OBUF	port map (O => OP6,	I => '0');
	OBUF_OP7: OBUF	port map (O => OP7,	I => '0');
	OBUF_OP8: OBUF	port map (O => OP8,	I => '0');
	OBUF_OR1: OBUF	port map (O => OR1,	I => '0');
	OBUF_OR11: OBUF	port map (O => OR11,	I => '0');
	OBUF_OR13: OBUF	port map (O => OR13,	I => '0');
	OBUF_OR15: OBUF	port map (O => OR15,	I => '0');
	OBUF_OR16: OBUF	port map (O => OR16,	I => '0');
	OBUF_OR19: OBUF	port map (O => OR19,	I => '0');
	OBUF_OR20: OBUF	port map (O => OR20,	I => '0');
	OBUF_OR22: OBUF	port map (O => OR22,	I => '0');
	OBUF_OR3: OBUF	port map (O => OR3,	I => '0');
	OBUF_OR4: OBUF	port map (O => OR4,	I => '0');
	OBUF_OR7: OBUF	port map (O => OR7,	I => '0');
	OBUF_OR8: OBUF	port map (O => OR8,	I => '0');
	OBUF_OR9: OBUF	port map (O => OR9,	I => '0');
	OBUF_OT1: OBUF	port map (O => OT1,	I => '0');
	OBUF_OT10: OBUF	port map (O => OT10,	I => '0');
	OBUF_OT11: OBUF	port map (O => OT11,	I => '0');
	OBUF_OT12: OBUF	port map (O => OT12,	I => '0');
	OBUF_OT14: OBUF	port map (O => OT14,	I => '0');
	OBUF_OT15: OBUF	port map (O => OT15,	I => '0');
	OBUF_OT16: OBUF	port map (O => OT16,	I => '0');
	OBUF_OT17: OBUF	port map (O => OT17,	I => '0');
	OBUF_OT18: OBUF	port map (O => OT18,	I => '0');
	OBUF_OT19: OBUF	port map (O => OT19,	I => '0');
	OBUF_OT2: OBUF	port map (O => OT2,	I => '0');
	OBUF_OT20: OBUF	port map (O => OT20,	I => '0');
	OBUF_OT21: OBUF	port map (O => OT21,	I => '0');
	OBUF_OT22: OBUF	port map (O => OT22,	I => '0');
	OBUF_OT3: OBUF	port map (O => OT3,	I => '0');
	OBUF_OT4: OBUF	port map (O => OT4,	I => '0');
	OBUF_OT5: OBUF	port map (O => OT5,	I => '0');
	OBUF_OT7: OBUF	port map (O => OT7,	I => '0');
	OBUF_OT8: OBUF	port map (O => OT8,	I => '0');
	OBUF_OU1: OBUF	port map (O => OU1,	I => '0');
	OBUF_OU10: OBUF	port map (O => OU10,	I => '0');
	OBUF_OU12: OBUF	port map (O => OU12,	I => '0');
	OBUF_OU13: OBUF	port map (O => OU13,	I => '0');
	OBUF_OU14: OBUF	port map (O => OU14,	I => '0');
	OBUF_OU16: OBUF	port map (O => OU16,	I => '0');
	OBUF_OU17: OBUF	port map (O => OU17,	I => '0');
	OBUF_OU19: OBUF	port map (O => OU19,	I => '0');
	OBUF_OU20: OBUF	port map (O => OU20,	I => '0');
	OBUF_OU22: OBUF	port map (O => OU22,	I => '0');
	OBUF_OU3: OBUF	port map (O => OU3,	I => '0');
	OBUF_OU4: OBUF	port map (O => OU4,	I => '0');
	OBUF_OU6: OBUF	port map (O => OU6,	I => '0');
	OBUF_OU8: OBUF	port map (O => OU8,	I => '0');
	OBUF_OV1: OBUF	port map (O => OV1,	I => '0');
	OBUF_OV13: OBUF	port map (O => OV13,	I => '0');
	OBUF_OV15: OBUF	port map (O => OV15,	I => '0');
	OBUF_OV17: OBUF	port map (O => OV17,	I => '0');
	OBUF_OV18: OBUF	port map (O => OV18,	I => '0');
	OBUF_OV19: OBUF	port map (O => OV19,	I => '0');
	OBUF_OV2: OBUF	port map (O => OV2,	I => '0');
	OBUF_OV20: OBUF	port map (O => OV20,	I => '0');
	OBUF_OV21: OBUF	port map (O => OV21,	I => '0');
	OBUF_OV22: OBUF	port map (O => OV22,	I => '0');
	OBUF_OV3: OBUF	port map (O => OV3,	I => '0');
	OBUF_OV5: OBUF	port map (O => OV5,	I => '0');
	OBUF_OV7: OBUF	port map (O => OV7,	I => '0');
	OBUF_OV9: OBUF	port map (O => OV9,	I => '0');
	OBUF_OW1: OBUF	port map (O => OW1,	I => '0');
	OBUF_OW13: OBUF	port map (O => OW13,	I => '0');
	OBUF_OW14: OBUF	port map (O => OW14,	I => '0');
	OBUF_OW15: OBUF	port map (O => OW15,	I => '0');
	OBUF_OW17: OBUF	port map (O => OW17,	I => '0');
	OBUF_OW18: OBUF	port map (O => OW18,	I => '0');
	OBUF_OW20: OBUF	port map (O => OW20,	I => '0');
	OBUF_OW22: OBUF	port map (O => OW22,	I => '0');
	OBUF_OW3: OBUF	port map (O => OW3,	I => '0');
	OBUF_OW4: OBUF	port map (O => OW4,	I => '0');
	OBUF_OW6: OBUF	port map (O => OW6,	I => '0');
	OBUF_OW8: OBUF	port map (O => OW8,	I => '0');
	OBUF_OW9: OBUF	port map (O => OW9,	I => '0');
	OBUF_OY1: OBUF	port map (O => OY1,	I => '0');
	OBUF_OY11: OBUF	port map (O => OY11,	I => '0');
	OBUF_OY14: OBUF	port map (O => OY14,	I => '0');
	OBUF_OY15: OBUF	port map (O => OY15,	I => '0');
	OBUF_OY16: OBUF	port map (O => OY16,	I => '0');
	OBUF_OY17: OBUF	port map (O => OY17,	I => '0');
	OBUF_OY18: OBUF	port map (O => OY18,	I => '0');
	OBUF_OY19: OBUF	port map (O => OY19,	I => '0');
	OBUF_OY2: OBUF	port map (O => OY2,	I => '0');
	OBUF_OY3: OBUF	port map (O => OY3,	I => '0');
	OBUF_OY4: OBUF	port map (O => OY4,	I => '0');
	OBUF_OY5: OBUF	port map (O => OY5,	I => '0');
	OBUF_OY6: OBUF	port map (O => OY6,	I => '0');
	OBUF_OY7: OBUF	port map (O => OY7,	I => '0');
	OBUF_OY8: OBUF	port map (O => OY8,	I => '0');
end PHY;

