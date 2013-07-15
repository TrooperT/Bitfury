--
-- Copyright 2012 www.bitfury.org
--
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

-- Primary SHA256 core
entity SHA_Primary is
	generic (
		NONCE_START		: std_logic_vector(31 downto 0) := x"12341234"
	);
	port (
		Clk			: in  std_logic;
		ProgC			: in  std_logic;
		ProgD			: in  std_logic;
		S_out			: out std_logic_vector(255 downto 0)
	);
end SHA_Primary;

architecture RTL of SHA_Primary is
	type S_array_type is array (0 to 63) of std_logic_vector(255 downto 0);
	type W_array_type is array (0 to 63) of std_logic_vector(511 downto 0);
	type k_array_type is array(0 to 63) of std_logic_vector(31 downto 0);
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
	signal Wi : k_array_type;

	signal W_in : std_logic_vector(95 downto 0);
	signal MS3_in : std_logic_vector(255 downto 0);
	signal ps1 : std_logic_vector(7 downto 0);
	signal ps2 : std_logic_vector(15 downto 0);
	signal Nonce1, Nonce2 : std_logic_vector(31 downto 0);
begin
	-- ProgD input shifter
	S1B: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps1(0), A => "11111", CE => '1', Clk => ProgC, D => ProgD);
	S2B: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps2(0), A => "11111", CE => '1', Clk => ProgC, D => ProgD);
	GS1: for i in 1 to 6 generate
		S1M: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps1(i), A => "11111", CE => '1', Clk => ProgC, D => ps1(i-1));
	end generate;
	GS2: for i in 1 to 14 generate
		S2M: SRLC32E generic map (INIT => x"00000000") port map (Q => open, Q31 => ps2(i), A => "11111", CE => '1', Clk => ProgC, D => ps2(i-1));
	end generate;
	S1E: SRLC32E generic map (INIT => x"00000000") port map (Q => ps1(7), Q31 => open, A => "11111", CE => '1', Clk => ProgC, D => ps1(6));
	S2E: SRLC32E generic map (INIT => x"00000000") port map (Q => ps2(15), Q31 => open, A => "11111", CE => '1', Clk => ProgC, D => ps2(14));

	FDMS3: FD port map (C => ProgC, D => ps1(7), Q => S(0)(0));
	FDWIN: FD port map (C => ProgC, D => ps2(15), Q => W_in(0));
	GFWIN: for i in 0 to 94 generate
		FWIN: FD port map (C => ProgC, D => W_in(i), Q => W_in(i+1));
	end generate;
	GFMS3: for i in 0 to 254 generate
		GFMS3: FD port map (C => ProgC, D => S(0)(i), Q => S(0)(i+1));
	end generate;

	N1G: entity WORK.SHA_NonceCtr generic map (NONCE_START => NONCE_START) port map (Clk => Clk, ProgC => ProgC, N_out => Nonce1);
	N2G: entity WORK.SHA_NonceCtr generic map (NONCE_START => NONCE_START) port map (Clk => Clk, ProgC => ProgC, N_out => Nonce2);

	-- First part - initial 13 rounds
	-- 61 rounds total, 47 rounds supp.

	Wi(1) <= Nonce1;
	Wi(2) <= x"80000000";
	Wi(3 to 12) <= (others => x"00000000");
	Wi(13) <= x"00000280";
	Wi(14) <= W_in(95 downto 64);

	GR1: for i in 1 to 14 generate
		RND: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(i-1), S_out => S(i), W_in => Wi(i), K_in => SHA_Consts(i+2));
	end generate;

	process (Clk) begin if rising_edge(Clk) then S(15) <= S(14); end if; end process;

	-- Proper time shifting for NONCE_START of SHA_NonceCtr (second)
	W(15) <= W_in(95 downto 64) & x"00000280" & x"00000000"& x"00000000"& x"00000000"& x"00000000"& x"00000000"& x"00000000"
		 & x"00000000"& x"00000000"& x"00000000"& x"00000000"& x"80000000"& Nonce2 & W_in(63 downto 32) & W_in(31 downto 0);

	GR2: for i in 16 to 38 generate
		RND: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(i-1), S_out => S(i), W_in => W(i)(511 downto 480), K_in => SHA_Consts(i+1));
		W(i)(511 downto 480) <= S(i-1)(159 downto 128); -- Feed E there!
--		WRN: entity WORK.SHA_WRound port map (Clk => Clk, W_in => W(i-1), W_out => W(i));
	end generate;

	S_out <= S(38);


--	process (Clk) begin if rising_edge(Clk) then S(39) <= S(38); W(39) <= W(38); end if; end process;

--	GR3: for i in 40 to 63 generate
--		RND: entity WORK.SHA_Round port map (Clk => Clk, S_in => S(i-1), S_out => S(i), W_in => W(i)(511 downto 480), K_in => SHA_Consts(i));
--		WRN: entity WORK.SHA_WRound port map (Clk => Clk, W_in => W(i-1), W_out => W(i));
--	end generate;

--	S_out <= S(60)(159 downto 128) & S(61)(159 downto 128) & S(62)(159 downto 128) & S(63)(159 downto 128) &
--	         S(60)(31  downto 0  ) & S(61)(31  downto 0  ) & S(62)(31  downto 0)   & S(63)(31 downto 0);
end RTL;
