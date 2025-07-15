library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_atari_wcc is
end tb_atari_wcc;

architecture sim of tb_atari_wcc is
    signal Clock_50 : std_logic := '0';
    signal PushBtn  : std_logic := '0';
    signal LED0, LED1, LED2, CSync_out : std_logic;
begin
    -- Instantiate the DUT (Device Under Test)
    uut: entity work.atari_wcc
        port map (
            Clock_50   => Clock_50,
            PushBtn    => PushBtn,
            LED0       => LED0,
            LED1       => LED1,
            LED2       => LED2,
            CSync_out  => CSync_out
        );

    -- Generate a 50 MHz clock (20 ns period)
    process
    begin
        Clock_50 <= '0';
        wait for 10 ns;
        Clock_50 <= '1';
        wait for 10 ns;
    end process;

    -- Example: Toggle PushBtn after 1 us
    process
    begin
        wait for 1 us;
        PushBtn <= '1';
        wait for 1 us;
        PushBtn <= '0';
        wait;
    end process;
end sim;