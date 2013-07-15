--
-- Copyright 2012 www.bitfury.org
--
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_Round is
	port (
		Clk			: in  std_logic;
		S_in			: in  std_logic_vector(255 downto 0);
		S_out			: out std_logic_vector(255 downto 0);
		W_in			: in  std_logic_vector(31 downto 0);
		K_in			: in  std_logic_vector(31 downto 0)
	);
end SHA_Round;

architecture RTL of SHA_Round is
	-- Input signals (parsed S_in)
	signal A_in, B_in, C_in, D_in, E_in, F_in, G_in, H_in : std_logic_vector(31 downto 0);

	signal A_ror1, A_ror2, A_ror3, E_ror1, E_ror2, E_ror3 : std_logic_vector(31 downto 0);
	signal A_out, E_out : std_logic_vector(31 downto 0);

	-- Carry signals
	signal Acsa1c, Ecsa1c, Xcsa1c, Xcsa2c : std_logic_vector(32 downto 0);
	signal Ecsa2s, Acsa2s, Ecsa2c, Acsa2c : std_logic_vector(31 downto 0);
begin
	A_in <= S_in(32*0+31 downto 32*0); B_in <= S_in(32*1+31 downto 32*1); C_in <= S_in(32*2+31 downto 32*2); D_in <= S_in(32*3+31 downto 32*3);
	E_in <= S_in(32*4+31 downto 32*4); F_in <= S_in(32*5+31 downto 32*5); G_in <= S_in(32*6+31 downto 32*6); H_in <= S_in(32*7+31 downto 32*7);
	A_ror1 <= A_in( 1 downto 0) & A_in(31 downto  2);
	A_ror2 <= A_in(12 downto 0) & A_in(31 downto 13);
	A_ror3 <= A_in(21 downto 0) & A_in(31 downto 22);
	E_ror1 <= E_in( 5 downto 0) & E_in(31 downto  6);
	E_ror2 <= E_in(10 downto 0) & E_in(31 downto 11);
	E_ror3 <= E_in(24 downto 0) & E_in(31 downto 25);

	Acsa1c(0) <= '1'; Ecsa1c(0) <= '0'; Xcsa1c(0) <= '0'; Xcsa2c(0) <= '0';
	BG: for i in 0 to 31 generate -- Instantiate primitives
		signal Acsa1s, Acsa1sa, Acsa2sa, Acsa1ca, Acsa2ca : std_logic;
		signal Ecsa1s, Ecsa1sa, Ecsa2sa, Ecsa1ca, Ecsa2ca : std_logic;
		signal Xcsa1s, Xcsa2s, Xcsa1sa, Xcsa2sa, Xcsa1ca, Xcsa2ca : std_logic;
		signal A_sh, B_sha, B_sh, C_sha, C_sh, C_shb, D_sha, D_sh, E_sh, F_sha, F_sh, G_sha, G_sh : std_logic;
	begin
		-- AUX round inputs (we feed constant here in dumb way, as anyway it is impossible to move C_in and H_in down!
		-- TODO - can be further reduced (!).
		XCSA1L6: LUT3 generic map (INIT => "11101000") port map (O => Xcsa1ca, I2 => K_in(i), I1 => H_in(i), I0 => W_in(i));
		XCSA1F6: FD port map (C => Clk, D => Xcsa1ca, Q => Xcsa1c(i+1));
		XCSA1L5: LUT3 generic map (INIT => "10010110") port map (O => Xcsa1sa, I2 => K_in(i), I1 => H_in(i), I0 => W_in(i));
		XCSA1F5: FD port map (C => Clk, D => Xcsa1sa, Q => Xcsa1s);
		XCSA2L6: LUT3 generic map (INIT => "11101000") port map (O => Xcsa2ca, I2 => Xcsa1c(i), I1 => Xcsa1s, I0 => D_in(i));
		XCSA2F6: FD port map (C => Clk, D => Xcsa2ca, Q => Xcsa2c(i+1));
		XCSA2L5: LUT3 generic map (INIT => "10010110") port map (O => Xcsa2sa, I2 => Xcsa1c(i), I1 => Xcsa1s, I0 => D_in(i));
		XCSA2F5: FD port map (C => Clk, D => Xcsa2sa, Q => Xcsa2s);

		-- Process XOR-CSA (first stage) EFGH
		ECSA1L6: LUT5 generic map (INIT => x"ff969600")
			port map (O => Ecsa1ca, I0 => E_ror1(i), I1 => E_ror2(i), I2 => E_ror3(i), I3 => Xcsa2s, I4 => Xcsa2c(i));
		ECSA1F6: FD port map (C => Clk, D => Ecsa1ca, Q => Ecsa1c(i+1));
		ECSA1L5: LUT5 generic map (INIT => x"96696996")
			port map (O => Ecsa1sa, I0 => E_ror1(i), I1 => E_ror2(i), I2 => E_ror3(i), I3 => Xcsa2s, I4 => Xcsa2c(i));
		ECSA1F5: FD port map (C => Clk, D => Ecsa1sa, Q => Ecsa1s);

		-- Process XOR-CSA (first stage) ABCD
		ACSA1L6: LUT5 generic map (INIT => x"9600ff96")
			port map (O => Acsa1ca, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => E_in(i), I4 => D_sh);
		ACSA1F6: FD port map (C => Clk, D => Acsa1ca, Q => Acsa1c(i+1));
		ACSA1L5: LUT5 generic map (INIT => x"69969669")
			port map (O => Acsa1sa, I0 => A_ror1(i), I1 => A_ror2(i), I2 => A_ror3(i), I3 => E_in(i), I4 => D_sh);
		ACSA1F5: FD port map (C => Clk, D => Acsa1sa, Q => Acsa1s);

		-- Process values in shift-register
		-- Reduce SLICE.M requirements to achieve fit
		SRLB: SRL16 port map (CLK => Clk, D => B_in(i), Q => B_sha, A0 => '1', A1 => '0', A2 => '0', A3 => '0');

		SRLC1: if i >= 16 generate
			SRLC: SRL16 port map (CLK => Clk, D => C_in(i), Q => C_sha, A0 => '0', A1 => '0', A2 => '0', A3 => '0');
		end generate;
		SRLC2: if i < 16 generate
			signal bfd1 : std_logic;
		begin
			SRLC: FD port map (C => Clk, D => C_in(i), Q => C_sha);
		end generate;

		SRLD: SRL16 port map (CLK => Clk, D => D_in(i), Q => D_sha, A0 => '0', A1 => '1', A2 => '0', A3 => '0');
		SRLF: SRL16 port map (CLK => Clk, D => F_in(i), Q => F_sha, A0 => '1', A1 => '0', A2 => '0', A3 => '0');
		SRLG: SRL16 port map (CLK => Clk, D => G_in(i), Q => G_sha, A0 => '1', A1 => '0', A2 => '0', A3 => '0');
		FDA:  FD port map (C => Clk, D => A_in(i), Q => A_sh);
		FDB:  FD port map (C => Clk, D => B_sha,   Q => B_sh);
		FDC:  FD port map (C => Clk, D => C_sha,   Q => C_shb);
		FDCC: FD port map (C => Clk, D => C_shb,   Q => C_sh);
		FDD:  FD port map (C => Clk, D => D_sha,   Q => D_sh);
		FDE:  FD port map (C => Clk, D => E_in(i), Q => E_sh);
		FDF:  FD port map (C => Clk, D => F_sha,   Q => F_sh);
		FDG:  FD port map (C => Clk, D => G_sha,   Q => G_sh);

		-- Shift out values to next round
		S_out(32 + i)   <= A_sh; S_out(32*2 + i) <= B_sh; S_out(32*3 + i) <= C_shb;
		S_out(32*5 + i) <= E_sh; S_out(32*6 + i) <= F_sh; S_out(32*7 + i) <= G_sh;

		ACSA2L6: LUT5 generic map (INIT => x"ffe8e800")
			port map (O => Acsa2ca, I0 => A_sh, I1 => B_sh, I2 => C_sh, I3 => Acsa1s, I4 => Acsa1c(i));
		ACSA2F6: FD port map (C => Clk, D => Acsa2ca, Q => Acsa2c(i));
		ACSA2L5: LUT5 generic map (INIT => x"e81717e8")
			port map (O => Acsa2sa, I0 => A_sh, I1 => B_sh, I2 => C_sh, I3 => Acsa1s, I4 => Acsa1c(i));
		ACSA2F5: FD port map (C => Clk, D => Acsa2sa, Q => Acsa2s(i));

		ECSA2L6: LUT5 generic map (INIT => x"ffcaca00")
			port map (O => Ecsa2ca, I0 => G_sh, I1 => F_sh, I2 => E_sh, I3 => Ecsa1s, I4 => Ecsa1c(i));
		ECSA2F6: FD port map (C => Clk, D => Ecsa2ca, Q => Ecsa2c(i));
		ECSA2L5: LUT5 generic map (INIT => x"ca3535ca")
			port map (O => Ecsa2sa, I0 => G_sh, I1 => F_sh, I2 => E_sh, I3 => Ecsa1s, I4 => Ecsa1c(i));
		ECSA2F5: FD port map (C => Clk, D => Ecsa2sa, Q => Ecsa2s(i));
	end generate;

	process (Clk) begin
		if rising_edge(Clk) then
			A_out(0) <= Acsa2s(0);
			E_out(0) <= Ecsa2s(0);
			A_out(31 downto 1) <= Acsa2s(31 downto 1) + Acsa2c(30 downto 0);
			E_out(31 downto 1) <= Ecsa2s(31 downto 1) + Ecsa2c(30 downto 0);
		end if;
	end process;

	S_out(31 downto 0) <= A_out; S_out(159 downto 128) <= E_out;
end RTL;

