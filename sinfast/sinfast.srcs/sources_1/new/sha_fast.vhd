--
-- Copyright 2012 www.bitfury.org
--
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_FullCore is
	generic (
		NONCE_START		: std_logic_vector(31 downto 0)
	);
	port (
		Clk			: in  std_logic;
		ProgC			: in  std_logic;
		ProgD			: in  std_logic;
		Match			: out std_logic
	);
end SHA_FullCore;

architecture RTL of SHA_FullCore is
	signal S_mid : std_logic_vector(255 downto 0);
begin
	SP: entity WORK.SHA_Primary generic map (NONCE_START => NONCE_START) port map (Clk => Clk, ProgC => ProgC, ProgD => ProgD, S_out => S_mid);
	Match <= S_mid(31);
--	SS: entity WORK.SHA_Secondary port map (Clk => Clk, ProgC => ProgC, ProgD => ProgD, S_in => S_mid, Match => Match);
end RTL;
