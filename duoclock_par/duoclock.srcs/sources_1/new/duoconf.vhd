--
-- Copyright 2012 www.bitfury.org
--

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_FC_Config is
	generic (
		NONCE_START		: std_logic_vector(31 downto 0)
	);
	port (
		-- Input - main clocks
		ClkS			: in  std_logic;
		ClkTX			: in  std_logic;

		-- Input (from interface) - programming
		MC_A			: in  std_logic_vector( 5 downto 0);
		MC_D			: in  std_logic_vector(31 downto 0);

		-- Output (to cores) - programming
		ProgC			: out std_logic;
		ProgD			: out std_logic;

		-- Input MATCH core
		MatchCoreEven		: in  std_logic; -- Even 2,4,...
		MatchCoreOdd		: in  std_logic;
	
		-- Stacked input
		Match_has_in		: in  std_logic;
		Match_data_in		: in  std_logic_vector(31 downto 0);

		-- Stacked output
		Match_has_out		: out std_logic;
		Match_data_out		: out std_logic_vector(31 downto 0);
		ScanDone		: out std_logic
	);
end SHA_FC_Config;

architecture RTL of SHA_FC_Config is
	attribute keep_hierarchy : string;
	attribute keep_hierarchy of RTL : architecture is "true";

	type prog_mem_type is array(0 to 31) of std_logic_vector(31 downto 0);
	signal prog_mem : prog_mem_type := (others => x"00000000");
	attribute ram_style : string;
	attribute ram_style of prog_mem : signal is "distributed";

	signal MemAddr, RdAddr  : std_logic_vector(4 downto 0);
	signal W0, W16, CurNonce, RdData : std_logic_vector(31 downto 0);
	signal w1_ror7, w1_ror18, w1_shr3 : std_logic_vector(31 downto 0);

	signal BitCnt : std_logic_vector(9 downto 0) := (others => '1');
	signal ShReg  : std_logic_vector(31 downto 0); -- Output shift register
	signal RdR, ProgCP, ProgCN, PROGCNA, PROGCPA, ProgCO, ProgCG : std_logic;
	signal MatchSA, MatchSA1, MatchSA2, MatchSA3, Match_has : std_logic := '0';
	signal MatchSample, MatchSample1, Match_data : std_logic_vector(31 downto 0) := (others => '0');
begin
	MemAddr <= MC_A(4 downto 0) when MC_A(5) = '1' else RdAddr;

	-- Calculate W16 (and store MC_D into registers when there is proper activation)
	w1_ror7  <= MC_D(6 downto 0) & MC_D(31 downto 7);
	w1_ror18 <= MC_D(17 downto 0) & MC_D(31 downto 18);
	w1_shr3  <= "000" & MC_D(31 downto 3);
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			if MC_A = "110000" then W0 <= MC_D; else W0 <= W0; end if;
			if MC_A = "110001" then W16 <= W0 + (w1_ror7 xor w1_ror18 xor w1_shr3); else W16 <= W16; end if;
		end if;
	end process;

	-- Write to program memory
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			if MC_A(5) = '1' then
				prog_mem(conv_integer(MemAddr)) <= MC_D; -- Store data into memory
			end if;
			RdData <= prog_mem(conv_integer(MemAddr));
		end if;
	end process;

	-- Programming bit counter
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			if MC_A(5) = '1' then
				bitcnt <= "1001011111";
			elsif   bitcnt /= "1111111110" then
				bitcnt <= bitcnt - 1;
			else
				bitcnt <= bitcnt;
			end if;
		end if;
	end process;

	-- Decode correct address
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			case bitcnt(9 downto 5) is
				when "10010" => RdAddr <= "10010"; RdR <= '1'; -- W2
				when "10001" => RdAddr <= "10001"; RdR <= '1'; -- W1
				when "10000" => RdAddr <= "01111"; RdR <= '1'; -- M3H
				when "01111" => RdAddr <= "01110"; RdR <= '1'; -- M3G
				when "01110" => RdAddr <= "01101"; RdR <= '1'; -- M3F
				when "01101" => RdAddr <= "01100"; RdR <= '1'; -- M3E
				when "01100" => RdAddr <= "01011"; RdR <= '1'; -- M3D
				when "01011" => RdAddr <= "01010"; RdR <= '1'; -- M3C
				when "01010" => RdAddr <= "01001"; RdR <= '1'; -- M3B
				when "01001" => RdAddr <= "01000"; RdR <= '1'; -- M3A
				when "01000" => RdAddr <= "00111"; RdR <= '1'; -- M0H
				when "00111" => RdAddr <= "00110"; RdR <= '1'; -- M0G
				when "00110" => RdAddr <= "00101"; RdR <= '1'; -- M0F
				when "00101" => RdAddr <= "00100"; RdR <= '1'; -- M0E
				when "00100" => RdAddr <= "00011"; RdR <= '1'; -- M0D
				when "00011" => RdAddr <= "00010"; RdR <= '1'; -- M0C
				when "00010" => RdAddr <= "00001"; RdR <= '1'; -- M0B
				when "00001" => RdAddr <= "00000"; RdR <= '1'; -- M0A
				when others  => RdAddr <= "00000"; RdR <= '0'; -- 00 and rest (!)
			end case;
		end if;
	end process;

	-- Shift register implementation
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			if MC_A(5) = '1' then
				ShReg <= W16;
			elsif bitcnt(4 downto 0) /= "00000" then
				ShReg(31 downto 1) <= ShReg(30 downto 0); ShReg(0) <= '0'; -- Shifting out
			elsif RdR = '1' then
				ShReg <= RdData;
			else
				ShReg <= ShReg;
			end if;
		end if;
	end process;

	-- Hereby we relay that delay of ClkTX/2 is enough to pass data to any destination (!).
	ProgCNA <= ProgCN when (bitcnt(9) = '1' and bitcnt(8) = '1' and bitcnt(0) = '1') else ProgCP; -- DO NOT TOUCH OR DROP!
	ProgCPA <= (not ProgCN) when (MC_A(5) = '0' and not (bitcnt(9) = '1' and bitcnt(8) = '1')) else ProgCP; -- RAISE OR DON'T TOUCH!
	FDPROGCN: FD generic map (INIT => '0') port map (C => ClkTX, D => ProgCNA, Q => ProgCN);
	FDPROGCP: FD_1 generic map (INIT => '0') port map (C => ClkTX, D => ProgCPA, Q => ProgCP);
	LPROGC: LUT2 generic map (INIT => "0110") port map (O => ProgCO, I0 => ProgCN, I1 => ProgCP);
	PROGCBUFG: BUFG port map (I => ProgCO, O => ProgCG); ProgC <= ProgCG;
	ProgD <= ShReg(31); -- Shift register!

	-- Place nonce counter with its internal reset logic, it is started just before (it is counting!)
	SHANCTR: entity WORK.SHA_NonceCtr generic map (LOC_X => 68, LOC_Y => 8, NONCE_START => NONCE_START - 308 - 10)
		port map ( ClkS => ClkS, ProgC => ProgCG, N_out => CurNonce );

	ScanDone <= '1' when CurNonce(31 downto 8) = x"ffffff" else '0'; -- Do not scan last 256 elements! This makes better cross-clock ScanDone tracking!

	-- So we have match !
	process (ClkS) begin
		if rising_edge(ClkS) then
			if MatchCoreEven = '1' or MatchCoreOdd = '1' then
				MatchSample(31 downto 1) <= CurNonce(31 downto 1);
				MatchSample(0) <= MatchCoreOdd;
				MatchSA <= not MatchSA3;    -- Flip it!
			else
				MatchSample <= MatchSample; -- Probe MatchSample
				MatchSA <= MatchSA;         -- Do not change
			end if;
		end if;
	end process;

	-- Capture on different clock domain!
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			MatchSample1 <= MatchSample;
			MatchSA1 <= MatchSA; MatchSA2 <= MatchSA1; MatchSA3 <= MatchSA2;
		end if;
	end process;

	-- Then Execute match output if capture was successful!
	process (ClkTX) begin
		if rising_edge(ClkTX) then
			if (MatchSA2 xor MatchSA3) = '1' then
				Match_data <= MatchSample1;
				Match_has <= '1';
			else
				Match_data <= Match_data_in;
				Match_has <= Match_has_in;
			end if;
		end if;
	end process;

	Match_data_out <= Match_data;
	Match_has_out <= Match_has;
end RTL;

