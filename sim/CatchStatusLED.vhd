-- Temporary board diagnostic, not a TM-035 circuit.
-- Active-low LED: 1P displays either debounced kick; 2P displays STOP.
library ieee;
use ieee.std_logic_1164.all;
entity CatchStatusLED is
    port (ONE_PLAYER, SOLID_KICK, CHECKED_KICK, STOPn : in std_logic;
          LEDn : out std_logic);
end;
architecture Structural of CatchStatusLED is
    signal kicks_n : std_logic;
begin
    U_KICKS: entity work.LS02
        port map(P2_A1=>SOLID_KICK, P3_B1=>CHECKED_KICK, P1_Y1=>kicks_n,
            P5_A2=>'0', P6_B2=>'0', P4_Y2=>open,
            P8_A3=>'0', P9_B3=>'0', P10_Y3=>open,
            P11_A4=>'0', P12_B4=>'0', P13_Y4=>open);
    U_SELECT: entity work.LS153
        port map(P1_Ea=>'0', P2_S1=>'0', P14_S0=>ONE_PLAYER,
            P6_1I0=>STOPn, P5_1I1=>kicks_n, P4_1I2=>'1', P3_1I3=>'1', P7_1Y=>LEDn,
            P10_2I0=>'0', P11_2I1=>'0', P12_2I2=>'0', P13_2I3=>'0',
            P9_2Y=>open, P15_Eb=>'1');
end;
