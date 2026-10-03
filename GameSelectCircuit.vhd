-- Game Select Circuit - TM-035 Figure 10, C5(LS08) gate 4.
-- GAME_SELECT_1 is the settled selector state from JammaSwitchAdapter.
-- That board adapter replaces the original SPDT switch and D9 inverter
-- contact latch (pins 2/4); D9 is not an LS74 flip-flop.
-- C5 pins 12/13/11 suppress one-player mode during attract.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity GameSelectCircuit is
    port (GAME_SELECT_1 : in STD_LOGIC;
          ATRCn : in STD_LOGIC;
          ONE_PLAYER : out STD_LOGIC);
end GameSelectCircuit;
architecture Structural of GameSelectCircuit is
begin
    C5: entity work.LS08
        port map(P1_A1=>'0', P2_B1=>'0', P3_Y1=>open,
                 P4_A2=>'0', P5_B2=>'0', P6_Y2=>open,
                 P9_A3=>'0', P10_B3=>'0', P8_Y3=>open,
                 P12_A4=>ATRCn, P13_B4=>GAME_SELECT_1, P11_Y4=>ONE_PLAYER);
end Structural;
