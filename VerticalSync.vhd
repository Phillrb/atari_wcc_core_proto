library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.components_pkg.ALL;

entity VerticalSync is
	Port (
		HRESET  : in  STD_LOGIC;
		VSYNC   : out STD_LOGIC;
		VSYNCn  : out STD_LOGIC;
		V1      : out STD_LOGIC;
		V2      : out STD_LOGIC;
		V4      : out STD_LOGIC;
		V8      : out STD_LOGIC;
		V16     : out STD_LOGIC;
		V32     : out STD_LOGIC;
		V64     : out STD_LOGIC;
		V128    : out STD_LOGIC;
		V256    : out STD_LOGIC;
		V256n   : out STD_LOGIC;
		VRESET  : out STD_LOGIC;
		VRESETn : out STD_LOGIC
	);
end VerticalSync;

architecture Behavioral of VerticalSync is

-- Internal signals
signal B1_p6 : STD_LOGIC;

begin

-- First counter (D1) - generates V1, V2, V4, V8
D1: LS93
	port map(
		P1_CP1n  => V1,
		P2_MR1   => VRESET,
		P3_MR2   => VRESET,
		P8_Q2    => V4,
		P9_Q1    => V2,
		P11_Q3   => V8,
		P12_Q0   => V1,
		P14_CP0n => HRESET
	);

-- Second counter (C1) - generates V16, V32, V64, V128
C1: LS93
	port map(
		P1_CP1n  => V16,
		P2_MR1   => VRESET,
		P3_MR2   => VRESET,
		P8_Q2    => V64,
		P9_Q1    => V32,
		P11_Q3   => V128,
		P12_Q0   => V16,
		P14_CP0n => V8
	);

-- Flip-flop (B2) - generates V256/V256n
B2: LS107
	port map(
		P5_Q2     => V256,
		P6_Q2n    => V256n,
		P8_J2     => '1',
		P9_CLK2   => V128,
		P10_CLR2n => VRESETn,
		P11_K2    => '1'
	);

-- NAND gate (B1) - detects vertical reset condition (V256, V32, V16, V8 all high)
B1: LS20
	port map(
		P1_A1 => V256,
		P2_B1 => V32,
		P4_C1 => V16,
		P5_D1 => V8,
		P6_Y1 => B1_p6
	);

-- Flip-flop (D2) - generates VRESET/VRESETn
D2: LS74
	port map(
		P8_Q2n 	  => VRESET,
		P9_Q2 	  => VRESETn,
		P10_SET2n => '1',
		P11_CLK2  => HRESET,
		P12_D2	  => B1_p6,
		P13_CLR2n => '1'
	);

-- NOR gate (F3) - generates VSYNC/VSYNCn
F3: LS02
    port map(
		P8_A3 	=> V8,
		P9_B3 	=> VSYNCn,
		P10_Y3 	=> VSYNC,
		P11_A4	=> VSYNC,
		P12_B4 	=> VRESET,
		P13_Y4	=> VSYNCn
    );

end Behavioral;
