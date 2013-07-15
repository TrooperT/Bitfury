--
-- Copyright 2012 www.bitfury.org
--
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_NonceCtr is
	generic (
		NONCE_START	: std_logic_vector(31 downto 0)
	);
	port (
		Clk		: in  std_logic;
		ProgC		: in  std_logic;
		N_out		: out std_logic_vector(31 downto 0)
	);
end SHA_NonceCtr;

architecture RTL of SHA_NonceCtr is
	signal ProgCND, ProgCPD, IProgC, IProgC1, IProgCA : std_logic;
	signal ctr_async, ctr : std_logic_vector(31 downto 0);
begin
	process (ProgC) begin
		if rising_edge(ProgC) then ProgCPD <= not ProgCND; end if;
		if falling_edge(ProgC) then ProgCND <= ProgCPD; end if;
	end process;

	process (Clk) begin
		if rising_edge(Clk) then
			IProgC <= ProgCND xor ProgCPD;
			IProgC1 <= IProgC;
			IProgCA <= IProgC or IProgC1;
		end if;
	end process;

	ctr_async <= ctr + 1;

	BG: for i in 0 to 31 generate
		BG1: if NONCE_START(i) = '1' generate
			FFP: FDSE port map (CE => '1', S => IProgCA, C => Clk, D => ctr_async(i), Q => ctr(i));
		end generate;
		BG0: if NONCE_START(i) = '0' generate
			FFP: FDRE port map (CE => '1', R => IProgCA, C => Clk, D => ctr_async(i), Q => ctr(i));
		end generate;
	end generate;

--	process (Clk) begin
--		if rising_edge(Clk) then
--			if IProgCA = '1' then
--				ctr <= NONCE_START;
--			else
--				ctr <= ctr + 1;
--			end if;
--		end if;
--	end process;

	N_out <= ctr;
end RTL;

