--
-- Copyright 2012 www.bitfury.org
--
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

-- Secondary SHA256 core
entity SHA_Secondary is
	port (
		Clk			: in  std_logic;
		ProgC			: in  std_logic;
		ProgD			: in  std_logic;
		S_in			: in  std_logic_vector(255 downto 0);
		Match			: out std_logic
	);
end SHA_Secondary;

architecture RTL of SHA_Secondary is
	type S_array_type is array (0 to 63) of std_logic_vector(255 downto 0);
	type W_array_type is array (0 to 63) of std_logic_vector(511 downto 0);
	type k_array_type is array(0 to 63) of std_logic_vector(31 downto 0);
	constant SHA_IV : std_logic_vector(255 downto 0) := x"5be0cd19_1f83d9ab_9b05688c_510e527f_a54ff53a_3c6ef372_bb67ae85_6a09e667";
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
	signal S : S_array_type;
	signal W : W_array_type;
	signal Ws, Wi : k_array_type;

	signal MS0_in : std_logic_vector(255 downto 0);

	signal H : std_logic_vector(31 downto 0);
	signal m : std_logic_vector(13 downto 0); -- m shifter
begin
	FDMS0: FD port map (C => ProgC, D => ProgD, Q => MS0_in(0));
	BGMS0: for i in 0 to 254 generate
	begin
		FMS0: FD port map (C => ProgC, D => MS0_in(i), Q => MS0_in(i+1));
	end generate;

	-- Add two of them
	process (Clk) begin
		if rising_edge(Clk) then
			Wi(0) <= Ws(0) + MS0_in(32*0 + 31 downto 32*0);
			Wi(1) <= Ws(1) + MS0_in(32*1 + 31 downto 32*1);
			Wi(2) <= Ws(2) + MS0_in(32*2 + 31 downto 32*2);
			Wi(3) <= Ws(3) + MS0_in(32*3 + 31 downto 32*3);
			Wi(4) <= Ws(4) + MS0_in(32*4 + 31 downto 32*4);
			Wi(5) <= Ws(5) + MS0_in(32*5 + 31 downto 32*5);
			Wi(6) <= Ws(6) + MS0_in(32*6 + 31 downto 32*6);
			Wi(7) <= Ws(7) + MS0_in(32*7 + 31 downto 32*7);
		end if;
	end process;

	-- SHIFT INPUTS
	BG: for i in 0 to 31 generate
		signal At, Bt, Ct, Dt, Et, Ft, Gt, Ht : std_logic;
	begin
		SRLA: SRL16 port map (Q => At, CLK => Clk, A3 => '0', A2 => '0', A1=> '0', A0 => '0', D => S_in(i));
		SRLAF: FD port map (D => At, Q => Ws(0)(i), C => Clk);
		SRLE: SRL16 port map (Q => Et, CLK => Clk, A3 => '0', A2 => '1', A1=> '0', A0 => '1', D => S_in(128+i));
		SRLEF: FD port map (D => Et, Q => Ws(4)(i), C => Clk);

		SRLB: SRL16 port map (Q => Bt, CLK => Clk, A3 => '0', A2 => '0', A1=> '1', A0 => '0', D => S_in(32+i));
		SRLBF: FD port map (D => Bt, Q => Ws(1)(i), C => Clk);
		SRLF: SRL16 port map (Q => Ft, CLK => Clk, A3 => '0', A2 => '1', A1=> '1', A0 => '1', D => S_in(160+i));
		SRLFF: FD port map (D => Ft, Q => Ws(5)(i), C => Clk);

		SRLC: SRL16 port map (Q => Ct, CLK => Clk, A3 => '0', A2 => '1', A1=> '0', A0 => '0', D => S_in(64+i));
		SRLCF: FD port map (D => Ct, Q => Ws(2)(i), C => Clk);
		SRLG: SRL16 port map (Q => Gt, CLK => Clk, A3 => '1', A2 => '0', A1=> '0', A0 => '1', D => S_in(192+i));
		SRLGF: FD port map (D => Gt, Q => Ws(6)(i), C => Clk);

		SRLD: SRL16 port map (Q => Dt, CLK => Clk, A3 => '0', A2 => '1', A1=> '1', A0 => '0', D => S_in(96+i));
		SRLDF: FD port map (D => Dt, Q => Ws(3)(i), C => Clk);
		SRLH: SRL16 port map (Q => Ht, CLK => Clk, A3 => '1', A2 => '0', A1=> '1', A0 => '1', D => S_in(224+i));
		SRLHF: FD port map (D => Ht, Q => Ws(7)(i), C => Clk);
	end generate;

	Wi(8) <= x"80000000"; Wi(14 downto 0) <= (others => x"00000000"); Wi(15) <= x"00000100";

	RNDS: entity WORK.SHA_Round port map (Clk => Clk, S_in => SHA_IV, S_out => S(0), W_in => Wi(0), K_in => SHA_Consts(0));

	GR1: for i in 1 to 13 generate
		RND: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(i-1), S_out => S(i), W_in => Wi(i), K_in => SHA_Consts(i));
	end generate;

	process (Clk) begin if rising_edge(Clk) then S(14) <= S(13); end if; end process;

	BG1: for i in 0 to 31 generate
		signal At, Bt, Ct, Dt, Et, Ft, Gt, Ht : std_logic;
	begin
		SRLA: SRL16 port map (Q => At, CLK => Clk, A3 => '0', A2 => '0', A1=> '0', A0 => '0', D => Wi(0)(i));
		SRLAF: FD port map (D => At, Q => W(16)(i), C => Clk);
		SRLE: SRL16 port map (Q => Et, CLK => Clk, A3 => '0', A2 => '1', A1=> '0', A0 => '1', D => Wi(4)(i));
		SRLEF: FD port map (D => Et, Q => W(16)(i+32*4), C => Clk);

		SRLB: SRL16 port map (Q => Bt, CLK => Clk, A3 => '0', A2 => '0', A1=> '1', A0 => '0', D => Wi(1)(i));
		SRLBF: FD port map (D => Bt, Q => W(16)(i+32), C => Clk);
		SRLF: SRL16 port map (Q => Ft, CLK => Clk, A3 => '0', A2 => '1', A1=> '1', A0 => '1', D => Wi(5)(i));
		SRLFF: FD port map (D => Ft, Q => W(16)(i+32*5), C => Clk);

		SRLC: SRL16 port map (Q => Ct, CLK => Clk, A3 => '0', A2 => '1', A1=> '0', A0 => '0', D => Wi(2)(i));
		SRLCF: FD port map (D => Ct, Q => W(16)(i+32*2), C => Clk);
		SRLG: SRL16 port map (Q => Gt, CLK => Clk, A3 => '1', A2 => '0', A1=> '0', A0 => '1', D => Wi(6)(i));
		SRLGF: FD port map (D => Gt, Q => W(16)(i+32*6), C => Clk);

		SRLD: SRL16 port map (Q => Dt, CLK => Clk, A3 => '0', A2 => '1', A1=> '1', A0 => '0', D => Wi(3)(i));
		SRLDF: FD port map (D => Dt, Q => W(16)(i+32*3), C => Clk);
		SRLH: SRL16 port map (Q => Ht, CLK => Clk, A3 => '1', A2 => '0', A1=> '1', A0 => '1', D => Wi(7)(i));
		SRLHF: FD port map (D => Ht, Q => W(16)(i+32*7), C => Clk);
	end generate;

	W(16)(31+32*8 downto 32*8)   <= x"80000000";
	W(16)(31+32*9 downto 32*9)   <= x"00000000";
	W(16)(31+32*10 downto 32*10) <= x"00000000";
	W(16)(31+32*11 downto 32*11) <= x"00000000";
	W(16)(31+32*12 downto 32*12) <= x"00000000";
	W(16)(31+32*13 downto 32*13) <= x"00000000";
	W(16)(31+32*14 downto 32*14) <= x"00000000";
	W(16)(31+32*15 downto 32*15) <= x"00000100";

	-- Next stage
	RND14: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(14), S_out => S(15), W_in => Wi(14), K_in => SHA_Consts(14));
	RND15: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(15), S_out => S(16), W_in => Wi(15), K_in => SHA_Consts(15));

	GR2: for i in 17 to 38 generate
		RND: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(i-1), S_out => S(i), W_in => W(i)(511 downto 480), K_in => SHA_Consts(i-1));
		WRN: entity WORK.SHA_WRound port map (Clk => Clk, W_in => W(i-1), W_out => W(i));
	end generate;

	process (Clk) begin if rising_edge(Clk) then S(39) <= S(38); W(39) <= W(38); end if; end process;

	GR3: for i in 40 to 62 generate
		RND: entity WORK.SHA_Round  port map (Clk => Clk, S_in => S(i-1), S_out => S(i), W_in => W(i)(511 downto 480), K_in => SHA_Consts(i-2));
		WRN: entity WORK.SHA_WRound port map (Clk => Clk, W_in => W(i-1), W_out => W(i));
	end generate;

	-- Perform MATCH
	H <= S(62)(159 downto 128);
	LM1: LUT6 generic map (INIT => x"0000008000000000") port map (O => m(0), I5 => H(5), I4 => H(4), I3 => H(3), I2 => H(2), I1 => H(1), I0 => H(0));
	LM2: LUT6 generic map (INIT => x"0000000000000800") port map (O => m(1), I5 => H(11), I4 => H(10), I3 => H(9), I2 => H(8),  I1 => H(7),  I0 => H(6));
	LM3: LUT6 generic map (INIT => x"0008000000000000") port map (O => m(2), I5 => H(17), I4 => H(16), I3 => H(15), I2 => H(14), I1 => H(13), I0 => H(12));
	LM4: LUT6 generic map (INIT => x"0000000000000080") port map (O => m(3), I5 => H(23), I4 => H(22), I3 => H(21), I2 => H(20), I1 => H(19), I0 => H(18));
	LM5: LUT6 generic map (INIT => x"0000001000000000") port map (O => m(4), I5 => H(29), I4 => H(28), I3 => H(27), I2 => H(26), I1 => H(25), I0 => H(24));
	LM6: LUT2 generic map (INIT => "0100") port map (O => m(5), I1 => H(31), I0 => H(30));
	LM1F: FD port map (C => Clk, D => m(0), Q => m(6));
	LM2F: FD port map (C => Clk, D => m(1), Q => m(7));
	LM3F: FD port map (C => Clk, D => m(2), Q => m(8));
	LM4F: FD port map (C => Clk, D => m(3), Q => m(9));
	LM5F: FD port map (C => Clk, D => m(4), Q => m(10));
	LM6F: FD port map (C => Clk, D => m(5), Q => m(11));
	LM7: LUT6 generic map (INIT => x"8000000000000000") port map (O => m(12), I5 => m(6), I4 => m(7), I3 => m(8), I2 => m(9), I1 => m(10), I0 => m(11));
	LM7F: FD port map (C => Clk, D => m(12), Q => m(13));
	Match <= m(13);
end RTL;
