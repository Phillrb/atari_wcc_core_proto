library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.components_pkg.ALL;

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

-- Internal signals
signal C2_p8, C3_p8, D3_p6, J1_p8 : STD_LOGIC;

begin

-- First counter (F1) - generates H1, H2, H4, H8
F1: LS93
	port map(
		P1_CP1n  => H1,
		P2_MR1   => HRESET,
		P3_MR2   => HRESET,
		P8_Q2    => H4,
		P9_Q1    => H2,
		P11_Q3   => H8,
		P12_Q0   => H1,
		P14_CP0n => CLOCK_7
	);

-- Second counter (E1) - generates H16, H32, H64, H128
E1: LS93
	port map(
		P1_CP1n  => H16,
		P2_MR1   => HRESET,
		P3_MR2   => HRESET,
		P8_Q2    => H64,
		P9_Q1    => H32,
		P11_Q3   => H128,
		P12_Q0   => H16,
		P14_CP0n => H8
	);

-- Flip-flop (B2) - generates H256/H256n
B2: LS107
	port map(
		P1_J1     => '1',
		P2_Q1n    => H256n,
		P3_Q1     => H256,
		P4_K1     => '1',
		P12_CLK1  => H128,
		P13_CLR1n => HRESETn
	);

-- NAND gate (C2) - detects reset condition (H4, H2, H128, H256 all high)
C2: LS30
	port map(
		P1_A1 => H4,
		P2_B1 => H2,
		P3_C1 => '1',
		P4_D1 => '1',
		P5_E1 => H128,
		P6_F1 => H256,
		P8_Y  => C2_p8,
		P11_G1 => '1',
		P12_H1 => H64
	);

-- Flip-flop (D2) - generates HRESET/HRESETn
D2: LS74
	port map(
		P1_CLR1n => '1',
		P2_D1    => C2_p8,
		P3_CLK1  => CLOCK_7,
		P4_SET1n => '1',
		P5_Q1    => HRESETn,
		P6_Q1n   => HRESET
	);

-- NAND gate (C3) - generates HBLANK/HBLANKn
C3: LS00
	port map(
		P1_A1 => C3_p8,
		P2_B1 => HBLANK,
		P3_Y1 => HBLANKn,
		P4_A2 => HBLANKn,
		P5_B2 => HRESETn,
		P6_Y2 => HBLANK,
		P8_A3 => C3_p8,
		P9_B3 => H16,
		P10_Y3 => H64
	);

-- Inverter (A1) - generates H64n
A1: LS04
	port map(
		P1_A1 => H64,
		P2_Y1 => H64n
	);

-- AND gate (D3) - combines H64n and HBLANK
D3: LS08
	port map(
		P4_A2 => H64n,
		P5_B2 => HBLANK,
		P6_Y2 => D3_p6
	);

-- NAND gate (J1) - generates HSYNC timing
J1: LS00
	port map(
		P8_A3 => J1_p8,
		P9_B3 => H32,
		P10_Y3 => H64n
	);

-- Flip-flop (E2) - generates HSYNC/HSYNCn
E2: LS74
	port map(
		P1_CLR1n => D3_p6,
		P2_D1    => J1_p8,
		P3_CLK1  => H16,
		P4_PRE1n => '1',
		P5_Q1    => HSYNC,
		P6_Q1n   => HSYNCn
	);

end Behavioral;