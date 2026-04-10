library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HorizontalSync is
	Port (
		CLOCK_7 : in  STD_LOGIC;
		HSYNC 	: out STD_LOGIC;
		HSYNCn  : out STD_LOGIC;
		H1      : out STD_LOGIC;
		H2      : out STD_LOGIC;
		H4      : out STD_LOGIC;
		H8      : out STD_LOGIC;
		H16     : out STD_LOGIC;
		H32     : out STD_LOGIC;
		H64     : out STD_LOGIC;
		H64n    : out STD_LOGIC;
		H128    : out STD_LOGIC;
		H256    : out STD_LOGIC;
		H256n   : out STD_LOGIC;
		HRESET  : out STD_LOGIC;
		HRESETn : out STD_LOGIC;
		HBLANK  : out STD_LOGIC;
		HBLANKn : out STD_LOGIC
	);
end HorizontalSync;

architecture Behavioral of HorizontalSync is

-- Internal signals for outputs that are read back (VHDL-93 can't read out ports)
signal h1_i, h2_i, h4_i, h8_i     : STD_LOGIC;
signal h16_i, h32_i, h64_i, h64n_i : STD_LOGIC;
signal h128_i, h256_i, h256n_i     : STD_LOGIC;
signal hreset_i, hresetn_i         : STD_LOGIC;
signal hblank_i, hblankn_i         : STD_LOGIC;
signal C2_p8, C3_p8, D3_p6, J1_p8 : STD_LOGIC;

begin

-- Drive entity outputs from internal signals
H1      <= h1_i;
H2      <= h2_i;
H4      <= h4_i;
H8      <= h8_i;
H16     <= h16_i;
H32     <= h32_i;
H64     <= h64_i;
H64n    <= h64n_i;
H128    <= h128_i;
H256    <= h256_i;
H256n   <= h256n_i;
HRESET  <= hreset_i;
HRESETn <= hresetn_i;
HBLANK  <= hblank_i;
HBLANKn <= hblankn_i;

-- First counter (F1) - generates H1, H2, H4, H8
F1: entity work.LS93
	port map(
		P1_CP1n  => h1_i,
		P2_MR1   => hreset_i,
		P3_MR2   => hreset_i,
		P8_Q2    => h4_i,
		P9_Q1    => h2_i,
		P11_Q3   => h8_i,
		P12_Q0   => h1_i,
		P14_CP0n => CLOCK_7
	);

-- Second counter (E1) - generates H16, H32, H64, H128
E1: entity work.LS93
	port map(
		P1_CP1n  => h16_i,
		P2_MR1   => hreset_i,
		P3_MR2   => hreset_i,
		P8_Q2    => h64_i,
		P9_Q1    => h32_i,
		P11_Q3   => h128_i,
		P12_Q0   => h16_i,
		P14_CP0n => h8_i
	);

-- Flip-flop (B2) - generates H256/H256n
B2: entity work.LS107
	port map(
		P1_J1     => '1',
		P2_Q1n    => h256n_i,
		P3_Q1     => h256_i,
		P4_K1     => '1',
		P12_CLK1  => h128_i,
		P13_CLR1n => hresetn_i
	);

-- NAND gate (C2) - detects reset condition (H4, H2, H128, H256 all high)
C2: entity work.LS30
	port map(
		P1_A  => h4_i,
		P2_B  => h2_i,
		P3_C  => '1',
		P4_D  => '1',
		P5_E  => h128_i,
		P6_F  => h256_i,
		P8_Y  => C2_p8,
		P11_G => '1',
		P12_H => h64_i
	);

-- Flip-flop (D2) - generates HRESET/HRESETn
D2: entity work.LS74
	port map(
		P1_CLR1n => '1',
		P2_D1    => C2_p8,
		P3_CLK1  => CLOCK_7,
		P4_SET1n => '1',
		P5_Q1    => hresetn_i,
		P6_Q1n   => hreset_i
	);

-- NAND gate (C3) - generates HBLANK/HBLANKn
C3: entity work.LS00
	port map(
		P1_A1  => C3_p8,
		P2_B1  => hblank_i,
		P3_Y1  => hblankn_i,
		P4_A2  => hblankn_i,
		P5_B2  => hresetn_i,
		P6_Y2  => hblank_i,
		P8_Y3  => C3_p8,
		P9_A3  => h16_i,
		P10_B3 => h64_i
	);

-- Inverter (A1) - generates H64n
A1: entity work.LS04
	port map(
		P1_A1 => h64_i,
		P2_Y1 => h64n_i
	);

-- AND gate (D3) - combines H64n and HBLANK
D3: entity work.LS08
	port map(
		P4_A2 => h64n_i,
		P5_B2 => hblank_i,
		P6_Y2 => D3_p6
	);

-- NAND gate (J1) - generates HSYNC timing
J1: entity work.LS00
	port map(
		P8_Y3  => J1_p8,
		P9_A3  => h32_i,
		P10_B3 => h64n_i
	);

-- Flip-flop (E2) - generates HSYNC/HSYNCn
E2: entity work.LS74
	port map(
		P1_CLR1n => D3_p6,
		P2_D1    => J1_p8,
		P3_CLK1  => h16_i,
		P4_SET1n => '1',
		P5_Q1    => HSYNC,
		P6_Q1n   => HSYNCn
	);

end Behavioral;
