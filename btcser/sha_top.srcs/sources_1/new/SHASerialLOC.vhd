--
-- Copyright 2012 www.bitfury.org
--

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

package SHASerialLOC_lib is
	type Str10_type is array (0 to 9) of string(1 to 1);
	constant Str10    : Str10_type := ("0","1","2","3","4","5","6","7","8","9");
	type BelNames_type is array(0 to 3) of string(1 to 1);
	constant BelNames : BelNames_type  := ("A", "B", "C", "D");
	constant RBelNames : BelNames_type := ("D", "C", "B", "A");

	function itoa( x : integer ) return string;

	constant DCBA_const : std_logic_vector(127 downto 0) := x"a54ff53a_3c6ef372_bb67ae85_6a09e667";
	constant HGFE_const : std_logic_vector(127 downto 0) := x"5be0cd19_1f83d9ab_9b05688c_510e527f";

	component SHA_HalfRound
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 24; -- Y position
			MSLICE_ORIGIN	: integer := 0;  -- 0 or 1
			IS_ABCD		: integer := 1
		);
		port (
			Clk		: in  std_logic;
			A_load		: in  std_logic;
			A_load_out	: out std_logic;
			A_in		: in  std_logic_vector(31 downto 0);
			ES_in		: in  std_logic_vector(31 downto 0);
			EC_in		: in  std_logic_vector(31 downto 0);
			A_out		: out std_logic_vector(31 downto 0);
			B_out		: out std_logic_vector(31 downto 0);
			C_out		: out std_logic_vector(31 downto 0);
			D_out		: out std_logic_vector(31 downto 0)
		);
	end component;
	component SHA_HalfRound_K
		generic (
			K		: std_logic_vector(127 downto 0) := DCBA_const;
			LOC_X		: integer := 0;
			LOC_Y		: integer := 24; -- Y position
			MSLICE_ORIGIN	: integer := 0;  -- 0 or 1
			IS_ABCD		: integer := 1
		);
		port (
			Clk		: in  std_logic;
			A_sel		: in  std_logic_vector( 3 downto 0);
			A_sel1_out	: out std_logic;
			ES_in		: in  std_logic_vector(31 downto 0);
			EC_in		: in  std_logic_vector(31 downto 0);
			A_out		: out std_logic_vector(31 downto 0);
			B_out		: out std_logic_vector(31 downto 0);
			C_out		: out std_logic_vector(31 downto 0);
			D_out		: out std_logic_vector(31 downto 0)
		);
	end component;
	component SHA_XferData
		generic (
			LOC_M		: integer := 2;
			LOC_X		: integer := 3;
			LOC_Y		: integer := 24
		);
		port (
			Clk		: in  std_logic;
			Prog_Sel	: in  std_logic;
			Prog_Data	: in  std_logic;
			AddrA_in	: in  std_logic_vector( 3 downto 0);
			AddrE_in	: in  std_logic_vector( 3 downto 0);
			A_we		: in  std_logic;
			E_we		: in  std_logic;
			A_in		: in  std_logic_vector(31 downto 0);
			E_in		: in  std_logic_vector(31 downto 0);
			A_mem		: out std_logic_vector(31 downto 0);
			E_mem		: out std_logic_vector(31 downto 0);
			R_in		: in  std_logic_vector(31 downto 0);
			R_out		: out std_logic_vector(31 downto 0);
			R_rst		: in  std_logic
		);
	end component;
	component SHA_AUXRound
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 24 -- Y position
		);
		port (
			Clk		: in  std_logic;
			G_in		: in  std_logic_vector(31 downto 0);
			K_in		: in  std_logic_vector(31 downto 0);
			W_in		: in  std_logic_vector(31 downto 0);
			S_out		: out std_logic_vector(31 downto 0);
			R_in		: in  std_logic_vector(31 downto 0);
			R_out		: out std_logic_vector(31 downto 0);
			RC_in		: in  std_logic;
			RC_out		: out std_logic
		);
	end component;
	component SHA_RoundExpander_Sec
		generic (
			MSLICE_ORIGIN	: integer := 0;  -- 0 or 1
			LOC_X		: integer := 0;
			LOC_Y		: integer := 24 -- Y position
		);
		port (
			Clk		: in  std_logic;
			W1_in		: in  std_logic_vector(31 downto 0);
			W2_in		: in  std_logic_vector(31 downto 0);
			W_load		: in  std_logic;
			W_load_ds	: in  std_logic;
			W_load_out	: out std_logic;
			R_in		: in  std_logic;
			R_out		: out std_logic;
			W_out		: out std_logic_vector(31 downto 0);
			W0_out		: out std_logic_vector(47 downto 0);
			W0_in		: in  std_logic_vector(47 downto 0);
			Ws_load		: in  std_logic
		);
	end component;
	component SHA_RoundExpander_Pri
		generic (
			MSLICE_ORIGIN	: integer := 0;  -- 0 or 1
			LOC_X		: integer := 0;
			LOC_E		: integer := 0; -- E location with route-through register
			IDX		: integer := 0;
			LOC_Y		: integer := 24 -- Y position
		);
		port (
			Clk		: in  std_logic;
			W_load		: in  std_logic;
			W_inject	: in  std_logic; -- Raised when injection of IDX is performed
			W_inject_d	: in  std_logic;
			W_load_out	: out std_logic;
			W_in		: in  std_logic_vector(31 downto 0);
			W_out		: out std_logic_vector(31 downto 0);
			B0_out		: out std_logic;
			B0_in		: in  std_logic
		);
	end component;
	component SHA_Match
		generic (
			LOC_X		: integer := 0;
			LOC_Y		: integer := 24; -- Y position
			IDX		: integer := 0
		);
		port (
			Clk		: in  std_logic;
			E_in		: in  std_logic_vector(31 downto 0);
			C_in		: in  std_logic_vector(10 downto 0);
			C_out		: out std_logic_vector(10 downto 0);
			A_sel_out	: out std_logic_vector( 3 downto 0);
			Imatch_in	: in  std_logic;
			Imatch_out	: out std_logic
		);
	end component;
	component SHA_Kernel
		generic (
			IDX		: integer := 0;
			LOC_X		: integer := 3;
			LOC_Y		: integer := 24 -- Y position
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
end SHASerialLOC_lib;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

package body SHASerialLOC_lib is
	function itoa( x : integer ) return string is
		variable n: integer := x; -- needed by some compilers
	begin
		if n < 0 then return "-" & itoa(-n);
		elsif n < 10 then return Str10(n);
		else return itoa(n/10) & Str10(n rem 10);
		end if;
	end function itoa;
end SHASerialLOC_lib;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_HalfRound is
	generic (
		LOC_X			: integer := 0;
		LOC_Y			: integer := 24; -- Y position
		MSLICE_ORIGIN		: integer := 0;  -- 0 or 1
		IS_ABCD			: integer := 1
	);
	port (
		Clk			: in  std_logic;
		A_load			: in  std_logic;
		A_load_out		: out std_logic;
		A_in			: in  std_logic_vector(31 downto 0);
		ES_in			: in  std_logic_vector(31 downto 0);
		EC_in			: in  std_logic_vector(31 downto 0);
		A_out			: out std_logic_vector(31 downto 0);
		B_out			: out std_logic_vector(31 downto 0);
		C_out			: out std_logic_vector(31 downto 0);
		D_out			: out std_logic_vector(31 downto 0)
	);
end SHA_HalfRound;

architecture PHYLOC of SHA_HalfRound is
	attribute LOC : string;
	attribute BEL : string;

	constant loc_mx    : string := "SLICE_X"&itoa(LOC_X + 2 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_mx1   : string := "SLICE_X"&itoa(LOC_X + 3 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx    : string := "SLICE_X"&itoa(LOC_X +     2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx1   : string := "SLICE_X"&itoa(LOC_X + 1 + 2 * MSLICE_ORIGIN)&"Y";
	constant rthru_loc : string := loc_mx1 & itoa(LOC_Y) & ":" & loc_mx1 & itoa(LOC_Y+7);

	signal A_load_local_muxsel : std_logic; -- Signal to trigger MUX
	signal csa2c, addl6o, csa1c, sum : std_logic_vector(31 downto 0);
	signal carries : std_logic_vector(32 downto 0);

	signal A_reg, B_reg, C_reg, D_reg : std_logic_vector(31 downto 0);
	signal A_ror1, A_ror2, A_ror3 : std_logic_vector(31 downto 0);

	-- Getting initializers for function-rounds depending on chosen variant!
	function init5sel(abcd : integer) return bit_vector is
	begin
		if abcd = 1 then return X"17E8E817"; end if;
		return X"D82727D8";
	end function;
	function init6sel(abcd : integer) return bit_vector is
	begin
		if abcd = 1 then return X"E8FF00E8"; end if;
		return X"FFD8D800";
	end function;

	function srl_loc(n : integer; xpos : integer) return string is
	begin
		if xpos /= 60 then return itoa(LOC_Y+n/4); end if;
		return itoa( LOC_Y + (n/8)*2 ); -- Generate fully interleaved version
	end function;
	
	type s56ch_type is array(0 to 1) of string(1 to 1);
	constant s56ch : s56ch_type := ("5", "6");
	
	signal B_tmp : std_logic_vector(31 downto 0);	
begin
	A_load_out <= A_load_local_muxsel;

	GROR_ABCD: if IS_ABCD = 1 generate -- ROR data set is different
		A_out <= A_reg;
		A_ror1 <= A_reg( 1 downto 0) & A_reg(31 downto  2);
		A_ror2 <= A_reg(12 downto 0) & A_reg(31 downto 13);
		A_ror3 <= A_reg(21 downto 0) & A_reg(31 downto 22);
		csa1c(0) <= '1';
	end generate;

	GROR_EFGH: if IS_ABCD = 0 generate
		A_out <= A_reg;
		A_ror1 <= A_reg( 5 downto 0) & A_reg(31 downto  6);
		A_ror2 <= A_reg(10 downto 0) & A_reg(31 downto 11);
		A_ror3 <= A_reg(24 downto 0) & A_reg(31 downto 25);
		csa1c(0) <= '0';
	end generate;

	csa2c(0) <= '0';
	carries(0) <= '0';

	BG: for i in 31 downto 0 generate -- Generate bit by bit
		signal C_tmp, D_tmp : std_logic;
		signal addl5o, csa1s, csa2s, csa2sa : std_logic;

		constant loc_y4 : string := itoa(LOC_Y + i/4);

		attribute LOC of BREG   : label is rthru_loc;
		attribute LOC of CSA1L5 : label is loc_mx1&loc_y4;
		attribute LOC of CSA2L5, CSA2FD5 : label is loc_lx1 & loc_y4;
		attribute BEL of CSA1L5, CSA2L5  : label is RBelNames(i rem 4) & "5LUT";
		attribute LOC of ADDL6, ADDL5, ADDFD5, ADDFD : label is loc_lx & loc_y4;
		attribute BEL of ADDL6 : label is BelNames(i rem 4) & "6LUT";
		attribute BEL of ADDL5 : label is BelNames(i rem 4) & "5LUT";
		attribute BEL of BREG : label is RBelNames(i rem 4) & "FF";
	begin
		GSRLD: if IS_ABCD = 1 generate -- Place two SRLs interleaved
			attribute LOC of SRLC, SRLCFD, SRLD, SRLDFD : label is loc_mx & loc_y4;
			attribute BEL of SRLC : label is BelNames(i rem 4) & "5LUT";
			attribute BEL of SRLD : label is BelNames(i rem 4) & "6LUT";
		begin
--			SRLD:	RAM16X1S generic map ( INIT => x"0000" )
--				     port map (WCLK => Clk, WE => '1', D => C_reg(i), O => D_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLD:	SRL16 generic map ( INIT => x"0000" )
				     port map (CLK => Clk, D => C_reg(i), Q => D_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLDFD: FD   port map (C => Clk, D => D_tmp, Q => D_reg(i));
--			SRLC:  RAM16X1S generic map ( INIT => x"0000" )
--				     port map (WCLK => Clk, WE => '1', D => B_reg(i), O => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLC:  SRL16 generic map ( INIT => x"0000" )
				     port map (CLK => Clk, D => B_reg(i), Q => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLCFD: FD   port map (C => Clk, D => C_tmp, Q => C_reg(i));
		end generate;

		-- A, B ... C, D ... A, B ... C, D special interleaving pattern
		-- 0,1,2,3  4,5,6,7
		GMEM: if IS_ABCD = 0 generate -- Interleave memory with 4 unused slices
			attribute LOC of SRLC, SRLCFD : label is loc_mx & srl_loc(i, LOC_X);
			attribute BEL of SRLC : label is BelNames( ((i/2) rem 2) + 2*((i/4) rem 2) ) & s56ch(i rem 2) & "LUT";
		begin
			D_reg(i) <= '0';
			SRLC:  SRL16 generic map ( INIT => x"0000" )
				     port map (CLK => Clk, D => B_reg(i), Q => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
--			SRLC:  RAM16X1S generic map ( INIT => x"0000" )
--				     port map (WCLK => Clk, WE => '1', D => B_reg(i), O => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLCFD: FD   port map (C => Clk, D => C_tmp, Q => C_reg(i));
		end generate;

		BREG:   FD   port map (C => Clk, D => B_tmp(i), Q => B_reg(i)); -- It is route-through register, BCD is on same switch!

		-- First part of carry save adder (producing sum)
		CSA1L5: LUT5 generic map (INIT => init5sel(IS_ABCD))
			     port map (O => csa1s, I0 => A_reg(i), I1 => B_reg(i), I2 => C_reg(i), I3 => ES_in(i), I4 => EC_in(i));
		CSA2L5: LUT5 generic map (INIT => x"96696996")
			     port map (O => csa2sa, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => csa1s, I4 => csa1c(i));
		CSA2FD5: FDRE port map (C => Clk, CE => '1', R => A_load, D => csa2sa, Q => csa2s);

		-- Generate second part of carry save adder!
		G1FD6: if i < 31 generate
			signal csa1ca, csa2ca : std_logic;
			attribute LOC of CSA1L6 : label is loc_mx1&loc_y4;
			attribute LOC of CSA2L6, CSA2FD6 : label is loc_lx1 & loc_y4;
			attribute BEL of CSA2L6, CSA1L6 : label is RBelNames(i rem 4) & "6LUT";
		begin
			CSA1L6: LUT5 generic map (INIT => init6sel(IS_ABCD))
				     port map (O => csa1c(i+1), I0 => A_reg(i), I1 => B_reg(i), I2 => C_reg(i), I3 => ES_in(i), I4 => EC_in(i));
			CSA2L6: LUT5 generic map (INIT => x"ff969600")
				     port map (O => csa2ca, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => csa1s, I4 => csa1c(i));
			CSA2FD6: FDRE port map (C => Clk, CE => '1', R => A_load, D => csa2ca, Q => csa2c(i+1));
		end generate;

		-- Generate delayed by one load load flag!
		G1FDL: if i = 31 generate
			attribute LOC of LFDFL : label is loc_lx1&itoa(LOC_Y)&":"&loc_lx1&itoa(LOC_Y+7);
		begin
			LFDFL: FDSE port map (C => Clk, CE => '1', S => A_load, D => '0', Q => A_load_local_muxsel);
		end generate;

		-- Just pass output to B_tmp register
		ADDL5: LUT1 generic map ( INIT => "10") port map (O => addl5o, I0 => A_reg(i));
		ADDFD5: FD port map (C => Clk, D => addl5o, Q => B_tmp(i));

		-- If A_load_local_muxsel = 1 then csa2c and csa2s guaranteed to be zeroes (smashed on XORCSA register set)
		-- transparently load data from A_in
		-- otherwise (if zero) - calculate XOR
		ADDL6: LUT4 generic map ( INIT => "1111000001100110")
			port map (O => addl6o(i), I3 => A_load_local_muxsel, I2 => A_in(i), I1 => csa2c(i), I0 => csa2s);
		ADDFD: FD port map (C => Clk, D => sum(i), Q => A_reg(i));

		GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
			attribute LOC of C4 : label is loc_lx & loc_y4;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csa2c(i+3 downto i),
			                     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;

	B_out <= B_reg;
	C_out <= C_reg;
	D_out <= D_reg;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_HalfRound_K is
	generic (
		K			: std_logic_vector(127 downto 0) := DCBA_const;
		LOC_X			: integer := 0;
		LOC_Y			: integer := 24; -- Y position
		MSLICE_ORIGIN		: integer := 0;  -- 0 or 1
		IS_ABCD			: integer := 1
	);
	port (
		Clk			: in  std_logic;
		A_sel			: in  std_logic_vector( 3 downto 0);
		A_sel1_out		: out std_logic;
		ES_in			: in  std_logic_vector(31 downto 0);
		EC_in			: in  std_logic_vector(31 downto 0);
		A_out			: out std_logic_vector(31 downto 0);
		B_out			: out std_logic_vector(31 downto 0);
		C_out			: out std_logic_vector(31 downto 0);
		D_out			: out std_logic_vector(31 downto 0)
	);
end SHA_HalfRound_K;

architecture PHYLOC of SHA_HalfRound_K is
	attribute LOC : string;
	attribute BEL : string;

	constant loc_mx    : string := "SLICE_X"&itoa(LOC_X + 2 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_mx1   : string := "SLICE_X"&itoa(LOC_X + 3 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx    : string := "SLICE_X"&itoa(LOC_X +     2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx1   : string := "SLICE_X"&itoa(LOC_X + 1 + 2 * MSLICE_ORIGIN)&"Y";
	constant rthru_loc : string := loc_mx1 & itoa(LOC_Y) & ":" & loc_mx1 & itoa(LOC_Y+7);

	signal csa2c, addl6o, csa1c, sum : std_logic_vector(31 downto 0);
	signal carries : std_logic_vector(32 downto 0);

	signal A_reg, B_reg, C_reg, D_reg : std_logic_vector(31 downto 0);
	signal A_ror1, A_ror2, A_ror3 : std_logic_vector(31 downto 0);

	-- Getting initializers for function-rounds depending on chosen variant!
	function init5sel(abcd : integer) return bit_vector is
	begin
		if abcd = 1 then return X"17E8E817"; end if;
		return X"D82727D8";
	end function;
	function init6sel(abcd : integer) return bit_vector is
	begin
		if abcd = 1 then return X"E8FF00E8"; end if;
		return X"FFD8D800";
	end function;

	signal B_tmp : std_logic_vector(31 downto 0);

	-- This lut just passes constant when A_sel set correctly!
	type gloadinit_type is array(0 to 7) of bit_vector(15 downto 0);
	constant gloadinit : gloadinit_type :=	(x"0006",x"00f6",x"0f06",x"0ff6",x"f006",x"f0f6",x"ff06",x"fff6");
begin
	GROR_ABCD: if IS_ABCD = 1 generate -- ROR data set is different
		A_out <= A_reg;
		A_ror1 <= A_reg( 1 downto 0) & A_reg(31 downto  2);
		A_ror2 <= A_reg(12 downto 0) & A_reg(31 downto 13);
		A_ror3 <= A_reg(21 downto 0) & A_reg(31 downto 22);
		csa1c(0) <= '1';
	end generate;

	GROR_EFGH: if IS_ABCD = 0 generate
		A_out <= A_reg;
		A_ror1 <= A_reg( 5 downto 0) & A_reg(31 downto  6);
		A_ror2 <= A_reg(10 downto 0) & A_reg(31 downto 11);
		A_ror3 <= A_reg(24 downto 0) & A_reg(31 downto 25);
		csa1c(0) <= '0';
	end generate;

	csa2c(0) <= '0';
	carries(0) <= '0';

	BG: for i in 31 downto 0 generate -- Generate bit by bit
		signal C_tmp, D_tmp : std_logic;
		signal addl5o, csa1s, csa2s, csa2sa : std_logic;

		constant loc_y4 : string := itoa(LOC_Y + i/4);

		attribute LOC of BREG   : label is rthru_loc;
		attribute LOC of CSA1L5 : label is loc_mx1&loc_y4;
		attribute LOC of CSA2L5, CSA2FD5 : label is loc_lx1 & loc_y4;
		attribute BEL of CSA1L5, CSA2L5  : label is RBelNames(i rem 4) & "5LUT";
		attribute LOC of ADDL6, ADDL5 : label is loc_lx & loc_y4;
		attribute BEL of ADDL6 : label is BelNames(i rem 4) & "6LUT";
		attribute BEL of ADDL5 : label is BelNames(i rem 4) & "5LUT";
--		attribute BEL of BREG : label is RBelNames(i rem 4) & "FF";
	begin
		GSRLD: if IS_ABCD = 1 generate -- Place two SRLs interleaved
			attribute LOC of SRLC, SRLCFD, SRLD, SRLDFD : label is loc_mx & loc_y4;
			attribute BEL of SRLC : label is BelNames(i rem 4) & "5LUT";
			attribute BEL of SRLD : label is BelNames(i rem 4) & "6LUT";
		begin
--			SRLD:  RAM16X1S generic map ( INIT => x"0000" )
--				     port map (WCLK => Clk, WE => '1', D => C_reg(i), O => D_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLD:  SRL16 generic map ( INIT => x"0000" )
				     port map (CLK => Clk, D => C_reg(i), Q => D_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLDFD: FD   port map (C => Clk, D => D_tmp, Q => D_reg(i));
--			SRLC:  RAM16X1S generic map ( INIT => x"0000" )
--				     port map (WCLK => Clk, WE => '1', D => B_reg(i), O => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLC:  SRL16 generic map ( INIT => x"0000" )
				     port map (CLK => Clk, D => B_reg(i), Q => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLCFD: FD   port map (C => Clk, D => C_tmp, Q => C_reg(i));
		end generate;

		GMEM: if IS_ABCD = 0 generate -- Give two slices at bottom and 2 slices at up!
			type lpla_type is array (0 to 7) of integer;
			type beln_type is array (0 to 31) of string (1 to 5);
			constant lpla : lpla_type := (0, 0, 3, 3, 4, 5, 6, 7);
			constant beln : beln_type :=
			("A5LUT","A6LUT","B5LUT","B6LUT","C5LUT","C6LUT","D5LUT","D6LUT",
			 "A5LUT","A6LUT","B5LUT","B6LUT","C5LUT","C6LUT","D5LUT","D6LUT",
			 "A5LUT","A6LUT","C5LUT","C6LUT","A5LUT","A6LUT","C5LUT","C6LUT",
			 "A5LUT","A6LUT","C5LUT","C6LUT","A5LUT","A6LUT","C5LUT","C6LUT");
			constant loc_y8 : string := itoa(LOC_Y + lpla(i/4));
			attribute LOC of SRLC, SRLCFD : label is loc_mx & loc_y8;
			attribute BEL of SRLC : label is beln(i);
		begin
			D_reg(i) <= '0';
			SRLC:  SRL16 generic map ( INIT => x"0000" )
				     port map (CLK => Clk, D => B_reg(i), Q => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
--			SRLC:  RAM16X1S generic map ( INIT => x"0000" )
--				     port map (WCLK => Clk, WE => '1', D => B_reg(i), O => C_tmp, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
			SRLCFD: FD   port map (C => Clk, D => C_tmp, Q => C_reg(i));
		end generate;

		BREG:   FD   port map (C => Clk, D => B_tmp(i), Q => B_reg(i)); -- It is route-through register, BCD is on same switch!

		-- First part of carry save adder (producing sum)
		CSA1L5: LUT5 generic map (INIT => init5sel(IS_ABCD))
			     port map (O => csa1s, I0 => A_reg(i), I1 => B_reg(i), I2 => C_reg(i), I3 => ES_in(i), I4 => EC_in(i));
		CSA2L5: LUT5 generic map (INIT => x"96696996")
			     port map (O => csa2sa, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => csa1s, I4 => csa1c(i));
		CSA2FD5: FDRE port map (C => Clk, CE => '1', R => A_sel(1), D => csa2sa, Q => csa2s);

		-- Generate second part of carry save adder!
		G1FD6: if i < 31 generate
			signal csa1ca, csa2ca : std_logic;
			attribute LOC of CSA1L6 : label is loc_mx1&loc_y4;
			attribute LOC of CSA2L6, CSA2FD6 : label is loc_lx1 & loc_y4;
			attribute BEL of CSA2L6, CSA1L6 : label is RBelNames(i rem 4) & "6LUT";
		begin
			CSA1L6: LUT5 generic map (INIT => init6sel(IS_ABCD))
				     port map (O => csa1c(i+1), I0 => A_reg(i), I1 => B_reg(i), I2 => C_reg(i), I3 => ES_in(i), I4 => EC_in(i));
			CSA2L6: LUT5 generic map (INIT => x"ff969600")
				     port map (O => csa2ca, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => csa1s, I4 => csa1c(i));
			CSA2FD6: FDRE port map (C => Clk, CE => '1', R => A_sel(1), D => csa2ca, Q => csa2c(i+1));
		end generate;

		GLD: if i = 31 generate
			attribute LOC of LDFD : label is loc_lx1 & itoa(LOC_Y+0) & ":" & loc_lx1 & itoa(LOC_Y+7);
		begin
			LDFD: FDSE port map (C => Clk, CE => '1', S => A_sel(1), D => '0', Q => A_sel1_out);
		end generate;

		-- Just pass output to B_tmp register
		ADDL5: LUT1 generic map ( INIT => "10") port map (O => addl5o, I0 => A_reg(i));

		GDHK1: if K(96+i) = '1' generate
			attribute LOC of ADDFD5, ADDFD : label is loc_lx & loc_y4;
		begin
			ADDFD5: FDSE port map (CE => '1', S => A_sel(0), C => Clk, D => addl5o, Q => B_tmp(i));
			ADDFD: FDSE port map (CE => '1', S => A_sel(0), C => Clk, D => sum(i), Q => A_reg(i));
		end generate;

		GDHK0: if K(96+i) = '0' generate
			attribute LOC of ADDFD5, ADDFD : label is loc_lx & loc_y4;
		begin
			ADDFD5: FDRE port map (CE => '1', R => A_sel(0), C => Clk, D => addl5o, Q => B_tmp(i));
			ADDFD: FDRE port map (CE => '1', R => A_sel(0), C => Clk, D => sum(i), Q => A_reg(i));
		end generate;

		ADDL6: LUT4 generic map ( INIT => gloadinit(conv_integer(K(64+i)&K(32+i)&K(i))) )
			port map (O => addl6o(i), I3 => A_sel(3), I2 => A_sel(2), I1 => csa2c(i), I0 => csa2s);

		GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
			attribute LOC of C4 : label is loc_lx & loc_y4;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csa2c(i+3 downto i),
			                     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;

	B_out <= B_reg;
	C_out <= C_reg;
	D_out <= D_reg;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_XferData is
	generic (
		LOC_M			: integer := 2;
		LOC_X			: integer := 3;
		LOC_Y			: integer := 24
	);
	port (
		Clk			: in  std_logic;
		Prog_Sel		: in  std_logic;
		Prog_Data		: in  std_logic;
		AddrA_in		: in  std_logic_vector( 3 downto 0);
		AddrE_in		: in  std_logic_vector( 3 downto 0);
		A_we			: in  std_logic;
		E_we			: in  std_logic;
		A_in			: in  std_logic_vector(31 downto 0);
		E_in			: in  std_logic_vector(31 downto 0);
		A_mem			: out std_logic_vector(31 downto 0);
		E_mem			: out std_logic_vector(31 downto 0);
		R_in			: in  std_logic_vector(31 downto 0);
		R_out			: out std_logic_vector(31 downto 0);
		R_rst			: in  std_logic
	);
end SHA_XferData;

architecture PHYLOC of SHA_XferData is
	attribute LOC : string;
	signal A_mux, E_mux, A_reg, E_reg, A_async, E_async : std_logic_vector(31 downto 0);
	constant loc_ms : string := "SLICE_X"&itoa(LOC_M)&"Y";
	constant loc_xs : string := "SLICE_X"&itoa(LOC_X)&"Y";
	constant loc_reg : string := "SLICE_X"&itoa(LOC_X)&"Y"&itoa(LOC_Y)&":SLICE_X"&itoa(LOC_X)&"Y"&itoa(LOC_Y+7);
	signal AddrA, AddrE : std_logic_vector(4 downto 0);
	function gram_init(i : integer) return bit_vector is
	begin
		if i /= 24 then return x"0000000000000000"; end if;
		return x"ffffffff00000000"; -- highest bit is ONE
	end function;
begin
	AddrA <= '1'&AddrA_in; -- When loading - use different address set!
	AddrE <= '1'&AddrE_in; -- When loading - use different address set!
	GKB: for i in 31 downto 0 generate
		constant loc_ay : string := itoa(LOC_Y + 2*(i/8) );
		constant loc_ey : string := itoa(LOC_Y + 2*(i/8) + 1);
		attribute LOC of RAM32FD_E : label is loc_ms & loc_ey;
		attribute LOC of RAM32FD_A : label is loc_ms & loc_ay;
		attribute LOC of RTHRUFD   : label is loc_reg;
	begin
		RTHRUFD: FDRE port map (CE => '1', R => R_rst, C => Clk, D => R_in(i), Q => R_out(i)); -- This register will be LOCed
		-- Place RAMs
		GRAM32M: if (i rem 8) = 0 generate
			attribute LOC of RAM32_E : label is loc_ms&loc_ey;
			attribute LOC of RAM32_A : label is loc_ms&loc_ay;
		begin
			RAM32_E: RAM32M generic map (INIT_D => gram_init(i)) port map (
				DOA => E_async(i+1 downto i), DOB => E_async(i+3 downto i+2),
				DOC => E_async(i+5 downto i+4), DOD => E_async(i+7 downto i+6),
				DIA => E_mux(i+1 downto i), DIB => E_mux(i+3 downto i+2),
				DIC => E_mux(i+5 downto i+4), DID => E_mux(i+7 downto i+6),
				WCLK => Clk, WE => E_we, ADDRA => AddrE, ADDRB => AddrE, ADDRC => AddrE, ADDRD => AddrE
			);
			RAM32_A: RAM32M port map (
				DOA => A_async(i+1 downto i), DOB => A_async(i+3 downto i+2),
				DOC => A_async(i+5 downto i+4), DOD => A_async(i+7 downto i+6),
				DIA => A_mux(i+1 downto i), DIB => A_mux(i+3 downto i+2),
				DIC => A_mux(i+5 downto i+4), DID => A_mux(i+7 downto i+6),
				WCLK => Clk, WE => A_we, ADDRA => AddrA, ADDRB => AddrA, ADDRC => AddrA, ADDRD => AddrA
			);
		end generate;

		RAM32FD_E: FD port map (C => Clk, Q => E_reg(i), D => E_async(i));
		RAM32FD_A: FD port map (C => Clk, Q => A_reg(i), D => A_async(i));

		-- Generate MUX that works as shift register.
		MUX1_31: if i > 0 generate
			attribute LOC of MUX1_31E : label is loc_xs&loc_ey;
			attribute LOC of MUX1_31A : label is loc_xs&loc_ay;
		begin
			MUX1_31E: LUT3 generic map (init => x"ca") port map (O => E_mux(i), I2 => Prog_Sel, I1 => E_reg(i-1), I0 => E_in(i));
			MUX1_31A: LUT3 generic map (init => x"ca") port map (O => A_mux(i), I2 => Prog_Sel, I1 => A_reg(i-1), I0 => A_in(i));
		end generate;

		MUX0: if i = 0 generate
			attribute LOC of MUX0E : label is loc_xs&loc_ey;
			attribute LOC of MUX0A : label is loc_xs&loc_ay;
		begin
			MUX0E: LUT3 generic map (init => x"ca") port map (O => E_mux(i), I2 => Prog_Sel, I1 => A_reg(31), I0 => E_in(i));
			MUX0A: LUT3 generic map (init => x"ca") port map (O => A_mux(i), I2 => Prog_Sel, I1 => Prog_Data, I0 => A_in(i));
		end generate;
	end generate;

	-- Output values in memory registers
	A_mem <= A_reg;
	E_mem <= E_reg;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_AUXRound is
	generic (
		LOC_X			: integer := 0;
		LOC_Y			: integer := 24 -- Y position
	);
	port (
		Clk			: in  std_logic;
		G_in			: in  std_logic_vector(31 downto 0);
		K_in			: in  std_logic_vector(31 downto 0);
		W_in			: in  std_logic_vector(31 downto 0);
		S_out			: out std_logic_vector(31 downto 0);
		R_in			: in  std_logic_vector(31 downto 0);
		R_out			: out std_logic_vector(31 downto 0);
		RC_in			: in  std_logic;
		RC_out			: out std_logic
	);
end SHA_AUXRound;

architecture PHYLOC of SHA_AUXRound is
	attribute LOC : string;
	attribute BEL : string;

	constant loc_lx    : string := "SLICE_X"&itoa(LOC_X  )&"Y";
	constant loc_lx1   : string := "SLICE_X"&itoa(LOC_X+1)&"Y";

	signal csac, addl6o, sum : std_logic_vector(31 downto 0);
	signal carries : std_logic_vector(32 downto 0);
begin
	csac(0) <= '0';
	carries(0) <= '0';

	BG: for i in 31 downto 0 generate -- Generate bit by bit
		signal csas, csasa, addl5o : std_logic;

		constant loc_y4 : string := itoa(LOC_Y + i/4);

		attribute BEL of CSAL5 : label is RBelNames(i rem 4) & "5LUT";
		attribute LOC of CSAL5, CSAL5FD : label is loc_lx1 & loc_y4;
		attribute BEL of ADDL6 : label is BelNames(i rem 4) & "6LUT";
		attribute BEL of ADDL5 : label is BelNames(i rem 4) & "5LUT";
		attribute LOC of ADDFD, ADDFD5, ADDL6, ADDL5 : label is loc_lx & loc_y4;
	begin
		-- Place carry save adder!
		CSAL5: LUT3 generic map (INIT => "10010110")
			port map (O => csasa, I2 => G_in(i), I1 => K_in(i), I0 => W_in(i));
		CSAL5FD: FD port map (C => Clk, D => csasa, Q => csas);

		GCSAL5: if i < 31 generate
			signal csaca : std_logic;
			attribute BEL of CSAL6 : label is RBelNames(i rem 4) & "6LUT";
			attribute LOC of CSAL6, CSAL6FD : label is loc_lx1 & loc_y4;
		begin
			CSAL6: LUT3 generic map (INIT => "11101000")
			port map (O => csaca, I2 => G_in(i), I1 => K_in(i), I0 => W_in(i));
			CSAL6FD: FD port map (C => Clk, D => csaca, Q => csac(i+1));
		end generate;

		GCSLAFD: if i = 31 generate
			attribute LOC of CSLAFD : label is loc_lx1 & loc_y4;
		begin
			CSLAFD: FD port map (C => Clk, D => RC_in, Q => RC_out);
		end generate;

		ADDL5:  LUT1 generic map ( INIT => "10") port map (O => addl5o, I0 => R_in(i));
		ADDFD5: FD port map (C => Clk, D => addl5o, Q => R_out(i));
		ADDFD:  FD port map (C => Clk, D => sum(i), Q => S_out(i));

		ADDL6: LUT2 generic map ( INIT => "0110" )
			port map (O => addl6o(i), I1 => csac(i), I0 => csas);

		GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
			attribute LOC of C4 : label is loc_lx & loc_y4;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csac(i+3 downto i),
			                     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;
	end generate;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_RoundExpander_Sec is
	generic (
		MSLICE_ORIGIN		: integer := 0;  -- 0 or 1
		LOC_X			: integer := 0;
		LOC_Y			: integer := 24 -- Y position
	);
	port (
		Clk			: in  std_logic;
		W1_in			: in  std_logic_vector(31 downto 0);
		W2_in			: in  std_logic_vector(31 downto 0);
		W_load			: in  std_logic;
		W_load_ds		: in  std_logic;
		W_load_out		: out std_logic;
		R_in			: in  std_logic;
		R_out			: out std_logic;
		W_out			: out std_logic_vector(31 downto 0);
		W0_out			: out std_logic_vector(47 downto 0);
		W0_in			: in  std_logic_vector(47 downto 0);
		Ws_load			: in  std_logic
	);
end SHA_RoundExpander_Sec;

architecture PHYLOC of SHA_RoundExpander_Sec is
	signal w14, w14_ror17, w14_ror19, w14_shr10 : std_logic_vector(31 downto 0);
	signal w1, w1_ror7, w1_ror18, w1_shr3 : std_logic_vector(31 downto 0);
	signal csa2c, addl6o, addl5o, csa1c, sum : std_logic_vector(31 downto 0);
	signal carries : std_logic_vector(32 downto 0);

	constant loc_mx    : string := "SLICE_X"&itoa(LOC_X + 2 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_mx1   : string := "SLICE_X"&itoa(LOC_X + 3 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx    : string := "SLICE_X"&itoa(LOC_X +     2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx1   : string := "SLICE_X"&itoa(LOC_X + 1 + 2 * MSLICE_ORIGIN)&"Y";
	constant rthru_loc : string := loc_lx1 & itoa(LOC_Y) & ":" & loc_lx1 & itoa(LOC_Y+7);

	signal W_load_d : std_logic;

	attribute LOC : string;
	attribute BEL : string;
begin
	W_load_out <= W_load_d;

	w1_ror7   <=  w1( 6 downto 0) & w1(31 downto  7);
	w1_ror18  <=  w1(17 downto 0) & w1(31 downto 18);
	w1_shr3   <=            "000" & w1(31 downto  3);
	w14_ror17 <= w14(16 downto 0) & w14(31 downto 17);
	w14_ror19 <= w14(18 downto 0) & w14(31 downto 19);
	w14_shr10 <=     "0000000000" & w14(31 downto 10);

	csa1c(0) <= '0';
	csa2c(0) <= '0';
	carries(0) <= '0';

	BG: for i in 31 downto 0 generate -- Generate bit by bit
		signal w14h1, w9_async, w1_async, w9, w0, w1s, csa1s, csa1sa, csa2sa, csa2s, w9i : std_logic;
		constant loc_y4 : string := itoa(LOC_Y + i/4);          -- Y4 locations

		attribute LOC of SRLW9 : label is loc_mx & loc_y4;
		attribute LOC of SRLW1, SRLW1FD : label is loc_mx & loc_y4;
		attribute LOC of CSA1L5, CSA1FD5 : label is loc_mx1 & loc_y4;
		attribute LOC of CSA2L5 : label is loc_lx1 & loc_y4;

		attribute LOC of ADDL6, ADDL5 : label is loc_lx & loc_y4;
		attribute BEL of ADDL6 : label is BelNames(i rem 4) & "6LUT";
		attribute BEL of ADDL5 : label is BelNames(i rem 4) & "5LUT";
		attribute BEL of CSA2L5 : label is RBelNames(i rem 4) & "5LUT";
		attribute BEL of CSA1L5 : label is RBelNames(i rem 4) & "5LUT";
	begin
		SRLW9:  SRL16 port map (CLK => Clk, D => w14(i), Q => w9, A0 => '1', A1 => '0', A2 => '0', A3 => '1');
		-- Then we shift to depth 17 (16 + 1) in second SRL with flip flop
		SRLW1:  SRL16 port map (CLK => Clk, D => w9i, Q => w1_async, A0 => '1', A1 => '1', A2 => '1', A3 => '1');
		SRLW1FD: FD   port map (C => Clk, D => w1_async, Q => w1s);

		GSRLW9FD0: if (i rem 2) = 0 generate
			attribute LOC of SRLW9FD : label is loc_mx & loc_y4;
		begin
			SRLW9FD: FD port map (C => Clk, D => w9, Q => w9i);
			w0 <= w1s;
			w1(i) <= w1_async;
		end generate;

		GSRLW9FD1: if (i rem 2) = 1 generate
			w9i <= w9;
			w1(i) <= w1s;
			W0_out(i/2) <= w1s; -- Route through external register (16-bit)
			w0 <= W0_in(i/2);
		end generate;

		CSA1L5: LUT5 generic map (INIT => x"96696996")
			     port map (O => csa1sa, I0 => w14_ror17(i), I1 => w14_ror19(i), I2 => w14_shr10(i), I3 => w0, I4 => w9);
		CSA2L5: LUT5 generic map (INIT => x"96696996")
			     port map (O => csa2sa, I0 => w1_ror7(i), I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => csa1s, I4 => csa1c(i));

		CSA1FD5: FD port map (C => Clk, D => csa1sa, Q => csa1s);

		G1FD6: if i < 31 generate
			signal csa1ca, csa2ca : std_logic;
			attribute LOC of CSA1L6, CSA1FD6 : label is loc_mx1 & loc_y4;
			attribute LOC of CSA2L6, CSA2FD6, CSA2FD5 : label is loc_lx1 & loc_y4;
			attribute BEL of CSA2L6 : label is RBelNames(i rem 4) & "6LUT";
			attribute BEL of CSA1L6 : label is RBelNames(i rem 4) & "6LUT";
		begin
			CSA1L6: LUT5 generic map (INIT => x"ff969600")
				     port map (O => csa1ca, I0 => w14_ror17(i), I1 => w14_ror19(i), I2 => w14_shr10(i), I3 => w0, I4 => w9);
			CSA1FD6: FD port map (C => Clk, D => csa1ca, Q => csa1c(i+1) );
			CSA2L6: LUT5 generic map (INIT => x"ff969600")
				     port map (O => csa2ca, I0 => w1_ror7(i), I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => csa1s, I4 => csa1c(i));
			CSA2FD6: FDRE port map (CE => '1', R => R_in, C => Clk, D => csa2ca, Q => csa2c(i+1));
			CSA2FD5: FDRE port map (CE => '1', R => R_in, C => Clk, D => csa2sa, Q => csa2s);
		end generate;

		-- Inject into unused CSA register transfer of control registers!
		GLFD: if i = 31 generate
			attribute LOC of LFDL  : label is loc_mx1 & itoa(LOC_Y) & ":" & loc_mx1 & itoa(LOC_Y+7);
			attribute LOC of LFDL1, CSA2FD5 : label is loc_lx1 & itoa(LOC_Y) & ":" & loc_lx1 & itoa(LOC_Y+7);
		begin
			LFDL: FD port map (C => Clk, D => W_load, Q => W_load_d);
			LFDL1: FDSE port map (CE => '1', S => R_in, C => Clk, D => '0', Q => R_out);
			CSA2FD5: FDSE port map (CE => '1', S => R_in, C => Clk, D => csa2sa, Q => csa2s); -- Rise high bit
		end generate;

		ADDL5: LUT3 generic map (INIT => "11001010") -- IF[W_load_d, W1_in(i), csa2c(i)]
			port map (O => addl5o(i), I2 => W_load_ds, I1 => W1_in(i), I0 => csa2c(i));
		ADDL6: LUT5 generic map (INIT => x"0ff06666") -- IF[I4,Xor[I3,I2],Xor[I1,I0]]
			port map (O => addl6o(i), I4 => W_load_ds, I3 => W1_in(i), I2 => W2_in(i), I1 => csa2s, I0 => csa2c(i));


		GADDFD0: if i /= 8 generate
			attribute LOC of ADDFD : label is loc_lx & loc_y4;
		begin
			ADDFD: FDRE port map (CE => '1', R => Ws_load, C => Clk, D => sum(i), Q => w14h1);
		end generate;

		GADDFD1: if i = 8 generate
			attribute LOC of ADDFD : label is loc_lx & loc_y4;
		begin
			ADDFD: FDSE port map (CE => '1', S => Ws_load, C => Clk, D => sum(i), Q => w14h1);
		end generate;


		W0_out(i+16) <= w14h1;
		w14(i) <= W0_in(i+16);

		GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
			attribute LOC of C4 : label is loc_lx & loc_y4;
		begin
			C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => addl5o(i+3 downto i),
			                     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
		end generate;

		W_out(i) <= w0; -- Take output from another point, so we'll have time to load data into round expander!
	end generate;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_ARITH.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_RoundExpander_Pri is
	generic (
		MSLICE_ORIGIN		: integer := 0;  -- 0 or 1
		LOC_X			: integer := 0;
		LOC_E			: integer := 0; -- Location of E round
		IDX			: integer := 0;
		LOC_Y			: integer := 24 -- Y position
	);
	port (
		Clk			: in  std_logic;
		W_load			: in  std_logic;
		W_inject		: in  std_logic; -- Raised when injection of IDX is performed
		W_inject_d		: in  std_logic;
		W_load_out		: out std_logic;
		W_in			: in  std_logic_vector(31 downto 0);
		W_out			: out std_logic_vector(31 downto 0);
		B0_out			: out std_logic;
		B0_in			: in  std_logic
	);
end SHA_RoundExpander_Pri;

architecture PHYLOC of SHA_RoundExpander_Pri is
	signal w9, w14, w14_ror17, w14_ror19, w14_shr10 : std_logic_vector(31 downto 0);
	signal w0, w1, w1_ror7, w1_ror18, w1_shr3 : std_logic_vector(31 downto 0);
	signal csa1s, csa2s, csa2c, addl6o, csa1c, sum : std_logic_vector(31 downto 0);
	signal carries : std_logic_vector(32 downto 0);

	signal W0_out, W0_in : std_logic_vector(15 downto 0); -- 16-bit route-through register
	signal W_load_d : std_logic;
	signal W_load_lo : std_logic;
	signal W_load_v : std_logic_vector(31 downto 0);

	constant loc_me    : string := "SLICE_X"&itoa(LOC_E)&"Y";
	constant idx_inject : std_logic_vector(6 downto 0) := conv_std_logic_vector(IDX,7);
	constant loc_mx    : string := "SLICE_X"&itoa(LOC_X + 2 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_mx1   : string := "SLICE_X"&itoa(LOC_X + 3 - 2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx    : string := "SLICE_X"&itoa(LOC_X +     2 * MSLICE_ORIGIN)&"Y";
	constant loc_lx1   : string := "SLICE_X"&itoa(LOC_X + 1 + 2 * MSLICE_ORIGIN)&"Y";
	constant rthru_loc : string := loc_mx1 & itoa(LOC_Y) & ":" & loc_mx1 & itoa(LOC_Y+7);

	attribute LOC : string;
	attribute BEL : string;
	
	function csa_loc(n : integer) return string is
	begin	     
		if LOC_X = 64 then
			if n < 28 then
				return loc_lx1 & itoa(LOC_Y + n/4 + ((LOC_Y/8) rem 2));
			end if;
			return loc_me & itoa(LOC_Y + 7); -- At top position we place carry save adder
		end if;
		return loc_lx1 & itoa(LOC_Y + n/4);
	end function;
begin
	W_load_out <= W_load_d;
	W_load_v(7 downto 0) <= (others => W_load_lo);
	W_load_v(31 downto 8) <= (others => W_load_d);

	w1_ror7   <=  w1( 6 downto 0) &  w1(31 downto  7);
	w1_ror18  <=  w1(17 downto 0) &  w1(31 downto 18);
	w1_shr3   <=            "000" &  w1(31 downto  3);
	w14_ror17 <= w14(16 downto 0) & w14(31 downto 17);
	w14_ror19 <= w14(18 downto 0) & w14(31 downto 19);
	w14_shr10 <=     "0000000000" & w14(31 downto 10);

	csa1c(0) <= '0';
	csa2c(0) <= '0';
	carries(0) <= '0';

	BG: for i in 31 downto 0 generate -- Generate bit by bit carry save adders
		signal w9_async, w1_async, w9i, csa1sa, csa2sa, w1s : std_logic;
		constant loc_y4 : string := itoa(LOC_Y + i/4);          -- Y4 locations

		attribute LOC of SRLW9 : label is loc_mx & loc_y4;
		attribute LOC of SRLW1, SRLW1FD : label is loc_mx & loc_y4;
		attribute LOC of CSA1L5, CSA1FD5 : label is loc_mx1 & loc_y4;
		
		attribute LOC of CSA2L5, CSA2FD5 : label is csa_loc(i);

		attribute BEL of CSA2L5 : label is RBelNames(i rem 4) & "5LUT";
		attribute BEL of CSA1L5 : label is RBelNames(i rem 4) & "5LUT";
	begin
		SRLW9:  SRL16 port map (CLK => Clk, D => w14(i), Q => w9(i), A0 => '1', A1 => '0', A2 => '0', A3 => '1');
		-- Then we shift to depth 17 (16 + 1) in second SRL with flip flop
		SRLW1:  SRL16 port map (CLK => Clk, D => w9i, Q => w1_async, A0 => '1', A1 => '1', A2 => '1', A3 => '1');
		SRLW1FD: FD   port map (C => Clk, D => w1_async, Q => w1s);

		GSRLW9FD0: if (i rem 2) = 0 generate
			attribute LOC of SRLW9FD : label is loc_mx & loc_y4;
		begin
			SRLW9FD: FD port map (C => Clk, D => w9(i), Q => w9i);
			w0(i) <= w1s;
			w1(i) <= w1_async;
		end generate;

		GSRLW9FD1: if (i rem 2) = 1 generate
			w9i <= w9(i);
			w1(i) <= w1s;
			W0_out(i/2) <= w1s; -- Route through external register (16-bit)
			w0(i) <= W0_in(i/2);
		end generate;

		CSA1L5: LUT5 generic map (INIT => x"96696996")
			     port map (O => csa1sa, I0 => w14_ror17(i), I1 => w14_ror19(i), I2 => w14_shr10(i), I3 => w0(i), I4 => w9(i));
		CSA2L5: LUT5 generic map (INIT => x"96696996")
			     port map (O => csa2sa, I0 => w1_ror7(i), I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => csa1s(i), I4 => csa1c(i));

		CSA1FD5: FD port map (C => Clk, D => csa1sa, Q => csa1s(i));
		CSA2FD5: FD port map (C => Clk, D => csa2sa, Q => csa2s(i));

		G1FD6: if i < 31 generate
			signal csa1ca, csa2ca : std_logic;
			attribute LOC of CSA1L6, CSA1FD6 : label is loc_mx1 & loc_y4;
			attribute LOC of CSA2L6 : label is csa_loc(i);
			attribute BEL of CSA2L6 : label is RBelNames(i rem 4) & "6LUT";
			attribute BEL of CSA1L6 : label is RBelNames(i rem 4) & "6LUT";
		begin
			CSA1L6: LUT5 generic map (INIT => x"ff969600")
				     port map (O => csa1ca, I0 => w14_ror17(i), I1 => w14_ror19(i), I2 => w14_shr10(i), I3 => w0(i), I4 => w9(i));
			CSA1FD6: FD port map (C => Clk, D => csa1ca, Q => csa1c(i+1) );
			CSA2L6: LUT5 generic map (INIT => x"ff969600")
				     port map (O => csa2ca, I0 => w1_ror7(i), I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => csa1s(i), I4 => csa1c(i));
			CSA2FD6: FD port map (C => Clk, D => csa2ca, Q => csa2c(i+1));
		end generate;

		G1FDL: if i = 31 generate
			attribute LOC of LFDFL : label is rthru_loc;
			attribute LOC of W015 : label is csa_loc(i);
		begin
			LFDFL: FD port map (C => Clk, D => W_load, Q => W_load_d);
			W015: FD port map (C => Clk, D => W0_out(15), Q => W0_in(15));
		end generate;
	end generate;

	-- Generate round variant when there's enough size (no special)
	BGN: if LOC_X /= 64 generate
		attribute LOC of LOILU, LOILUF : label is loc_me & itoa(LOC_Y+1);
		signal sloilu : std_logic;
	begin
		B0_out <= '1'; -- Do nothing
		LOILU: LUT2 generic map (INIT => "0110") port map (O => sloilu, I1 => W_load, I0 => W_inject_d);
		LOILUF: FD port map (C => Clk, D => sloilu, Q => W_load_lo);
		
		RT: for i in 0 to 14 generate -- Generate route-through registers using
			attribute LOC of RTFD : label is loc_me & itoa(LOC_Y+i/2);
		begin
			RTFD: FD port map (C => Clk, D => W0_out(i), Q => W0_in(i));
		end generate;

		BGB: for i in 0 to 31 generate
			constant loc_y4 : string := itoa(LOC_Y + i/4);          -- Y4 locations
			signal addl5o, w14h1 : std_logic;
			attribute LOC of ADDL5, ADDL6  : label is loc_lx & loc_y4;
			attribute BEL of ADDL5  : label is BelNames(i rem 4) & "5LUT";
			attribute BEL of ADDL6  : label is BelNames(i rem 4) & "6LUT";
		begin
			-- ADDL6 calculates XOR
			ADDL6: LUT2 generic map ( INIT => "0110" ) port map ( O => addl6o(i), I1 => csa2c(i), I0 => csa2s(i) );

			-- ADDL5 calculates If[W_load_d,W_in(i),w14h1]
			ADDL5: LUT3 generic map ( INIT => "11001010") port map (O => addl5o, I2 => W_load_v(i), I1 => W_in(i), I0 => w14h1);

			-- Injection of index is done via SR pulse
			GFDN: if i >= 8 generate
				attribute LOC of ADDFD5, ADDFD : label is loc_lx & loc_y4;
			begin
				ADDFD5: FD port map (C => Clk, D => addl5o, Q => w14(i));
				ADDFD:  FD port map (C => Clk, D => sum(i), Q => w14h1);
			end generate;

			GFD: if (i > 0 and i < 8) generate
				GFD1: if idx_inject(i-1) = '1' generate
					attribute LOC of ADDFD5, ADDFD : label is loc_lx & loc_y4;
				begin
					ADDFD5: FDSE port map (CE => '1', S => W_inject_d, C => Clk, D => addl5o, Q => w14(i));
					ADDFD:  FDSE port map (CE => '1', S => W_inject_d, C => Clk, D => sum(i), Q => w14h1);
				end generate;
				GFD0: if idx_inject(i-1) = '0' generate
					attribute LOC of ADDFD5, ADDFD : label is loc_lx & loc_y4;
				begin
					ADDFD5: FDRE port map (CE => '1', R => W_inject_d, C => Clk, D => addl5o, Q => w14(i));
					ADDFD:  FDRE port map (CE => '1', R => W_inject_d, C => Clk, D => sum(i), Q => w14h1);
				end generate;
			end generate;

			GFD0: if i = 0 generate
				attribute LOC of ADDFD5, ADDFD : label is loc_lx & loc_y4;
			begin
				ADDFD5: FDRE port map (CE => '1', R => W_inject_d, C => Clk, D => addl5o, Q => w14(i));
				ADDFD:  FDSE port map (CE => '1', S => W_inject_d, C => Clk, D => sum(i), Q => w14h1);
			end generate;

			GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
				attribute LOC of C4 : label is loc_lx & loc_y4;
			begin
				C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csa2c(i+3 downto i),
						     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
			end generate;
		end generate;
	end generate;

	BGF: if LOC_X = 64 generate
		signal w14h1_0, csa2st, carry1 : std_logic;         -- Group of carries from secondary part
		signal sxor, ssuma, txor, tsuma, tsumf : std_logic_vector(3 downto 0);
		signal csa2cfilt : std_logic_vector(27 downto 0);
		attribute LOC of TC4 : label is loc_me & itoa(5 + LOC_Y);
		attribute LOC of SC4 : label is loc_me & itoa(3 + LOC_Y);
		attribute LOC of FD0T, LUT0T, LUT0TF : label is loc_me & itoa(1 + LOC_Y);
	begin
		B0_out <= W0_out(14); W0_in(14) <= B0_in; -- Route-through W0 register
		
		-- Add upper 4 bits of csa2s / csa2c
		GTADD: for i in 0 to 3 generate -- 4 registers for 4 higher bits and adder
			attribute LOC of ADDL6, ADDL5, ADDL6F, ADDL5F : label is loc_me & itoa(5 + LOC_Y);
			attribute BEL of ADDL6 : label is BelNames(i) & "6LUT";
			attribute BEL of ADDL5 : label is BelNames(i) & "5LUT";
			signal addl5o : std_logic;
		begin
			ADDL6: LUT2 generic map (INIT => "0110") port map (O => txor(i), I1 => csa2s(i+28), I0 => csa2c(i+28));
			ADDL5: LUT1 generic map (INIT => "10") port map (O => addl5o, I0 => W0_out(i+9));
			ADDL6F: FD port map (D => tsuma(i), Q => tsumf(i), C => Clk);
			ADDL5F: FD port map (D => addl5o, Q => W0_in(i+9), C => Clk);
		end generate;
		TC4: CARRY4 port map (CYINIT => '0', CI => '0', S => txor, DI => csa2s(31 downto 28), CO => open, O => tsuma);
		
		-- Then add with carry!
		GSADD: for i in 0 to 3 generate -- W output (4 bits) goes here!
			attribute LOC of ADDL6, ADDL6F : label is loc_me & itoa(3 + LOC_Y);
			attribute BEL of ADDL6 : label is BelNames(i) & "6LUT";
			signal addl5o : std_logic;
		begin
			ADDL6: LUT3 generic map (INIT => x"ca") port map (O => sxor(i), I2 => W_load_d, I1 => W_in(i+28), I0 => tsumf(i));
			ADDL6F: FD port map (D => ssuma(i), Q => w14(i+28), C => Clk);
			
			GF5: if i > 0 generate -- One flip-flop is isolated.
				attribute LOC of ADDL5, ADDL5F : label is loc_me & itoa(3 + LOC_Y);
				attribute BEL of ADDL5 : label is BelNames(i) & "5LUT";
			begin
				ADDL5: LUT1 generic map (INIT => "10") port map (O => addl5o, I0 => W0_out(i+5));
				ADDL5F: FD port map (D => addl5o, Q => W0_in(i+5), C => Clk);
			end generate;
		end generate;
		
		SC4: CARRY4 port map (CYINIT => '0', CI => carry1, S => sxor, DI => (others => '0'), CO => open, O => ssuma);
		
		RT1: for i in 0 to 5 generate -- (6 bits - lower route-through)
			attribute LOC of RTFD : label is loc_me & itoa(1+LOC_Y);
		begin
			RTFD: FD port map (C => Clk, D => W0_out(i), Q => W0_in(i));
		end generate;
		
		FD0T:  FD port map (C => Clk, D => csa2s(0), Q => csa2st);
		LUT0T: LUT3 generic map (INIT => x"ca") port map (O => w14h1_0, I2 => W_load_d, I1 => W_in(0), I0 => csa2st);
		LUT0TF: FD port map (C => Clk, D => w14h1_0, Q => w14(0));
		
		-- Process _first_ bit

		csa2cfilt(26 downto 0) <= csa2c(27 downto 1);
		csa2cfilt(27) <= '0';
		
		-- 27-bit adder (1..27) bits
		BGB: for i in 0 to 26 generate -- Generate 27 bits
			constant loc_y4 : string := itoa(LOC_Y + i/4 + ((LOC_Y/8) rem 2));          -- Y4 locations
			signal addl5o, w14h1 : std_logic;
			attribute LOC of ADDL5, ADDL6, ADDFD, ADDFD5  : label is loc_lx & loc_y4;
			attribute BEL of ADDL5  : label is BelNames(i rem 4) & "5LUT";
			attribute BEL of ADDL6  : label is BelNames(i rem 4) & "6LUT";
		begin
			GCF: if i = 26 generate
				attribute LOC of CFD, CL6, CL5, CL5FD : label is loc_lx & loc_y4; -- Place there 27th element
				attribute BEL of CL6 : label is "D6LUT";
				attribute BEL of CL5 : label is "D5LUT";
				signal addx : std_logic;
			begin
				-- If W_load is ONE then we supply '0' to carry output
				-- Otherwise we supply there '1'
				CL6: LUT1 generic map (INIT => "01") port map (O => addl6o(27), I0 => W_load);
				CL5: LUT1 generic map (INIT => "10") port map (O => addx, I0 => W0_out(13));
				CL5FD: FD port map (C => Clk, D => addx, Q => W0_in(13));
				CFD:  FD port map (C => Clk, D => carries(28), Q => carry1); -- Save carry output into register!
			end generate;

			-- ADDL6 calculates XOR
			ADDL6: LUT2 generic map ( INIT => "0110" ) port map ( O => addl6o(i), I1 => csa2c(i+1), I0 => csa2s(i+1) );

			-- ADDL5 calculates If[W_load_d,W_in(i),w14h1]
			ADDL5: LUT3 generic map ( INIT => "11001010") port map (O => addl5o, I2 => W_load_d, I1 => W_in(i+1), I0 => w14h1);
			
			-- No injection is performed (we expect that injection is done in other kernels)
			ADDFD5: FD port map (C => Clk, D => addl5o, Q => w14(i+1));
			ADDFD:  FD port map (C => Clk, D => sum(i), Q => w14h1);

			GC4: if (i rem 4) = 0 generate -- Generate CARRY4 element
				attribute LOC of C4 : label is loc_lx & loc_y4;
			begin
				C4: CARRY4 port map (CYINIT => '0', CI => carries(i), S => addl6o(i+3 downto i), DI => csa2cfilt(i+3 downto i),
						     CO => carries(i+4 downto i+1), O => sum(i+3 downto i));
			end generate;
		end generate;
	end generate;

	W_out <= w14;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_ARITH.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

-- 16 registers placed at upper part.
-- Comparator placed at lower part. (7 output bits).

entity SHA_Match is
	generic (
		LOC_X			: integer := 0;
		LOC_Y			: integer := 24; -- Y position
		IDX			: integer := 0
	);
	port (
		Clk			: in  std_logic;
		E_in			: in  std_logic_vector(31 downto 0);
		C_in			: in  std_logic_vector(10 downto 0);
		C_out			: out std_logic_vector(10 downto 0);
		A_sel_out		: out std_logic_vector( 3 downto 0);
		Imatch_in		: in  std_logic;
		Imatch_out		: out std_logic
	);
end SHA_Match;

-- We compare E_in with A4 1F 32 E7
-- 1010 0100 0001 1111 0011 0010 1110 0111
architecture PHYLOC of SHA_Match is
	attribute LOC : string;
	attribute BEL : string;
	constant loc_lx : string := "SLICE_X"&itoa(LOC_X)&"Y";

	constant reg1_loc : string := loc_lx&itoa(LOC_Y+4);
	constant reg2_loc : string := loc_lx&itoa(LOC_Y+5);
	constant reg3_loc : string := loc_lx&itoa(LOC_Y+6);
	constant reg4_loc : string := loc_lx&itoa(LOC_Y+7);
	type cmpvec_type is array (0 to 7) of bit_vector(15 downto 0);

	constant cmpvec : cmpvec_type := (
		"0000000010000000", -- 0111   7
		"0100000000000000", -- 1110  14
		"0000000000000100", -- 0010   2
		"0000000000001000", -- 0011   3
		"1000000000000000", -- 1111  15
		"0000000000000010", -- 0001   1
		"0000000000010000", -- 0100   4
		"0000010000000000"  -- 1010  10
--                    1         0
--               5432109876543210
	);

	signal carry : std_logic_vector(8 downto 0);
	signal match : std_logic := '0';

	signal C_reg : std_logic_vector(10 downto 0);
	signal AS_in, AS_reg : std_logic_vector(5 downto 0); -- 6 registers

	signal AS_treg : std_logic_vector(3 downto 0);

	constant idx_vec : std_logic_vector(5 downto 0) := conv_std_logic_vector(IDX, 6);

	function gmut_init(n : integer) return bit_vector is
	begin
		if n = 0 then
			return "00110010"; -- If match is '1' then return zero, if Imatch is 1 return 1, otherwise return C_in!
		end if;
		if idx_vec(n) = '1' then
			return "11111110"; -- Return '1' if any matched, otherwise return C_in
		end if;
		return "00000010"; -- Return '0' if any matched, otherwise return C_in
	end function;

	attribute LOC of FDAS1 : label is reg2_loc;
begin
	carry(0) <= C_reg(4); -- Match enable signal
	AS_in( 5 downto 2) <=   C_in( 3 downto 0); -- E_sel (full copy)
	C_reg( 3 downto 0) <= AS_reg( 5 downto 2);
	AS_in(0) <= AS_treg(2); A_sel_out(2) <= AS_reg(0);
	AS_in(1) <= AS_treg(3); A_sel_out(3) <= AS_reg(1);

	FDAS1: FD port map (C => Clk, D => AS_treg(0), Q => A_sel_out(0));
	A_sel_out(1) <= AS_treg(1);

	-- Generate match signals!
	GCMP: for i in 0 to 7 generate
		signal o6, o5 : std_logic;
		constant loc_ly : string := loc_lx&itoa(LOC_Y+i/4+1);
		attribute BEL of L6 : label is BelNames(i rem 4) & "6LUT";
		attribute LOC of L6, MUX : label is loc_ly;
	begin
		L6: LUT4 generic map (INIT => cmpvec(i)) port map (O => o6, I3 => E_in(i*4+3), I2 => E_in(i*4+2), I1 => E_in(i*4+1), I0 => E_in(i*4));
		GLFD0: if i = 1 generate -- Place it especially near carry chain, so its output will go directly to input AX!
			attribute BEL of L5 : label is BelNames(i rem 4) & "5LUT";
			attribute LOC of L5, L5FD : label is loc_ly;
		begin
			L5: LUT1 generic map (INIT => "10") port map (O => o5, I0 => C_in(4));
			L5FD: FD port map (C => Clk, D => o5, Q => C_reg(4));
		end generate;

		GLFD1: if i > 1 generate -- Put A_sel and E_sel at the bottom (otherwise timing will be not met!)
			attribute BEL of L5 : label is BelNames(i rem 4) & "5LUT";
			attribute LOC of L5, L5FD : label is loc_ly;
		begin
			L5: LUT1 generic map (INIT => "10") port map (O => o5, I0 => AS_in(i-2));
			L5FD: FD port map (C => Clk, D => o5, Q => AS_reg(i-2));
		end generate;

		MUX: MUXCY port map (S => o6, DI => '0', CI => carry(i), O => carry(i+1));

		GMUXFD: if i = 7 generate
			attribute LOC of MUXFD : label is loc_ly;
		begin
			MUXFD: FD port map (C => Clk, D => carry(8), Q => match);
		end generate;
	end generate;
	Imatch_out <= match; -- Found MATCH condition (when C_reg(22) marked!)

	GFD1: for i in 0 to 3 generate
		attribute LOC of CFD : label is reg1_loc;
	begin
		CFD: FD port map (C => clk, D => C_reg(i), Q => AS_treg(i)); -- Generate delay for A_sel part!
	end generate;

	-- Emerge set of MUXes and flip-flops that route address enables!
	GMUC3: for i in 0 to 1 generate
		signal luto : std_logic;
		attribute LOC of MLUT, MLUTFD : label is reg3_loc;
	begin
		MLUT: LUT3 generic map (INIT => gmut_init(i)) port map (O => luto, I2 => Imatch_in, I1 => match, I0 => C_in(i+5));
		MLUTFD: FD generic map (INIT => '0') port map (C => clk, D => luto, Q => C_reg(i+5));
	end generate;

	-- Emerge set of MUXes
	GMUC4: for i in 2 to 5 generate
		signal luto : std_logic;
		attribute LOC of MLUT, MLUTFD : label is reg4_loc;
	begin
		MLUT: LUT3 generic map (INIT => gmut_init(i)) port map (O => luto, I2 => Imatch_in, I1 => match, I0 => C_in(i+5));
		MLUTFD: FD generic map (INIT => '0') port map (C => clk, D => luto, Q => C_reg(i+5));
	end generate;
	
	C_out <= C_reg;
end PHYLOC;

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;
library WORK;
	use WORK.SHASerialLOC_lib.All;

entity SHA_Kernel is
	generic (
		IDX			: integer := 0;
		LOC_X			: integer := 3;
		LOC_Y			: integer := 24 -- Y position
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
end SHA_Kernel;

architecture PHYLOC of SHA_Kernel is
	type P_type is array(0 to 4) of integer;

	constant ABCD1_P  : P_type := ( 34,  44,  94, 104, 24);
	constant ABCD1_M  : P_type := (  0,   1,   1,   1,  0);
	constant AUX1_P   : P_type := ( 32,  42,  88, 102, 32);
	constant EFG1_P   : P_type := ( 28,  38,  90,  98, 28);
	constant EFG1_M   : P_type := (  0,   0,   1,   0,  0);
	constant REXP1_P  : P_type := ( 24,  48,  84, 108, 20);
	constant REXP1_M  : P_type := (  0,   1,   1,   1,  0);
	constant XFER_P   : P_type := ( 22,  52,  80, 112, 18);
	constant AUX0_P   : P_type := ( 20,  54,  82, 114, 16);
	constant ABCD0_P  : P_type := ( 16,  56,  76, 116, 12);
	constant ABCD0_M  : P_type := (  0,   1,   1,   1,  0);
	constant EFG0_P   : P_type := ( 12,  60,  72, 120,  8);
	constant EFG0_M   : P_type := (  0,   1,   1,   1,  0);
	constant REXP0_P  : P_type := (  8,  64,  68, 124,  4);
	constant REXP0_M  : P_type := (  0,   1,   1,   1,  0);

	signal W1a, W1r : std_logic_vector(47 downto 0);

 	-- 29-bit register (A_sel is delayed "in-place")
	signal C_reg : std_logic_vector(28 downto 0);
	
	signal B0_out : std_logic;

	signal A0M, E0M, A0, C0, E0, G0, D0, AX0, W0, K : std_logic_vector(31 downto 0);
	signal W1, C1, E1, G1, D1, AX1 : std_logic_vector(31 downto 0);
	signal A_sel, dummy1 : std_logic_vector(3 downto 0);

	attribute LOC : string;
	constant e_me : integer := EFG0_P(LOC_X) + 2 - 2 * EFG0_M(LOC_X);
begin
	-- Instances written in this code in LAYOUT order!
	-- Layout contains re-ordering in a way that ensures SINGLE interconnect usage
	-- between slices in round-expander and rounds. It is extremely important, otherwise timing
	-- will not be met!

	REXP0: SHA_RoundExpander_Pri generic map (MSLICE_ORIGIN => REXP0_M(LOC_X), LOC_X => REXP0_P(LOC_X), IDX => IDX, LOC_Y => LOC_Y, LOC_E => e_me)
		port map ( Clk => Clk, W_load => C_in(0), W_inject => C_in(1), W_load_out => C_reg(0), W_inject_d => C_reg(1),
		           W_in => W_in, W_out => W0, B0_out => B0_out, B0_in => dummy1(3));

	EFG0: SHA_HalfRound generic map (LOC_X => EFG0_P(LOC_X), LOC_Y => LOC_Y, MSLICE_ORIGIN => EFG0_M(LOC_X), IS_ABCD => 0)
		port map ( Clk => Clk, A_load => C_in(2), A_load_out => C_reg(2), A_in => E0M, ES_in => C0, EC_in => AX0,
		        A_out => E0, B_out => open, C_out => G0, D_out => open);

	ABCD0: SHA_HalfRound generic map (LOC_X => ABCD0_P(LOC_X), LOC_Y => LOC_Y, MSLICE_ORIGIN => ABCD0_M(LOC_X), IS_ABCD => 1)
		port map ( Clk => Clk, A_load => C_in(3), A_load_out => C_reg(3), A_in => A0M, ES_in => D0, EC_in => E0,
		        A_out => A0, B_out => open, C_out => C0, D_out => D0);

	-- Via AUX0 round part of C_reg is passed!
	AUX0: SHA_AUXRound generic map (LOC_X => AUX0_P(LOC_X), LOC_Y => LOC_Y)
		port map ( Clk => Clk, G_in => G0, K_in => K, W_in => W0, S_out => AX0, RC_in => '1', RC_out => open,
			R_in(31) => B0_out,      R_in(30) => W1a(15), 
			R_in(29) => C_in(15),    R_in(28) => W1a(14), 
			R_in(27) => C_in(14),    R_in(26) => W1a(13), 
			R_in(25) => C_in(13),    R_in(24) => W1a(12), 
			R_in(23) => C_in(12),    R_in(22) => W1a(11), 
			R_in(21) => C_in(11),    R_in(20) => W1a(10), 
			R_in(19) => C_in(10),    R_in(18) => W1a( 9), 
			R_in(17) => C_in( 9),    R_in(16) => W1a( 8), 
			R_in(15) => C_in( 8),    R_in(14) => W1a( 7), 
			R_in(13) => C_in( 7),    R_in(12) => W1a( 6), 
			R_in(11) => C_in( 6),    R_in(10) => W1a( 5), 
			R_in( 9) => C_in( 5),    R_in( 8) => W1a( 4), 
			R_in( 7) => C_in( 4),    R_in( 6) => W1a( 3), 
			R_in( 5) => W_in( 7),    R_in( 4) => W1a( 2), 
			R_in( 3) => C_in(16),    R_in( 2) => W1a( 1), 
			R_in( 1) => C_in( 1),    R_in( 0) => W1a( 0), 		
			R_out(31) => dummy1(3), R_out(30) => W1r(15),
			R_out(29) => C_reg(15), R_out(28) => W1r(14),
			R_out(27) => C_reg(14), R_out(26) => W1r(13),
			R_out(25) => C_reg(13), R_out(24) => W1r(12),
			R_out(23) => C_reg(12), R_out(22) => W1r(11),
			R_out(21) => C_reg(11), R_out(20) => W1r(10),
			R_out(19) => C_reg(10), R_out(18) => W1r( 9),
			R_out(17) => C_reg( 9), R_out(16) => W1r( 8),
			R_out(15) => C_reg( 8), R_out(14) => W1r( 7),
			R_out(13) => C_reg( 7), R_out(12) => W1r( 6),
			R_out(11) => C_reg( 6), R_out(10) => W1r( 5),
			R_out( 9) => C_reg( 5), R_out( 8) => W1r( 4),
			R_out( 7) => C_reg( 4), R_out( 6) => W1r( 3),
			R_out( 5) => dummy1(2), R_out( 4) => W1r( 2),
			R_out( 3) => dummy1(1), R_out( 2) => W1r( 1),
			R_out( 1) => C_reg( 1), R_out( 0) => W1r( 0) );
	
	-- W(7) signal is bypassed AS IS.
	W_out <= W0;
	Wl_out(7) <= dummy1(2);
	Wl_out( 6 downto 0) <= W0( 6 downto 0);
	Wl_out(31 downto 8) <= W0(31 downto 8);
			
	-- Via XFER registers we pass part of REXP1 register
	XFER: SHA_XferData generic map (LOC_M => XFER_P(LOC_X), LOC_X => XFER_P(LOC_X)+1, LOC_Y => LOC_Y)
		port map ( Clk => Clk, A_in => A0, E_in => E0, A_mem => A0M, E_mem => E0M, R_in => W1a(47 downto 16),
			R_out => W1r(47 downto 16), Prog_Sel => C_reg(17), Prog_Data => C_reg(16), R_rst => C_reg(5),
			AddrA_in => C_reg(13 downto 10),  AddrE_in => C_reg(9 downto 6), A_we => C_reg(15), E_we => C_reg(14) );

	REXP1: SHA_RoundExpander_Sec generic map (MSLICE_ORIGIN => REXP1_M(LOC_X), LOC_X => REXP1_P(LOC_X), LOC_Y => LOC_Y)
		port map ( Clk => Clk, W1_in => A0M, W2_in => E0M, W_load => C_in(16), W_load_out => C_reg(16), W_load_ds => dummy1(1),
		           R_in => C_in(17), R_out => C_reg(17), W_out => W1, W0_out => W1a, W0_in => W1r, Ws_load => C_reg(4) );

	EFG1: SHA_HalfRound_K generic map (LOC_X => EFG1_P(LOC_X), LOC_Y => LOC_Y, MSLICE_ORIGIN => EFG1_M(LOC_X), IS_ABCD => 0, K => HGFE_const)
		port map ( Clk => Clk, A_sel1_out => C_out(19), ES_in => C1, EC_in => AX1, 
		A_out => E1, B_out => open, C_out => G1, D_out => open, 
		A_sel(3) => C_reg(21), A_sel(2) => C_reg(20), A_sel(1) => C_in(19), A_sel(0) => C_reg(18));

	AUX1: SHA_AUXRound generic map (LOC_X => AUX1_P(LOC_X), LOC_Y => LOC_Y)
		port map ( Clk => Clk, G_in => G1, K_in => K, W_in => W1, S_out => AX1, R_in => K_in, R_out => K, RC_in => '1', RC_out => open);

	ABCD1: SHA_HalfRound_K generic map (LOC_X => ABCD1_P(LOC_X), LOC_Y => LOC_Y, MSLICE_ORIGIN => ABCD1_M(LOC_X), IS_ABCD => 1, K => DCBA_const)
		port map ( Clk => Clk, A_sel1_out => open, ES_in => D1, EC_in => E1, 
		        A_out => open, B_out => open, C_out => C1, D_out => D1, A_sel => A_sel);

	MATCH: SHA_Match generic map (LOC_X => EFG1_P(LOC_X) + 2 - 2*EFG1_M(LOC_X), LOC_Y => LOC_Y, IDX => IDX)
		port map ( Clk => Clk, E_in => E1, C_in => C_in(28 downto 18), C_out => C_reg(28 downto 18), A_sel_out => A_sel, Imatch_in => Imatch_in,
			Imatch_out => Imatch_out );

	K_out <= K;
	
	-- This is required patch for multi-phase (12-phase) system
	-- Because C_reg(19) causes multiple timing failures otherwise
	C_out(18 downto 0) <= C_reg(18 downto 0);
	C_out(28 downto 20) <= C_reg(28 downto 20);
end PHYLOC;
