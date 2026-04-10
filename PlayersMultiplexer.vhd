-- Players Multiplexer - Goal IV (WCC) TM-035 Figure 11
-- L7 and H7 (74LS153 dual 4:1). Select = TEAM (S1) and Qn (S0) from vertical window.
-- L7: B1-B4 -> 1Y=PP2; C1-C4 -> 2Y=PP3. B1 (M7 pin 13) -> L7 pin 6 (1I0); C1 (M7 pin 12) -> L7 pin 10 (2I0).
-- H7: D1-D4 -> 1Y=PP4; E1-E4 -> 2Y (to M1 pin 5). D1 (M7 pin 11) -> H7 pin 6 (1I0). H7 pin 15 = PLAYER_WINDOWn.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PlayersMultiplexer is
    Port (
        TEAM            : in  STD_LOGIC;
        Qn              : in  STD_LOGIC;   -- D6 pin 8 (Q2n)
        PLAYER_WINDOWn  : in  STD_LOGIC;   -- H6 pin 6 -> H7 pin 15
        B1              : in  STD_LOGIC;
        B2              : in  STD_LOGIC;
        B3              : in  STD_LOGIC;
        B4              : in  STD_LOGIC;
        C1              : in  STD_LOGIC;
        C2              : in  STD_LOGIC;
        C3              : in  STD_LOGIC;
        C4              : in  STD_LOGIC;
        D1              : in  STD_LOGIC;
        D2              : in  STD_LOGIC;
        D3              : in  STD_LOGIC;
        D4              : in  STD_LOGIC;
        E1              : in  STD_LOGIC;
        E2              : in  STD_LOGIC;
        E3              : in  STD_LOGIC;
        E4              : in  STD_LOGIC;
        PP2             : out STD_LOGIC;
        PP3             : out STD_LOGIC;
        PP4             : out STD_LOGIC;
        SYMBOL          : out STD_LOGIC    -- H7 pin 9 (2Y) -> M1 pin 5
    );
end PlayersMultiplexer;

architecture Schematic of PlayersMultiplexer is
begin
    -- L7 (LS153): both enables low; select S1=TEAM, S0=Qn; 1Y=PP2, 2Y=PP3
    IC_L7: entity work.LS153
        port map(
            P1_Ea    => '0',
            P2_S1    => TEAM,
            P14_S0   => Qn,
            P6_1I0   => B1,
            P5_1I1   => B2,
            P4_1I2   => B3,
            P3_1I3   => B4,
            P7_1Y    => PP2,
            P10_2I0  => C1,
            P11_2I1  => C2,
            P12_2I2  => C3,
            P13_2I3  => C4,
            P9_2Y    => PP3,
            P15_Eb   => '0'
        );

    -- H7 (LS153): Ea=0; Eb=PLAYER_WINDOWn (enable mux 2 when window active); S1=TEAM, S0=Qn; 1Y=PP4, 2Y=SYMBOL
    IC_H7: entity work.LS153
        port map(
            P1_Ea    => '0',
            P2_S1    => TEAM,
            P14_S0   => Qn,
            P6_1I0   => D1,
            P5_1I1   => D2,
            P4_1I2   => D3,
            P3_1I3   => D4,
            P7_1Y    => PP4,
            P10_2I0  => E1,
            P11_2I1  => E2,
            P12_2I2  => E3,
            P13_2I3  => E4,
            P9_2Y    => SYMBOL,
            P15_Eb   => PLAYER_WINDOWn
        );
end Schematic;
