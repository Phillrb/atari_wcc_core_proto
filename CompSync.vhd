library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CompSync is
	Port (
		CLOCK_14 : in  STD_LOGIC;
		CSYNC 	: out STD_LOGIC
	);
end CompSync;

architecture Behavioral of CompSync is

signal C2_p8, C3_p8, D3_p6, E2_p8, J1_p8, B1_p6 : STD_LOGIC;

signal CLOCK_7 : STD_LOGIC;
signal HSYNC, HSYNCn : STD_LOGIC;
signal H1, H2, H4, H8, H16, H32, H64, H64n, H128, H256, H256n : STD_LOGIC;
signal HRESET, HRESETn : STD_LOGIC;
signal HBLANK, HBLANKn : STD_LOGIC;
signal VSYNC, VSYNCn : STD_LOGIC;
signal V1, V2, V4, V8, V16, V32, V64, V128, V256, V256n : STD_LOGIC;
signal VRESET, VRESETn : STD_LOGIC;

component LS00 is
port( P1_A1  : in  STD_LOGIC := '0';
		P2_B1  : in  STD_LOGIC := '0';
		P3_Y1  : out STD_LOGIC;
	  
		P4_A2  : in  STD_LOGIC := '0';
		P5_B2  : in  STD_LOGIC := '0';
		P6_Y2  : out STD_LOGIC;
	  
		P8_Y3  : out STD_LOGIC;
		P9_A3  : in  STD_LOGIC := '0';
		P10_B3 : in  STD_LOGIC := '0';
	  
		P11_Y4 : out STD_LOGIC;
		P12_A4 : in  STD_LOGIC := '0';
		P13_B4 : in  STD_LOGIC := '0');
end component;

component LS02 is
	Port (
		P1_Y1 	: out STD_LOGIC;
		P2_A1 	: in  STD_LOGIC := '0';
		P3_B1		: in  STD_LOGIC := '0';
		P4_Y2 	: out STD_LOGIC;
		P5_A2		: in  STD_LOGIC := '0';
		P6_B2 	: in  STD_LOGIC := '0';
		-- P7 : GND
		P8_A3 	: in  STD_LOGIC := '0';
		P9_B3 	: in  STD_LOGIC := '0';
		P10_Y3 	: out	STD_LOGIC;
		P11_A4	: in  STD_LOGIC := '0';
		P12_B4 	: in  STD_LOGIC := '0';
		P13_Y4	: out STD_LOGIC
		-- P14 : VCC
	);
end component;

component LS04 is
port (P1_A1 	: in  STD_LOGIC := '0';
		P2_Y1 	: out STD_LOGIC;
		
		P3_A2		: in  STD_LOGIC := '0';
		P4_Y2 	: out STD_LOGIC;
		
		P5_A3		: in  STD_LOGIC := '0';
		P6_Y3 	: out STD_LOGIC;
		
		P8_Y4 	: out STD_LOGIC;
		P9_A4 	: in  STD_LOGIC := '0';
		
		P10_Y5 	: out STD_LOGIC;
		P11_A5	: in  STD_LOGIC := '0';
		
		P12_Y6 	: out STD_LOGIC;
		P13_A6	: in  STD_LOGIC := '0');
end component;

component LS08 is
port(P1_A1  : in  STD_LOGIC := '0';
	  P2_B1  : in  STD_LOGIC := '0';
	  P3_Y1  : out STD_LOGIC;
	  
	  P4_A2  : in  STD_LOGIC := '0';
	  P5_B2  : in  STD_LOGIC := '0';
	  P6_Y2  : out STD_LOGIC;
	  
	  P8_Y3  : out STD_LOGIC;
	  P9_A3  : in  STD_LOGIC := '0';
	  P10_B3 : in  STD_LOGIC := '0';
	  
	  P11_Y4 : out STD_LOGIC;
	  P12_A4 : in  STD_LOGIC := '0';
	  P13_B4 : in  STD_LOGIC := '0');
end component;

component LS20 is
	Port (
		P1_A1	 : in  STD_LOGIC := '0';
		P2_B1  : in  STD_LOGIC := '0';
		-- P3  : NC
		P4_C1  : in  STD_LOGIC := '0';
		P5_D1  : in  STD_LOGIC := '0';
		P6_Y1	 : out STD_LOGIC;
		-- P7  : GND
		P8_Y2	 : out STD_LOGIC;
		P9_D2  : in  STD_LOGIC := '0';
		P10_C2 : in  STD_LOGIC := '0';
		-- P11 : NC
		P12_B2 : in  STD_LOGIC := '0';
		P13_A2 : in  STD_LOGIC := '0'
		-- P14 : VCC
	);
end component;

component LS30 is
port (P1_A	 : in  STD_LOGIC := '0';
		P2_B 	 : in  STD_LOGIC := '0';
		P3_C	 : in  STD_LOGIC := '0';
		P4_D 	 : in  STD_LOGIC := '0';
		P5_E	 : in  STD_LOGIC := '0';
		P6_F 	 : in  STD_LOGIC := '0';
		-- P7  : GND
		P8_Y 	 : out STD_LOGIC;
		-- P9  : NC
		-- P10 : NC
		P11_G	 : in  STD_LOGIC := '0';
		P12_H  : in  STD_LOGIC := '0'
		-- P13 : NC
		-- P14 : VCC
	);
end component;

component LS74 is
	Port (
		P1_CLR1n : in  STD_LOGIC := '1';
		P2_D1 	: in  STD_LOGIC := '0';
		P3_CLK1	: in  STD_LOGIC := '0';
		P4_SET1n : in  STD_LOGIC := '1';
		P5_Q1    : out STD_LOGIC;
		P6_Q1n   : out STD_LOGIC;
		-- P7 : GND
		P8_Q2n 	: out STD_LOGIC;
		P9_Q2 	: out STD_LOGIC;
		P10_SET2n : in STD_LOGIC := '1';
		P11_CLK2	:  in STD_LOGIC := '0';
		P12_D2	:  in STD_LOGIC := '0';
		P13_CLR2n : in STD_LOGIC := '1'
		-- P14 : VCC
	);
end component;

component LS86 is
	Port (
		P1_A1 	: in  STD_LOGIC := '0';
		P2_B1 	: in  STD_LOGIC := '0';
		P3_Y1		: out STD_LOGIC;
		P4_A2 	: in  STD_LOGIC := '0';
		P5_B2		: in  STD_LOGIC := '0';
		P6_Y2 	: out STD_LOGIC;
		-- P7 : GND
		P8_Y3 	: out STD_LOGIC;
		P9_A3 	: in  STD_LOGIC := '0';
		P10_B3 	: in	STD_LOGIC := '0';
		P11_Y4	: out STD_LOGIC;
		P12_A4 	: in  STD_LOGIC := '0';
		P13_B4	: in  STD_LOGIC := '0'
		-- P14 : VCC
	);
end component;

component LS93 is
 Port (
		P1_CP1n 	: in  STD_LOGIC := '1';
		P2_MR1 	: in  STD_LOGIC := '1';
   	P3_MR2	: in  STD_LOGIC := '1';
		-- P4 : NC
		-- P5 : VCC
		-- P6 : NC
		-- P7 : NC
		P8_Q2 	: out STD_LOGIC;
		P9_Q1 	: out STD_LOGIC;
		-- P10 : GND
		P11_Q3	: out STD_LOGIC;
		P12_Q0	: out STD_LOGIC;
		-- P13 : NC
		P14_CP0n : in  STD_LOGIC := '1'
	);
end component;

component LS107 is
	Port (
		P1_J1    : in  STD_LOGIC := '0';
		P2_Q1n 	: out STD_LOGIC;
		P3_Q1 	: out STD_LOGIC;
		P4_K1    : in  STD_LOGIC := '0';
		P5_Q2    : out STD_LOGIC;
		P6_Q2n   : out STD_LOGIC;
		-- P7 : GND
		P8_J2 	 : in STD_LOGIC := '0';
		P9_CLK2 	 : in STD_LOGIC := '1';
		P10_CLR2n : in STD_LOGIC := '1';
		P11_K2	 : in STD_LOGIC := '0';
		P12_CLK1	 : in STD_LOGIC := '1';
		P13_CLR1n : in STD_LOGIC := '1'
		-- P14 : VCC
	);
end component;
	
begin

F1: LS93
	port map(
		H1,
		HRESET,
		HRESET,
		H4,
		H2,
		H8,
		H1,
		CLOCK_7
	);
	
E1: LS93
	port map(
		H16,
		HRESET,
		HRESET,
		H64,
		H32,
		H128,
		H16,
		H8
	);
	
B2: LS107
	port map(
		'1',
		H256n,
		H256,
		'1',
		
		V256,
		V256n,
		'1',
		V128,
		VRESETn,
		'1',
		
		H128,
		HRESETn
	);
	
C2: LS30
	port map(
		H4,
		H2,
		'1',
		'1',
		H128,
		H256,
		C2_p8,
		'1',
		H64
	);

D2: LS74
	port map(
		'1',
		C2_p8,
		CLOCK_7,
		'1',
		HRESETn,
		HRESET,
		
		VRESET,
		VRESETn,
		'1',
		HRESET,
		B1_p6,
		'1'
	);
 
C3: LS00
	port map(
		C3_p8,
		HBLANK,
		HBLANKn,
		HBLANKn,
		HRESETn,
		HBLANK,
		C3_p8,
		H16,
		H64
		--P11_Y4,
		--P12_A4,
		--P13_B4
	);
	
A1: LS04
	port map(
		H64,
		H64n
		--P3_A2,
		--P4_Y3,
		--P5_A3,
		--P6_Y3,
		--P8_Y4,
		--P9_A4,
		--P10_Y5,
		--P11_A5,
		--P12_Y6,
		--P13_A6
	);
	
D3: LS08
	port map(
		--P1_A1,
		--P2_B1,
		--P3_Y1,
		P4_A2 => H64n,
		P5_B2 => HBLANK,
		P6_Y2 => D3_p6
		--P8_Y3,
		--P9_A3,
		--P10_B3,
		--P11_Y4,
		--P12_A4,
		--P13_B4
	);
	
J1: LS00
	port map(
		--P1_A1,
		--P2_B1,
		--P3_Y1,
		--P4_A2,
		--P5_B2,
		--P6_Y2,
		P8_Y3 => J1_p8,
		P9_A3 => H32,
		P10_B3 => H64n
		--P11_Y4,
		--P12_A4,
		--P13_B4
	);
	
D1: LS93
	port map(
		V1,
		VRESET,
   	VRESET,
		V4,
		V2,
		V8,
		V1,
		HRESET
	);
	
C1: LS93
	port map(
		V16,
		VRESET,
   	VRESET,
		V64,
		V32,
		V128,
		V16,
		V8
	);
	
B1: LS20
	port map(
		V256,
		V32,
		V16,
		V8,
		B1_p6
		
		--P8_Y2,
		--P9_D2,
		--P10_C2,
		--P12_B2,
		--P13_A2
	);
	
E2: LS74
	port map(
		D3_p6,
		J1_p8,
		H16,
		'1',
		HSYNC,
		HSYNCn,
		
		E2_p8,
		CLOCK_7,
		'1',
		CLOCK_14,
		E2_p8,
		'1'
	);
	
F3: LS02
	port map(
		--P1_Y1,
		--P2_A1,
		--P3_B1,
		--P4_Y2,
		--P5_A2,
		--P6_B2,
		P8_A3  => V8,
		P9_B3  => VSYNCn,
		P10_Y3 => VSYNC,
		P11_A4 => VSYNC,
		P12_B4 => VRESET,
		P13_Y4 => VSYNCn
	);
	
A5: LS86
	port map (
		--P1_A1,
		--P2_B1,
		--P3_Y1,
		P4_A2 => VSYNCn,
		P5_B2	=> HSYNC,
		P6_Y2 => CSYNC
		--P8_Y3,
		--P9_A3,
		--P10_B3,
		--P11_Y4,
		--P12_A4,
		--P13_B4
	);

-- PushBtn
--	LED0 <= not jk_Q;
--	LED1 <= not jk_Qn;
--	LED2 <= '1';
	
end Behavioral;
