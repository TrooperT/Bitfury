--
-- Copyright 2012 www.bitfury.org
--
library IEEE;
	use IEEE.STD_LOGIC_1164.All;
	use IEEE.STD_LOGIC_UNSIGNED.All;
library UNISIM;
	use UNISIM.VComponents.All;

entity SHA_WRound is
	port (
		Clk			: in  std_logic;
		W_in			: in  std_logic_vector(511 downto 0);
		W_out			: out std_logic_vector(511 downto 0)
	);
end SHA_WRound;

architecture RTL of SHA_WRound is
	signal W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15 : std_logic_vector(31 downto 0);

	signal w14i, w14_ror17, w14_ror19, w14_shr10 : std_logic_vector(31 downto 0);
	signal w1_ror7, w1_ror18, w1_shr3 : std_logic_vector(31 downto 0);

	signal w_reg : std_logic_vector(31 downto 0);
	signal wcsa2c, wcsa2s : std_logic_vector(31 downto 0);
	signal wcsa1c : std_logic_vector(32 downto 0);
begin
	-- Parse all inputs into appr. W registers
	W0 <= W_in(32*0 +31 downto 32*0 ); W1 <= W_in(32*1 +31 downto 32*1 ); W2 <= W_in(32*2 +31 downto 32*2 ); W3 <= W_in(32*3 +31 downto 32*3 );
	W4 <= W_in(32*4 +31 downto 32*4 ); W5 <= W_in(32*5 +31 downto 32*5 ); W6 <= W_in(32*6 +31 downto 32*6 ); W7 <= W_in(32*7 +31 downto 32*7 );
	W8 <= W_in(32*8 +31 downto 32*8 ); W9 <= W_in(32*9 +31 downto 32*9 ); W10<= W_in(32*10+31 downto 32*10); W11<= W_in(32*11+31 downto 32*11);
	W12<= W_in(32*12+31 downto 32*12); W13<= W_in(32*13+31 downto 32*13); W14<= W_in(32*14+31 downto 32*14); W15<= W_in(32*15+31 downto 32*15);

	-- Nice zero-cost rors
	w1_ror7   <=  w1( 6 downto 0) & w1(31 downto  7);
	w1_ror18  <=  w1(17 downto 0) & w1(31 downto 18);
	w1_shr3   <=            "000"  & w1(31 downto  3);
	w14_ror17 <= w14i(16 downto 0) & w14i(31 downto 17);
	w14_ror19 <= w14i(18 downto 0) & w14i(31 downto 19);
	w14_shr10 <=     "0000000000"  & w14i(31 downto 10);
	wcsa1c(0) <= '0';

	BG: for i in 0 to 31 generate
		signal W1_sha1, W1_sha2, W9_sha : std_logic;
		signal wcsa2ca, wcsa2sa, wcsa1ca, wcsa1sa, wcsa1s : std_logic;
	begin
		-- 12 slices M + 24 slices X to transfer state

		-- Three registers to delay properly W_output
		FDW16:  FD port map (C => Clk, D => w_reg(i), Q => W_out(480 + i)); -- Output W16 (new)
		FDW15:  FD port map (C => Clk, D => W15(i), Q => W_out(448 + i)); -- Output W15 (new)
		FDW14:  FD port map (C => Clk, D => W14(i), Q => w14i(i)); W_out(416 + i) <= w14i(i); -- Output W14 (new)

		-- Prepare W9 (pass through registers)
		W_out(384 + i) <= W13(i);
		FDW12:  FD port map (C => Clk, D => W13(i), Q => W_out(352+i));
		W_out(320 + i) <= W12(i);
		SRLW9:  SRL16 port map (CLK => Clk, D => W11(i), Q => W9_sha, A0 => '1', A1 => '0', A2 => '1', A3 => '1');
		FDW9:   FD port map (C => Clk, D => W9_sha, Q => W_out(288+i)); -- W9 input for next round (!).

		-- Prepare W1 (pass through registers and SRLs)
		W_out(256+i) <= W9(i);
		FDW8:   FD port map (C => Clk, D => W8(i), Q => W_out(224+i));
		W_out(192+i) <= W7(i);
		SRLW1A: SRL16 port map (CLK => Clk, D => W6(i), Q => W1_sha1, A0 => '0', A1 => '1', A2 => '0', A3 => '1');
		FDW1A:  FD port map (C => Clk, D => W1_sha1, Q => W_out(160+i));
		W_out(128+i) <= W5(i);
		SRLW2A: SRL16 port map (CLK => Clk, D => W4(i), Q => W1_sha2, A0 => '0', A1 => '1', A2 => '0', A3 => '1');
		FDW2A:  FD port map (C => Clk, D => W1_sha2, Q => W_out(96+i));
		W_out(64+i) <= W3(i);
		FDW1:   FD port map (C => Clk, D => W2(i), Q => W_out(32+i));
		FDW0:   FD port map (C => Clk, D => W1(i), Q => W_out(i)); -- W0 input from previous!

		WCSA1L6: LUT5 generic map (INIT => x"ff969600") port map (O => wcsa1ca, I0 => w14_ror17(i),I1 => w14_ror19(i), I2 => w14_shr10(i), I3 => W0(i), I4 => W9(i));
		WCSA1F6: FD port map (C => Clk, D => wcsa1ca, Q => wcsa1c(i+1));
		WCSA1L5: LUT5 generic map (INIT => x"96696996") port map (O => wcsa1sa, I0 => w14_ror17(i),I1 => w14_ror19(i), I2 => w14_shr10(i), I3 => W0(i), I4 => W9(i));
		WCSA1F5: FD port map (C => Clk, D => wcsa2ca, Q => wcsa1s);

		WCSA2L6: LUT5 generic map (INIT => x"ff969600") port map (O => wcsa2ca, I0 => w1_ror7(i),I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => wcsa1c(i), I4 => wcsa1s);
		WCSA2F6: FD port map (C => Clk, D => wcsa2ca, Q => wcsa2c(i));
		WCSA2L5: LUT5 generic map (INIT => x"96696996") port map (O => wcsa2sa, I0 => w1_ror7(i),I1 => w1_ror18(i), I2 => w1_shr3(i), I3 => wcsa1c(i), I4 => wcsa1s);
		WCSA2F5: FD port map (C => Clk, D => wcsa2ca, Q => wcsa2s(i));
	end generate;

	process (Clk) begin
		if rising_edge(Clk) then
			w_reg(0) <= wcsa2s(0); w_reg(31 downto 1) <= wcsa2s(31 downto 1) + wcsa2c(30 downto 0);
		end if;
	end process;
end RTL;
