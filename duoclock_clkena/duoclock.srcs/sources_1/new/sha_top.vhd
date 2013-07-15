--
-- Copyright 2012 www.bitfury.org
--

--
-- Only two snakes design unit of sha_top
--

library IEEE;
	use IEEE.STD_LOGIC_1164.All;
library UNISIM;
	use UNISIM.VComponents.All;

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
	signal GClk, SCK, MISO, MOSI, MISO_en, nMISO_en : std_logic;
	signal ID_in, IDIO_in : std_logic_vector(2 downto 0);

	-- Generate main clock and transmission clock (ClkTX)
	-- FC_NONCE_START should be always even number
	constant FC_NONCE_START : std_logic_vector(31 downto 0) := x"00000200"; -- Fullcores starting point

	signal clkfbout, Clk, Clk_l, ClkTX_l, ClkTX, ClkE, ClkE_ls, ClkE_l, ClkNE : std_logic;

	signal ProgC, ProgD, MatchCoreEven, MatchCoreOdd : std_logic;

	signal Match_has, ScanDone_in : std_logic;
	signal MC_D_slow, Match_data : std_logic_vector(31 downto 0);
	signal MC_A_slow : std_logic_vector( 5 downto 0);

	signal C_in, C_out : std_logic_vector(28 downto 0);
	signal W_in, K_in : std_logic_vector(31 downto 0);

	signal DCM_Freeze, DCM_Data, DCM_Data_En, DCM_Rst, DCM_Locked, DCM_Locked_int : std_logic;
	signal DCM_Status : std_logic_vector(1 downto 0);
begin
	IBUF_SCK:      IBUF generic map (IOSTANDARD => "LVCMOS33") port map (O => SCK,      I => SCK_in);
	nMISO_en <= not MISO_en;
	OBUF_MISO_EN: OBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => MISO_EN_out, I => nMISO_en);
	OBUF_MISO:    OBUFT generic map (IOSTANDARD => "LVCMOS33") port map (T => nMISO_en, O => MISO_out, I => MISO);
	IBUF_MOSI:    IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => MOSI,     I => MOSI_in);
	IBUF_ID0:     IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => ID_in(0),    I => ID0_in);
	IBUF_ID1:     IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => ID_in(1),    I => ID1_in);
	IBUF_ID2:     IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => ID_in(2),    I => ID2_in);
	IBUF_IO3:     IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => IDIO_in(0),  I => IO3_in);
	IBUF_IO0:     IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => IDIO_in(1),  I => IO0_in);
	IBUF_IO2:     IBUF  generic map (IOSTANDARD => "LVCMOS33") port map (O => IDIO_in(2),  I => IO2_in);

	-- Fix and get ID, depending on its source
--	IDIO_fixed <= IDIO_in when IDIO_in(2) = '0' else (IDIO_in(2) & (not IDIO_in(1)) & (not IDIO_in(0)));
--	ID <= ID_in when (ID_in /= "111") else IDIO_fixed;

	-- SPI CONTROLLER (register access + frame matching)
	SHASPIinst: entity WORK.SHA_IfCtrl(RTL) port map (
		Clk => ClkTX, ChipID => ID_in, AltChipID => IDIO_in,
		SCK => SCK, MOSI => MOSI, MISO => MISO, MISO_en => MISO_en,
		DCM_Freeze => DCM_Freeze, DCM_Data_En => DCM_Data_En, DCM_Data => DCM_Data, DCM_Rst => DCM_Rst, DCM_Locked => DCM_Locked,
		MC_D => MC_D_slow, MC_A => MC_A_slow,
		ScanDone_in => ScanDone_in, -- Scan done flag!
		Match_has => Match_has, Match_data => Match_data
	);

	-- Two full cores instantiated
	SHAFCE: entity WORK.SHA_FullCore generic map (LOC_Y => 0, NONCE_START => FC_NONCE_START)
		port map (Clk => Clk, ClkE => ClkE, ProgC => ProgC, ProgD => ProgD, Match => MatchCoreEven);
	SHAFCO: entity WORK.SHA_FullCore generic map (LOC_Y => 1, NONCE_START => FC_NONCE_START xor x"00000001")
		port map (Clk => Clk, ClkE => ClkE, ProgC => ProgC, ProgD => ProgD, Match => MatchCoreOdd);
--    MatchCoreOdd <= '0'; -- THIS FUNCTIONALITY IS DISABLED TO VALIDATE LOWER PARTIAL BUILD! IT SHALL BE RE-ENABLED ONCE VALIDATED!

	-- Channeled configuration unit (it emits own found nonces + generates receipts on signals)
	SHACONFIG: entity WORK.SHA_FC_Config generic map (NONCE_START => FC_NONCE_START)
		port map (Clk => Clk, ClkE => ClkE, ClkTX => ClkTX, MC_A => MC_A_slow, MC_D => MC_D_slow, 
		          ProgC => ProgC, ProgD => ProgD, MatchCoreEven => MatchCoreEven, MatchCoreOdd => MatchCoreOdd,
			  Match_has_in  => '0', Match_data_in => (others => '0'),
		          Match_has_out => Match_has, Match_data_out => Match_data, ScanDone => ScanDone_in );

	-- Programmable DCM clock generator, which uses programmed frequency
	DCMCI: DCM_CLKGEN generic map (
			CLKFXDV_DIVIDE => 2,
			CLKFX_DIVIDE => 1,
			CLKFX_MD_MAX => 17.0, -- Maximum clock is 340 Mhz!
			CLKFX_MULTIPLY => 10, -- Default clock is 200 Mhz!
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

	-- Static slow system clock generator (60 Mhz placed, 30 Mhz actual)
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

	-- ClkTX is transmission clock used throughout the chip!
	BUFGCLK:    BUFG port map (O => Clk, I => Clk_l);
	BUFGCLKTX:  BUFG port map (O => ClkTX, I => ClkTX_l);
	DVLUT1: LUT1 generic map (INIT => "01") port map (I0 => ClkE, O => ClkNE);
	DVFD: FD generic map (INIT => '0') port map (C => Clk, D => ClkNE, Q => ClkE_ls);
	ClkE_l <= ClkE_ls after 800ps; -- Slight FD / BUFG delay added!
	DVBUF: BUFG port map (I => ClkE_l, O => ClkE);

	-- TIE TO GROUND (LVCMOS33 STANDARD)
	OBUF_OA10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA10,	I => '0');
	OBUF_OA11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA11,	I => '0');
	OBUF_OA12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA12,	I => '0');
	OBUF_OA13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA13,	I => '0');
	OBUF_OA14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA14,	I => '0');
	OBUF_OA15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA15,	I => '0');
	OBUF_OA16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA16,	I => '0');
	OBUF_OA17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA17,	I => '0');
	OBUF_OA18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA18,	I => '0');
	OBUF_OA2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA2,	I => '0');
	OBUF_OA20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA20,	I => '0');
	OBUF_OA21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA21,	I => '0');
	OBUF_OA3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA3,	I => '0');
	OBUF_OA4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA4,	I => '0');
	OBUF_OA5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA5,	I => '0');
	OBUF_OA6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA6,	I => '0');
	OBUF_OA7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA7,	I => '0');
	OBUF_OA8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA8,	I => '0');
	OBUF_OA9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OA9,	I => '0');
	OBUF_OAA10:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA10,	I => '0');
	OBUF_OAA14:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA14,	I => '0');
	OBUF_OAA16:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA16,	I => '0');
	OBUF_OAA18:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA18,	I => '0');
	OBUF_OAA2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA2,	I => '0');
	OBUF_OAA21:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA21,	I => '0');
	OBUF_OAA4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA4,	I => '0');
	OBUF_OAA6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAA6,	I => '0');
	OBUF_OAB10:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB10,	I => '0');
	OBUF_OAB14:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB14,	I => '0');
	OBUF_OAB15:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB15,	I => '0');
	OBUF_OAB16:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB16,	I => '0');
	OBUF_OAB17:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB17,	I => '0');
	OBUF_OAB18:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB18,	I => '0');
	OBUF_OAB19:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB19,	I => '0');
	OBUF_OAB2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB2,	I => '0');
	OBUF_OAB20:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB20,	I => '0');
	OBUF_OAB21:OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB21,	I => '0');
	OBUF_OAB3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB3,	I => '0');
	OBUF_OAB4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB4,	I => '0');
	OBUF_OAB5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB5,	I => '0');
	OBUF_OAB6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB6,	I => '0');
	OBUF_OAB7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB7,	I => '0');
	OBUF_OAB8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OAB8,	I => '0');
	OBUF_OB1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB1,	I => '0');
	OBUF_OB10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB10,	I => '0');
	OBUF_OB12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB12,	I => '0');
	OBUF_OB14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB14,	I => '0');
	OBUF_OB16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB16,	I => '0');
	OBUF_OB18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB18,	I => '0');
	OBUF_OB2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB2,	I => '0');
	OBUF_OB20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB20,	I => '0');
	OBUF_OB21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB21,	I => '0');
	OBUF_OB22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB22,	I => '0');
	OBUF_OB3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB3,	I => '0');
	OBUF_OB6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB6,	I => '0');
	OBUF_OB8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OB8,	I => '0');
	OBUF_OC1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC1,	I => '0');
	OBUF_OC10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC10,	I => '0');
	OBUF_OC11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC11,	I => '0');
	OBUF_OC12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC12,	I => '0');
	OBUF_OC13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC13,	I => '0');
	OBUF_OC14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC14,	I => '0');
	OBUF_OC15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC15,	I => '0');
	OBUF_OC16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC16,	I => '0');
	OBUF_OC17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC17,	I => '0');
	OBUF_OC19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC19,	I => '0');
	OBUF_OC20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC20,	I => '0');
	OBUF_OC22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC22,	I => '0');
	OBUF_OC3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC3,	I => '0');
	OBUF_OC4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC4,	I => '0');
	OBUF_OC5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC5,	I => '0');
	OBUF_OC6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC6,	I => '0');
	OBUF_OC7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC7,	I => '0');
	OBUF_OC9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OC9,	I => '0');
	OBUF_OD1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD1,	I => '0');
	OBUF_OD10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD10,	I => '0');
	OBUF_OD11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD11,	I => '0');
	OBUF_OD12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD12,	I => '0');
	OBUF_OD13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD13,	I => '0');
	OBUF_OD14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD14,	I => '0');
	OBUF_OD15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD15,	I => '0');
	OBUF_OD17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD17,	I => '0');
	OBUF_OD19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD19,	I => '0');
	OBUF_OD2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD2,	I => '0');
	OBUF_OD20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD20,	I => '0');
	OBUF_OD21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD21,	I => '0');
	OBUF_OD22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD22,	I => '0');
	OBUF_OD3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD3,	I => '0');
	OBUF_OD5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD5,	I => '0');
	OBUF_OD6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD6,	I => '0');
	OBUF_OD7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD7,	I => '0');
	OBUF_OD8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD8,	I => '0');
	OBUF_OD9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OD9,	I => '0');
	OBUF_OE1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE1,	I => '0');
	OBUF_OE10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE10,	I => '0');
	OBUF_OE12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE12,	I => '0');
	OBUF_OE14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE14,	I => '0');
	OBUF_OE16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE16,	I => '0');
	OBUF_OE20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE20,	I => '0');
	OBUF_OE22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE22,	I => '0');
	OBUF_OE3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE3,	I => '0');
	OBUF_OE4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE4,	I => '0');
	OBUF_OE5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE5,	I => '0');
	OBUF_OE6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE6,	I => '0');
	OBUF_OE8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OE8,	I => '0');
	OBUF_OF1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF1,	I => '0');
	OBUF_OF10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF10,	I => '0');
	OBUF_OF12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF12,	I => '0');
	OBUF_OF13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF13,	I => '0');
	OBUF_OF14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF14,	I => '0');
	OBUF_OF15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF15,	I => '0');
	OBUF_OF16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF16,	I => '0');
	OBUF_OF17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF17,	I => '0');
	OBUF_OF18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF18,	I => '0');
	OBUF_OF19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF19,	I => '0');
	OBUF_OF2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF2,	I => '0');
	OBUF_OF20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF20,	I => '0');
	OBUF_OF21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF21,	I => '0');
	OBUF_OF22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF22,	I => '0');
	OBUF_OF3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF3,	I => '0');
	OBUF_OF5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF5,	I => '0');
	OBUF_OF7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF7,	I => '0');
	OBUF_OF8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF8,	I => '0');
	OBUF_OF9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OF9,	I => '0');
	OBUF_OG1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG1,	I => '0');
	OBUF_OG11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG11,	I => '0');
	OBUF_OG13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG13,	I => '0');
	OBUF_OG16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG16,	I => '0');
	OBUF_OG17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG17,	I => '0');
	OBUF_OG19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG19,	I => '0');
	OBUF_OG20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG20,	I => '0');
	OBUF_OG22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG22,	I => '0');
	OBUF_OG3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG3,	I => '0');
	OBUF_OG4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG4,	I => '0');
	OBUF_OG6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG6,	I => '0');
	OBUF_OG7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG7,	I => '0');
	OBUF_OG8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG8,	I => '0');
	OBUF_OG9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OG9,	I => '0');
	OBUF_OH1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH1,	I => '0');
	OBUF_OH10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH10,	I => '0');
	OBUF_OH11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH11,	I => '0');
	OBUF_OH12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH12,	I => '0');
	OBUF_OH13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH13,	I => '0');
	OBUF_OH14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH14,	I => '0');
	OBUF_OH16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH16,	I => '0');
	OBUF_OH17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH17,	I => '0');
	OBUF_OH18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH18,	I => '0');
	OBUF_OH19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH19,	I => '0');
	OBUF_OH2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH2,	I => '0');
	OBUF_OH20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH20,	I => '0');
	OBUF_OH21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH21,	I => '0');
	OBUF_OH22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH22,	I => '0');
	OBUF_OH3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH3,	I => '0');
	OBUF_OH4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH4,	I => '0');
	OBUF_OH5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH5,	I => '0');
	OBUF_OH6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH6,	I => '0');
	OBUF_OH8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OH8,	I => '0');
	OBUF_OJ1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ1,	I => '0');
	OBUF_OJ16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ16,	I => '0');
	OBUF_OJ17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ17,	I => '0');
	OBUF_OJ19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ19,	I => '0');
	OBUF_OJ20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ20,	I => '0');
	OBUF_OJ22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ22,	I => '0');
	OBUF_OJ3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ3,	I => '0');
	OBUF_OJ4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ4,	I => '0');
	OBUF_OJ6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ6,	I => '0');
	OBUF_OJ7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OJ7,	I => '0');
	OBUF_OK1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK1,	I => '0');
	OBUF_OK16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK16,	I => '0');
	OBUF_OK17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK17,	I => '0');
	OBUF_OK18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK18,	I => '0');
	OBUF_OK19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK19,	I => '0');
	OBUF_OK2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK2,	I => '0');
	OBUF_OK20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK20,	I => '0');
	OBUF_OK21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK21,	I => '0');
	OBUF_OK22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK22,	I => '0');
	OBUF_OK3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK3,	I => '0');
	OBUF_OK4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK4,	I => '0');
	OBUF_OK5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK5,	I => '0');
	OBUF_OK6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK6,	I => '0');
	OBUF_OK7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK7,	I => '0');
	OBUF_OK8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OK8,	I => '0');
	OBUF_OL1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL1,	I => '0');
	OBUF_OL15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL15,	I => '0');
	OBUF_OL17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL17,	I => '0');
	OBUF_OL19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL19,	I => '0');
	OBUF_OL20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL20,	I => '0');
	OBUF_OL22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL22,	I => '0');
	OBUF_OL3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL3,	I => '0');
	OBUF_OL4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL4,	I => '0');
	OBUF_OL6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OL6,	I => '0');
	OBUF_OM1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM1,	I => '0');
	OBUF_OM16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM16,	I => '0');
	OBUF_OM17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM17,	I => '0');
	OBUF_OM18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM18,	I => '0');
	OBUF_OM19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM19,	I => '0');
	OBUF_OM2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM2,	I => '0');
	OBUF_OM20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM20,	I => '0');
	OBUF_OM21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM21,	I => '0');
	OBUF_OM22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM22,	I => '0');
	OBUF_OM3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM3,	I => '0');
	OBUF_OM4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM4,	I => '0');
	OBUF_OM5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM5,	I => '0');
	OBUF_OM6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM6,	I => '0');
	OBUF_OM7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM7,	I => '0');
	OBUF_OM8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OM8,	I => '0');
	OBUF_ON1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON1,	I => '0');
	OBUF_ON16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON16,	I => '0');
	OBUF_ON19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON19,	I => '0');
	OBUF_ON20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON20,	I => '0');
	OBUF_ON22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON22,	I => '0');
	OBUF_ON3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON3,	I => '0');
	OBUF_ON4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON4,	I => '0');
	OBUF_ON6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON6,	I => '0');
	OBUF_ON7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => ON7,	I => '0');
	OBUF_OP1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP1,	I => '0');
	OBUF_OP17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP17,	I => '0');
	OBUF_OP18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP18,	I => '0');
	OBUF_OP19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP19,	I => '0');
	OBUF_OP2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP2,	I => '0');
	OBUF_OP20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP20,	I => '0');
	OBUF_OP21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP21,	I => '0');
	OBUF_OP22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP22,	I => '0');
	OBUF_OP3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP3,	I => '0');
	OBUF_OP4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP4,	I => '0');
	OBUF_OP5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP5,	I => '0');
	OBUF_OP6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP6,	I => '0');
	OBUF_OP7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP7,	I => '0');
	OBUF_OP8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OP8,	I => '0');
	OBUF_OR1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR1,	I => '0');
	OBUF_OR11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR11,	I => '0');
	OBUF_OR13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR13,	I => '0');
	OBUF_OR15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR15,	I => '0');
	OBUF_OR16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR16,	I => '0');
	OBUF_OR19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR19,	I => '0');
	OBUF_OR20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR20,	I => '0');
	OBUF_OR22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR22,	I => '0');
	OBUF_OR3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR3,	I => '0');
	OBUF_OR4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR4,	I => '0');
	OBUF_OR7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR7,	I => '0');
	OBUF_OR8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR8,	I => '0');
	OBUF_OR9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OR9,	I => '0');
	OBUF_OT1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT1,	I => '0');
	OBUF_OT10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT10,	I => '0');
	OBUF_OT11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT11,	I => '0');
	OBUF_OT12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT12,	I => '0');
	OBUF_OT14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT14,	I => '0');
	OBUF_OT15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT15,	I => '0');
	OBUF_OT16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT16,	I => '0');
	OBUF_OT17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT17,	I => '0');
	OBUF_OT18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT18,	I => '0');
	OBUF_OT19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT19,	I => '0');
	OBUF_OT2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT2,	I => '0');
	OBUF_OT20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT20,	I => '0');
	OBUF_OT21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT21,	I => '0');
	OBUF_OT22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT22,	I => '0');
	OBUF_OT3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT3,	I => '0');
	OBUF_OT4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT4,	I => '0');
	OBUF_OT5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT5,	I => '0');
	OBUF_OT7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT7,	I => '0');
	OBUF_OT8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OT8,	I => '0');
	OBUF_OU1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU1,	I => '0');
	OBUF_OU10: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU10,	I => '0');
	OBUF_OU12: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU12,	I => '0');
	OBUF_OU13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU13,	I => '0');
	OBUF_OU14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU14,	I => '0');
	OBUF_OU16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU16,	I => '0');
	OBUF_OU17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU17,	I => '0');
	OBUF_OU19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU19,	I => '0');
	OBUF_OU20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU20,	I => '0');
	OBUF_OU22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU22,	I => '0');
	OBUF_OU3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU3,	I => '0');
	OBUF_OU4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU4,	I => '0');
	OBUF_OU6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU6,	I => '0');
	OBUF_OU8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OU8,	I => '0');
	OBUF_OV1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV1,	I => '0');
	OBUF_OV13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV13,	I => '0');
	OBUF_OV15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV15,	I => '0');
	OBUF_OV17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV17,	I => '0');
	OBUF_OV18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV18,	I => '0');
	OBUF_OV19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV19,	I => '0');
	OBUF_OV2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV2,	I => '0');
	OBUF_OV20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV20,	I => '0');
	OBUF_OV21: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV21,	I => '0');
	OBUF_OV22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV22,	I => '0');
	OBUF_OV3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV3,	I => '0');
	OBUF_OV5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV5,	I => '0');
	OBUF_OV7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV7,	I => '0');
	OBUF_OV9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OV9,	I => '0');
	OBUF_OW1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW1,	I => '0');
	OBUF_OW13: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW13,	I => '0');
	OBUF_OW14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW14,	I => '0');
	OBUF_OW15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW15,	I => '0');
	OBUF_OW17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW17,	I => '0');
	OBUF_OW18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW18,	I => '0');
	OBUF_OW20: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW20,	I => '0');
	OBUF_OW22: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW22,	I => '0');
	OBUF_OW3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW3,	I => '0');
	OBUF_OW4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW4,	I => '0');
	OBUF_OW6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW6,	I => '0');
	OBUF_OW8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW8,	I => '0');
	OBUF_OW9: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OW9,	I => '0');
	OBUF_OY1: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY1,	I => '0');
	OBUF_OY11: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY11,	I => '0');
	OBUF_OY14: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY14,	I => '0');
	OBUF_OY15: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY15,	I => '0');
	OBUF_OY16: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY16,	I => '0');
	OBUF_OY17: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY17,	I => '0');
	OBUF_OY18: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY18,	I => '0');
	OBUF_OY19: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY19,	I => '0');
	OBUF_OY2: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY2,	I => '0');
	OBUF_OY3: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY3,	I => '0');
	OBUF_OY4: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY4,	I => '0');
	OBUF_OY5: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY5,	I => '0');
	OBUF_OY6: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY6,	I => '0');
	OBUF_OY7: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY7,	I => '0');
	OBUF_OY8: OBUF	generic map (IOSTANDARD => "LVCMOS33") port map (O => OY8,	I => '0');
end PHY;

